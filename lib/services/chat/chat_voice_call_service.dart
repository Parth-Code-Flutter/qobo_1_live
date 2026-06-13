import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';

/// Firestore signaling for 1:1 voice/video calls inside a chat room.
///
/// Zego media runs on `callId`; this doc coordinates ring / accept / end.
enum ChatCallType { voice, video }

class ChatVoiceCallService {
  ChatVoiceCallService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  bool get isAvailable => FirebaseBootstrap.isAvailable;

  FirebaseFirestore? get _firestore {
    if (!isAvailable) return null;
    return _firestoreOverride ?? FirebaseFirestore.instance;
  }

  static const String _activeDocId = 'active';

  DocumentReference<Map<String, dynamic>>? _activeRef(String roomId) {
    final firestore = _firestore;
    if (roomId.isEmpty || firestore == null) return null;
    return firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('calls')
        .doc(_activeDocId);
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

  Future<String> startOutgoingCall({
    required String roomId,
    required String callerId,
    required String callerName,
    String? calleeId,
    ChatCallType callType = ChatCallType.voice,
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
      if (calleeId != null && calleeId.isNotEmpty) 'calleeId': calleeId,
      'type': callType == ChatCallType.video ? 'video' : 'voice',
      'status': 'ringing',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    LoggerUtils.logInfo(
      'ChatVoiceCallService: ringing chatRooms/$roomId/calls/active',
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
      LoggerUtils.logWarning('ChatVoiceCallService: markAccepted failed — $e');
    }
  }

  Future<void> endCall(String roomId) async {
    final ref = _activeRef(roomId);
    if (ref == null) return;
    try {
      await ref.delete();
    } catch (e) {
      LoggerUtils.logWarning('ChatVoiceCallService: endCall failed — $e');
    }
  }
}
