import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Realtime Firestore messaging for `chatRooms/{roomId}/messages`.
///
/// Safe when Firebase was not initialized (e.g. iOS without GoogleService-Info.plist).
class ChatFirebaseService {
  ChatFirebaseService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  /// Skip repeated ack attempts for missing or already-acked messages.
  static final Set<String> _ackedMessageKeys = <String>{};
  static final Set<String> _failedAckKeys = <String>{};

  bool get isAvailable => FirebaseBootstrap.isAvailable;

  FirebaseFirestore? get _firestore {
    if (!isAvailable) return null;
    return _firestoreOverride ?? FirebaseFirestore.instance;
  }

  /// Live message stream ordered oldest → newest (client-side sort so pending
  /// serverTimestamp writes are not excluded by orderBy).
  Stream<List<Map<String, dynamic>>> watchMessages(String roomId) {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => {
                  ...Map<String, dynamic>.from(doc.data()),
                  'id': doc.id,
                },
              )
              .toList();
          list.sort((a, b) {
            final ad = _messageSortTime(a);
            final bd = _messageSortTime(b);
            return ad.compareTo(bd);
          });
          return list;
        });
  }

  static DateTime _messageSortTime(Map<String, dynamic> raw) {
    return _toDateTime(raw['createdAt']) ??
        _toDateTime(raw['clientCreatedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
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
      if (!isTyping) {
        await ref.delete();
        return;
      }
      await ref.set({
        'userId': userId,
        'isTyping': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      LoggerUtils.logWarning('ChatFirebaseService: setTyping failed — $e');
    } catch (e) {
      LoggerUtils.logWarning('ChatFirebaseService: setTyping failed — $e');
    }
  }

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
      if (e.code == 'permission-denied') return;
      LoggerUtils.logWarning('ChatFirebaseService: setMyPresence failed — $e');
    } catch (e) {
      LoggerUtils.logWarning('ChatFirebaseService: setMyPresence failed — $e');
    }
  }

  Future<void> ackIncomingMessages({
    required String roomId,
    required String myUserId,
    required List<Map<String, dynamic>> rawMessages,
    required bool markRead,
  }) async {
    final firestore = _firestore;
    if (roomId.isEmpty || myUserId.isEmpty || firestore == null) return;

    final ackUserId =
        FirebaseAuth.instance.currentUser?.uid ?? myUserId;
    final pendingUpdates = <DocumentReference<Map<String, dynamic>>,
        Map<String, dynamic>>{};

    for (final raw in rawMessages) {
      final messageId =
          raw['id']?.toString() ?? raw['messageId']?.toString() ?? '';
      final senderId = raw['senderId']?.toString() ?? '';
      if (messageId.isEmpty ||
          senderId.isEmpty ||
          senderId == myUserId ||
          senderId == ackUserId) {
        continue;
      }

      final status = raw['status'];
      final statusMap = status is Map
          ? Map<String, dynamic>.from(status)
          : <String, dynamic>{};
      final mine = statusMap[ackUserId] ?? statusMap[myUserId];
      final mineMap =
          mine is Map ? Map<String, dynamic>.from(mine) : <String, dynamic>{};

      final hasDelivered = mineMap['deliveredAt'] != null;
      final hasRead = mineMap['readAt'] != null;
      if (hasRead || (markRead == false && hasDelivered)) continue;

      final ref = firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messageReceipts')
          .doc('$messageId-$ackUserId');

      if (markRead && !hasDelivered) {
        pendingUpdates[ref] = {
          'messageId': messageId,
          'userId': ackUserId,
          'deliveredAt': FieldValue.serverTimestamp(),
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
      } else {
        pendingUpdates[ref] = {
          'messageId': messageId,
          'userId': ackUserId,
          if (markRead) 'readAt': FieldValue.serverTimestamp(),
          if (!markRead) 'deliveredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }
    }

    if (pendingUpdates.isEmpty) return;

    for (final entry in pendingUpdates.entries) {
      final ref = entry.key;
      final messageId = ref.id;
      final key = '$roomId:$messageId';
      if (_ackedMessageKeys.contains(key) || _failedAckKeys.contains(key)) {
        continue;
      }

      try {
        await ref.set(entry.value, SetOptions(merge: true));
        _ackedMessageKeys.add(key);
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          _failedAckKeys.add(key);
        } else {
          LoggerUtils.logWarning(
            'ChatFirebaseService: ack $messageId skipped — ${e.code}',
          );
        }
      } catch (e) {
        LoggerUtils.logWarning(
          'ChatFirebaseService: ack $messageId skipped — $e',
        );
      }
    }
  }

  /// One-shot fetch when REST history is empty (bootstrap / iOS fallback).
  Future<List<Map<String, dynamic>>> fetchMessagesOnce(String roomId) async {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .get();
      final list = snapshot.docs
          .map(
            (doc) => {
              ...Map<String, dynamic>.from(doc.data()),
              'id': doc.id,
            },
          )
          .toList();
      list.sort((a, b) {
        final ad = _messageSortTime(a);
        final bd = _messageSortTime(b);
        return ad.compareTo(bd);
      });
      return list;
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: fetchMessagesOnce failed — $e',
      );
      return [];
    }
  }

  /// Inbox rows from Firestore when REST `/api/chat/list` is empty or stale.
  Future<List<Map<String, dynamic>>> fetchInboxRoomsForUser(
    String userId,
  ) async {
    final firestore = _firestore;
    if (userId.isEmpty || firestore == null) return [];

    try {
      final roomsSnap = await firestore
          .collection('chatRooms')
          .where('memberIds', arrayContains: userId)
          .get();

      final rows = <Map<String, dynamic>>[];
      for (final roomDoc in roomsSnap.docs) {
        final roomData = Map<String, dynamic>.from(roomDoc.data());
        if (roomData['isActive'] == false) continue;

        final memberIds = (roomData['memberIds'] as List?)
                ?.map((e) => e.toString())
                .where((id) => id.isNotEmpty)
                .toList() ??
            <String>[];
        final peerId =
            memberIds.firstWhere((id) => id != userId, orElse: () => '');
        if (peerId.isEmpty) continue;

        final messages = await fetchMessagesOnce(roomDoc.id);
        if (messages.isEmpty) continue;

        final latest = messages.last;
        final preview = _extractMessagePreview(latest);
        if (preview.isEmpty) continue;

        rows.add({
          'id': peerId,
          'roomId': roomDoc.id,
          'lastMessage': preview,
          'lastMessageTime': _formatFirestoreTime(
            latest['createdAt'] ?? latest['clientCreatedAt'],
          ),
          'lastMessageType': latest['type']?.toString() ?? 'text',
          'unreadCount': 0,
          'recipient': {'id': peerId},
        });
      }

      rows.sort((a, b) {
        final at = a['lastMessageTime']?.toString() ?? '';
        final bt = b['lastMessageTime']?.toString() ?? '';
        return bt.compareTo(at);
      });
      return rows;
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: fetchInboxRoomsForUser failed — $e',
      );
      return [];
    }
  }

  static String _extractMessagePreview(Map<String, dynamic> raw) {
    final content = raw['content'];
    if (content is Map) {
      final text = content['text'] ?? content['message'];
      if (text != null && text.toString().trim().isNotEmpty) {
        return text.toString();
      }
    }
    if (content is String && content.trim().isNotEmpty) return content;
    final type = raw['type']?.toString() ?? 'text';
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      default:
        return '';
    }
  }

  static String _formatFirestoreTime(dynamic raw) {
    final dt = _toDateTime(raw);
    if (dt == null) return DateTime.now().toUtc().toIso8601String();
    return dt.toUtc().toIso8601String();
  }

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

    // Rules check request.auth.uid == senderId — always use Firebase Auth uid.
    final authUid = FirebaseAuth.instance.currentUser?.uid ?? senderId;

    unawaited(
      setTyping(roomId: roomId, userId: authUid, isTyping: false),
    );

    final docRef = firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final messageId = docRef.id;
    final dedupeId = clientMessageId ?? messageId;
    final clientNow = FieldValue.serverTimestamp();

    final initialStatus = <String, dynamic>{};
    if (recipientId != null && recipientId.isNotEmpty) {
      initialStatus[recipientId] = <String, dynamic>{};
    }

    try {
      await docRef.set({
        'messageId': messageId,
        'roomId': roomId,
        'senderId': authUid,
        'type': 'text',
        'content': {'text': text},
        'deliveryState': 'sent',
        'status': initialStatus,
        'createdAt': clientNow,
        'clientCreatedAt': clientNow,
        'clientMessageId': dedupeId,
      });
      LoggerUtils.logInfo(
        'ChatFirebaseService: message written chatRooms/$roomId/messages/$messageId',
      );
    } on FirebaseException catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: message write failed — ${e.code}: ${e.message}',
      );
      rethrow;
    }

    unawaited(
      _touchInboxPreview(
        firestore: firestore,
        userId: authUid,
        roomId: roomId,
        preview: text,
        senderId: authUid,
        peerId: recipientId,
      ),
    );

    return messageId;
  }

  Future<void> _touchInboxPreview({
    required FirebaseFirestore firestore,
    required String userId,
    required String roomId,
    required String preview,
    required String senderId,
    String? peerId,
  }) async {
    try {
      await firestore
          .collection('userChats')
          .doc(userId)
          .collection('rooms')
          .doc(roomId)
          .set({
        'lastMessagePreview': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageType': 'text',
        'updatedAt': FieldValue.serverTimestamp(),
        'roomId': roomId,
        if (peerId != null && peerId.isNotEmpty) 'peerId': peerId,
      }, SetOptions(merge: true));
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
