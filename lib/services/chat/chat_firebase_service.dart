import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
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
      final payload = entry.value;
      final messageId = payload['messageId']?.toString() ?? '';
      if (messageId.isEmpty) continue;

      final key = '$roomId:$messageId';
      if (_ackedMessageKeys.contains(key) || _failedAckKeys.contains(key)) {
        continue;
      }

      try {
        await ref.set(payload, SetOptions(merge: true));
        _ackedMessageKeys.add(key);
      } on FirebaseException catch (e) {
        _failedAckKeys.add(key);
        LoggerUtils.logWarning(
          'ChatFirebaseService: receipt $messageId skipped — ${e.code}',
        );
      } catch (e) {
        LoggerUtils.logWarning(
          'ChatFirebaseService: receipt $messageId skipped — $e',
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
      final fromUserChats = await _fetchInboxFromUserChats(firestore, userId);
      if (fromUserChats.isNotEmpty) return fromUserChats;

      return _fetchInboxFromChatRooms(firestore, userId);
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: fetchInboxRoomsForUser failed — $e',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInboxFromUserChats(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    QuerySnapshot<Map<String, dynamic>> roomsSnap;
    try {
      roomsSnap = await firestore
          .collection('userChats')
          .doc(userId)
          .collection('rooms')
          .orderBy('lastMessageAt', descending: true)
          .get();
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: userChats orderBy failed — $e (fallback get)',
      );
      roomsSnap = await firestore
          .collection('userChats')
          .doc(userId)
          .collection('rooms')
          .get();
    }

    if (roomsSnap.docs.isEmpty) return [];

    final rows = <Map<String, dynamic>>[];
    for (final doc in roomsSnap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final peerId = data['peerId']?.toString() ?? '';
      if (peerId.isEmpty) continue;

      final roomId = data['roomId']?.toString() ?? doc.id;
      var type = data['lastMessageType']?.toString();
      var previewRaw = data['lastMessagePreview']?.toString() ?? '';
      var activityAt = _toDateTime(data['lastMessageAt']);
      var lastCallDirection = data['lastCallDirection']?.toString();

      final latestCall = await _fetchLatestCallHistory(firestore, roomId);
      if (latestCall != null) {
        final callAt = _toDateTime(latestCall['endedAt']);
        if (callAt != null &&
            (activityAt == null || callAt.isAfter(activityAt))) {
          final isVideo = latestCall['type']?.toString() == 'video';
          final outcome = latestCall['status']?.toString() ?? 'completed';
          final isCallee = latestCall['calleeId']?.toString() == userId;
          type = ChatInboxPreviewType.inboxTypeForUser(
            isVideo: isVideo,
            outcome: outcome,
            isCallee: isCallee,
          );
          previewRaw = ChatInboxPreviewType.displayLabel(type);
          activityAt = callAt;
          lastCallDirection = isCallee ? 'incoming' : 'outgoing';
        }
      }

      final preview = ChatInboxPreviewType.displayLabel(
        type,
        fallbackPreview: previewRaw,
      );
      if (preview.isEmpty &&
          !ChatInboxPreviewType.isCallType(type) &&
          type != ChatInboxPreviewType.text) {
        continue;
      }

      rows.add({
        'id': peerId,
        'roomId': roomId,
        'lastMessage': preview,
        'lastMessageTime': _formatFirestoreTime(activityAt),
        'lastMessageType': type ?? ChatInboxPreviewType.text,
        'lastCallType': data['lastCallType'] ?? latestCall?['type'],
        'lastCallStatus': data['lastCallStatus'] ?? latestCall?['status'],
        'lastCallDirection': lastCallDirection,
        'unreadCount': data['unreadCount'] ?? 0,
        'recipient': {
          'id': peerId,
          if (data['title']?.toString().trim().isNotEmpty == true)
            'name': data['title']?.toString().trim(),
          if (data['photoUrl']?.toString().trim().isNotEmpty == true)
            'displayPicture': data['photoUrl']?.toString().trim(),
        },
      });
    }

    rows.sort((a, b) {
      final at = a['lastMessageTime']?.toString() ?? '';
      final bt = b['lastMessageTime']?.toString() ?? '';
      return bt.compareTo(at);
    });
    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchInboxFromChatRooms(
    FirebaseFirestore firestore,
    String userId,
  ) async {
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
      final latestCall = await _fetchLatestCallHistory(firestore, roomDoc.id);

      Map<String, dynamic>? latestMessage;
      if (messages.isNotEmpty) {
        latestMessage = messages.last;
      }

      final messageAt = latestMessage != null
          ? _toDateTime(
              latestMessage['createdAt'] ?? latestMessage['clientCreatedAt'],
            )
          : null;
      final callAt = _toDateTime(latestCall?['endedAt']);

      final useCall = callAt != null &&
          (messageAt == null || callAt.isAfter(messageAt));

      if (useCall && latestCall != null) {
        final isVideo = latestCall['type']?.toString() == 'video';
        final outcome = latestCall['status']?.toString() ?? 'completed';
        final isCallee = latestCall['calleeId']?.toString() == userId;
        final inboxType = ChatInboxPreviewType.inboxTypeForUser(
          isVideo: isVideo,
          outcome: outcome,
          isCallee: isCallee,
        );
        rows.add({
          'id': peerId,
          'roomId': roomDoc.id,
          'lastMessage': ChatInboxPreviewType.displayLabel(inboxType),
          'lastMessageTime': _formatFirestoreTime(latestCall['endedAt']),
          'lastMessageType': inboxType,
          'lastCallType': isVideo ? 'video' : 'voice',
          'lastCallStatus': outcome,
          'lastCallDirection': isCallee ? 'incoming' : 'outgoing',
          'unreadCount': 0,
          'recipient': {'id': peerId},
        });
        continue;
      }

      if (latestMessage == null) continue;

      final preview = _extractMessagePreview(latestMessage);
      if (preview.isEmpty) continue;

      rows.add({
        'id': peerId,
        'roomId': roomDoc.id,
        'lastMessage': preview,
        'lastMessageTime': _formatFirestoreTime(
          latestMessage['createdAt'] ?? latestMessage['clientCreatedAt'],
        ),
        'lastMessageType': latestMessage['type']?.toString() ?? 'text',
        'lastCallType': null,
        'lastCallStatus': null,
        'lastCallDirection': null,
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
  }

  Future<Map<String, dynamic>?> _fetchLatestCallHistory(
    FirebaseFirestore firestore,
    String roomId,
  ) async {
    final list = await _fetchCallHistoryDocs(firestore, roomId);
    if (list.isEmpty) return null;
    return list.last;
  }

  /// All call log rows for a room, oldest → newest.
  Future<List<Map<String, dynamic>>> fetchCallHistoryOnce(String roomId) async {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) return [];
    return _fetchCallHistoryDocs(firestore, roomId);
  }

  Stream<List<Map<String, dynamic>>> watchCallHistory(String roomId) {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('callHistory')
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
          return _sortCallHistoryAsc(list);
        });
  }

  Future<List<Map<String, dynamic>>> _fetchCallHistoryDocs(
    FirebaseFirestore firestore,
    String roomId,
  ) async {
    try {
      final snap = await firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('callHistory')
          .orderBy('endedAt', descending: false)
          .get();
      return snap.docs
          .map(
            (doc) => {
              ...Map<String, dynamic>.from(doc.data()),
              'id': doc.id,
            },
          )
          .toList();
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: callHistory fetch failed — $e (fallback)',
      );
      try {
        final snap = await firestore
            .collection('chatRooms')
            .doc(roomId)
            .collection('callHistory')
            .get();
        return _sortCallHistoryAsc(
          snap.docs
              .map(
                (doc) => {
                  ...Map<String, dynamic>.from(doc.data()),
                  'id': doc.id,
                },
              )
              .toList(),
        );
      } catch (_) {
        return [];
      }
    }
  }

  static List<Map<String, dynamic>> _sortCallHistoryAsc(
    List<Map<String, dynamic>> list,
  ) {
    final sorted = List<Map<String, dynamic>>.from(list)
      ..sort((a, b) {
        final ad = _callHistorySortTime(a);
        final bd = _callHistorySortTime(b);
        if (ad == null && bd == null) return 0;
        if (ad == null) return -1;
        if (bd == null) return 1;
        return ad.compareTo(bd);
      });
    return sorted;
  }

  static DateTime? _callHistorySortTime(Map<String, dynamic> raw) {
    return _toDateTime(raw['endedAt']) ?? _toDateTime(raw['clientEndedAt']);
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
      case 'voice_call':
        return 'Voice call';
      case 'video_call':
        return 'Video call';
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

  /// WhatsApp-style call row in `messages` (same collection as text).
  Future<String?> recordCallLogMessage({
    required String roomId,
    required String senderId,
    required String callerId,
    required String calleeId,
    required bool isVideo,
    required String outcome,
    int? durationSeconds,
    String? historyDocId,
    String? zegoCallId,
    String? callStartedAt,
  }) async {
    if (roomId.isEmpty || senderId.isEmpty || callerId.isEmpty) {
      return null;
    }

    final firestore = _firestore;
    if (firestore == null) return null;

    final authUid = FirebaseAuth.instance.currentUser?.uid ?? senderId;
    final docId = historyDocId?.trim().isNotEmpty == true
        ? historyDocId!.trim()
        : firestore
            .collection('chatRooms')
            .doc(roomId)
            .collection('messages')
            .doc()
            .id;

    final ref = firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(docId);

    try {
      final existing = await ref.get();
      if (existing.exists) {
        LoggerUtils.logInfo(
          'ChatFirebaseService: call message $docId already exists — skip',
        );
        return docId;
      }

      final durationMinutes =
          ChatInboxPreviewType.durationMinutesFromSeconds(durationSeconds);
      final messageType = isVideo ? 'video_call' : 'voice_call';
      final initialStatus = <String, dynamic>{};
      if (calleeId.isNotEmpty) {
        initialStatus[calleeId] = <String, dynamic>{};
      }
      if (callerId.isNotEmpty && callerId != calleeId) {
        initialStatus[callerId] = <String, dynamic>{};
      }

      await ref.set({
        'messageId': docId,
        'roomId': roomId,
        'senderId': authUid,
        'type': messageType,
        'content': {
          'callId': docId,
          'callerId': callerId,
          'calleeId': calleeId,
          'status': outcome,
          if (zegoCallId != null && zegoCallId.isNotEmpty) 'zegoCallId': zegoCallId,
          if (callStartedAt != null && callStartedAt.isNotEmpty)
            'callStartedAt': callStartedAt,
          if (durationSeconds != null && durationSeconds > 0)
            'durationSeconds': durationSeconds,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
        },
        'deliveryState': 'sent',
        'status': initialStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'clientCreatedAt': FieldValue.serverTimestamp(),
        'clientMessageId': docId,
      });
      LoggerUtils.logInfo(
        'ChatFirebaseService: call log message chatRooms/$roomId/messages/$docId',
      );
      return docId;
    } on FirebaseException catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: call log message failed — ${e.code}: ${e.message}',
      );
      return null;
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatFirebaseService: call log message failed — $e',
      );
      return null;
    }
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
        'lastMessageType': ChatInboxPreviewType.text,
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
