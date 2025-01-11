//
//  SecManager.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import Foundation
import Security
import CryptoKit
enum SecAlgo {
    ///AttrKeyType: kSecAttrKeyTypeEC, bitSize:256, encryptionAlgorithm: eciesEncryptionStandardX963SHA256AESGCM
    case ecc
    ///AttrKeyType: kSecAttrKeyTypeRSA, bitSize: 2048, encryptionAlgorithm: rsaEncryptionOAEPSHA512,
    case rsa
    
    var getType: SecKeyAlgorithm {
        switch self  {
        case .ecc:
            return .eciesEncryptionStandardX963SHA256AESGCM
        case .rsa:
            return .rsaEncryptionOAEPSHA512
        }
    }
}

enum SecManagerError: Error {
    case keyGenerationFailed(desc: String)
    case failedToGeneratePublicKey
    case encryptionFailed(desc: String)
    case decryptionFailed(desc: String)
    case fileEncryptionFailed(desc: String)
    case fileDecryptionFailed(desc: String)
}
class AsymmetricCrypto {
    let algo: SecAlgo
    
    init(algo: SecAlgo = .ecc) {
        self.algo = algo
    }
    // Generate RSA Key Pair in Secure Enclave
    func generateRSAKeyPair()throws -> (privateKey: SecKey, publicKey: SecKey) {
        // Create a unique tag for the key pair
        let tag = Util.bundleId.data(using: .utf8)!
        
        // Define key parameters
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            kSecAttrIsPermanent: true,
            kSecAttrApplicationTag: tag,
            kSecPublicKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag
            ] as [String: Any],
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
            ] as [String: Any]
        ]
        
        // First, try to delete any existing key with the same tag
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw SecManagerError.keyGenerationFailed(desc: String(describing: error))
            
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw SecManagerError.failedToGeneratePublicKey
        }
        
        return (privateKey, publicKey)
    }
    
    // Generate ECC Key Pair in Secure Enclave
    func generateECCKeyPair() throws -> (privateKey: SecKey, publicKey: SecKey) {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeEC, // Use kSecAttrKeyTypeRSA for RSA
            kSecAttrKeySizeInBits: 256,  // For ECC (256-bit) or 2048 for RSA
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrIsPermanent: true,
            kSecAttrApplicationTag: Util.bundleId.data(using: .utf8)!
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            dlog("Error generating key: \(String(describing: error))")
            throw SecManagerError.keyGenerationFailed(desc: String(describing: error))
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            dlog("Failed to get public key")
            throw SecManagerError.failedToGeneratePublicKey
        }
        
        return (privateKey, publicKey)
    }
    
    ///Encrypt Data (using public key)
    func encryptData(data: Data, publicKey: SecKey)throws -> Data? {
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey,
                                                            algo.getType,  // Choose Encryption algorithm
                                                            data as CFData, &error) else {
            dlog("Encryption failed: \(String(describing: error))")
            throw SecManagerError.encryptionFailed(desc: String(describing: error))
        }
        return encryptedData as Data
    }
    
    ///Decrypt Data (using private key)
    func decryptData(data: Data, privateKey: SecKey)throws -> Data? {
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey,
                                                            algo.getType,  // Choose Decryption algorithm
                                                            data as CFData, &error) else {
            dlog("Decryption failed: \(String(describing: error))")
            throw SecManagerError.decryptionFailed(desc: String(describing: error))
        }
        return decryptedData as Data
    }
    
    ///    Encrypt File
    ///    For file encryption, read the file data, encrypt it in chunks (if large), and write the encrypted data to a new file.
    func encryptFile(inputURL: URL, outputURL: URL, publicKey: SecKey) throws {
        do {
            
            let fileData = try Data(contentsOf: inputURL)
            
            if let encryptedData = try encryptData(data: fileData, publicKey: publicKey) {
                try encryptedData.write(to: outputURL)
                //                // Encrypt the data
                //                let sealedBox = try AES.GCM.seal(data, using: key)
                //                let encryptedData = sealedBox.combined!
                
                // Save to file
                let fileURL = outputURL
                try encryptedData.write(to: fileURL, options: .completeFileProtection)
                
                // Set file protection
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                      ofItemAtPath: fileURL.path)
                
                dlog("File encrypted successfully!")
                
            } else {
                print("Encryption failed.")
                throw SecManagerError.fileEncryptionFailed(desc: inputURL.absoluteString)
            }
        } catch {
            print("Error reading file: \(error)")
            throw SecManagerError.fileEncryptionFailed(desc: error.localizedDescription)
        }
    }
    
    
    ///    Decrypt File
    ///    For decrypting the file, read the encrypted data, decrypt it, and write the decrypted data to a new file.
    func decryptFile(inputURL: URL, outputURL: URL, privateKey: SecKey) throws {
        do {
            let encryptedData = try Data(contentsOf: inputURL)
            if let decryptedData = try decryptData(data: encryptedData, privateKey: privateKey) {
                try decryptedData.write(to: outputURL)
                print("File decrypted successfully!")
            } else {
                print("Decryption failed.")
                throw SecManagerError.fileDecryptionFailed(desc: inputURL.absoluteString)
            }
        } catch {
            
            print("Error reading file: \(error)")
            throw SecManagerError.fileDecryptionFailed(desc: error.localizedDescription)
        }
    }
    
}

class SMExample {
    
    func perform(){
        let data: Data = "HelloSecure Stuff".data(using: .utf8)!
        let ac1: AsymmetricCrypto = AsymmetricCrypto()
        do {
            let (privateKey, publicKey) = try ac1.generateECCKeyPair()
            
            let encData = try ac1.encryptData(data: data, publicKey: publicKey)
            
            if let ed = encData {
                
                print("Encrypted Data: " + (String(data: ed, encoding: .utf8) ?? "no data"))
                if let decData = try ac1.decryptData(data: ed, privateKey: privateKey) {
                    print("Encrypted Data: " + (String(data: decData, encoding: .utf8) ?? "no data"))
                }
            }
            
        }catch {
            print(error)
        }
        
        let ac2: AsymmetricCrypto = AsymmetricCrypto(algo: .rsa)
        
        do{
            let (privateKey, publicKey) = try ac2.generateRSAKeyPair()
            
            let encData = try ac2.encryptData(data: data, publicKey: publicKey)
            
            if let ed = encData {
                print("Encrypted Data: " + (String(data: ed, encoding: .utf8) ?? "no data"))
                if let decData = try ac2.decryptData(data: ed, privateKey: privateKey) {
                    print("Encrypted Data: " + (String(data: decData, encoding: .utf8) ?? "no data"))
                }
            }
        }catch {
            print(error)
        }
    }
}
