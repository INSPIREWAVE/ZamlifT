const { ensureTripParticipant, getTripMessages } = require('../services/chatService');

async function getTripChatMessages(req, res, next) {
  try {
    const { tripId } = req.validated.params;
    const isParticipant = await ensureTripParticipant(req.user.id, tripId);

    if (!isParticipant && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const messages = await getTripMessages(tripId);
    return res.json(messages);
  } catch (error) {
    return next(error);
  }
}

module.exports = { getTripChatMessages };
