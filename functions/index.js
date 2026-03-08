const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Rate Limiting Helper ─────────────────────────────────────────────────────
async function checkRateLimit(key, windowMs, maxHits) {
  const ref = db.collection('_rate_limits').doc(key);
  const now = Date.now();

  return db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const data = doc.exists ? doc.data() : { hits: [], blockedUntil: 0 };

    if (data.blockedUntil > now) {
      throw new HttpsError('resource-exhausted', 'Rate limit exceeded. Try again later.');
    }

    // Prune old hits outside the window
    const recent = (data.hits || []).filter((t) => now - t < windowMs);
    if (recent.length >= maxHits) {
      tx.set(ref, { hits: recent, blockedUntil: now + windowMs });
      throw new HttpsError('resource-exhausted', 'Too many requests. Please slow down.');
    }

    tx.set(ref, { hits: [...recent, now], blockedUntil: 0 });
  });
}

// Helper: send FCM safely
async function sendFcm(userId, notification, data = {}) {
  try {
    const tokenDoc = await db.collection('user_tokens').doc(userId).get();
    if (!tokenDoc.exists) return;

    const token = tokenDoc.data().token;
    if (!token) return;

    await messaging.send({ token, notification, data });
  } catch (err) {
    console.warn(`FCM send failed for ${userId}:`, err.message);
  }
}

// ─── 1. logProximity ─────────────────────────────────────────────────────────
exports.logProximity = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required.');

  const discovererId = request.auth.uid;
  const { anonId } = request.data;
  if (!anonId) throw new HttpsError('invalid-argument', 'Missing anonId.');

  // Rate limit: max 30 events per minute per user
  await checkRateLimit(`proximity:${discovererId}`, 60 * 1000, 30);

  // BLE Anonymous ID resolution
  // In production: lookup anonId in ble_rotations collection for real UID
  const bleDoc = await db.collection('ble_rotations').doc(anonId).get();
  const discoveredUserId = bleDoc.exists ? bleDoc.data().uid : anonId;

  if (discovererId === discoveredUserId) {
    return { status: 'self', message: 'Cannot detect yourself.' };
  }

  // 5-minute cooldown per pairing at Firestore level
  const recent = await db.collection('proximity_events')
    .where('discovererId', '==', discovererId)
    .where('discoveredUserId', '==', discoveredUserId)
    .orderBy('detectedAt', 'desc')
    .limit(1)
    .get();

  if (!recent.empty) {
    const lastTime = recent.docs[0].data().detectedAt.toDate();
    if (Date.now() - lastTime.getTime() < 5 * 60 * 1000) {
      return { status: 'debounced', message: 'Within cooldown window.' };
    }
  }

  // Fetch discoverer & discovered user info
  const [discovererDoc, discoveredDoc] = await Promise.all([
    db.collection('users').doc(discovererId).get(),
    db.collection('users').doc(discoveredUserId).get(),
  ]);

  if (!discoveredDoc.exists) return { status: 'not_found' };

  // Check stealth mode
  if (discoveredDoc.data().stealthMode === true) {
    return { status: 'stealth', message: 'User is in stealth mode.' };
  }

  const discoveredName = discoveredDoc.data().displayName || 'Someone';
  const discovererName = discovererDoc.exists
    ? discovererDoc.data().displayName
    : 'Someone';

  // Write event
  const eventRef = db.collection('proximity_events').doc();
  await eventRef.set({
    id: eventRef.id,
    discovererId,
    discoveredUserId,
    distance: 3.0,
    detectedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Award XP
  await Promise.all([
    db.collection('users').doc(discovererId).update({
      xpPoints: admin.firestore.FieldValue.increment(2),
    }),
    db.collection('users').doc(discoveredUserId).update({
      xpPoints: admin.firestore.FieldValue.increment(2),
    }),
  ]);

  // Push notification to discovered user
  await sendFcm(discoveredUserId, {
    title: 'You crossed paths! ⚡',
    body: `${discovererName} was just near you.`,
  }, { type: 'PROXIMITY', discovererId });

  return { status: 'match_found', name: discoveredName };
});


