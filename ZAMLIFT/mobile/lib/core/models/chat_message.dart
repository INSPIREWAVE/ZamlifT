/// Mirrors `trip_messages` joined with `users` (sender_name).
/// Both the REST response and Socket.io `trip:new-message` event use this shape.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    this.senderName,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final String senderId;
  final String message;
  final String? senderName;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        senderId: json['sender_id'] as String,
        message: json['message'] as String,
        senderName: json['sender_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
