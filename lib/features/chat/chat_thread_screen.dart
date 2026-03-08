import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'controllers/chat_controller.dart';
import 'services/chat_service.dart';
import 'widgets/message_bubble.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String chatId;

  const ChatThreadScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.chatId,
  });

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() => _showSendButton = _textController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(chatControllerProvider).sendMessage(widget.chatId, text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));
    final controller = ref.read(chatControllerProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Typing indicator
    final chatService = ref.read(chatServiceProvider);
    final typingStream = chatService.getTypingStatus(widget.chatId, widget.otherUserId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: AppTheme.surfaceAlt,
              child: Icon(Icons.person, size: 18)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                StreamBuilder<bool>(
                  stream: typingStream,
                  builder: (_, snap) {
                    final isTyping = snap.data ?? false;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isTyping
                          ? const Text('typing...', style: TextStyle(fontSize: 11, color: AppTheme.mint))
                          : const Text('online', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('👋', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text("Say hi!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Be the first to break the ice", style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ]),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.fromUser == myUid;

                    if (!isMe && !msg.seenBy.contains(myUid)) {
                      controller.markMessageSeen(widget.chatId, msg.id);
                    }

                    final isRead = msg.seenBy.contains(widget.otherUserId);

                    // Show date divider when consecutive messages are far apart
                    final showDate = i == messages.length - 1 ||
                        messages[i + 1].createdAt.day != msg.createdAt.day;

                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        MessageBubble(text: msg.text, isMe: isMe, isRead: isRead,
                            timestamp: msg.createdAt),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text("Failed to load messages")),
            ),
          ),

          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (_) => controller.onTyping(widget.chatId),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _showSendButton ? AppTheme.primaryGradient : null,
                      color: _showSendButton ? null : Colors.white12,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _showSendButton ? _sendMessage : null,
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

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String _label() {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return 'Today';
    if (date.day == now.day - 1 && date.month == now.month) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_label(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ]),
    );
  }
}
