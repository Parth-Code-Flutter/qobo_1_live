import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';

/// 1:1 chat call type for Firestore signaling + Zego UI config.
enum ChatCallType { voice, video }

/// How an active call ended for inbox / call history.
enum ChatCallOutcome { completed, missed, cancelled }

/// Firestore ring / accept / end at `chatRooms/{roomId}/calls/active`.
///
/// Zego RTC uses [ZegoCallIdUtils.fromRoomId] — both peers must join the same
/// `callID`.
class ChatCallService {
  ChatCallService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

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

  /// Writes ringing state; returns Zego `callID`.
  Future<String> ringOutgoingCall({
    required String roomId,
    required String callerId,
    required String callerName,
    required String calleeId,
    required ChatCallType callType,
  }) async {
    final ref = _activeRef(roomId);
    if (ref == null) {
      throw StateError('Firebase is not available');
    }

    final callId = ZegoCallIdUtils.fromRoomId(roomId);
    await ref.set({
      'callId': callId,
      'roomId': roomId,
      'callerId': callerId,
      'callerName': callerName,
      'calleeId': calleeId,
      'type': callType == ChatCallType.video ? 'video' : 'voice',
      'status': 'ringing',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    LoggerUtils.logInfo(
      'ChatCallService: ring chatRooms/$roomId/calls/$activeDocId '
      'type=${callType.name} callId=$callId',
    );
    return callId;
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

    await _persistCall(
      roomId: roomId,
      callerId: active['callerId']?.toString() ?? '',
      calleeId: active['calleeId']?.toString() ?? '',
      isVideo: active['type']?.toString() == 'video',
      status: active['status']?.toString() ?? 'ringing',
      endedByUserId: endedByUserId,
      outcomeOverride: outcomeOverride,
      durationSeconds: durationSeconds,
      callId: active['callId']?.toString(),
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
    String? callId,
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
      callId: callId,
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
    String? callId,
  }) async {
    if (callerId.isEmpty || calleeId.isEmpty) return;

    final outcome = outcomeOverride ??
        _resolveOutcome(
          status: status,
          endedByUserId: endedByUserId,
          callerId: callerId,
          calleeId: calleeId,
          durationSeconds: durationSeconds,
        );

    await _recordCallHistory(
      roomId: roomId,
      callerId: callerId,
      calleeId: calleeId,
      isVideo: isVideo,
      outcome: outcome,
      durationSeconds: durationSeconds,
      callId: callId,
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
    String? callId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final docId =
          callId?.trim().isNotEmpty == true
              ? callId!.trim()
              : firestore.collection('chatRooms').doc().id;

      final ref = firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('callHistory')
          .doc(docId);

      final existing = await ref.get();
      if (existing.exists) {
        LoggerUtils.logInfo(
          'ChatCallService: callHistory/$docId already exists — skip duplicate',
        );
        return true;
      }

      await ref.set({
        'callId': docId,
        'roomId': roomId,
        'callerId': callerId,
        'calleeId': calleeId,
        'type': isVideo ? 'video' : 'voice',
        'status': outcome.name,
        'clientEndedAt': DateTime.now().toUtc().toIso8601String(),
        if (durationSeconds != null &&
            durationSeconds > 0 &&
            outcome == ChatCallOutcome.completed)
          'durationSeconds': durationSeconds,
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
