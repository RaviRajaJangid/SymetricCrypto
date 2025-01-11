//
//  KeyManager.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import Foundation
import CryptoKit

class KeyManager {

    // Save key to Keychain
    static func saveKey(_ key: SymmetricKey, forFile filename: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "\(App.bundleId).\(filename)",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
//            dlog("CRYPTO  Key added successfully!")
        } else if status == errSecDuplicateItem {
            // The key already exists, so update it
//            dlog("CRYPTO  Key already exists in the Keychain. Updating the key.")
            
            // Define the update query, specifying the new key data
            let updateQuery: [String: Any] = [
                kSecValueData as String: keyData
            ]
            
            // Update the key in the Keychain
            let updateStatus = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            
            if updateStatus == errSecSuccess {
//                dlog("CRYPTO  Key updated successfully!")
            } else {
//                dlog("CRYPTO  Failed to update key: \(updateStatus)")
                throw CryptoError.keyFailedToUpdate
            }
        } else {
//            dlog("CRYPTO  Failed to add key: \(status)")
            throw CryptoError.keySaveError
        }
    }
    
    // Load key from Keychain
    static func loadKey(forFile filename: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "\(App.bundleId).\(filename)",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw CryptoError.keyLoadingError
        }
        
        return SymmetricKey(data: keyData)
    }
}