// ─── 2. friendRequestNotification ────────────────────────────────────────────
exports.friendRequestNotification = onDocumentCreated(
  'friend_requests/{requestId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const senderDoc = await db.collection('users').doc(data.senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().displayName : 'Someone';

    await sendFcm(data.receiverId, {
      title: 'New connection request 🤝',
      body: `${senderName} wants to connect with you.`,
    }, {
      type: 'FRIEND_REQUEST',
      requestId: event.params.requestId,
      senderId: data.senderId,
    });
  }
);


// ─── 3. acceptRequest (callable) ─────────────────────────────────────────────
exports.acceptFriendRequest = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required.');

  const { requestId } = request.data;
  if (!requestId) throw new HttpsError('invalid-argument', 'Missing requestId.');

  const reqDoc = await db.collection('friend_requests').doc(requestId).get();
  if (!reqDoc.exists) throw new HttpsError('not-found', 'Request not found.');

  const { senderId, receiverId } = reqDoc.data();
  if (receiverId !== request.auth.uid) throw new HttpsError('permission-denied', 'Not your request.');

  const batch = db.batch();

  // Update request status
  batch.update(db.collection('friend_requests').doc(requestId), {
    status: 'accepted',
  });

  // Create bidirectional connection
  const ids = [senderId, receiverId].sort();
  const connId = ids.join('_');
  batch.set(db.collection('connections').doc(connId), {
    users: ids,
    connectedAt: admin.firestore.FieldValue.serverTimestamp(),
    participants: ids,
  });

  // XP reward
  batch.update(db.collection('users').doc(senderId), {
    xpPoints: admin.firestore.FieldValue.increment(10),
  });
  batch.update(db.collection('users').doc(receiverId), {
    xpPoints: admin.firestore.FieldValue.increment(10),
  });

  await batch.commit();

  // Notify sender
  const receiverDoc = await db.collection('users').doc(receiverId).get();
  const receiverName = receiverDoc.data().displayName || 'Someone';
  await sendFcm(senderId, {
    title: 'Connection accepted! 🎉',
    body: `${receiverName} accepted your connection request.`,
  }, { type: 'REQUEST_ACCEPTED', connId });

  return { status: 'success', connId };
});


// ─── 4. deleteExpiredStories (hourly cron) ────────────────────────────────────
exports.deleteExpiredStories = onSchedule("every 1 hours", async () => {
  const now = new Date().toISOString();

  const snapshot = await db.collection('stories')
    .where('expiresAt', '<=', now)
    .get();

  if (snapshot.empty) {
    console.log('No expired stories.');
    return;
  }

  // Batch deletes in chunks of 400 (Firestore limitation is 500)
  const BATCH_SIZE = 400;
  let count = 0;

  const docs = snapshot.docs;
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const chunk = docs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    chunk.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    count += chunk.length;
  }

  console.log(`Deleted ${count} expired stories.`);
});


// ─── 5. updateStreak (daily cron) ─────────────────────────────────────────────
exports.updateDailyStreaks = onSchedule("every 24 hours", async () => {
  const cutoff = new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString(); // 25h window

  // Find users who were active in last 25h and increment streak
  const activeSnap = await db.collection('users')
    .where('lastActive', '>=', cutoff)
    .get();

  const batch = db.batch();
  activeSnap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      streakCount: admin.firestore.FieldValue.increment(1),
    });
  });
  await batch.commit();

  // Find inactive users and reset streak
  const inactiveSnap = await db.collection('users')
    .where('lastActive', '<', cutoff)
    .where('streakCount', '>', 0)
    .get();

  const batch2 = db.batch();
  inactiveSnap.docs.forEach((doc) => {
    batch2.update(doc.ref, { streakCount: 0 });
  });
  await batch2.commit();

  console.log(`Streaks: ${activeSnap.size} incremented, ${inactiveSnap.size} reset.`);
});
