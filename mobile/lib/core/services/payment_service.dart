import '../constants/api_constants.dart';
import '../models/payment.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Payment endpoints:
///
/// POST  /api/payments/deposit                   (auth)
/// GET   /api/payments/my                        (auth)
/// GET   /api/payments                           (admin)
/// PATCH /api/payments/:paymentId/status         (admin)
class PaymentService {
  PaymentService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage);

  final ApiClient _client;

  /// Initiate a mobile-money deposit for a booking.
  ///
  /// Request body:
  /// ```json
  /// { "bookingId": "uuid", "amount": 250.00, "phoneNumber": "+260977000000" }
  /// ```
  Future<Payment> deposit({
    required String bookingId,
    required double amount,
    required String phoneNumber,
  }) async {
    final data = await _client.post(
      ApiConstants.deposit,
      {
        'bookingId': bookingId,
        'amount': amount,
        'phoneNumber': phoneNumber,
      },
    ) as Map<String, dynamic>;
    return Payment.fromJson(data);
  }

  /// List the authenticated user's own payments.
  Future<List<Payment>> getMyPayments() async {
    final data = await _client.get(ApiConstants.myPayments) as List;
    return data.cast<Map<String, dynamic>>().map(Payment.fromJson).toList();
  }

  /// [Admin only] List all payments.
  Future<List<Payment>> listAllPayments() async {
    final data = await _client.get(ApiConstants.allPayments) as List;
    return data.cast<Map<String, dynamic>>().map(Payment.fromJson).toList();
  }

  /// [Admin only] Update a payment's status.
  ///
  /// [status]: 'pending' | 'completed' | 'failed'
  Future<Payment> updatePaymentStatus({
    required String paymentId,
    required String status,
  }) async {
    final data = await _client.patch(
      ApiConstants.paymentStatus(paymentId),
      {'status': status},
    ) as Map<String, dynamic>;
    return Payment.fromJson(data);
  }
}
