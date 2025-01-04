//
//  SymetricCryptoApp.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//

import SwiftUI

@main
struct SymetricCryptoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
