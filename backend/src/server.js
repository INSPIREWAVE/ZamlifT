const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const env = require('./config/env');
const socketHandlers = require('./modules/realtime/socket');

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: env.clientOrigin === '*' ? true : env.clientOrigin,
    methods: ['GET', 'POST', 'PATCH'],
  },
});

app.set('io', io);
socketHandlers(io);

server.listen(env.port, () => {
  console.log(`ZamLift backend listening on port ${env.port}`);
});
