import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';

class SocketService {
  io.Socket? _socket;

  void connect(String token) {
    _socket = io.io(
      Env.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket?.connect();
  }

  void joinTripRoom(int tripId) => _socket?.emit('trip:join', tripId);

  void joinChatRoom(String conversationId) => _socket?.emit('chat:join', conversationId);

  void sendMessage(String conversationId, String message) =>
      _socket?.emit('chat:message', {'conversationId': conversationId, 'message': message});

  void onMessage(void Function(dynamic) handler) => _socket?.on('chat:message', handler);

  void onTripStatus(void Function(dynamic) handler) => _socket?.on('trip:status_updated', handler);

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}
