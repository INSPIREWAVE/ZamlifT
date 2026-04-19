const jwt = require('jsonwebtoken');
const { query } = require('./db');
const { ensureTripParticipant, saveTripMessage } = require('../services/chatService');

function registerSocket(io) {
  io.use(async (socket, next) => {
    try {
      const authHeader = socket.handshake.auth?.token || socket.handshake.headers.authorization;
      if (!authHeader) {
        return next(new Error('Unauthorized'));
      }

      const token = authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : authHeader;
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const userRes = await query('SELECT id, full_name, role, is_active FROM users WHERE id = $1 LIMIT 1', [decoded.sub]);
      const user = userRes.rows[0];

      if (!user || !user.is_active) {
        return next(new Error('Unauthorized'));
      }

      socket.user = user;
      return next();
    } catch (error) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('trip:join', async ({ tripId }) => {
      if (!tripId) return;
      const allowed = socket.user.role === 'admin' || (await ensureTripParticipant(socket.user.id, tripId));
      if (!allowed) {
        socket.emit('trip:error', { message: 'Forbidden' });
        return;
      }

      socket.join(`trip:${tripId}`);
      socket.emit('trip:joined', { tripId });
    });

    socket.on('trip:message', async ({ tripId, message }) => {
      if (!tripId || !message || typeof message !== 'string' || !message.trim()) return;

      const allowed = socket.user.role === 'admin' || (await ensureTripParticipant(socket.user.id, tripId));
      if (!allowed) {
        socket.emit('trip:error', { message: 'Forbidden' });
        return;
      }

      const saved = await saveTripMessage({
        tripId,
        senderId: socket.user.id,
        message: message.trim(),
      });

      io.to(`trip:${tripId}`).emit('trip:new-message', {
        ...saved,
        sender_name: socket.user.full_name,
      });
    });
  });
}

module.exports = { registerSocket };
