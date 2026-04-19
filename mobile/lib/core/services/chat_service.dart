import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../constants/api_constants.dart';
import '../models/chat_message.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Chat service – combines:
///  * REST:     GET /api/chat/trips/:tripId/messages  (auth)
///  * Socket.io: connects to backend root, emits trip:join / trip:message,
///               listens for trip:joined / trip:new-message / trip:error
class ChatService {
  ChatService({required TokenStorage tokenStorage})
      : _client = ApiClient(tokenStorage: tokenStorage),
        _tokenStorage = tokenStorage;

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  sio.Socket? _socket;

  /// Load message history for a trip via REST.
  Future<List<ChatMessage>> getMessages(String tripId) async {
    final data =
        await _client.get(ApiConstants.tripMessages(tripId)) as List;
    return data
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  // ── Socket.io ─────────────────────────────────────────────────────────────

  /// Connect to the Socket.io server and authenticate with JWT.
  ///
  /// The backend middleware reads the token from
  /// `socket.handshake.auth.token`.
  Future<sio.Socket> connect() async {
    final token = await _tokenStorage.getToken();
    _socket = sio.io(
      ApiConstants.baseUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    return _socket!;
  }

  /// Join a trip's chat room.
  ///
  /// Emits: `trip:join { "tripId": "..." }`
  /// Listens for: `trip:joined { "tripId": "..." }`
  void joinTrip(String tripId) {
    _socket?.emit('trip:join', {'tripId': tripId});
  }

  /// Send a chat message to a trip room.
  ///
  /// Emits: `trip:message { "tripId": "...", "message": "..." }`
  /// Server broadcasts: `trip:new-message { ...ChatMessage fields, sender_name }`
  void sendMessage({required String tripId, required String message}) {
    _socket?.emit('trip:message', {'tripId': tripId, 'message': message});
  }

  /// Listen for new messages in the currently joined trip room.
  ///
  /// Returns a broadcast [Stream] of [ChatMessage].
  Stream<ChatMessage> onNewMessage() {
    final controller = StreamController<ChatMessage>.broadcast();
    _socket?.on('trip:new-message', (data) {
      if (data is Map) {
        controller.add(
          ChatMessage.fromJson(Map<String, dynamic>.from(data as Map)),
        );
      }
    });
    return controller.stream;
  }

  /// Listen for errors emitted by the server.
  Stream<String> onError() {
    final controller = StreamController<String>.broadcast();
    _socket?.on('trip:error', (data) {
      if (data is Map && data['message'] is String) {
        controller.add(data['message'] as String);
      }
    });
    return controller.stream;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
