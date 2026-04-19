const jwt = require('jsonwebtoken');
const env = require('../../config/env');

module.exports = (io) => {
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('Authentication token missing'));
      socket.user = jwt.verify(token, env.jwtSecret);
      return next();
    } catch (_error) {
      return next(new Error('Invalid authentication token'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('trip:join', (tripId) => {
      socket.join(`trip:${tripId}`);
    });

    socket.on('chat:join', (conversationId) => {
      socket.join(`chat:${conversationId}`);
    });

    socket.on('chat:message', ({ conversationId, message }) => {
      if (!message) return;
      io.to(`chat:${conversationId}`).emit('chat:message', {
        senderId: socket.user.id,
        message,
        sentAt: new Date().toISOString(),
      });
    });
  });
};
