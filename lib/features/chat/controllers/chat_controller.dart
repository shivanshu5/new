import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';
import '../../../shared/models/chat_message.dart';
import 'dart:async';

// Generate a consistent chatId from two user IDs
String getChatId(String uid1, String uid2) {
  final ids = [uid1, uid2];
  ids.sort();
  return ids.join('_');
}

final messagesStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  // Default limit 50 for infinite scroll base
  return chatService.getMessagesStream(chatId, limit: 50);
});

final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(ref.read(chatServiceProvider));
});

class ChatController {
  final ChatService _chatService;
  Timer? _typingTimer;

  ChatController(this._chatService);

  Future<void> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return;
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _chatService.sendMessage(chatId, text.trim(), uid);
  }

  void onTyping(String chatId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _chatService.setTypingStatus(chatId, uid, true);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.setTypingStatus(chatId, uid, false);
    });
  }

  Future<void> markMessageSeen(String chatId, String messageId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _chatService.markAsSeen(chatId, messageId, uid);
  }
}
