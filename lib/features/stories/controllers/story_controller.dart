import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'story_service.dart';
import '../models/story_model.dart';

// Stream provider to fetch live stories
final activeStoriesProvider = StreamProvider<List<StoryModel>>((ref) {
  final service = ref.watch(storyServiceProvider);
  return service.getActiveStories();
});

final storyControllerProvider = StateNotifierProvider<StoryController, bool>((ref) {
  return StoryController(ref.read(storyServiceProvider));
});

class StoryController extends StateNotifier<bool> {
  final StoryService _storyService;

  StoryController(this._storyService) : super(false);

  Future<void> uploadStory({
    required String type,
    required String visibility,
    File? mediaFile,
    String? textContent,
  }) async {
    state = true; // uploading
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _storyService.createStory(
        authorId: uid,
        type: type,
        visibility: visibility,
        mediaFile: mediaFile,
        textContent: textContent,
      );
    } catch (e) {
      print("Story Upload Failed: $e");
    } finally {
      state = false;
    }
  }

  Future<void> reactToStory(String storyId, String emoji) async {
    await _storyService.addReaction(storyId, emoji);
  }
}
