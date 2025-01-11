//
//  Home.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//

import SwiftUI

struct Home: View {
    @State private var selectedFileURL: URL?
    @State private var showPicker = false
    @State private var rawText: String = ""
    @State private var cipherText: String?
    @State private var plainText: String?
    var body: some View {
        VStack {
            TextField("Raw Text", text: $rawText)
                        .padding(15) // Padding for text
                        .background(Color.white) // Background color for the TextField
                        .cornerRadius(30) // Create rounded corners (with large corner radius for circular shape)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.blue, lineWidth: 2) // Circular border with blue color
                        )
                        .padding()
            Button("Encrypt"){
                cipherText = "This is encrypted text"
            }.padding()
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(10)
            
            if let ct = cipherText {
                Text("Encrypted: \(ct)").padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth:0.5) // Circular border with blue color
                    )
            }
            
            Button("Decrypt"){
                plainText = "This is encrypted text"
            }.padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .cornerRadius(10)
            if let pt = plainText {
                Text("PlainText: \(pt)").padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth:0.5) // Circular border with blue color
                    )
            }
               
            
            Button(action: {
                showPicker.toggle()
            }){
                Text("Select File").padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            
            if let fileUrl = selectedFileURL {
                Text("Selected File: \(fileUrl.lastPathComponent)").padding()
            }
        }
        .fullScreenCover(isPresented: $showPicker){
            DocumentPickerView(onFilePicked: {
                selectedFileURL = $0
                showPicker = false
            }, onCancel: {
                showPicker = false
            })
        }
        
        
    }
}

#Preview {
    Home()
}

// UIViewControllerRepresentable to wrap UIDocumentPickerViewController
struct DocumentPickerView: UIViewControllerRepresentable {
    
    
    var onFilePicked: (URL) -> Void
    var onCancel: () -> Void
    
    // Create the document picker view controller
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    // Update the UIViewController (not needed in this case)
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    // Make the Coordinator
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

class Coordinator: NSObject, UIDocumentPickerDelegate {
    var parent: DocumentPickerView
    
    init(parent: DocumentPickerView) {
        self.parent = parent
    }
    
    // Handle file selection
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt URLs: [URL]) {
        // Pass the selected URL to the parent
        if let selectedURL = URLs.first {
            parent.onFilePicked(selectedURL)
        }
    }
    
    // Handle cancel event
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        parent.onCancel()
    }
}
