import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({required ChatService chatService})
      : _service = chatService;

  final ChatService _service;

  List<ChatMessage> _messages = [];
  bool _connected = false;
  bool _loading = false;
  String? _error;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<String>? _errorSub;

  List<ChatMessage> get messages => _messages;
  bool get connected => _connected;
  bool get loading => _loading;
  String? get error => _error;

  /// Load history then open a Socket.io connection for [tripId].
  Future<void> joinTrip(String tripId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _service.getMessages(tripId);

      final socket = await _service.connect();
      _connected = socket.connected;

      _messageSub = _service.onNewMessage().listen((msg) {
        _messages.add(msg);
        notifyListeners();
      });

      _errorSub = _service.onError().listen((err) {
        _error = err;
        notifyListeners();
      });

      _service.joinTrip(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void sendMessage({required String tripId, required String message}) {
    _service.sendMessage(tripId: tripId, message: message);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _errorSub?.cancel();
    _service.disconnect();
    super.dispose();
  }
}
