import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../features/chat/providers/chat_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Trip chat screen.
///
/// Route argument: `tripId` (String).
///
/// Loads message history via REST and then opens a Socket.io connection
/// to receive and send real-time messages.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late String _tripId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tripId = ModalRoute.of(context)!.settings.arguments as String;
      context.read<ChatProvider>().joinTrip(_tripId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(
          tripId: _tripId,
          message: text,
        );
    _msgCtrl.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final myId =
        context.select((AuthProvider p) => p.user?.id);

    // Auto-scroll when new messages arrive.
    if (provider.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Chat')),
      body: Column(
        children: [
          if (provider.loading)
            const LinearProgressIndicator(),
          if (provider.error != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: provider.messages.length,
              itemBuilder: (_, i) {
                final msg = provider.messages[i];
                final isMe = msg.senderId == myId;
                return _MessageBubble(
                  message: msg.message,
                  senderName: msg.senderName ?? msg.senderId.substring(0, 8),
                  time: msg.createdAt,
                  isMe: isMe,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1B6CA8),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.time,
    required this.isMe,
  });

  final String message;
  final String senderName;
  final DateTime time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? const Color(0xFF1B6CA8)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final fg = isMe ? Colors.white : null;
    final align =
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMe)
            Text(
              senderName,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(message, style: TextStyle(color: fg)),
          ),
          Text(
            DateFormat('HH:mm').format(time.toLocal()),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
