import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/avatar_widget.dart';
import '../../routes/app_routes.dart';
import 'controllers/chat_controller.dart';
import '../connections/connections_service.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('💬', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Connect with people to start chatting', style: TextStyle(color: Colors.white54)),
              ]),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final user = users[i];
              final chatId = getChatId(myUid, user.id);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: AvatarWidget(imageUrl: user.profilePhotoUrl, radius: 26),
                title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Tap to chat', style: TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.mint,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.chatThread,
                  arguments: {
                    'otherUserId': user.id,
                    'otherUserName': user.displayName,
                    'chatId': chatId,
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
