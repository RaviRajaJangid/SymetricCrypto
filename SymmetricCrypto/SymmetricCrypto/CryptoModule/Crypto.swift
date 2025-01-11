//
//  Crypto.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import Foundation
import CryptoKit
import UIKit

public typealias ChunksWiseEncryptedInfo = (encryptedFile: URL, nonces: [Data], tags: [Data])
public typealias EncryptionCompletionCallback = (_ encryptionInfo: ChunksWiseEncryptedInfo?, _ error: Error?)->Void
public typealias DecryptionCompletionCallback = (_ url: URL?, _ error: Error?)->Void


class Crypto {
    
    static let encryptedFileExtension = "ed"
    static let nonceFile = "meta_n.meta"//"nonces"
    static let tagFile = "meta_t.meta"//"tags"
    static let secureSpace = "SecureSpace/encryptedData"
    //Chunks size
    private static let chunkSize = 1024 * 1024 // 1MB chunks
    // Queue for background processing
    static let queueName = Util.bundleId+".CryptoProcessing"
    static private let cryptoProcessingQueue = DispatchQueue(label: queueName,
                                              qos: .userInitiated,
                                              attributes: .concurrent)
    static weak var delegate: CryptoProgressDelegate?
    
    /// This function should be called on main thread, this function set the AppDelegate object to Crypto.delegate to get the process progress continuous update
    static func registerForProgressEvents(){
//        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//            // Now you can access properties and methods of your AppDelegate
//            Crypto.delegate = appDelegate
//        }
    }
    /// Get the secure .libraryDirectory directory path that is more secure then .documentsDirectory
    /// if it required iCloud backup than switch to .documentDirectory
    static func getSecureDirectory() throws -> URL  {
        
        let encryptedDataURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Crypto.secureSpace)
        print(encryptedDataURL)
        
        do {
            // Check if the directory exists
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: encryptedDataURL.path) {
                // If the directory doesn't exist, create it
                try fileManager.createDirectory(at: encryptedDataURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            throw CryptoError.unableToCreateSecureDir
        }
        
        return encryptedDataURL
    }
    
    static func getEncryptedFileURL(forFile name: String) throws ->URL {
        
        let output = try getSecureDirectory()
        let fileName = name + "." + encryptedFileExtension
        return output.appendingPathComponent(fileName)
    }
    
    // Generate random nonce data
    private static func randomNonceData()throws -> Data {
        let nonceDataCount = 12 //byte
        var nonceData: Data = Data(count: nonceDataCount)
        // Create a copy of the address before passing it into the closure
        let result =  nonceData.withUnsafeMutableBytes { bytes in
            // Copy random bytes into the nonceData's memory space
            SecRandomCopyBytes(kSecRandomDefault, nonceDataCount , bytes.baseAddress!)
        }
        guard result == errSecSuccess else {
                throw  CryptoError.failedToGenerateNonce
        }
        // Convert the AES.GCM.Nonce to a Data object
        return nonceData
    }
    
    
    static private func getNoncePath(forFile name: String)throws ->URL {
        return try getSecureDirectory().appendingPathComponent(name + Crypto.nonceFile) //TODO:
    }
    
    static private func getTagsPath(forFile name: String)throws ->URL {
        return try getSecureDirectory().appendingPathComponent(name + Crypto.tagFile) //TODO:
    }

    static func isEncryptedFileExist(fileName: String) -> Bool{
        guard let  encryptedFilePath = try?  Crypto.getEncryptedFileURL(forFile: fileName) else {
            return false
        }
        let fileManager = FileManager.default
        
        // Check if the file exists at the given path
        if fileManager.fileExists(atPath: encryptedFilePath.path) {
            return true
        } else {
            return false
        }
    }
    static func getDecryptedFileURL(fileName: String, ext: String) -> URL? {
        guard let  encryptedFilePath = try?  Crypto.getEncryptedFileURL(forFile: fileName) else {
            return nil
        }
        let decFileUrl = encryptedFilePath.deletingPathExtension().appendingPathExtension(ext)
        return decFileUrl
    }
   static func isDecryptedFileExist(fileName: String, ext: String) -> Bool{
        guard let  encryptedFilePath = try?  Crypto.getEncryptedFileURL(forFile: fileName) else {
            return false
        }
        let decFileUrl = encryptedFilePath.deletingPathExtension().appendingPathExtension(ext)
        
        let fileManager = FileManager.default
        
        // Check if the file exists at the given path
        if fileManager.fileExists(atPath: decFileUrl.path) {
            return true
        } else {
            return false
        }
    }
    
