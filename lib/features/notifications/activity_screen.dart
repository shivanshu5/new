import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('proximity_events')
            .where('discoveredUserId', isEqualTo: myUid)
            .orderBy('detectedAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, proxSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('friend_requests')
                .where('receiverId', isEqualTo: myUid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, reqSnap) {
              final activities = <_ActivityItem>[];

              if (proxSnap.hasData) {
                for (final doc in proxSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  activities.add(_ActivityItem(
                    icon: '📡',
                    title: 'Someone crossed your path!',
                    subtitle: 'Detected nearby via BLE',
                    timestamp: _parseTs(data['detectedAt']),
                    color: AppTheme.mint,
                  ));
                }
              }

              if (reqSnap.hasData) {
                for (final doc in reqSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  activities.add(_ActivityItem(
                    icon: status == 'accepted' ? '🤝' : '👤',
                    title: status == 'accepted'
                        ? 'Connection accepted!'
                        : 'New connection request',
                    subtitle: 'From ${data['senderId']}',
                    timestamp: _parseTs(data['createdAt']),
                    color: status == 'accepted' ? AppTheme.hotPink : AppTheme.violet,
                  ));
                }
              }

              // Sort all by timestamp
              activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              if (activities.isEmpty) {
                return const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('🔔', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    Text('No activity yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Activity appears when people are nearby', style: TextStyle(color: Colors.white54)),
                  ]),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ActivityTile(item: activities[i]),
              );
            },
          );
        },
      ),
    );
  }

  DateTime _parseTs(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    if (ts is Timestamp) return ts.toDate();
    return DateTime.now();
  }
}

class _ActivityItem {
  final String icon;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Color color;

  _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.color,
  });
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(item.timestamp);
    final timeStr = diff.inMinutes < 1
        ? 'just now'
        : diff.inHours < 1
            ? '${diff.inMinutes}m ago'
            : diff.inDays < 1
                ? '${diff.inHours}h ago'
                : '${diff.inDays}d ago';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(item.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
