## gRPC client

This client reads the `../protos/chatService.proto` to understand how to talk to the gRPC server in `../server`

It then executes the following two methods in order.

* `login()`
* `logout()`

Currently the entire process is automated. No human interaciton exists.

## Setup

```console
$ npm install
```

## Running

```console
$ node run src/client.js
```

The client will execute `login()` and then `logout()` on the server and print out the following messages:

```console
login successful
{ token: '8d102091', timeoutSeconds: 86399 }
logout successful
{ token: '', timeoutSeconds: 0 }
```
