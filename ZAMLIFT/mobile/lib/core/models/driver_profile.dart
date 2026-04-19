/// Mirrors `driver_profiles` with optional joined `users` fields.
class DriverProfile {
  const DriverProfile({
    required this.userId,
    required this.licenseNumber,
    required this.nationalId,
    required this.phone,
    required this.verificationStatus,
    required this.averageRating,
    required this.totalRatings,
    this.verifiedBy,
    this.verifiedAt,
    this.fullName,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String licenseNumber;
  final String nationalId;
  final String phone;
  final String verificationStatus; // 'pending' | 'approved' | 'rejected'
  final double averageRating;
  final int totalRatings;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  // joined from users (available in admin list)
  final String? fullName;
  final String? email;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        userId: json['user_id'] as String,
        licenseNumber: json['license_number'] as String,
        nationalId: json['national_id'] as String,
        phone: json['phone'] as String,
        verificationStatus: json['verification_status'] as String,
        averageRating:
            double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
        totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
        verifiedBy: json['verified_by'] as String?,
        verifiedAt: json['verified_at'] != null
            ? DateTime.parse(json['verified_at'] as String)
            : null,
        fullName: json['full_name'] as String?,
        email: json['email'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
