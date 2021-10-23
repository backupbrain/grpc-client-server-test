// load the .proto file to generate service descriptors and stub definitions
const PROTO_PATH = __dirname + '/../../protos/chatService.proto';
console.log(PROTO_PATH)
const grpc = require('@grpc/grpc-js')
const protoLoader = require('@grpc/proto-loader')
const { defaultOptions } = require('highcharts')


class ChatLogin {
    constructor (username, password) {
        this.username = username
        this.authToken = Math.random().toString(16).substr(2, 8)
        this.refreshExpiration()
    }
    refreshExpiration () {
        const currentTime = new Date()
        this.expires = currentTime.setDate(currentTime.getDate() + 1)
    }
    isLoggedIn () {
        const currentTime = new Date()
        return this.expires >= currentTime
    }
    logout () {
        const currentTime = new Date()
        this.expires = currentTime
    }
}

class ChatMessage {
    constructor (username, msg) {
        this.username = username
        this.message = msg
    }
}

class ChatServer {
    constructor () {
        this.authTokens = {}
        this.activeUsers = {}
        this.messages = []
    }
    login (username, password) {
        let loginData = {}
        if (username in this.activeUsers) {
            loginData = this.activeUsers[username]
            this.authTokens[loginData.authToken].refreshExpiration()
        } else {
            loginData = new ChatLogin(username, password)
            this.authTokens[loginData.authToken] = loginData
            this.activeUsers[username] = loginData.authToken
        }
        const currentTime = new Date()
        const output = {
            token: loginData.authToken,
            timeoutSeconds: Math.floor((loginData.expires - currentTime) / 1000)
        }
        return output
    }
    logout (authToken) {
        if (authToken in this.authTokens) {
            const loginData = this.authTokens[authToken]
            delete this.activeUsers[loginData.username]
            delete this.authTokens[authToken]
        }
        return { token: '', timeoutSeconds: 0 }
    }
}

// suggested options for similarity to loading grpc.load behavior
const packageDefinition = protoLoader.loadSync(
    PROTO_PATH,
    {
        keepCase: true,
        longs: String, // JavaScript doesn't support long ints
        enums: String, // JavaScript doesn't support enum types
        defaults: true,
        oneofs: true
    }
)

const protoDescriptor = grpc.loadPackageDefinition(packageDefinition)
// the protoDescriptor object has the full package hierarchy
const chatService = protoDescriptor.chatService

// once this is done, the stub constructor is in the service namespace
// named after the service.proto file. and the service descriptor
// is a property of the stub, protoDescriptor.chatService.ChatServiceRoutes.service

// now we have to implement the server
const chatServer = new ChatServer()
// const grpcServer = new grpc.Server()

const login = (call, callback) => {
    let username = call.request.username
    let password = call.request.password
    console.log(`Login for username: '${username}'`)
    const authData = chatServer.login(username, password)
    callback(null, authData)
}

const logout = (call, callback) => {
    let authToken = call.request.token
    console.log(`Logout for token: '${authToken}'`)
    const authData = chatServer.logout(authToken)
    callback(null, authData)
}

function getGrpcServer () {
    const grpcServer = new grpc.Server()
    grpcServer.addService(chatService.ChatServiceRoutes.service, {
        login: login,
        logout: logout
    })
    return grpcServer
}
const grpcServer = getGrpcServer()
console.log('Starting gRPC server on port 0.0.0.0:50051...')
grpcServer.bindAsync('0.0.0.0:50051', grpc.ServerCredentials.createInsecure(), () => {
    grpcServer.start()
})