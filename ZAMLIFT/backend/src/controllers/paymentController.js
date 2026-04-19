const { getBookingById } = require('../models/bookingModel');
const { listUserPayments, listAllPayments } = require('../models/paymentModel');
const { createDeposit, updatePaymentStatus } = require('../services/paymentService');

async function depositHandler(req, res, next) {
  try {
    const { bookingId, amount, phoneNumber } = req.validated.body;
    const booking = await getBookingById(bookingId);

    if (!booking || booking.passenger_id !== req.user.id) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    const payment = await createDeposit({
      bookingId,
      payerId: req.user.id,
      amount,
      phoneNumber,
    });

    return res.status(201).json(payment);
  } catch (error) {
    return next(error);
  }
}

async function updatePaymentStatusHandler(req, res, next) {
  try {
    const { paymentId } = req.validated.params;
    const { status } = req.validated.body;

    const payment = await updatePaymentStatus(paymentId, status);
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    return res.json(payment);
  } catch (error) {
    return next(error);
  }
}

async function listMyPaymentsHandler(req, res, next) {
  try {
    const payments = await listUserPayments(req.user.id);
    return res.json(payments);
  } catch (error) {
    return next(error);
  }
}

async function listPaymentsAdminHandler(req, res, next) {
  try {
    const payments = await listAllPayments();
    return res.json(payments);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  depositHandler,
  updatePaymentStatusHandler,
  listMyPaymentsHandler,
  listPaymentsAdminHandler,
};
