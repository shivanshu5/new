import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/avatar_widget.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../routes/app_routes.dart';

// Provider to stream a specific user profile
final userProfileProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromJson({'id': doc.id, ...doc.data()!}) : null);
});

class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnProfile = uid == FirebaseAuth.instance.currentUser?.uid;
    final profileAsync = ref.watch(userProfileProvider(uid));

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }
        return _ProfileContent(user: user, isOwnProfile: isOwnProfile);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;

  const _ProfileContent({required this.user, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible header with gradient
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    AvatarWidget(imageUrl: user.profilePhotoUrl, radius: 50, hasStory: false),
                    const SizedBox(height: 14),
                    Text(user.displayName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.bolt, color: Colors.yellowAccent, size: 16),
                      const SizedBox(width: 4),
                      Text('${user.xpPoints} XP  ·  🔥 ${user.streakCount} day streak',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
            ),
            actions: isOwnProfile
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditSheet(context, user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
                        }
                      },
                    ),
                  ]
                : null,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intent badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Here for: ${_intentLabel(user.intent)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  if (user.bio.isNotEmpty) ...[
                    const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(user.bio, style: const TextStyle(color: Colors.white70, height: 1.5)),
                    const SizedBox(height: 20),
                  ],

                  // Interests
                  if (user.interests.isNotEmpty) ...[
                    const Text('Interests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests
                          .map((i) => ChipTag(label: i, isSelected: true))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Stats row
                  Row(
                    children: [
                      _StatTile('XP', '${user.xpPoints}'),
                      _StatTile('Streak', '${user.streakCount}d'),
                      _StatTile('Privacy', user.photoPrivacy),
                    ],
                  ),

                  if (!isOwnProfile) ...[
                    const SizedBox(height: 30),
                    _ActionButtons(userId: user.id),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _intentLabel(String intent) {
    switch (intent) {
      case 'dating':     return 'Dating ❤️';
      case 'networking': return 'Networking 💼';
      case 'explore':    return 'Exploring 🌍';
      default:           return 'Friends 🤝';
    }
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    final bioCtrl = TextEditingController(text: user.bio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, 
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(hintText: 'Write your bio...'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .update({'bio': bioCtrl.text.trim()});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.mint)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String userId;
  const _ActionButtons({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Connection request logic handled in ConnectionsController
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Connect'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to chat
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
            label: const Text('Message', style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}
