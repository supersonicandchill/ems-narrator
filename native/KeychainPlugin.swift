//
//  KeychainPlugin.swift
//  EMS Narrator
//
//  Secure on-device storage for the user's Anthropic API key.
//  Uses the iOS Keychain (Security framework) — NOT localStorage/UserDefaults,
//  which are not encrypted at rest. This matters because the API key is a
//  credential, not app preference data.
//

import Foundation
import Capacitor
import Security

@objc(KeychainPlugin)
public class KeychainPlugin: CAPPlugin {

    // Service string scopes these entries to this app in the Keychain.
    private let service = "com.supersonicandchill.emsnarrator.apikey"
    private let account = "anthropic_api_key"

    // MARK: - Save (upsert)
    @objc func setKey(_ call: CAPPluginCall) {
        guard let value = call.getString("value"), !value.isEmpty else {
            call.reject("No value provided to store.")
            return
        }

        guard let data = value.data(using: .utf8) else {
            call.reject("Could not encode key value.")
            return
        }

        // Remove any existing entry first so this is a clean upsert.
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            // Accessible only while the device is unlocked, and never
            // synced to iCloud Keychain or migrated to a new device —
            // appropriate for a per-device API credential.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecSuccess {
            call.resolve(["status": "saved"])
        } else {
            call.reject("Keychain save failed with OSStatus \(status)")
        }
    }

    // MARK: - Get
    @objc func getKey(_ call: CAPPluginCall) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data, let value = String(data: data, encoding: .utf8) {
            call.resolve(["value": value])
        } else if status == errSecItemNotFound {
            // Not an error — just means no key has been saved yet.
            call.resolve(["value": NSNull()])
        } else {
            call.reject("Keychain read failed with OSStatus \(status)")
        }
    }

    // MARK: - Delete
    @objc func deleteKey(_ call: CAPPluginCall) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            call.resolve(["status": "deleted"])
        } else {
            call.reject("Keychain delete failed with OSStatus \(status)")
        }
    }
}
