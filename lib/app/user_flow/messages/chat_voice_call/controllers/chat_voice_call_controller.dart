import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_detail/controllers/chat_detail_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
import 'package:qobo_one_live/repo/calling/calling_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

class ChatVoiceCallController extends GetxController {
  ChatVoiceCallController({
    ChatCallService? callService,
    CallingRepo? callingRepo,
    ChatLocalStore? localStore,
  }) : _callService = callService ?? ChatCallService(),
       _callingRepo = callingRepo ?? CallingRepo(),
       _localStore = localStore ?? ChatLocalStore();

  final ChatCallService _callService;
  final CallingRepo _callingRepo;
  final ChatLocalStore _localStore;

  final callId = ''.obs;
  final roomId = ''.obs;
  final hostId = ''.obs;
  final peerName = 'User'.obs;
  final isCaller = true.obs;
  final isVideo = false.obs;

  DateTime? _startedAt;
  bool _charged = false;
  bool _callRecorded = false;
  bool _peerJoined = false;

  String get zegoUserId {
    if (!Get.isRegistered<UserSessionController>()) {
      return ZegoLiveIdUtils.sanitizeUserId('guest');
    }
    return ZegoLiveIdUtils.sanitizeUserId(
      Get.find<UserSessionController>().userId,
    );
  }

  String get zegoUserName {
    if (!Get.isRegistered<UserSessionController>()) return 'User';
    final name = Get.find<UserSessionController>().displayName;
    return name.isNotEmpty ? name : 'User';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      roomId.value = args['roomId']?.toString() ?? '';
      hostId.value = args['hostId']?.toString() ?? '';
      peerName.value = args['peerName']?.toString() ?? 'User';
      isCaller.value = args['isCaller'] != false;
      isVideo.value = args['isVideo'] == true;
      final passedCallId = args['callId']?.toString() ?? '';
      callId.value = passedCallId.isNotEmpty
          ? passedCallId
          : ZegoCallIdUtils.fromRoomId(roomId.value);
    }
    _startedAt = DateTime.now();
    LoggerUtils.logInfo(
      'ChatVoiceCallController: Zego join callId=${callId.value} '
      'room=${roomId.value} video=${isVideo.value}',
    );
  }

  void onPeerJoined() => _peerJoined = true;

  void onZegoError(Object error) {
    LoggerUtils.logWarning('ChatVoiceCallController: $error');
  }

  /// Records call + returns summary for chat thread (WhatsApp-style log row).
  Future<Map<String, dynamic>?> finishCall({bool refreshInbox = true}) async {
    final summary = await _recordCallIfNeeded();
    await _chargeCallIfNeeded();
    if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
      Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(false);
    }
    if (summary != null && Get.isRegistered<ChatDetailController>()) {
      Get.find<ChatDetailController>().ingestCallSummary(summary);
    }
    if (refreshInbox) {
      refreshMessagesInbox();
    }
    return summary;
  }

  Future<void> onCallScreenDisposed() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await ZegoEngineUtils.resetAfterCall();
  }

  static void refreshMessagesInbox() {
    if (!Get.isRegistered<MessagesTabController>()) return;
    unawaited(Get.find<MessagesTabController>().fetchInbox());
  }

  @override
  void onClose() {
    unawaited(_recordCallIfNeeded());
    super.onClose();
  }

  Future<Map<String, dynamic>?> _recordCallIfNeeded() async {
    if (_callRecorded || roomId.value.isEmpty) return null;

    final myId = _rawUserId;
    if (myId.isEmpty) return null;

    final startedAt = _startedAt;
    final endedAt = DateTime.now().toUtc();
    final durationSeconds = startedAt == null
        ? null
        : endedAt.difference(startedAt).inSeconds;

    final callerId = isCaller.value ? myId : hostId.value.trim();
    final calleeId = isCaller.value ? hostId.value.trim() : myId;
    if (callerId.isEmpty || calleeId.isEmpty) return null;

    final wasAccepted = _peerJoined;
    final outcome = wasAccepted
        ? 'completed'
        : (isCaller.value ? 'cancelled' : 'missed');

    var recorded = await _callService.endCall(
      roomId.value,
      endedByUserId: myId,
      durationSeconds: durationSeconds,
    );

    if (!recorded) {
      await _callService.recordCallSession(
        roomId: roomId.value,
        callerId: callerId,
        calleeId: calleeId,
        isVideo: isVideo.value,
        endedByUserId: myId,
        durationSeconds: durationSeconds,
        wasAccepted: wasAccepted,
        callId: callId.value,
      );
      recorded = true;
    }

    if (!recorded) return null;

    _callRecorded = true;

    final summary = {
      'callId': callId.value,
      'id': callId.value,
      'roomId': roomId.value,
      'callerId': callerId,
      'calleeId': calleeId,
      'type': isVideo.value ? 'video' : 'voice',
      'status': outcome,
      'clientEndedAt': endedAt.toIso8601String(),
      if (durationSeconds != null &&
          durationSeconds > 0 &&
          outcome == 'completed')
        'durationSeconds': durationSeconds,
    };

    await _localStore.appendCallEntry(roomId: roomId.value, entry: summary);
    await _localStore.upsertCallPreview(
      targetId: hostId.value.trim(),
      roomId: roomId.value,
      isVideo: isVideo.value,
      outcome: outcome,
      isIncoming: !isCaller.value,
      name: peerName.value,
    );

    LoggerUtils.logInfo(
      'ChatVoiceCallController: call logged outcome=$outcome room=${roomId.value}',
    );
    return summary;
  }

  String get _rawUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId;
  }

  Future<void> _chargeCallIfNeeded() async {
    if (_charged || !isCaller.value || hostId.value.trim().isEmpty) return;
    if (!_peerJoined) return;
    _charged = true;
    final startedAt = _startedAt;
    if (startedAt == null) return;
    final durationSeconds = DateTime.now().difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return;

    try {
      await _callingRepo.chargeCall(
        hostId: hostId.value.trim(),
        durationSeconds: durationSeconds,
        isShowLoader: false,
      );
    } catch (e) {
      LoggerUtils.logWarning('ChatVoiceCallController: charge failed — $e');
    }
  }
}
