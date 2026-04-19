import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _messages = <String>[];
  final _conversationId = 'trip-room-1';

  @override
  void initState() {
    super.initState();
    final socket = context.read<SocketService>();
    socket.joinChatRoom(_conversationId);
    socket.onMessage((payload) {
      final map = payload as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _messages.add('${map['senderId']}: ${map['message']}'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.read<SocketService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Passenger ↔ Driver Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, index) => ListTile(title: Text(_messages[index])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _messageController.text.trim();
                    if (text.isEmpty) return;
                    socket.sendMessage(_conversationId, text);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
