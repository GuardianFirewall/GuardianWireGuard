//
//  GRDKeychain.swift
//  GRDWireGuardKitmacOS
//
//  Created by Constantin Jacob on 16.03.22.
//

import Foundation
import Security

class GRDKeychain {
	static func keychainBaseQuery(bundleIdentifier: String) -> [CFString: Any] {
		var query = [CFString: Any]()
		query[kSecClass as CFString] = kSecClassGenericPassword
		query[kSecAttrAccount] = "GuardianConnect WireGuard Config"
        query[kSecAttrService as CFString] = bundleIdentifier
		
		return query
	}
	
	static func loadWGQuickConfig(bundleId: String) -> String? {
		var query = keychainBaseQuery(bundleIdentifier: bundleId)
		query[kSecMatchLimit] = kSecMatchLimitOne
		query[kSecReturnData] = true
			
		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecSuccess {
			guard let data = result as? Data, let password = String(data: data, encoding: .utf8) else {
				NSLog("[ERROR] Failed to decode wg-quick config data to string")
				return nil
			}
			return password
			
		} else {
			NSLog("[ERROR] Failed to read wg-quick config from keychain: \(status).")
			return nil
		}
	}
		
	static func saveWGQuickConfig(bundleId: String, wgQuickConfig: String) -> Bool {
		if let oldWGQuickConfig = Self.loadWGQuickConfig(bundleId: bundleId) {
			if oldWGQuickConfig == wgQuickConfig {
				NSLog("[INFO] New wg-quick config is the same as the old wg-quick config. Skipping keychain write.")
				return true
				
			} else {
				NSLog("[WARNING] wg-quick config to delete found in the keychain.")
				Self.deleteWGQuickConfig(bundleId: bundleId)
			}
			
		} else {
			NSLog("[INFO] No wg-quick config in the keychain. Writing new keychain item")
		}
			
		var query = Self.keychainBaseQuery(bundleIdentifier: bundleId)
		query[kSecClass] = kSecClassGenericPassword
		query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
		query[kSecValueData] = wgQuickConfig.data(using: .utf8)
		query[kSecAttrLabel] = bundleId

		let status = SecItemAdd(query as CFDictionary, nil)
		if status != errSecSuccess {
			NSLog("[ERROR] Failed to write wg-quick to keychain: \(status).")
			return false
		}
		return true
	}
		
	static func deleteWGQuickConfig(bundleId: String) {
		let query = Self.keychainBaseQuery(bundleIdentifier: bundleId)
		
		let ret = SecItemDelete(query as CFDictionary)
		if ret != errSecSuccess {
			NSLog("[ERROR] Failed to delete wg-quick config from keychain: \(ret)")
		}
	}
}
