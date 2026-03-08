import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/avatar_widget.dart';
import '../../routes/app_routes.dart';
import 'connections_service.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final requestsAsync = ref.watch(incomingRequestsProvider);
    final service = ref.read(connectionsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: CustomScrollView(
        slivers: [
          // Incoming Requests section
          SliverToBoxAdapter(
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text('Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ...requests.map((req) => _RequestCard(
                      request: req,
                      onAccept: () => service.acceptRequest(req.id, req.senderId),
                      onDecline: () => service.declineRequest(req.id),
                    )),
                    const Divider(height: 30),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Connections header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text('Your Connections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          // Connections List
          connectionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('💫', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('No connections yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Discover people near you from the Home tab', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ]),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final user = users[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: AvatarWidget(imageUrl: user.profilePhotoUrl, radius: 26),
                    title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(user.interests.take(2).join(' · '),
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile, arguments: user.id),
                  );
                }, childCount: users.length),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({required this.request, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const AvatarWidget(imageUrl: '', radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.senderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('Wants to connect', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle, color: AppTheme.mint, size: 32),
          ),
          IconButton(
            onPressed: onDecline,
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 32),
          ),
        ],
      ),
    );
  }
}
