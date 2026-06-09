import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Realtime Firestore messaging + Phase 5 signals (typing, presence, read receipts).
///
/// Safe when Firebase was not initialized (e.g. iOS without GoogleService-Info.plist).
class ChatFirebaseService {
  ChatFirebaseService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  bool get isAvailable => FirebaseBootstrap.isAvailable;

  FirebaseFirestore? get _firestore {
    if (!isAvailable) return null;
    return _firestoreOverride ?? FirebaseFirestore.instance;
  }

  /// Live message stream ordered oldest → newest.
  Stream<List<Map<String, dynamic>>> watchMessages(String roomId) {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  ...Map<String, dynamic>.from(doc.data()),
                  'id': doc.id,
                },
              )
              .toList(),
        );
  }

  /// `true` when any other member has `isTyping: true` (stale after ~5s).
  Stream<bool> watchPeerTyping({
    required String roomId,
    required String myUserId,
  }) {
    final firestore = _firestore;
    if (roomId.isEmpty || myUserId.isEmpty || firestore == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      for (final doc in snapshot.docs) {
        if (doc.id == myUserId) continue;
        final data = doc.data();
        if (data['isTyping'] != true) continue;
        final updatedAt = _toDateTime(data['updatedAt']);
        if (updatedAt != null &&
            now.difference(updatedAt).inSeconds > 5) {
          continue;
        }
        return true;
      }
      return false;
    });
  }

  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) async {
    final firestore = _firestore;
    if (roomId.isEmpty || userId.isEmpty || firestore == null) return;

    final ref = firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('typing')
        .doc(userId);

    try {
      // Use merge set instead of delete — works with rules that allow update only.
      await ref.set({
        'userId': userId,
        'isTyping': isTyping,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!isTyping) {
        // Best-effort cleanup; ignore if rules disallow delete.
        try {
          await ref.delete();
        } catch (_) {}
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        LoggerUtils.logWarning(
          'ChatFirebaseService: typing skipped — publish typing Security Rules',
        );
        return;
      }
      LoggerUtils.logWarning('ChatFirebaseService: setTyping failed — $e');
    } catch (e) {
      LoggerUtils.logWarning('ChatFirebaseService: setTyping failed — $e');
    }
  }

  Stream<Map<String, dynamic>> watchPeerPresence(String peerUserId) {
    final firestore = _firestore;
    if (peerUserId.isEmpty || firestore == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('users')
        .doc(peerUserId)
        .collection('presence')
        .doc('main')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <String, dynamic>{};
      return Map<String, dynamic>.from(snapshot.data() ?? {});
    });
  }

  Future<void> setMyPresence({
    required String userId,
    required bool isOnline,
    String platform = 'mobile',
  }) async {
    final firestore = _firestore;
    if (userId.isEmpty || firestore == null) return;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc('main')
          .set({
        'isOnline': isOnline,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'platform': platform,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        LoggerUtils.logWarning(
          'ChatFirebaseService: presence skipped — publish presence Security Rules',
        );
        return;
      }
      LoggerUtils.logWarning('ChatFirebaseService: setMyPresence failed — $e');
    } catch (e) {
      LoggerUtils.logWarning('ChatFirebaseService: setMyPresence failed — $e');
    }
  }

  /// Recipient marks peer messages as delivered/read in `status.{myUserId}`.
  Future<void> ackIncomingMessages({
    required String roomId,
    required String myUserId,
    required List<Map<String, dynamic>> rawMessages,
    required bool markRead,
  }) async {
    final firestore = _firestore;
    if (roomId.isEmpty || myUserId.isEmpty || firestore == null) return;

    final batch = firestore.batch();
    var hasWrites = false;

    for (final raw in rawMessages) {
      final messageId =
          raw['id']?.toString() ?? raw['messageId']?.toString() ?? '';
      final senderId = raw['senderId']?.toString() ?? '';
      if (messageId.isEmpty || senderId.isEmpty || senderId == myUserId) {
        continue;
      }

      final status = raw['status'];
      final statusMap = status is Map
          ? Map<String, dynamic>.from(status)
          : <String, dynamic>{};
      final mine = statusMap[myUserId];
      final mineMap =
          mine is Map ? Map<String, dynamic>.from(mine) : <String, dynamic>{};

      final hasDelivered = mineMap['deliveredAt'] != null;
      final hasRead = mineMap['readAt'] != null;
      if (hasRead || (markRead == false && hasDelivered)) continue;

      final ref = firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      final updateKey = markRead ? 'readAt' : 'deliveredAt';
      if (markRead && !hasDelivered) {
        batch.update(ref, {
          'status.$myUserId.deliveredAt': FieldValue.serverTimestamp(),
          'status.$myUserId.readAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(ref, {
          'status.$myUserId.$updateKey': FieldValue.serverTimestamp(),
        });
      }
      hasWrites = true;
    }

    if (hasWrites) {
      try {
        await batch.commit();
      } catch (e) {
        LoggerUtils.logWarning('ChatFirebaseService: ack messages skipped — $e');
      }
    }
  }

  /// Writes a text message. Returns Firestore document id.
  Future<String> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
    String? clientMessageId,
    String? recipientId,
  }) async {
    if (roomId.isEmpty || senderId.isEmpty) {
      throw ArgumentError('roomId and senderId are required');
    }

    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firebase is not initialized on this platform');
    }

    // Non-blocking — typing rules may not be deployed yet.
    unawaited(setTyping(roomId: roomId, userId: senderId, isTyping: false));

    final docRef = firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final messageId = docRef.id;
    final dedupeId = clientMessageId ?? messageId;

    final initialStatus = <String, dynamic>{};
    if (recipientId != null && recipientId.isNotEmpty) {
      initialStatus[recipientId] = {
        'deliveredAt': null,
        'readAt': null,
      };
    }

    await docRef.set({
      'messageId': messageId,
      'roomId': roomId,
      'senderId': senderId,
      'type': 'text',
      'content': {'text': text},
      'deliveryState': 'sent',
      'status': initialStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'clientCreatedAt': FieldValue.serverTimestamp(),
      'clientMessageId': dedupeId,
    });

    await _touchInboxPreview(
      firestore: firestore,
      userId: senderId,
      roomId: roomId,
      preview: text,
      senderId: senderId,
    );

    return messageId;
  }

  Future<void> _touchInboxPreview({
    required FirebaseFirestore firestore,
    required String userId,
    required String roomId,
    required String preview,
    required String senderId,
  }) async {
    try {
      await firestore
          .collection('userChats')
          .doc(userId)
          .collection('rooms')
          .doc(roomId)
          .update({
        'lastMessagePreview': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageType': 'text',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: inbox preview update skipped — $e',
      );
    }
  }

  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
