//
//  CryptoProgressDelegate.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import UIKit

// Progress update protocol
protocol CryptoProgressDelegate: AnyObject {
    func encryptionStarted()
    func didUpdateEncryptionProgress(_ progress: Float)
    func didFinishEncryptionProcess()
    func didFailEncryption(with error: Error)
    
    func decryptionStarted()
    func didUpdateDecryptionProgress(_ progress: Float)
    func didFinishDecryptionProcess()
    func didFailDecryption(with error: Error)
}


//extension AppDelegate: CryptoProgressDelegate {
//
//    
//    func addProgressView(){
//        
//        progressView.backgroundColor = Colors.cellBg
//        progressView.translatesAutoresizingMaskIntoConstraints = false
//        progressView.layer.cornerRadius = 10
//        progressView.borderColor = Colors.primaryBorder
//        progressView.borderWidth = 1.5
//        progressView.isHidden = true
//        let rootViewController = self.window?.rootViewController
//       
//        if let rv = rootViewController?.view {
//            
//            let leadingConstraint = progressView.leadingAnchor.constraint(equalTo:  rv.leadingAnchor, constant: UIScreen.main.bounds.width)
//            let trailingConstraint = progressView.trailingAnchor.constraint(equalTo:  rv.trailingAnchor, constant: -16)
//            progressView.leadingConstraint = leadingConstraint
//            rv.addSubview(progressView)
//            NSLayoutConstraint.activate([
//                leadingConstraint,
//                trailingConstraint,
//                progressView.topAnchor.constraint(equalTo:  rv.safeAreaLayoutGuide.topAnchor),
//                progressView.heightAnchor.constraint(equalToConstant: 44)
//            ])
//            rv.layoutIfNeeded()
//        }
//    }
//    
//    func isProgressViewInHierarchy(view: UIView) -> Bool {
//        if let _ = progressView.superview {
//            return true
//        }
//        return false
//    }
//    
//    func encryptionStarted() {
//        if !isProgressViewInHierarchy(view: progressView) {
//            addProgressView()
//        }
//        progressView.showProgressBar()
//        let message = "Encryption started"
//        self.progressView.setMessage(message)
//    }
//    
//    
//    func didUpdateEncryptionProgress(_ progress: Float) {
//        self.progressView.updateProgress(to: progress, animated: true)
//        let progressString = String(format: "%.2f", progress * 100)
//        let message = "Encryption in progress... \(progressString)%"
//        self.progressView.setMessage(message)
//    }
//    
//    func didFinishEncryptionProcess() {
//        let message = "Encryption complete"
//        self.progressView.setMessage(message, success: true)
//        self.progressView.processCompleted()
//    }
//    
//    func didFailEncryption(with error: any Error) {
//        let message = "Encryption failed"
//        if let err = error as? CryptoError {
//            self.progressView.setMessage(err.message, success: false)
//        }else {
//            self.progressView.setMessage(message, success: false)
//        }
//        self.progressView.processCompleted()
//    }
//    
//    func decryptionStarted() {
//        if !isProgressViewInHierarchy(view: progressView) {
//            addProgressView()
//        }
//        progressView.showProgressBar()
//        let message = "Decryption started"
//        self.progressView.setMessage(message)
//    }
//    
//    func didUpdateDecryptionProgress(_ progress: Float) {
//        let progressString = String(format: "%.2f", progress * 100)
//        let message = "Decryption in progress... \(progressString)%"
//        self.progressView.setMessage(message)
//        self.progressView.updateProgress(to: progress, animated: true)
//    }
//    
//    func didFinishDecryptionProcess() {
//        let message = "Decryption complete"
//        self.progressView.setMessage(message,success: true)
//        self.progressView.processCompleted()
//    }
//    
//    func didFailDecryption(with error: any Error) {
//        let message = "Decryption failed"
//        if let err = error as? CryptoError {
//            self.progressView.setMessage(err.message, success: false)
//        }else {
//            self.progressView.setMessage(message, success: false)
//        }
//        self.progressView.processCompleted()
//    }
//    
//}
