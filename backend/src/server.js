const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const env = require('./config/env');
const socketHandlers = require('./modules/realtime/socket');

const server = http.createServer(app);
const allowedOrigins = env.clientOrigin
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const io = new Server(server, {
  cors: {
    origin: allowedOrigins,
    methods: ['GET', 'POST', 'PATCH'],
  },
});

app.set('io', io);
socketHandlers(io);

server.listen(env.port, () => {
  console.log(`ZamLift backend listening on port ${env.port}`);
});
