import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/friend_request.dart';

final connectionsServiceProvider = Provider<ConnectionsService>((ref) {
  return ConnectionsService(FirebaseFirestore.instance);
});

// Streams accepted connections for current user
final connectionsProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(connectionsServiceProvider).getConnections();
});

// Streams incoming pending requests
final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.read(connectionsServiceProvider).getIncomingRequests();
});

class ConnectionsService {
  final FirebaseFirestore _firestore;
  ConnectionsService(this._firestore);

  Future<void> sendRequest(String toUserId) async {
    final fromUid = FirebaseAuth.instance.currentUser?.uid;
    if (fromUid == null || fromUid == toUserId) return;

    // Check if request already exists
    final existing = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: fromUid)
        .where('receiverId', isEqualTo: toUserId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final docRef = _firestore.collection('friend_requests').doc();
    await docRef.set(FriendRequest(
      id: docRef.id,
      senderId: fromUid,
      receiverId: toUserId,
      status: 'pending',
    ).toJson());
  }

  Future<void> acceptRequest(String requestId, String senderId) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final batch = _firestore.batch();

    // Update request status
    batch.update(
      _firestore.collection('friend_requests').doc(requestId),
      {'status': 'accepted'},
    );

    // Write connection document (bidirectional reference)
    final connRef = _firestore.collection('connections').doc('${myUid}_$senderId');
    batch.set(connRef, {
      'users': [myUid, senderId],
      'connectedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Future<void> declineRequest(String requestId) async {
    await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  Stream<List<FriendRequest>> getIncomingRequests() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => FriendRequest.fromJson(d.data())).toList());
  }

  Stream<List<UserModel>> getConnections() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _firestore
        .collection('connections')
        .where('users', arrayContains: myUid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];
      final others = snapshot.docs.map((doc) {
        final users = List<String>.from(doc.data()['users']);
        return users.firstWhere((u) => u != myUid, orElse: () => '');
      }).where((u) => u.isNotEmpty).toList();

      final futures = others.map((uid) =>
          _firestore.collection('users').doc(uid).get());
      final results = await Future.wait(futures);
      return results
          .where((d) => d.exists)
          .map((d) => UserModel.fromJson({'id': d.id, ...d.data()!}))
          .toList();
    });
  }
}
