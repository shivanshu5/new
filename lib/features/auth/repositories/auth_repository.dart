import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseFirestore.instance);
});

class AuthRepository {
  final FirebaseFirestore _firestore;
  AuthRepository(this._firestore);

  Future<void> saveUserRecordIfNew(User firebaseUser) async {
    final ref = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      final newUser = UserModel(
        id: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'Nearmate',
        profilePhotoUrl: firebaseUser.photoURL ?? '',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      await ref.set(newUser.toJson());
    } else {
      // Soft update lastActive only
      await ref.update({
        'lastActive': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson({'id': doc.id, ...doc.data()!});
    }
    return null;
  }

  /// Returns true if user has completed onboarding (has a displayName set beyond default)
  Future<bool> hasCompletedOnboarding(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    // Check if interests have been set as a proxy for onboarding completion
    final interests = List<String>.from(data?['interests'] ?? []);
    return interests.isNotEmpty;
  }
}
