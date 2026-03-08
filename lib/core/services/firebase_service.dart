import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "dummy-key",
          appId: "1:1234567890:web:1234567890",
          messagingSenderId: "1234567890",
          projectId: "dummy-project",
        ),
      );
    } catch (e) {
      debugPrint('Firebase dummy init error: $e');
    }
  }
}