    // Encryption function for a file with chunking
    static func fileReadEncryptWriteToMemory(inputFile: URL,
                                             outputURL: URL,
                                             key: SymmetricKey,
                                             onCompletion:@escaping EncryptionCompletionCallback ) {

        
        cryptoProcessingQueue.async {
            if let delegate =  Crypto.delegate {
                //if progress consumed by UI using delegate wait for 1 second to appear progress UI
                DispatchQueue.main.async {
                    delegate.encryptionStarted()
                }
                //usleep(100000) //0.5sec
            }
            let fileName = inputFile.deletingPathExtension()
                .appendingPathExtension(encryptedFileExtension)
                .lastPathComponent
            
            let outputFile = outputURL.appendingPathComponent(fileName)
            
            
            do{
                
                let data = try Data(contentsOf: inputFile)
                FileManager.default.createFile(atPath: outputFile.path, contents: nil)
                let fileHandle = try FileHandle(forWritingTo: outputFile)
                
                defer { try? fileHandle.close() }
                
                var encryptedData = Data()
                var nonces: [Data] = []
                var tags: [Data] = []
                
                var startIndex = 0
                let totalBytes = data.count
                while startIndex < totalBytes {
                    let endIndex = min(startIndex + chunkSize, data.count)
                    let chunk = data[startIndex..<endIndex]
                    
                    // Generate a unique nonce for each chunk
                    let nonceAsData  = try randomNonceData()
                    let nonce = try AES.GCM.Nonce(data: nonceAsData)  // Generate a random nonce
                    let sealedBox = try AES.GCM.seal(chunk, using: key, nonce: nonce)
                    
                    // Append the encrypted data, nonce, and tag
                    encryptedData.append(sealedBox.ciphertext)
                    
                    nonces.append(nonceAsData)
                    tags.append(sealedBox.tag)
                    
                    startIndex = endIndex
                    try fileHandle.write(contentsOf: sealedBox.ciphertext)
                    print("Enc Progress:==>\(Double(startIndex)/Double(totalBytes) * 100)")
                    let progress: Float = Float(startIndex)/Float(totalBytes)
                    DispatchQueue.main.async {
                        delegate?.didUpdateEncryptionProgress(progress)
                    }
                    //usleep(200000)
                }
                //fileName witout extension
                let fileName = outputFile.deletingPathExtension().lastPathComponent
                
                 let tagsFileName = try getTagsPath(forFile: fileName)
                    writeTags(path: tagsFileName, tags: tags)
                    
               
                let nonceFileName = try getNoncePath(forFile: fileName)
                    writeNonces(path: nonceFileName, nuance: nonces)
                
                
                DispatchQueue.main.async {
                    delegate?.didFinishEncryptionProcess()
                    let encryptedInfo = (outputFile, nonces, tags)
                    onCompletion(encryptedInfo, nil)
                   
                }
               
              
                    // Set file protection
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                                          ofItemAtPath: outputURL.path)
               
           
            }catch {
              
                onCompletion(nil, CryptoError.failedToEncrypt)
                DispatchQueue.main.async {
                    delegate?.didFailEncryption(with: error)
                }
            }
        }
    }
    
    ///  fileName: witout extension
    static func fileReadDecryptWriteToMemory(fileName: String,
                                             decFileExt: String,
                                             onCompletion: @escaping DecryptionCompletionCallback ) {
        
        cryptoProcessingQueue.async {
            if let delegate =  Crypto.delegate {
                DispatchQueue.main.async {
                    delegate.decryptionStarted()
                }
                //if progress consumed by UI using delegate wait for 0.5 seconds to appear progress UI
                usleep(200000) //0.5 sec
            }
            do {
                
                let key = try KeyManager.loadKey(forFile: fileName)
                
                let encryptedFilePath = try  Crypto.getEncryptedFileURL(forFile: fileName)
                
                let fileURL = encryptedFilePath.deletingPathExtension().appendingPathExtension(decFileExt)
                
                let tagsPath = try getTagsPath(forFile: fileName)
                let noncePath = try getNoncePath(forFile: fileName)
                guard let tags = getTags(path: tagsPath),let nonces = getNonces(path: noncePath) else {
                    
                    throw CryptoError.decryptionMetadataNotFound
                    
                }
                
                let encryptedData = try Data(contentsOf: encryptedFilePath)
                
               
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                defer { try? fileHandle.close() }
                var decryptedData = Data()
                var startIndex = 0
                let totalBytes = encryptedData.count
                for (index, nonceData) in nonces.enumerated() {
                    let endIndex = min(startIndex + chunkSize, encryptedData.count)
                    let chunk = encryptedData[startIndex..<endIndex]
                    
                    let nonce = try AES.GCM.Nonce(data: nonceData)
                    let tag = tags[index]
                    
                    // Create the sealed box with the nonce, ciphertext, and tag
                    let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: chunk, tag: tag)
                    
                    // Decrypt the chunk
                    let decryptedChunk = try AES.GCM.open(sealedBox, using: key)
                    decryptedData.append(decryptedChunk)
                    
                    startIndex = endIndex
                    try fileHandle.write(contentsOf: decryptedChunk)
                    print("DecProgress:==>\(Double(startIndex)/Double(totalBytes) * 100)")
                    let progress: Float = Float(startIndex)/Float(totalBytes)
                    DispatchQueue.main.async {
                        delegate?.didUpdateDecryptionProgress(progress)
                    }
                    //usleep(200000)
                }
                
                DispatchQueue.main.async {
                    delegate?.didFinishDecryptionProcess()
                    onCompletion(fileURL, nil)
                }
                
            }catch {
                DispatchQueue.main.async {
                    delegate?.didFailDecryption(with: error)
                    onCompletion(nil, error)
                }
            }
            
           
        }
    }
    
    // Write Nonces Asynchronously
    static private  func writeNonces(path: URL, nuance: [Data]) {
        // Use DispatchQueue to perform the writing task asynchronously
        DispatchQueue.global(qos: .background).async {
            do {
                // Create a directory if it doesn't exist
                let directoryURL = path.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directoryURL.path) {
                    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                // Use PropertyListEncoder to serialize the nuance array
                let encoder = PropertyListEncoder()
                let serializedData = try encoder.encode(nuance)
                
                // Write the serialized data to disk
                try serializedData.write(to: path)
                print("Successfully wrote nonces to \(path)")
            } catch {
                print("Error writing nonces: \(error)")
            }
        }
    }
    
    // Write Tags Asynchronously
    static private func writeTags(path: URL, tags: [Data]) {
        // Use DispatchQueue to perform the writing task asynchronously
        DispatchQueue.global(qos: .background).async {
            do {
                // Create a directory if it doesn't exist
                let directoryURL = path.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directoryURL.path) {
                    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                // Use PropertyListEncoder to serialize the tags array
                let encoder = PropertyListEncoder()
                let serializedData = try encoder.encode(tags)
                
                // Write the serialized data to disk
                try serializedData.write(to: path)
                print("Successfully wrote tags to \(path)")
            } catch {
                print("Error writing tags: \(error)")
            }
        }
    }
    
    // Get Nonces Synchronously
    static private func getNonces(path: URL) -> [Data]? {
        do {
            // Read the data from the file
            let serializedData = try Data(contentsOf: path)
            
            // Use PropertyListDecoder to deserialize the data
            let decoder = PropertyListDecoder()
            let nonces = try decoder.decode([Data].self, from: serializedData)
            
            return nonces
        } catch {
            print("Error reading nonces: \(error)")
            return nil
        }
    }
    
    // Get Tags Synchronously
    static private func getTags(path: URL) -> [Data]? {
        do {
            // Read the data from the file
            let serializedData = try Data(contentsOf: path)
            
            // Use PropertyListDecoder to deserialize the data
            let decoder = PropertyListDecoder()
            let tags = try decoder.decode([Data].self, from: serializedData)
            
            return tags
        } catch {
            print("Error reading tags: \(error)")
            return nil
        }
    }
}
