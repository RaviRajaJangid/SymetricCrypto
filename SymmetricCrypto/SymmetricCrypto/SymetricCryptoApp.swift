//
//  SymmetricCryptoApp.swift
//  SymmetricCrypto
//
//  Created by Ravi Raja Jangid on 04/01/25.
//

import SwiftUI

@main
struct wSymmetricCryptoApp: App {
//    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CryptoHelperScreen()
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
