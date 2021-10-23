//
//  ChatClient.swift
//  ios-only-grpc-login-logout-client
//
//  Created by Adonis Gaitatzis on 10/22/21.
//

import Foundation
import GRPC
import NIO

class GrpcChatClient {
    var chatServiceClient: ChatService_ChatServiceRoutesClient?
    let port: Int = 50051
    init() {
        // build a foundain of EventLoops
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        do {
            // open a channel to the gPRC server
            let channel = try GRPCChannelPool.with(
                target: .host("localhost", port: self.port),
                transportSecurity: .plaintext,
                eventLoopGroup: eventLoopGroup
            )
            // create a Client
            self.chatServiceClient = ChatService_ChatServiceRoutesClient(channel: channel)
            print("grpc connection initialized")
        } catch {
            print("Couldn't connect to gRPC server")
        }
    }
    /**
      * Unary call example. Calls `login` and prints the response.
      * This method calls the chatService.ChatServiceRoutes.login() method
      * an tries to understand the response.
      *
      * It sends a `ChatService_AccountCredentials` object, found in
      * chatservice.pb.swift through the gRPC method and receives a
      * `ChatService_OauthCredentials` object back, which it attempts to
      * parse.
      */
    func grpcLogin(username: String, password: String) -> String {
        print("Login: username=\(username)")

        // build the AccountCredentials object
        let accountCredentials: ChatService_AccountCredentials = .with {
          $0.username = username
          $0.password = password
        }
        // grab the login() method from the gRPC client
        let call = self.chatServiceClient!.login(accountCredentials)
        // prepare an empty response object
        let oauthCredentials: ChatService_OauthCredentials

        // execute the gRPC call and grab the result
        do {
            oauthCredentials = try call.response.wait()
        } catch {
            print("RPC method 'login' failed: \(error)")
            // it would be better to throw an error here, but
            // let's keep this simple for demo purposes
            return ""
        }
        // Do something interesting with the result
        let oauthToken = oauthCredentials.token
        // let timeoutSeconds = oauthCredentials.timeoutSeconds
        
        print("Logged in with oauth token '\(oauthToken)'")
        // return a value so we can use it in the app
        return oauthToken
    }
    
    func grpcLogout(oauthToken: String) {
      print("Logout: token=\(oauthToken)")

      // build the OauthCredentials object
      let oauthCredentials: ChatService_OauthCredentials = .with {
        $0.token = oauthToken
      }
      // grab the logout() method from the gRPC client
      let call = self.chatServiceClient!.logout(oauthCredentials)

      // execute the gRPC call and grab the result
      do {
        _ = try call.response.wait()
      } catch {
          print("RPC method 'logout' failed: \(error)")
          // it would be better to throw an error here, but
          // let's keep this simple for demo purposes
          return
      }
      print("Logged out")
    }
}

