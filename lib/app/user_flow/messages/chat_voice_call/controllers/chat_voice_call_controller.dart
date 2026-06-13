import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/repo/calling/calling_repo.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_voice_call_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

class ChatVoiceCallController extends GetxController {
  ChatVoiceCallController({
    ChatVoiceCallService? voiceCallService,
    CallingRepo? callingRepo,
  }) : _voiceCallService = voiceCallService ?? ChatVoiceCallService(),
       _callingRepo = callingRepo ?? CallingRepo();

  final ChatVoiceCallService _voiceCallService;
  final CallingRepo _callingRepo;

  final callId = ''.obs;
  final roomId = ''.obs;
  final hostId = ''.obs;
  final peerName = 'User'.obs;
  final isCaller = true.obs;
  final isVideo = false.obs;
  DateTime? _startedAt;
  bool _charged = false;

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
      'ChatVoiceCallController: joining callId=$callId room=${roomId.value} '
      'user=$zegoUserId caller=${isCaller.value} video=${isVideo.value}',
    );
  }

  void onZegoError(Object error) {
    LoggerUtils.logWarning('ChatVoiceCallController: Zego error — $error');
  }

  Future<void> onCallEnded() async {
    if (roomId.value.isEmpty) return;
    await _voiceCallService.endCall(roomId.value);
    await _chargeCallIfNeeded();
    if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
      Get.find<ChatIncomingCallCoordinator>().setOnCallScreen(false);
    }
    unawaited(ZegoEngineUtils.resetAfterCall());
  }

  Future<void> _chargeCallIfNeeded() async {
    if (_charged || !isCaller.value || hostId.value.trim().isEmpty) return;
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
      LoggerUtils.logWarning('ChatVoiceCallController: call charge failed — $e');
    }
  }
}
