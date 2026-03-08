import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story_model.dart';
import 'controllers/story_controller.dart';
import '../../../core/theme/app_theme.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryModel story;
  const StoryViewerScreen({super.key, required this.story});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _progressCtrl;
  final _reactions = ['🔥', '❤️', '😂', '😮', '😢', '👏'];

  @override
  void initState() {
    super.initState();

    // Progress bar animates over story duration
    final duration = widget.story.type == 'video'
        ? const Duration(seconds: 10)
        : const Duration(seconds: 5);

    _progressCtrl = AnimationController(vsync: this, duration: duration)
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.pop(context);
        }
      });

    if (widget.story.type == 'video' && widget.story.mediaUrl.isNotEmpty) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.story.mediaUrl))
            ..initialize().then((_) {
              if (mounted) setState(() {});
              _videoController!.play();
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _progressCtrl.stop(),
        onTapUp: (_) => _progressCtrl.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content
            _buildMedia(),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Progress bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: AnimatedBuilder(
                animation: _progressCtrl,
                builder: (_, __) => LinearProgressIndicator(
                  value: _progressCtrl.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mint),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 3,
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 22,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),

            // Story type label
            Positioned(
              top: MediaQuery.of(context).padding.top + 28,
              left: 16,
              child: Row(children: [
                const CircleAvatar(radius: 18, backgroundColor: AppTheme.violet,
                    child: Icon(Icons.person, size: 18, color: Colors.white)),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Vibe Story', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(_timeAgo(), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              ]),
            ),

            // Reaction bar
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _reactions.map((emoji) {
                  return GestureDetector(
                    onTap: () async {
                      await ref.read(storyControllerProvider.notifier)
                          .reactToStory(widget.story.id, emoji);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reacted $emoji'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final s = widget.story;
    if (s.type == 'image' && s.mediaUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: s.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.black),
        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 64)),
      );
    }
    if (s.type == 'video' && _videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    if (s.type == 'text') {
      return Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              s.textContent ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.4),
            ),
          ),
        ),
      );
    }
    return Container(color: Colors.black38);
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(widget.story.createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
