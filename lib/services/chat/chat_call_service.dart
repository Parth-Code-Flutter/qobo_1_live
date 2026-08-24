import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';

/// Zego channel id + stable Firestore history / message document id.
class ChatOutgoingCallIds {
  const ChatOutgoingCallIds({
    required this.zegoCallId,
    required this.historyDocId,
    this.callStartedAt,
  });

  final String zegoCallId;
  final String historyDocId;
  final String? callStartedAt;
}

/// 1:1 chat call type for Firestore signaling + Zego UI config.
enum ChatCallType { voice, video }

/// How an active call ended for inbox / call history.
enum ChatCallOutcome { completed, missed, cancelled }

/// Firestore ring / accept / end at `chatRooms/{roomId}/calls/active`.
///
/// Zego RTC uses [ZegoCallIdUtils.fromRoomId] — both peers must join the same
/// `callID`.
class ChatCallService {
  ChatCallService({
    FirebaseFirestore? firestore,
    ChatFirebaseService? firebaseService,
  }) : _firestoreOverride = firestore,
       _firebaseService = firebaseService ?? ChatFirebaseService();

  final FirebaseFirestore? _firestoreOverride;
  final ChatFirebaseService _firebaseService;

  bool get isAvailable => FirebaseBootstrap.isAvailable;

  FirebaseFirestore? get _firestore {
    if (!isAvailable) return null;
    return _firestoreOverride ?? FirebaseFirestore.instance;
  }

  static const String activeDocId = 'active';

