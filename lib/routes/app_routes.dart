import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_thread_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/connections/connections_screen.dart';

class AppRoutes {
  static const String splash       = '/splash';
  static const String auth         = '/auth';
  static const String otp          = '/otp';
  static const String onboarding   = '/onboarding';
  static const String home         = '/home';
  static const String chatThread   = '/chat/thread';
  static const String profile      = '/profile';
  static const String connections  = '/connections';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(const SplashScreen());

      case auth:
        return _fade(const AuthScreen());

      case otp:
        final verificationId = settings.arguments as String;
        return _slide(OtpScreen(verificationId: verificationId));

      case onboarding:
        return _fade(const OnboardingScreen());

      case home:
        return _fade(const HomeScreen());

      case chatThread:
        final args = settings.arguments as Map<String, String>;
        return _slide(ChatThreadScreen(
          otherUserId:   args['otherUserId']!,
          otherUserName: args['otherUserName']!,
          chatId:        args['chatId']!,
        ));

      case profile:
        final uid = settings.arguments as String?;
        return _slide(ProfileScreen(userId: uid));

      case connections:
        return _slide(const ConnectionsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  static PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}
