import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story_model.dart';
import '../../../shared/models/user_model.dart'; // Assume we fetch user context

final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

class StoryService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StoryService(this._firestore, this._storage);

  Future<void> createStory({
    required String authorId,
    required String type,
    required String visibility,
    File? mediaFile,
    String? textContent,
  }) async {
    final docRef = _firestore.collection('stories').doc();
    String mediaUrl = '';

    if (mediaFile != null) {
      // Use Firebase Storage
      final storageRef = _storage.ref().child('stories').child('${docRef.id}.media');
      await storageRef.putFile(mediaFile);
      mediaUrl = await storageRef.getDownloadURL();
    }

    final story = StoryModel(
      id: docRef.id,
      authorId: authorId,
      mediaUrl: mediaUrl,
      type: type,
      visibility: visibility,
      textContent: textContent,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    await docRef.set(story.toJson());
  }

  Stream<List<StoryModel>> getActiveStories() {
    // For now, get all stories that haven't expired. 
    // Usually, you would filter by Visibility + Proximity limits over Firebase Functions
    // or by querying friends only.
    final now = DateTime.now().toIso8601String();
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => StoryModel.fromJson(doc.data())).toList());
  }

  Future<void> addReaction(String storyId, String emoji) async {
    await _firestore.collection('stories').doc(storyId).update({
      'reactions': FieldValue.arrayUnion([emoji])
    });
  }
}
