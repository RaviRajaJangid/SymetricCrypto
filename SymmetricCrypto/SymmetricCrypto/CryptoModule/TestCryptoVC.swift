//
//  CryptoTestVC.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//


import UIKit

class TestCryptoVC: UIViewController {
    var selectedFilePath: URL! { //file to encrypt
        didSet {
            fileName = selectedFilePath.deletingPathExtension().lastPathComponent
            fileExtension =  selectedFilePath.pathExtension
        }
    }
    var fileExtension: String?
    var fileName: String?
    
    @IBOutlet weak var encryptionInfo: UILabel!
    @IBOutlet weak var decryptionInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        Crypto.registerForProgressEvents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    @IBAction func buttonAction(_ sender: Any) {
    }
    
    @IBAction func selectFileAndEncrypt(_ sender: Any) {
        
        self.selectDoc()
    }
    
    @IBAction func selectFileAndDecrypt(_ sender: Any) {
        
        updateDecryptionInfo(message: "File Selected")
        
        if let fn = fileName, let fe = fileExtension {
            
            SecManager.decryptFileData(fileName: fn, fileExtension: fe) { [weak self] url, error in
                
                if let url = url {
                    
                    self?.updateDecryptionInfo(message: "Selected file decrypted")
                    
                }else if let error = error {
                    
                    self?.updateDecryptionInfo(message: "Error file decryption \(error)")
                    
                }
                
            }
            
        }
        
        
    }
    
    func updateEncryptionInfo(message: String) {
        encryptionInfo.text =  "EncryptionInfo: \(message)"
        print(encryptionInfo.text ?? "")
    }
    func updateDecryptionInfo(message: String) {
        decryptionInfo.text =  "DecryptionInfo: \(message)"
        print(decryptionInfo.text ?? "")
    }
}

extension TestCryptoVC: UIDocumentPickerDelegate {
    func selectDoc(){
        // Create a document picker for opening a file
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // Set this to true if you want to allow multiple file selection
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerDelegate Methods
    // Called when a document is selected
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let selectedFileURL = urls.first {
            print("File selected: \(selectedFileURL)")
            selectedFilePath = selectedFileURL
            updateEncryptionInfo(message: "File Selected")
            self.fileReadEncryptWriteToMemory()
        }
        
    }
    
    // Called if the user cancels the document picker
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }
    
    
    func fileReadEncryptWriteToMemory(){
        
        let fileName = selectedFilePath.deletingPathExtension().lastPathComponent
        
        SecManager.startEncryptionFor(fileName: fileName, inputFile: selectedFilePath) {  [weak self] encryptionInfo, error in
            
           if let error = error {
                
               self?.updateEncryptionInfo(message: "Error file decryption \(error)")
                
            }else {
                
                self?.updateEncryptionInfo(message: "File encrypted")
            }
            
        }
    }
}


