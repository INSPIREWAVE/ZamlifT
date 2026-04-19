/// Mirrors the `users` table row returned by login/register endpoints.
/// Response JSON uses snake_case keys.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String role; // 'passenger' | 'driver' | 'admin'
  final bool isActive;
  final DateTime? createdAt;

  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';
  bool get isPassenger => role == 'passenger';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'is_active': isActive,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
