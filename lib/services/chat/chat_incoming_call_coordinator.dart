import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_voice_call/controllers/chat_voice_call_controller.dart';
import 'package:qobo_one_live/repo/call/call_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/incoming_call_ring_ui.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';

/// Listens for Firestore `calls/active` and shows incoming call UI.
class ChatIncomingCallCoordinator extends GetxService {
  ChatIncomingCallCoordinator({
    ChatCallService? callService,
    CallRepo? callRepo,
  })  : _callService = callService ?? ChatCallService(),
        _callRepo = callRepo ?? CallRepo();

  final ChatCallService _callService;
  final CallRepo _callRepo;

  final Map<String, StreamSubscription<Map<String, dynamic>>> _subscriptions =
      {};
  final Set<String> _watchedRooms = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _userChatsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userRingSub;
  bool _dialogOpen = false;
  bool _onCallScreen = false;
  bool _bootstrapStarted = false;
  String? _lastHandledRingKey;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  void setOnCallScreen(bool value) => _onCallScreen = value;

  Future<void> _bootstrap() async {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;

    await syncWatchedRoomsFromFirestore();
    await _startLiveListeners();
  }

  void syncWatchedRooms(Iterable<String> roomIds, {bool replace = false}) {
    if (!_callService.isAvailable) return;

    final normalized = roomIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (replace) {
      _watchedRooms
        ..clear()
        ..addAll(normalized);
    } else {
      _watchedRooms.addAll(normalized);
    }
    _applyWatchers();
  }

  /// Merges Firestore inbox/chat rooms so discover calls can ring peers.
  Future<void> syncWatchedRoomsFromFirestore() async {
    if (!_callService.isAvailable) return;

    final myId = _myUserId;
    if (myId.isEmpty) return;

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn =
        await Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
    if (!signedIn) return;

    final rows = await ChatFirebaseService().fetchInboxRoomsForUser(myId);
    final roomIds = rows
        .map((row) => row['roomId']?.toString() ?? '')
        .where((id) => id.isNotEmpty);
    syncWatchedRooms(roomIds, replace: false);
  }

  Future<void> _startLiveListeners() async {
    if (!FirebaseBootstrap.isAvailable) return;

    final myId = _myUserId;
    if (myId.isEmpty) return;

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn =
        await Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
    if (!signedIn) return;

    await _userChatsSub?.cancel();
    _userChatsSub = FirebaseFirestore.instance
        .collection('userChats')
        .doc(myId)
        .collection('rooms')
        .snapshots()
        .listen(
          (snapshot) {
            final roomIds = snapshot.docs
                .map((doc) => doc.data()['roomId']?.toString() ?? doc.id)
                .where((id) => id.isNotEmpty);
            syncWatchedRooms(roomIds, replace: false);
          },
          onError: (_) {},
        );

    await _userRingSub?.cancel();
    _userRingSub = FirebaseFirestore.instance
        .collection('userIncomingCalls')
        .doc(myId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              _lastHandledRingKey = null;
              return;
            }
            final data = Map<String, dynamic>.from(snapshot.data() ?? {});
            final roomId = data['roomId']?.toString() ?? '';
            if (roomId.isEmpty) return;
            _onActiveCallSnapshot(roomId: roomId, data: data);
          },
          onError: (_) {},
        );
  }

  void _applyWatchers() {
    final stale = _subscriptions.keys
        .where((roomId) => !_watchedRooms.contains(roomId))
        .toList();
    for (final roomId in stale) {
      unawaited(_subscriptions.remove(roomId)?.cancel());
    }

    for (final roomId in _watchedRooms) {
      if (_subscriptions.containsKey(roomId)) continue;
      _subscriptions[roomId] = _callService
          .watchActiveCall(roomId)
          .listen(
            (data) => _onActiveCallSnapshot(roomId: roomId, data: data),
            onError: (_) {},
          );
    }
  }

  void _onActiveCallSnapshot({
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    if (data.isEmpty || _onCallScreen || _dialogOpen) return;

    final myId = _myUserId;
    if (myId.isEmpty) return;

    final status = data['status']?.toString() ?? '';
    final callerId = data['callerId']?.toString() ?? '';
    if (status != 'ringing' || callerId.isEmpty || callerId == myId) return;

    final calleeId = data['calleeId']?.toString() ?? '';
    if (calleeId.isNotEmpty && calleeId != myId) return;

    final callId =
        data['callId']?.toString() ?? ZegoCallIdUtils.fromRoomId(roomId);
    final ringKey = '$roomId:$callId:ringing';
    if (_lastHandledRingKey == ringKey) return;
    _lastHandledRingKey = ringKey;

    _dialogOpen = true;
    final callerName = data['callerName']?.toString() ?? 'Someone';
    final historyDocId = data['historyDocId']?.toString() ?? '';
    final callStartedAt = data['callStartedAt']?.toString() ?? '';
    final recordCallHistory = data['recordCallHistory'] != false;
    final isVideo = data['type']?.toString() == 'video';

    unawaited(
      IncomingCallRingUi.show(
        callerName: callerName,
        subtitle: isVideo
            ? '$callerName is video calling you'
            : '$callerName is calling you',
        isVideo: isVideo,
        onDecline: () async {
          _dialogOpen = false;
          _lastHandledRingKey = null;
          await _callRepo.respondDirectCall(
            callId: callId,
            roomId: roomId,
            action: 'reject',
            isShowLoader: false,
          );
          await _callService.endCall(
            roomId,
            endedByUserId: myId,
          );
          ChatVoiceCallController.refreshMessagesInbox();
        },
        onAccept: () async {
          _dialogOpen = false;
          _lastHandledRingKey = null;
          await _acceptCall(
            roomId: roomId,
            callId: callId,
            historyDocId: historyDocId,
            callStartedAt: callStartedAt,
            callerId: callerId,
            callerName: callerName,
            isVideo: isVideo,
            recordCallHistory: recordCallHistory,
          );
        },
      ).whenComplete(() {
        _dialogOpen = false;
        _lastHandledRingKey = null;
      }),
    );
  }

  Future<void> _acceptCall({
    required String roomId,
    required String callId,
    required String historyDocId,
    required String callStartedAt,
    required String callerId,
    required String callerName,
    required bool isVideo,
    bool recordCallHistory = true,
  }) async {
    final myId = _myUserId;
    if (myId.isEmpty) return;

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn =
        await Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
    if (!signedIn) return;

    await _callRepo.respondDirectCall(
      callId: callId,
      roomId: roomId,
      action: 'accept',
      isShowLoader: false,
    );
    await _callService.markAccepted(roomId: roomId, userId: myId);
    await ZegoEngineUtils.resetForCallProject();
    _onCallScreen = true;

    await Get.toNamed(
      Routes.CHAT_VOICE_CALL,
      arguments: {
        'roomId': roomId,
        'callId': callId,
        if (historyDocId.isNotEmpty) 'historyDocId': historyDocId,
        if (callStartedAt.isNotEmpty) 'callStartedAt': callStartedAt,
        'hostId': callerId,
        'peerName': callerName,
        'isCaller': false,
        'isVideo': isVideo,
        'recordCallHistory': recordCallHistory,
      },
    );
    _onCallScreen = false;
  }

  String get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId;
  }

  @override
  void onClose() {
    unawaited(_userChatsSub?.cancel());
    unawaited(_userRingSub?.cancel());
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    super.onClose();
  }
}
