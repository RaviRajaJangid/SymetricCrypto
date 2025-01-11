//
//  SecStorage.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import Foundation
import CryptoKit
import UIKit

//How much GB documents a user can store on device Local storage?
//What should happen when user reaches that limit?
//How to manage duplicate file?
//What is the file uniqueness criteria?
//How to manage encryption / decryption for document like unique private key for each document or a single key for all document on a device?
//will that encrypted document can backed up on iCloud ?

class SecManager {
    
    public struct FileSizeInfo {
        
        let originalSize: UInt64
        let encryptedSize: UInt64
        let overhead: UInt64
        
        var overheadPercentage: Double {
            return Double(overhead) / Double(originalSize) * 100
        }
    }
    
    private static let chunkSize = 1024 * 1024 // 1MB chunks
    /// Default minimum free space requirement (500MB)
    private static let minimumFreeSpaceRequired: UInt64 = 500 * 1024 * 1024
    
    /// Maximum allowed storage for encrypted files (e.g., 5GB)
    private static let maximumStorageLimit: UInt64 = 5 * 1024 * 1024 * 1024
    
    /// Its for server purpose we will user this to send client public key to server
    func getPublicKeyData(publicKey: SecKey)throws -> Data? {
        var error: Unmanaged<CFError>?
        if let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) {
            return publicKeyData as Data
        } else {
            dlog("CRYPTO  Error extracting public key: \(error?.takeRetainedValue() as Error?)")
            throw CryptoError.unableToGeneratePublicKey
            
        }
    }
    
    func sendPublicKeyToServer(publicKeyData: Data) {
        //    TODO:  Implement later
    }
    
    
    
    ///calculateEncryptionOverhead: forFileSize is used to determine whether a encrypted file can be stored or not by checking available storage
    private static func calculateEncryptionOverhead(forFileSize size: UInt64) -> FileSizeInfo {
        let blockSize: UInt64 = 16
        let authTagSize: UInt64 = 16
        let nonceSize: UInt64 = 12
        
        // Calculate padding (if needed)
        let remainderBytes = size % blockSize
        let paddingBytes = remainderBytes > 0 ? (blockSize - remainderBytes) : 0
        
        // Calculate total overhead
        let totalOverhead = authTagSize + nonceSize + paddingBytes
        let encryptedSize = size + totalOverhead
        
        return FileSizeInfo(
            originalSize: size,
            encryptedSize: encryptedSize,
            overhead: totalOverhead
        )
    }
    
    //MARK TODO: will work later
    static private func isNewVersion(){
        
    }
    
    // Clean up old files if needed
    static private func cleanupOldFiles(keepingMostRecent: Int = 10) throws {
        let fileManager = FileManager.default
        let secureDirectory = try Crypto.getSecureDirectory()
        let files = try fileManager.contentsOfDirectory(at: secureDirectory,
                                                        includingPropertiesForKeys: [.creationDateKey])
        
        let sortedFiles = try files.sorted {
            let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1 > date2
        }
        
        if sortedFiles.count > keepingMostRecent {
            for fileURL in sortedFiles[keepingMostRecent...] {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    
    // Check available storage space, Total available storage space on user's device
    static private func checkAvailableStorage() throws -> UInt64 {
        
        do {
            let fileURL = try Crypto.getSecureDirectory()
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let availableCapacity = values.volumeAvailableCapacity {
                return UInt64(availableCapacity)
            }
            throw CryptoError.fileOperationFailed
        } catch  {
            //print(error.localizedDescription)
            throw CryptoError.fileOperationFailed
        }
    }
    
    /// Get current storage usage / consumed by the encrypted files
    /// Total space consumed on device local storage
    static private func getCurrentStorageUsage() throws -> UInt64 {
        let fileManager = FileManager.default
        let secureDirectory = try Crypto.getSecureDirectory()
        
        guard let enumerator = fileManager.enumerator(at: secureDirectory,
                                                      includingPropertiesForKeys: [.fileSizeKey],
                                                      options: [.skipsHiddenFiles]) else {
            throw CryptoError.fileOperationFailed
        }
        
        var totalSize: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += UInt64(attributes.fileSize ?? 0)
        }
        
        return totalSize
    }
    
}

extension SecManager {
    
    private static func getFileSize(file: URL) throws -> UInt64{
        do {
            return try FileManager.default.attributesOfItem(atPath: file.path)[.size] as! UInt64
        }catch {
            throw CryptoError.unableToDetermineFileSize
        }
    }
    
    // Create encrypted file with storage checks
    public static func startEncryptionFor(fileName:String,inputFile: URL, onCompletion:@escaping EncryptionCompletionCallback ) {
        do{
            // Generate a new key for this file
            let key = SymmetricKey(size: .bits256)
            
            // Save the key to Keychain
            try KeyManager.saveKey(key, forFile: fileName)
            
            let fileSize = try getFileSize(file: inputFile)
            
            // Calculate expected size increase
            let sizeInfo = calculateEncryptionOverhead(forFileSize: fileSize)
            
            // Check available space including overhead
            let availableSpace = try checkAvailableStorage()
            let requiredSpace = sizeInfo.encryptedSize + minimumFreeSpaceRequired
            
            guard availableSpace >= requiredSpace else {
                throw CryptoError.insufficientStorage
            }
            
            // Is total available storage space is sufficient to store new upcoming file
            guard availableSpace > minimumFreeSpaceRequired + requiredSpace else {
                throw CryptoError.insufficientStorage
            }
            
            // Check storage limit
            let currentUsage = try getCurrentStorageUsage()
            guard currentUsage + fileSize <= maximumStorageLimit else {
                throw CryptoError.storageLimitExceeded
            }
            
            // Create secure directory if it doesn't exist
            let output = try Crypto.getSecureDirectory()
            
            Crypto.fileReadEncryptWriteToMemory(inputFile: inputFile, outputURL: output,
                                                key: key, onCompletion: onCompletion)
        }catch {
            Crypto.delegate?.didFailEncryption(with: error)
            onCompletion(nil, error)
        }
    }
    
    
    // Read and decrypt file
    public static func decryptFileData(fileName: String, fileExtension: String, onCompletion: @escaping DecryptionCompletionCallback)  {
        
        do{
            
        Crypto.delegate?.decryptionStarted()
       
        let fileSize = try getFileSize(file: Crypto.getEncryptedFileURL(forFile: fileName))
        
        // Calculate expected size increase
        let sizeInfo = calculateEncryptionOverhead(forFileSize: fileSize)
        
        // Check available space including overhead
        let availableSpace = try checkAvailableStorage()
        let requiredSpace = sizeInfo.encryptedSize + minimumFreeSpaceRequired
        
        guard availableSpace >= requiredSpace else {
            throw CryptoError.insufficientStorage
        }
        
        // Is total available storage space is sufficient to store new upcoming file
        guard availableSpace > minimumFreeSpaceRequired + requiredSpace else {
            throw CryptoError.insufficientStorage
        }
        
        // Check storage limit
        let currentUsage = try getCurrentStorageUsage()
        guard currentUsage + fileSize <= maximumStorageLimit else {
            throw CryptoError.storageLimitExceeded
        }
        
        Crypto.fileReadDecryptWriteToMemory(fileName: fileName,
                                            decFileExt: fileExtension,
                                            onCompletion: onCompletion )
    }catch {
        Crypto.delegate?.didFailEncryption(with: error)
        onCompletion(nil, error)
    }
        
    }
    
}
