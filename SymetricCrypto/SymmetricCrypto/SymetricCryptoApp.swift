//
//  SymmetricCryptoApp.swift
//  SymmetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//

import SwiftUI

@main
struct SymmetricCryptoApp: App {
//    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Home()
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
