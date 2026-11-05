//
//  StoreKitPlugin.m
//  EMS Narrator
//
//  Capacitor bridge registration for StoreKitPlugin.swift.
//  Without this file, window.Capacitor.Plugins.StoreKit does not exist
//  in JavaScript — the Swift class alone is not enough to expose it.
//  Exposes: purchaseProduct, restoreTransactions, and checkEntitlement
//  (StoreKit2-based launch-time subscription verification).
//

#import <Capacitor/Capacitor.h>

CAP_PLUGIN(StoreKitPlugin, "StoreKit",
  CAP_PLUGIN_METHOD(purchaseProduct, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(restoreTransactions, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(checkEntitlement, CAPPluginReturnPromise);
)
