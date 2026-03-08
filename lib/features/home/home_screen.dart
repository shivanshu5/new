import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../feed/feed_screen.dart';
import '../notifications/activity_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../proximity/controllers/proximity_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _screens = [
      const FeedScreen(),
      const ActivityScreen(),
      const ChatScreen(),
      ProfileScreen(userId: uid),
    ];

    // Start BLE scanning once home is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(proximityControllerProvider.notifier)
            .requestPermissionsAndStartScanning(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(proximityControllerProvider);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.mint,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Activity',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      // Floating BLE status indicator
      floatingActionButton: isScanning
          ? FloatingActionButton.small(
              onPressed: null,
              backgroundColor: AppTheme.mint.withOpacity(0.2),
              child: const Icon(Icons.bluetooth_searching, color: AppTheme.mint, size: 20),
            )
          : null,
    );
  }
}
