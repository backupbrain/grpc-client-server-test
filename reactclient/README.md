
# React Native gRPC client for iOS / Swift

## What is happening

gRPC is a way for clients and servers to communicate with each other over the Internet. It is intended as an upgrade from REST APIs, with some great features:
* It transmits faster by using a binary format instead of JSON.
* It uses a language-agnostic data format, which can be defined and passed. around to clients without the need for per-language developer documentation.
* It translates it's common data format into the native data formats of the server and client.
* It supports versioning, so future versions of server code don't requrie a total rewrite of the client.
* It defines how to find the endpoints, so URL naming is no longer an issue.
* It works over HTTP/3, which enables bidirectional streaming with less network latency.

The down sides (at the time of writing) are:
* It requires custom compiler code for each language to perform all the conversions and binary format conversions.
* The mechanics of operation are totaly obscure to developers. It either works or it doesn't.
* The toolchains are new and not very well supported. Sometimes getting a simple call and response to work can take hours or days to get working.
* In particular, it is poorly supported
* HTTP/3 is poorly supported by browsers and app software, especially over at Apple.

In this tutorial, I will attempt to walk you through the process I went through to get a simple gRPC client working in React Native on iOS.

## Prerequisites

In order to build this project, we will need some developement tools:

* [An Apple computer](https://www.apple.com/mac/)
* [Xcode and Command-Line-Tools](https://developer.apple.com/xcode/), (require an Apple computer) Apple's IDE and compiler tools for building iOS projects
* [GoLang](https://golang.org/), a programming lanugage made by Google
* [Homebrew](https://brew.sh/) (require Xcode), the MacOS package manager
* [NodeJS](https://nodejs.org/) (Requires Homebrew), Javascript interpreter for command-line programming
* [Cocoapods](https://cocoapods.org/), a package manager for Xcode project libraries and frameworks.

For reference, my Swift version is `5.4.2`. This affects how things are written later in the tutorial.

```console
$ xcrun swift -version
Apple Swift version 5.4.2 (swiftlang-1205.0.28.2 clang-1205.0.19.57)
Target: x86_64-apple-darwin20.6.0
```

### Installing Toolchain

Assuming you already have the required tools listed above set up properly, you can proceed with installing the toolchain, which consists of:

* `protobuf`, a tool that compiles gRPC `.proto` definition files into native libraries.
* `grpc-swift`, a plugin for `protobuf` that lets you compile `.proto` files into a Swift library


Install Protocol Buffer Compiler, which compiles `.proto` files into a native code library in one of several languages.

```console
$ brew install protobuf
```

Install the Swift plugin that allows us to compile `.proto` files into Swift-compatible code.

```console
$ cd ~/sandbox
$ git clone https://github.com/grpc/grpc-swift
$ cd grpc-swift
$ make plugins
$ cp .build/release/protoc-gen-swift .build/release/protoc-gen-grpc-swift /usr/local/bin
```

The latest documentation on for setting this up can be found on the [grpc-swift GitHub page](https://github.com/grpc/grpc-swift)

## Configuring Project

### Install protobuf and grpc-swift

Remember `protobuf` and `grpc-swift`? Here you can compile your `.proto` file into a Swift library. 

```console
$ protoc ./chatService.proto \
		--proto_path=. \
		--swift_opt=Visibility=Public \
		--swift_out=.
$ protoc ./chatService.proto \
		--proto_path=. \
		--grpc-swift_opt=Visibility=Public \
		--grpc-swift_out=.
```

That generates two new files:

* `chatService.grpc.swift`, which contains the implementation of your generated service classes
* `chatService.pb.swift`, which contains the implementation of your generated message classes

The basic format for using this command is:

```console
$ protoc /path/to/proto_dir/proto_file.proto \
    --proto_path=/path/to/proto_dir/ \
    --plugin=/path/to/grpc-swift-github-checkout/.build/release/protoc-gen-swift \  # If this binary is not in your $PATH
    --swift_opt=Visibility=Public \
    --swift_out=/path/to/xcode_project_dir
```
### Install Frameworks

Next we need to update the Podfile, which cocoapods will use to install requied frameworks

Update your `Podfile` to include the following `pod` definitions inside the `target` definition:

```
target 'ios-only-grpc-login-logout-client' do
  use_frameworks!
    pod 'gRPC-Swift', '~> 1.5.0'  # Latest at the time of writing
    pod 'gRPC-Swift-Plugins'
end
```

From your Terminal, install the new frameworks with this commmand:

```
$ cd <xcode-proejct-dir>
$ pod install
```

This should create a `<xcode-project-name>.xcworkspace` folder, which you can use to open Xcode.

Open the working folder in Finder and then double click this `<xcode-project-name>.xcworkspace` to open Xcode.

You'll be using the `.xcworkspace` file to open this project from now on.

```console
$ open . &  # open Finder
$ open ios-only-grpc-login-logout-client.xcworkspace &  # open Xcode project
```

When XCode opens, drag the nwo new files (`chatService.grpc.swift` and `chatService.pb.swift`) into the XCode project under <xcode-project-name>/<xcode-project-name>` and select "Copy Items if Needed" and "Create foder referenes" to make sure they are included in the compile later.

You'll be dragging it into the same folder as the `Info.plist`.

Now is a good time to build the project to make sure there are no errors.

## Building Features

Now let's create the functionality.

Create a new Swift File, name it `ChatClient.swift`

```swift
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
```

Try to compile again. Hopefully no crashing.

That works, now we need to add some buttons.

## Building Views

Now we can add two text fields and two buttons
* TextField 1: username
* TextField 2: password
* Button 1: Login
* Button 2: Logout
* TextView to display oauth token

```swift
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
    
    // initialize our gRPC ChatService client
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
      // execute the login() method in our gRPC client
      self.oauthToken = self.grpcChatClient.grpcLogin(username: self.username, password: self.password)
      self.isLoggedIn = self.oauthToken.count > 0
    }
    
    private func doLogout() {
      // execute the logout() method in our gRPC client
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
```

If you don't already have the gRPC server running, now is a good time to start. Open a terminal and run:

```console
$ cd sandbox/grpc-client-server-test/server
$ node src/server.js
```

Compile and run your iOS project. You shoud see a simple UI that lets you click a "login" button to grab an OAuth token from the gRPC server.

==========================================

The following tutorials DID NOT WORK!

Follow this guide: [gRPC for Objective-C](https://github.com/grpc/grpc/tree/master/src/objective-c#install)o

If you get an error that reads:

```console
Error: homebrew/dupes was deprecated. This tap is now empty and all its contents were either deleted or migrated.
```

Try this:
[Error: homebrew/dupes was deprecated #701](https://github.com/Linuxbrew/brew/issues/701)

```console
$ grep -irl homebrew/dupes $(brew --repo homebrew/core)/../..
```

Install NodeJS and [GoLang](https://golang.org/dl/):

```console
$ brew install node
```

Install Cocoapods
```console
$ sudo gem install cocoapods
$ curl -fsSL https://goo.gl/getgrpc | bash -
```

Actually we don't need to do this step for the client:
Install prerequisites to generate code from `.proto` file:
```console
$ export PATH=$HOME/go/bin:$PATH
$ go get -u google.golang.org/grpc
$ go get -u github.com/golang/protobuf/proto
$ go get -u github.com/golang/protobuf/protoc-gen-go
```

Install Protocol Buffer Compiler
```console
$ brew install protobuf
$ protoc --version
libprotoc 3.17.3
```

GAAAAAAAAAA WHY IS IT SO FUCKING HARD TO INSTALL THIS FUCKING SOFTWARE

```console
$ brew install autoconf
$ brew install automake
$ brew install libffi
$ export LDFLAGS=-L/usr/local/lib
$ git clone https://github.com/alexeyxo/protobuf-swift
$ cd protobuf-swift
$ ./scripts/build.sh
# this failed with:
protobuf test program failed to link:
perhaps you need to add -Llibdir to your LDFLAGS.
```

NO PROTOBUF SOFTWARE WORKS! WHY THE FUCK IS THIS?

[Install protobuf compiler](https://github.com/alexeyxo/protobuf-swift#how-to-install-protobuf)

```console
$ brew install protobuf-swift
```

LET'S TRY THIS:

```console
$ cd sandbox
$ git clone https://github.com/grpc/grpc-swift
$ cd grpc-swift
$ make plugins
$ cd ..
```

[follow basic tutorial](https://github.com/grpc/grpc-swift/blob/main/docs/basic-tutorial.md)

```console
$ protoc chatService.proto \
		--proto_path=. \
		--plugin=~/sandbox/grpc-swift/.build/release/protoc-gen-swift \
		--swift_opt=Visibility=Public \
		--swift_out=.
$ protoc chatService.proto \
		--proto_path=. \
		--plugin=~/sandbox/grpc-swift/.build/release/protoc-gen-grpc-swift \
		--grpc-swift_opt=Visibility=Public \
		--grpc-swift_out=.
```

That generates two new files:

* `chatService.grpc.swift`, which contains the implementation of your generated service classes
* `chatService.pb.swift`, which contains the implementation of your generated message classes


## Implementing the Client Code






















We created a new react-native-app:
```console
$ npx react-native init reactnativeclient
$ cd reactnativeclient
```

Build for iOS:
```console
$ npx react-native run-ios
```

Download and configure a [Podspec file](https://github.com/grpc/grpc/blob/v1.41.0/examples/objective-c/route_guide/RouteGuide.podspec), put it into `ios/ChatServiceRoutes.podspec`

Make sure the `.proto` file matches the file in `../../protos`
```
    s.prepare_command = <<-CMD
      mkdir -p #{dir}
      #{protoc} \
          --plugin=protoc-gen-grpc=#{plugin} \
          --objc_out=#{dir} \
          --grpc_out=#{dir} \
          -I #{src} \
          -I #{protoc_dir} \
          #{src}/chatService.proto
    CMD
```


Create an `ios/reactnativeclient/ChatService.h` and `ios/reactnativeclient/ChatService.m` and add to the Xcode project.



Build for iOS again:
```console
$ npx react-native run-ios
```


```
$ cd ios
$ pod init
$ pod 'reactclient', :path => '.'
$ pod install
```


[Create a New React App](https://reactjs.org/docs/create-a-new-react-app.html)
Inside that directory, you can run several commands:

  npm start
    Starts the development server.

  npm run build
    Bundles the app into static files for production.

  npm test
    Starts the test runner.

  npm run eject
    Removes this tool and copies build dependencies, configuration files
    and scripts into the app directory. If you do this, you can’t go back!

We suggest that you begin by typing:

  cd reactnative-client
  npm start

Happy hacking!