  DocumentReference<Map<String, dynamic>>? _activeRef(String roomId) {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) return null;
    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('calls')
        .doc(activeDocId);
  }

  /// One-shot read of `calls/active` (used by caller ring poll).
  Future<Map<String, dynamic>> fetchActiveCall(String roomId) async {
    final ref = _activeRef(roomId);
    if (ref == null) return <String, dynamic>{};
    try {
      final snap = await ref.get();
      if (!snap.exists) return <String, dynamic>{};
      return {...Map<String, dynamic>.from(snap.data() ?? {}), 'id': snap.id};
    } catch (e) {
      LoggerUtils.logWarning('ChatCallService: fetchActiveCall failed — $e');
      return <String, dynamic>{};
    }
  }

  DocumentReference<Map<String, dynamic>>? _userIncomingCallRef(String userId) {
    final firestore = _firestore;
    if (userId.isEmpty || firestore == null) return null;
    return firestore.collection('userIncomingCalls').doc(userId);
  }

  Future<void> _clearUserIncomingCall({
    required String calleeId,
    String? roomId,
  }) async {
    final ref = _userIncomingCallRef(calleeId);
    if (ref == null) return;

    try {
      if (roomId != null && roomId.isNotEmpty) {
        final snap = await ref.get();
        if (!snap.exists) return;
        final activeRoom = snap.data()?['roomId']?.toString() ?? '';
        if (activeRoom.isNotEmpty && activeRoom != roomId) return;
      }
      await ref.delete();
    } catch (e) {
      LoggerUtils.logWarning(
        'ChatCallService: clear userIncomingCalls/$calleeId failed — $e',
      );
    }
  }

  Stream<Map<String, dynamic>> watchActiveCall(String roomId) {
    final ref = _activeRef(roomId);
    if (ref == null) return const Stream.empty();

    return ref.snapshots().map((snapshot) {
      if (!snapshot.exists) return <String, dynamic>{};
      return {
        ...Map<String, dynamic>.from(snapshot.data() ?? {}),
        'id': snapshot.id,
      };
    });
  }

  /// Writes ringing state; returns Zego `callID` + shared history/message doc id.
  Future<ChatOutgoingCallIds> ringOutgoingCall({
    required String roomId,
    required String callerId,
    required String callerName,
    required String calleeId,
    required ChatCallType callType,
    String? callIdOverride,
    bool recordCallHistory = true,
  }) async {
    final ref = _activeRef(roomId);
    if (ref == null) {
      throw StateError('Firebase is not available');
    }

    // Prefer backend callId from /api/call/start. Both peers then use the
    // same id for backend respond/end and Zego room login.
    final callId = callIdOverride?.trim().isNotEmpty == true
        ? callIdOverride!.trim()
        : ZegoCallIdUtils.fromRoomId(roomId);
    final historyDocId = 'call_${DateTime.now().microsecondsSinceEpoch}';
    final callStartedAt = DateTime.now().toUtc().toIso8601String();
    await ref.set({
      'callId': callId,
      if (recordCallHistory) 'historyDocId': historyDocId,
      'callStartedAt': callStartedAt,
      'roomId': roomId,
      'callerId': callerId,
      'callerName': callerName,
      'calleeId': calleeId,
      'type': callType == ChatCallType.video ? 'video' : 'voice',
      'status': 'ringing',
      'recordCallHistory': recordCallHistory,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userRingRef = _userIncomingCallRef(calleeId);
    if (userRingRef != null) {
      try {
        await userRingRef.set({
          'callId': callId,
          if (recordCallHistory) 'historyDocId': historyDocId,
          'callStartedAt': callStartedAt,
          'roomId': roomId,
          'callerId': callerId,
          'callerName': callerName,
          'calleeId': calleeId,
          'type': callType == ChatCallType.video ? 'video' : 'voice',
          'status': 'ringing',
          'recordCallHistory': recordCallHistory,
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        LoggerUtils.logWarning(
          'ChatCallService: userIncomingCalls/$calleeId write failed — $e',
        );
      }
    }
    LoggerUtils.logInfo(
      'ChatCallService: ring chatRooms/$roomId/calls/$activeDocId '
      'type=${callType.name} callId=$callId history=$historyDocId',
    );
    return ChatOutgoingCallIds(
      zegoCallId: callId,
      historyDocId: recordCallHistory ? historyDocId : '',
      callStartedAt: callStartedAt,
    );
  }

  /// Removes ephemeral `calls/active` only — no call history or chat log writes.
  Future<void> clearActiveCall(String roomId, {String? endedByUserId}) async {
    final ref = _activeRef(roomId);
    if (ref == null) return;

    try {
      final snap = await ref.get();
      final calleeId = snap.data()?['calleeId']?.toString() ?? '';
      await ref.delete();
      if (calleeId.isNotEmpty) {
        await _clearUserIncomingCall(calleeId: calleeId, roomId: roomId);
      }
      LoggerUtils.logInfo(
        'ChatCallService: cleared active call for $roomId '
        '(endedBy=${endedByUserId ?? 'unknown'})',
      );
    } catch (e) {
      LoggerUtils.logWarning('ChatCallService: clearActiveCall failed — $e');
    }
  }

  Future<void> markAccepted({
    required String roomId,
    required String userId,
  }) async {
    final ref = _activeRef(roomId);
    if (ref == null) return;
    try {
      await ref.set({
        'status': 'accepted',
        'acceptedBy': userId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _clearUserIncomingCall(calleeId: userId, roomId: roomId);
    } catch (e) {
      LoggerUtils.logWarning('ChatCallService: markAccepted failed — $e');
    }
  }

  /// Clears active call doc and writes call history + inbox preview when possible.
  ///
  /// Returns `true` when history was recorded. When the active doc is already
  /// gone (peer hung up first), use [recordCallSession] with cached session data.
  Future<bool> endCall(
    String roomId, {
    String? endedByUserId,
    ChatCallOutcome? outcomeOverride,
    int? durationSeconds,
    String? historyDocId,
    String? callStartedAt,
  }) async {
    final ref = _activeRef(roomId);
    if (ref == null) return false;

    Map<String, dynamic>? active;
    try {
      final snap = await ref.get();
      if (snap.exists) {
        active = Map<String, dynamic>.from(snap.data() ?? {});
      }
      await ref.delete();
      final calleeId = active?['calleeId']?.toString() ?? '';
      if (calleeId.isNotEmpty) {
        await _clearUserIncomingCall(calleeId: calleeId, roomId: roomId);
      }
    } catch (e) {
      LoggerUtils.logWarning('ChatCallService: endCall failed — $e');
      return false;
    }

    if (active == null || active.isEmpty) {
      LoggerUtils.logInfo(
        'ChatCallService: no active call doc for $roomId (already cleared)',
      );
      return false;
    }

    final recordCallHistory = active['recordCallHistory'] != false;
    if (!recordCallHistory) {
      LoggerUtils.logInfo(
        'ChatCallService: skipped call history for $roomId (direct call)',
      );
      return false;
    }

    await _persistCall(
      roomId: roomId,
      callerId: active['callerId']?.toString() ?? '',
      calleeId: active['calleeId']?.toString() ?? '',
      isVideo: active['type']?.toString() == 'video',
      status: active['status']?.toString() ?? 'ringing',
      endedByUserId: endedByUserId,
      outcomeOverride: outcomeOverride,
      durationSeconds: durationSeconds,
      zegoCallId: active['callId']?.toString(),
      historyDocId: historyDocId ?? active['historyDocId']?.toString(),
      callStartedAt: callStartedAt ?? active['callStartedAt']?.toString(),
    );
    return true;
  }

  /// Records call history when the active Firestore doc is no longer available.
  Future<void> recordCallSession({
    required String roomId,
    required String callerId,
    required String calleeId,
    required bool isVideo,
    required String endedByUserId,
    ChatCallOutcome? outcomeOverride,
    int? durationSeconds,
    bool wasAccepted = false,
    String? zegoCallId,
    String? historyDocId,
    String? callStartedAt,
  }) async {
    if (roomId.isEmpty || callerId.isEmpty || calleeId.isEmpty) return;

    await _persistCall(
      roomId: roomId,
      callerId: callerId,
      calleeId: calleeId,
      isVideo: isVideo,
      status: wasAccepted ? 'accepted' : 'ringing',
      endedByUserId: endedByUserId,
      outcomeOverride: outcomeOverride,
      durationSeconds: durationSeconds,
      zegoCallId: zegoCallId,
      historyDocId: historyDocId,
      callStartedAt: callStartedAt,
    );
  }

  Future<void> _persistCall({
    required String roomId,
    required String callerId,
    required String calleeId,
    required bool isVideo,
    required String status,
    required String? endedByUserId,
    ChatCallOutcome? outcomeOverride,
    int? durationSeconds,
    String? zegoCallId,
    String? historyDocId,
    String? callStartedAt,
  }) async {
    if (callerId.isEmpty || calleeId.isEmpty) return;

    final outcome =
        outcomeOverride ??
        _resolveOutcome(
          status: status,
          endedByUserId: endedByUserId,
          callerId: callerId,
          calleeId: calleeId,
          durationSeconds: durationSeconds,
        );

    final resolvedHistoryId = historyDocId?.trim().isNotEmpty == true
        ? historyDocId!.trim()
        : null;

    await _recordCallHistory(
      roomId: roomId,
      callerId: callerId,
      calleeId: calleeId,
      isVideo: isVideo,
      outcome: outcome,
      durationSeconds: durationSeconds,
      zegoCallId: zegoCallId,
      historyDocId: resolvedHistoryId,
      callStartedAt: callStartedAt,
    );

    final recorderId = endedByUserId?.trim().isNotEmpty == true
        ? endedByUserId!.trim()
        : callerId;

    await _firebaseService.recordCallLogMessage(
      roomId: roomId,
      senderId: recorderId,
      callerId: callerId,
      calleeId: calleeId,
      isVideo: isVideo,
      outcome: outcome.name,
      durationSeconds: durationSeconds,
      historyDocId: resolvedHistoryId,
      zegoCallId: zegoCallId,
      callStartedAt: callStartedAt,
    );

    await _updateInboxForCall(
      roomId: roomId,
      callerId: callerId,
      calleeId: calleeId,
      isVideo: isVideo,
      outcome: outcome,
      durationSeconds: durationSeconds,
    );

    LoggerUtils.logInfo(
      'ChatCallService: recorded ${outcome.name} ${isVideo ? 'video' : 'voice'} '
      'call for room $roomId',
    );
  }

  static ChatCallOutcome _resolveOutcome({
    required String status,
    required String? endedByUserId,
    required String callerId,
    required String calleeId,
    int? durationSeconds,
  }) {
    if (status == 'accepted') {
      return ChatCallOutcome.completed;
    }

    final endedBy = endedByUserId?.trim() ?? '';
    if (endedBy == calleeId) {
      return ChatCallOutcome.missed;
    }
    if (endedBy.isEmpty || endedBy == callerId) {
      return ChatCallOutcome.cancelled;
    }
    return ChatCallOutcome.missed;
  }

  Future<bool> _recordCallHistory({
    required String roomId,
    required String callerId,
    required String calleeId,
    required bool isVideo,
    required ChatCallOutcome outcome,
    int? durationSeconds,
    String? zegoCallId,
    String? historyDocId,
    String? callStartedAt,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final docId = historyDocId?.trim().isNotEmpty == true
          ? historyDocId!.trim()
          : firestore.collection('chatRooms').doc().id;
      final durationMinutes = ChatInboxPreviewType.durationMinutesFromSeconds(
        durationSeconds,
      );

      final ref = firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('callHistory')
          .doc(docId);

      await ref.set({
        'callId': docId,
        'roomId': roomId,
        'callerId': callerId,
        'calleeId': calleeId,
        'type': isVideo ? 'video' : 'voice',
        'status': outcome.name,
        if (zegoCallId != null && zegoCallId.isNotEmpty)
          'zegoCallId': zegoCallId,
        if (callStartedAt != null && callStartedAt.isNotEmpty)
          'callStartedAt': callStartedAt,
        'clientEndedAt': DateTime.now().toUtc().toIso8601String(),
        if (durationSeconds != null &&
            durationSeconds > 0 &&
            outcome == ChatCallOutcome.completed)
          'durationSeconds': durationSeconds,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'endedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      LoggerUtils.logWarning('ChatCallService: callHistory write failed — $e');
      return false;
    }
  }

  Future<void> _updateInboxForCall({
    required String roomId,
    required String callerId,
    required String calleeId,
    required bool isVideo,
    required ChatCallOutcome outcome,
    int? durationSeconds,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    final outcomeName = outcome.name;
    final now = FieldValue.serverTimestamp();

    Future<void> touchUser({
      required String userId,
      required String peerId,
      required bool isCallee,
      required String direction,
    }) async {
      final inboxType = ChatInboxPreviewType.inboxTypeForUser(
        isVideo: isVideo,
        outcome: outcomeName,
        isCallee: isCallee,
      );
      final preview = ChatInboxPreviewType.displayLabel(inboxType);

      try {
        await firestore
            .collection('userChats')
            .doc(userId)
            .collection('rooms')
            .doc(roomId)
            .set({
              'roomId': roomId,
              'peerId': peerId,
              'lastMessagePreview': preview,
              'lastMessageAt': now,
              'lastMessageType': inboxType,
              'lastCallType': isVideo ? 'video' : 'voice',
              'lastCallStatus': outcomeName,
              'lastCallDirection': direction,
              'lastCallAt': now,
              if (durationSeconds != null && durationSeconds > 0)
                'lastCallDurationSeconds': durationSeconds,
              'updatedAt': now,
            }, SetOptions(merge: true));
      } catch (e) {
        LoggerUtils.logWarning(
          'ChatCallService: inbox call preview skipped for $userId — $e',
        );
      }
    }

    await Future.wait([
      touchUser(
        userId: callerId,
        peerId: calleeId,
        isCallee: false,
        direction: 'outgoing',
      ),
      touchUser(
        userId: calleeId,
        peerId: callerId,
        isCallee: true,
        direction: 'incoming',
      ),
    ]);
  }
}
