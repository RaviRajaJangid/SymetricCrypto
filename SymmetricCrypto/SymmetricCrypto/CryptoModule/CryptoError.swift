//
//  CryptoError.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import Foundation

public enum CryptoError: Error {
    
    case unableToGenerateKey
    case unableToGeneratePublicKey
    case unableToDetermineFileSize
    case failedToGenerateNonce
    case failedToEncrypt
    case failedToDecrypt
    
    case fileOperationFailed
    case insufficientStorage
    case storageLimitExceeded
    case unableToCreateSecureDir
    case decryptionMetadataNotFound // nonce or tag not found
    
    //Key related issue
    case keySaveError
    case keyFailedToUpdate
    case keyLoadingError
    case keyNotFound
    
}

extension CryptoError {
    var message: String {
        switch self {
            
        case .unableToGenerateKey:
            return "Unable to generate key"
        case .unableToGeneratePublicKey:
            return "Unable to generate publicKey"
        case .unableToDetermineFileSize:
            return "Unable to determine file size"
        case .failedToGenerateNonce:
            return "Unable to generate nonce"
        case .failedToEncrypt:
            return  "Unable to encrypt this file"
        case .failedToDecrypt:
            return "Unable to decrypt this file"
        case .fileOperationFailed:
            return "File operation failed"
        case .insufficientStorage:
            return "The available storage is insufficient"
        case .storageLimitExceeded:
            return "Storage limit exceeded"
        case .unableToCreateSecureDir:
            return "Unable to create secure directory to store encrypted files"
        case .decryptionMetadataNotFound:
            return "Decryption metadata not found"
        case .keySaveError:
            return "Error in saving key"
        case .keyFailedToUpdate:
            return "Key is already exists failed to update"
        case .keyLoadingError:
            return "Error in key loading"
        case .keyNotFound:
            return "Key not found"
        }
    }
    
    var debugDescription: String {
            switch self {
                
            case .unableToGenerateKey:
                return "Unable to generate cryptographic key. Ensure the cryptographic module is correctly initialized and try again."

            case .unableToGeneratePublicKey:
                return "Failed to generate the public key. Please check the key generation parameters or the cryptographic algorithm being used."

            case .unableToDetermineFileSize:
                return "Unable to determine the file size. Ensure the file path is correct and the file is accessible."

            case .failedToGenerateNonce:
                return "Failed to generate a unique nonce. This could indicate an issue with random number generation or cryptographic initialization."

            case .failedToEncrypt:
                return "Encryption failed. Check if the encryption algorithm, key, and data are correct and compatible."

            case .failedToDecrypt:
                return "Decryption failed. Ensure the correct key and encryption method are being used for the provided data."

            case .fileOperationFailed:
                return "File operation failed. Check if the file exists, the path is correct, and there are sufficient permissions to read/write the file."

            case .insufficientStorage:
                return "Insufficient storage space available. Free up space or choose a different location to proceed with the operation."

            case .storageLimitExceeded:
                return "Storage limit exceeded. The file or operation exceeds the available storage capacity. Please check the storage settings or limit the file size."

            case .unableToCreateSecureDir:
                return "Unable to create a secure directory to store encrypted files. Check if the target location has appropriate permissions and sufficient space."

            case .decryptionMetadataNotFound:
                return "Decryption metadata is missing or corrupted. Ensure the correct decryption metadata file is available and accessible."

            case .keySaveError:
                return "Failed to save the encryption key. Ensure that the key storage location is valid and that there are no permission issues."

            case .keyFailedToUpdate:
                return "Failed to update the encryption key. The key already exists, and there was an error during the update process. Try deleting the old key or choose a different one."

            case .keyLoadingError:
                return "Failed to load the encryption key. Check if the key file exists, the path is correct, and the file is accessible."

            case .keyNotFound:
                return "The required encryption key could not be found. Ensure the key exists and is located in the correct directory."
            }
        }
}
