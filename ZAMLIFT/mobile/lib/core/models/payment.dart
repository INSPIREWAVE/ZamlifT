/// Mirrors the `payments` table (with optional joined fields).
class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.payerId,
    required this.amount,
    required this.provider,
    required this.reference,
    required this.phoneNumber,
    required this.status,
    this.tripId,
    this.payerName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String payerId;
  final double amount;
  final String provider;
  final String reference;
  final String phoneNumber;
  final String status; // 'pending' | 'completed' | 'failed'

  // Joined fields
  final String? tripId; // from GET /api/payments/my
  final String? payerName; // from GET /api/payments (admin)

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        payerId: json['payer_id'] as String,
        amount: double.parse(json['amount']?.toString() ?? '0'),
        provider: json['provider'] as String,
        reference: json['reference'] as String,
        phoneNumber: json['phone_number'] as String,
        status: json['status'] as String,
        tripId: json['trip_id'] as String?,
        payerName: json['payer_name'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
