//
//  ios_only_grpc_login_logout_clientApp.swift
//  ios-only-grpc-login-logout-client
//
//  Created by Adonis Gaitatzis on 10/22/21.
//

import SwiftUI

@main
struct ios_only_grpc_login_logout_clientApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
