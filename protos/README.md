# Protobuffer Files

This folder contains the protobuffer file (`.proto`) from which the gRPC interfaces are derived.

Currently there is one protobuffer defined, `chatService` which creates a service called `ChatServiceRoutes`, which defines two methods:

* `login()`
* `logout()`

The `.proto` file is loaded by other software for use with automatic code generation functionality.