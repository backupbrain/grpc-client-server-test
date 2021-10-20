const grpc = require('@grpc/grpc-js')
const protoLoader = require('@grpc/proto-loader')
const PROTO_PATH = __dirname + '/../../protos/chatService.proto'
const packageDefinition = protoLoader.loadSync(
    PROTO_PATH,
    {
        keepCase: true,
        longs: String,
        enums: String,
        defaults: true,
        oneofs: true
    }
);

const chatService = grpc.loadPackageDefinition(packageDefinition).chatService;
const grpcClientStub = new chatService.ChatServiceRoutes('localhost:50051', grpc.credentials.createInsecure())


username = 'tonyg'
password = 'insecurepassword'

const loginData = { username: username, password: password }
let loggedInOauthCredentials = { token: '' }
grpcClientStub.login(loginData, (error, oauthCredentials) => {
    if (error) {
        console.log('Error!')
        console.log(error.message)
    } else {
        console.log('login successful')
        console.log(oauthCredentials)
        loggedInOauthCredentials = oauthCredentials
    }
})


const logoutData = { token: loggedInOauthCredentials.token }
grpcClientStub.logout(logoutData, (error, oauthCredentials) => {
    if (error) {
        console.log('Error!')
        console.log(error.message)
    } else {
        console.log('logout successful')
        console.log(oauthCredentials)
    }
})
