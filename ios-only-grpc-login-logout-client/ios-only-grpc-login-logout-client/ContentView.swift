//
//  ContentView.swift
//  ios-only-grpc-login-logout-client
//
//  Created by Adonis Gaitatzis on 10/22/21.
//

import SwiftUI
import CoreData

import GRPC
import NIO

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // placeholders for TextFields
    public let usernamePlaceholder: String = "Username"
    public let passwordPlaceholder: String = "Password"
    
    // data stores for TextFields (with default values set)
    @State var username = "email@example.com"
    @State var password = "password"
    
    // gRPC client
    let grpcChatClient = GrpcChatClient()
    
    // data store for our login Auth token
    @State var oauthToken = "(none)"
    @State var isLoggedIn = false

    var body: some View {
        VStack {
            TextField(usernamePlaceholder, text: $username)
            TextField(passwordPlaceholder, text: $password)
            Button(action: {
                doLogin()
            }) {
                Text("Login")
            }
            Button(action: {
                doLogout()
            }) {
                Text("Logout")
            }
            Text("Oauth Token: \(oauthToken)")
        }
    }
    
    private func doLogin() {
        self.oauthToken = self.grpcChatClient.grpcLogin(username: self.username, password: self.password)
        self.isLoggedIn = self.oauthToken.count > 0
    }
    
    private func doLogout() {
        self.grpcChatClient.grpcLogout(oauthToken: self.oauthToken)
        self.isLoggedIn = false
        self.oauthToken = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
