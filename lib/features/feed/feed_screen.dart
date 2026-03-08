import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/avatar_widget.dart';
import '../../shared/widgets/chip_tag.dart';
import '../stories/controllers/story_controller.dart';
import '../stories/screens/story_viewer_screen.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: const Text('Nearmates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.tune_outlined), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Story Rail
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Text('Vibe Stories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                SizedBox(
                  height: 110,
                  child: storiesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stories) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stories.length + 1,
                      itemBuilder: (ctx, index) {
                        if (index == 0) {
                          return _AddStoryTile();
                        }
                        final story = stories[index - 1];
                        return _StoryTile(
                          imageUrl: story.type == 'image' ? story.mediaUrl : '',
                          label: 'Vibe',
                          hasUnread: true,
                          onTap: () => Navigator.push(ctx,
                              MaterialPageRoute(builder: (_) => StoryViewerScreen(story: story))),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: 24),
              ],
            ),
          ),

          // "People Near You" section header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('People Near You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          // Nearby People Feed
          _NearbyPeopleFeed(),
        ],
      ),
    );
  }
}

class _AddStoryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12, width: 2),
            color: AppTheme.surfaceAlt,
          ),
          child: const Icon(Icons.add, color: Colors.white54, size: 28),
        ),
        const SizedBox(height: 6),
        const Text('Add', style: TextStyle(fontSize: 11, color: Colors.white54)),
      ]),
    );
  }
}

class _StoryTile extends StatelessWidget {
  final String imageUrl;
  final String label;
  final bool hasUnread;
  final VoidCallback onTap;

  const _StoryTile({required this.imageUrl, required this.label, required this.hasUnread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(children: [
          AvatarWidget(imageUrl: imageUrl, radius: 35, hasStory: hasUnread),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
    );
  }
}

class _NearbyPeopleFeed extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('stealthMode', isEqualTo: false)
              .limit(20)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data!.docs.where((d) => d.id != myUid).toList();
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No one nearby yet. Keep Nearmates open! 📡', textAlign: TextAlign.center)),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final interests = List<String>.from(data['interests'] ?? []);
                return _NearbyPersonCard(
                  uid: doc.id,
                  name: data['displayName'] ?? 'User',
                  bio: data['bio'] ?? '',
                  interests: interests.take(3).toList(),
                  avatarUrl: data['profilePhotoUrl'] ?? '',
                  intent: data['intent'] ?? 'friends',
                );
              }).toList(),
            );
          },
        );
        // Guard: only render one item representing the whole stream
      }, childCount: 1),
    );
  }
}

class _NearbyPersonCard extends StatelessWidget {
  final String uid;
  final String name;
  final String bio;
  final List<String> interests;
  final String avatarUrl;
  final String intent;

  const _NearbyPersonCard({
    required this.uid,
    required this.name,
    required this.bio,
    required this.interests,
    required this.avatarUrl, 
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: uid),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            AvatarWidget(imageUrl: avatarUrl, radius: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    _IntentBadge(intent: intent),
                  ]),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(bio, style: const TextStyle(color: Colors.white54, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (interests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: interests
                          .map((i) => ChipTag(label: i, isSelected: false))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _IntentBadge extends StatelessWidget {
  final String intent;
  const _IntentBadge({required this.intent});

  String get _emoji {
    switch (intent) {
      case 'dating':     return '❤️';
      case 'networking': return '💼';
      case 'explore':    return '🌍';
      default:           return '🤝';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(_emoji, style: const TextStyle(fontSize: 13)),
    );
  }
}
