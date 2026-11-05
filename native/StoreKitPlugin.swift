//
//  StoreKitPlugin.swift
//  EMS Narrator
//
//  Purchasing uses StoreKit1 (SKPaymentQueue / SKPaymentTransactionObserver).
//  Entitlement CHECKING (checkEntitlement, below) uses StoreKit2's
//  Transaction.currentEntitlements, which is safe to use alongside StoreKit1
//  purchasing on iOS 15+ and gives real, cryptographically-verified proof of
//  an active subscription without a server-side receipt validator. This is a
//  deliberate hybrid: StoreKit1 for the purchase UI flow (matches the rest of
//  this plugin), StoreKit2 for the one thing it does better — answering
//  "is this device currently entitled?" — which is what app-launch checks need.
//

import Foundation
import StoreKit
import Capacitor

@objc(StoreKitPlugin)
public class StoreKitPlugin: CAPPlugin, SKPaymentTransactionObserver, SKProductsRequestDelegate {

    static let tag = "StoreKitPlugin"
    let defaultProductId = "com.supersonicandchill.emsnarrator.monthly"

    // Holds the pending purchase call while we wait on the product fetch
    private var pendingPurchaseCall: CAPPluginCall?
    private var productsRequest: SKProductsRequest?

    override public func load() {
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Entitlement Check (StoreKit2)
    // Real truth-check for "does this device currently hold an active,
    // non-revoked subscription to our product?" — checked against Apple's
    // signed transaction data, not a local flag. Call this on every app
    // launch before trusting any locally-cached "subscribed" state.
    @objc func checkEntitlement(_ call: CAPPluginCall) {
        let productIdentifier = call.getString("productIdentifier") ?? defaultProductId

        if #available(iOS 15.0, *) {
            Task {
                var isEntitled = false
                var expirationDate: String? = nil

                for await result in Transaction.currentEntitlements {
                    // .verified means Apple's signature check passed — this is
                    // the cryptographic verification a local flag can't give you.
                    guard case .verified(let transaction) = result else { continue }
                    guard transaction.productID == productIdentifier else { continue }
                    guard transaction.revocationDate == nil else { continue }

                    if let expiry = transaction.expirationDate {
                        if expiry > Date() {
                            isEntitled = true
                            expirationDate = ISO8601DateFormatter().string(from: expiry)
                        }
                    } else {
                        // Non-expiring entitlement (shouldn't normally apply to
                        // an auto-renewable subscription, but handle it safely).
                        isEntitled = true
                    }
                }

                call.resolve([
                    "entitled": isEntitled,
                    "expirationDate": expirationDate as Any
                ])
            }
        } else {
            // Below iOS 15, StoreKit2 isn't available. Fall back to telling
            // the caller we couldn't verify — JS should treat this as
            // "unknown" and keep relying on restoreTransactions() instead,
            // not silently assume entitled or not-entitled.
            call.reject("StoreKit2 entitlement check requires iOS 15+.")
        }
    }

    // MARK: - Purchase Method
    // Real products must be FETCHED from Apple via SKProductsRequest before
    // you can build a valid SKPayment — you cannot construct a usable
    // SKProduct yourself. This method kicks off that fetch; the actual
    // payment is added to the queue once productsRequest(_:didReceive:) fires.
    @objc func purchaseProduct(_ call: CAPPluginCall) {
        guard SKPaymentQueue.canMakePayments() else {
            call.reject("In-app purchases are disabled on this device.")
            return
        }

        let productIdentifier = call.getString("productIdentifier") ?? defaultProductId
        pendingPurchaseCall = call

        let request = SKProductsRequest(productIdentifiers: [productIdentifier])
        request.delegate = self
        productsRequest = request
        request.start()
    }

    // MARK: - SKProductsRequestDelegate
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            guard let product = response.products.first else {
                let invalidIds = response.invalidProductIdentifiers.joined(separator: ", ")
                self.pendingPurchaseCall?.reject("Product not found in App Store Connect. Invalid ID(s): \(invalidIds)")
                self.pendingPurchaseCall = nil
                return
            }

            // Now we have a REAL SKProduct fetched from Apple — safe to build a payment from it
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)

            self.pendingPurchaseCall?.resolve(["status": "processing"])
            self.pendingPurchaseCall = nil
        }
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.pendingPurchaseCall?.reject("Failed to fetch product: \(error.localizedDescription)")
            self.pendingPurchaseCall = nil
        }
    }

    // MARK: - Restore Purchases
    @objc func restoreTransactions(_ call: CAPPluginCall) {
        SKPaymentQueue.default().restoreCompletedTransactions()
        call.resolve(["status": "restoring"])
    }

    // MARK: - SKPaymentTransactionObserver
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                DispatchQueue.main.async {
                    self.notifyListeners("purchaseSuccess", data: [
                        "productIdentifier": transaction.payment.productIdentifier,
                        "transactionId": transaction.transactionIdentifier ?? "unknown"
                    ])
                    SKPaymentQueue.default().finishTransaction(transaction)
                }

            case .failed:
                DispatchQueue.main.async {
                    self.notifyListeners("purchaseFailed", data: [
                        "error": transaction.error?.localizedDescription ?? "Unknown error"
                    ])
                    SKPaymentQueue.default().finishTransaction(transaction)
                }

            case .restored:
                DispatchQueue.main.async {
                    self.notifyListeners("purchaseRestored", data: [
                        "productIdentifier": transaction.payment.productIdentifier,
                        "transactionId": transaction.transactionIdentifier ?? "unknown"
                    ])
                    SKPaymentQueue.default().finishTransaction(transaction)
                }

            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
}
