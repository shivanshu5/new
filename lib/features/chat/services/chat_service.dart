import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/chat_message.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(FirebaseFirestore.instance);
});

class ChatService {
  final FirebaseFirestore _firestore;

  ChatService(this._firestore);

  /// Streams messages for a given chat ID (which is derived from 2 users)
  Stream<List<ChatMessage>> getMessagesStream(String chatId, {int limit = 20}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<void> sendMessage(String chatId, String text, String fromUser) async {
    final docRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    final message = ChatMessage(
      id: docRef.id,
      fromUser: fromUser,
      text: text,
      createdAt: DateTime.now(),
      seenBy: [fromUser], // Sender automatically sees it
    );

    // Batch write to update latest message in chat thread too
    final batch = _firestore.batch();
    
    batch.set(docRef, message.toJson());
    
    // Update thread meta
    batch.set(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageAt': message.createdAt.toIso8601String(),
      'participants': FieldValue.arrayUnion([fromUser]),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> markAsSeen(String chatId, String messageId, String userId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'seenBy': FieldValue.arrayUnion([userId])
    });
  }

  // Stream for Typing indicator
  Stream<bool> getTypingStatus(String chatId, String otherUserId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(otherUserId)
        .snapshots()
        .map((doc) => doc.exists ? (doc.data()?['isTyping'] ?? false) : false);
  }

  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({'isTyping': isTyping});
  }
}
