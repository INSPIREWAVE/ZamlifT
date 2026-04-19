require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const { registerSocket } = require('./config/socket');

const PORT = Number(process.env.PORT || 5000);

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.CLIENT_ORIGIN?.split(',') || ['http://localhost:5173'],
    methods: ['GET', 'POST', 'PATCH'],
  },
});

registerSocket(io);

server.listen(PORT, () => {
  console.log(`ZamLift backend running on port ${PORT}`);
});
