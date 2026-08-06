import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_detail/controllers/chat_detail_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
import 'package:qobo_one_live/repo/calling/calling_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/security/screen_capture_guard.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_celebration_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_chat_celebration_tracker.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';
import 'package:qobo_one_live/utils/zego_call_id_utils.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_uikit/zego_uikit.dart';

class ChatVoiceCallController extends GetxController
    with WidgetsBindingObserver {
  ChatVoiceCallController({
    ChatCallService? callService,
    CallingRepo? callingRepo,
    EconomyRepo? economyRepo,
    RoomRepo? roomRepo,
    ChatLocalStore? localStore,
  }) : _callService = callService ?? ChatCallService(),
       _callingRepo = callingRepo ?? CallingRepo(),
       _economyRepo = economyRepo ?? EconomyRepo(),
       _roomRepo = roomRepo ?? RoomRepo(),
       _localStore = localStore ?? ChatLocalStore();

  final ChatCallService _callService;
  final CallingRepo _callingRepo;
  final EconomyRepo _economyRepo;
  final RoomRepo _roomRepo;
  final ChatLocalStore _localStore;

  final callId = ''.obs;
  final historyDocId = ''.obs;
  final roomId = ''.obs;
  final hostId = ''.obs;
  final peerName = 'User'.obs;
  final peerAvatar = RxnString();
  final peerCountry = ''.obs;
  final peerBio = ''.obs;
  final isCaller = true.obs;
  final isVideo = false.obs;
  final hasPeerJoined = false.obs;
  final elapsedSeconds = 0.obs;
  final billableSeconds = 0.obs;
  final coinsBalance = 0.obs;
  final coinsPerSecond = 1.0.obs;
  final sessionEarnings = SessionEarningsTracker();
  final giftCatalog = <Map<String, String>>[].obs;
  final isLoadingGifts = false.obs;

  DateTime? _startedAt;
  DateTime? _billingStartedAt;
  String? _callStartedAtIso;
  bool _charged = false;
  bool _callRecorded = false;
  bool _peerJoined = false;
  bool _recordCallHistory = true;
  Timer? _ticker;

  /// Peer gift celebration via Zego in-room messages (same markers as live rooms).
  StreamSubscription<List<ZegoInRoomMessage>>? _giftMessageSub;
  final GiftChatCelebrationTracker _giftCelebrationTracker =
      GiftChatCelebrationTracker();
  bool _giftListenerBound = false;
  Timer? _sessionEarningsTimer;

  /// True after we turned on [ScreenCaptureGuard] for this video session.
  bool _screenCaptureLocked = false;

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

  String get currentUserName => zegoUserName;

  String? get currentUserAvatar {
    if (!Get.isRegistered<UserSessionController>()) return null;
    return Get.find<UserSessionController>().displayPictureUrl;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments;
    if (args is Map) {
      roomId.value = args['roomId']?.toString() ?? '';
      hostId.value = args['hostId']?.toString() ?? '';
      peerName.value = args['peerName']?.toString() ?? 'User';
      peerAvatar.value = _cleanText(args['peerAvatar']);
      peerCountry.value = _cleanText(args['peerCountry']) ?? '';
      peerBio.value = _cleanText(args['peerBio']) ?? '';
      isCaller.value = args['isCaller'] != false;
      isVideo.value = _parseBool(args['isVideo']);
      coinsPerSecond.value =
          _positiveDouble(args['coinsPerSecond']) ??
          _currentUserCoinsPerSecond() ??
          1;
      final passedCallId = args['callId']?.toString() ?? '';
      callId.value = passedCallId.isNotEmpty
          ? passedCallId
          : ZegoCallIdUtils.fromRoomId(roomId.value);
      historyDocId.value = args['historyDocId']?.toString() ?? '';
      _callStartedAtIso = args['callStartedAt']?.toString();
      _recordCallHistory = args['recordCallHistory'] != false;
    }
    _startedAt = DateTime.now();
    _callStartedAtIso ??= _startedAt!.toUtc().toIso8601String();
    if (!isCaller.value) {
      _markPeerJoined();
    }
    _startTicker();
    unawaited(loadWalletBalance());
    unawaited(loadGiftCatalog());
    if (!isCaller.value) {
      _startSessionEarningsPolling();
    }
    // Listen for peer gifts once the call room message bus is available.
    _bindGiftMessageListener();
    // 1:1 video only — block screenshots / screen recording while on this call.
    _lockScreenCaptureIfVideo();
    LoggerUtils.logInfo(
      'ChatVoiceCallController: Zego join callId=${callId.value} '
      'room=${roomId.value} video=${isVideo.value}',
    );
  }

  /// Re-apply FLAG_SECURE / SurfaceView.setSecure after resume or late Zego views.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _screenCaptureLocked) {
      unawaited(ScreenCaptureGuard.reapply());
    }
  }

  void _lockScreenCaptureIfVideo() {
    if (!isVideo.value || _screenCaptureLocked) return;
    _screenCaptureLocked = true;
    // Post-frame so native plugins / activity binding are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ScreenCaptureGuard.enable());
    });
  }

  static bool _parseBool(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'video';
    }
    return false;
  }

  String get formattedDuration =>
      hasPeerJoined.value ? _formatDuration(billableSeconds.value) : 'Ringing';

  int get estimatedCoinDelta =>
      (billableSeconds.value * coinsPerSecond.value).ceil();

  int get estimatedRemainingCoins {
    if (!isCaller.value) return coinsBalance.value;
    final remaining = coinsBalance.value - estimatedCoinDelta;
    return remaining < 0 ? 0 : remaining;
  }

  int get sessionGiftCoinsEarned => sessionEarnings.displayCoins;

  int get sessionTotalCoinsEarned {
    if (isCaller.value) return 0;
    return sessionGiftCoinsEarned + estimatedCoinDelta;
  }

  String get billingRoleLabel => hasPeerJoined.value
      ? (isCaller.value ? 'Coins spending' : 'Session earning')
      : 'Starts after answer';

  String get billingAmountLabel {
    if (!hasPeerJoined.value) return '0';
    if (isCaller.value) {
      return '-${SessionEarningsUtils.formatAmountForPill(estimatedCoinDelta)}';
    }
    return '+${SessionEarningsUtils.formatAmountForPill(sessionTotalCoinsEarned)}';
  }

  String get sessionEarningsSubtitle => isCaller.value
      ? 'Remaining ${SessionEarningsUtils.formatAmountForPill(estimatedRemainingCoins)}'
      : 'Session ${SessionEarningsUtils.formatAmountForPill(sessionTotalCoinsEarned)}';

  void onCallUserEntered(String userId) {
    final rawEnteredId = userId.trim();
    if (rawEnteredId.isEmpty) return;

    final enteredId = ZegoLiveIdUtils.sanitizeUserId(rawEnteredId);
    final currentId = zegoUserId;
    final expectedPeerId = ZegoLiveIdUtils.sanitizeUserId(hostId.value);

    if (enteredId == currentId) {
      LoggerUtils.logInfo(
        'ChatVoiceCallController: ignored local call user $enteredId',
      );
      return;
    }

    // Billing should only begin when the actual caller/callee enters. Zego can
    // emit user-enter events for the local SDK user or stale room users, which
    // must not count as an answered paid call.
    if (expectedPeerId.isNotEmpty && enteredId != expectedPeerId) {
      LoggerUtils.logInfo(
        'ChatVoiceCallController: ignored non-peer call user $enteredId',
      );
      return;
    }

    _markPeerJoined();
  }

  void _markPeerJoined() {
    _peerJoined = true;
    hasPeerJoined.value = true;
    _billingStartedAt ??= DateTime.now();
    // Engine is usually ready once the peer is in — (re)bind gift messages.
    _bindGiftMessageListener(force: true);
  }

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
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopSessionEarningsPolling();
    _giftMessageSub?.cancel();
    _giftCelebrationTracker.reset();
    GiftCelebrationOverlay.dismiss();
    // Always clear video screenshot lock when leaving the call screen.
    if (_screenCaptureLocked) {
      _screenCaptureLocked = false;
      unawaited(ScreenCaptureGuard.disable());
    }
    unawaited(_recordCallIfNeeded());
    super.onClose();
  }

  Future<void> loadWalletBalance() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (!isEconomyApiSuccess(response) || data is! Map) return;
    coinsBalance.value = parseWalletAmount(
      data['coins'] ?? data['coin'] ?? data['balance'] ?? data['coinBalance'],
    );
  }

  Future<void> loadGiftCatalog() async {
    isLoadingGifts.value = true;
    try {
      final response = await _economyRepo.getGiftList(isShowLoader: false);
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is List) {
        giftCatalog.assignAll(
          data
              .whereType<Map>()
              .map(
                (raw) =>
                    GiftMediaUtils.mapGiftFromApi(Map<String, dynamic>.from(raw)),
              )
              .where((gift) => (gift['id'] ?? '').isNotEmpty)
              .toList(),
        );
      }
    } finally {
      isLoadingGifts.value = false;
    }
  }

  Future<void> sendGift(Map<String, String> gift) async {
    final giftId = gift['id']?.trim() ?? '';
    final receiverId = hostId.value.trim();
    final currentRoomId = roomId.value.trim();
    if (giftId.isEmpty || receiverId.isEmpty || currentRoomId.isEmpty) {
      Get.snackbar(
        'Gift not sent',
        'Gift, receiver, or room id is missing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final price = int.tryParse(gift['price'] ?? '0') ?? 0;
    if (coinsBalance.value < price) {
      Get.snackbar(
        'Insufficient Coins',
        'You need ${formatLedgerAmount(price - coinsBalance.value)} more coins.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final response = await _economyRepo.sendGift(
      receiverId: receiverId,
      giftId: giftId,
      roomId: currentRoomId,
      isShowLoader: true,
    );
    if (isEconomyApiSuccess(response)) {
      await loadWalletBalance();

      final animationUrl = GiftMediaUtils.animationUrlFromResponse(
        response,
        gift,
      );
      final soundUrl = GiftMediaUtils.soundUrlFromResponse(response, gift);

      // Match live/audio rooms: dismiss sheet, then celebrate for both sides.
      unawaited(
        GiftMediaUtils.dismissSheetThenCelebrate(
          giftName: gift['name'],
          animationUrl: animationUrl,
          soundUrl: soundUrl,
        ),
      );

      // Notify the peer so they play the same animation on their call UI.
      final giftLabel = GiftMediaUtils.buildChatLabel(
        giftName: gift['name'],
        giftIcon: gift['icon'],
        animationUrl: animationUrl,
        soundUrl: soundUrl,
      );
      _bindGiftMessageListener(force: true);
      unawaited(
        ZegoUIKit().sendInRoomMessage(giftLabel).catchError((_) => false),
      );
      return;
    }
    Get.snackbar(
      'Gift not sent',
      response?['message']?.toString() ?? 'Unable to send this gift.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Subscribes to Zego in-room messages for peer gift celebrations.
  ///
  /// [force] rebinds after the call engine becomes ready (peer join / reconnect).
  void _bindGiftMessageListener({bool force = false}) {
    if (_giftListenerBound && !force) return;
    try {
      final zego = ZegoUIKit();
      _giftMessageSub?.cancel();
      _giftMessageSub = zego.getInRoomMessageListStream().listen(
        _maybeCelebrateIncomingGift,
      );
      _giftListenerBound = true;
      _maybeCelebrateIncomingGift(zego.getInRoomMessages());
    } catch (error) {
      // Call engine may not be ready yet — retry when the peer joins.
      _giftListenerBound = false;
      LoggerUtils.logInfo(
        'ChatVoiceCallController: gift message bind deferred ($error)',
      );
    }
  }

  /// Plays celebration for peer gift chat events (skips own send duplicates).
  void _maybeCelebrateIncomingGift(List<ZegoInRoomMessage> messages) {
    _giftCelebrationTracker.onGiftMessages(
      myUserId: zegoUserId,
      events: messages
          .where((m) => GiftMediaUtils.isGiftChatMessage(m.message))
          .map(
            (m) => (
              key: '${m.messageID}_${m.timestamp}',
              senderId: ZegoLiveIdUtils.sanitizeUserId(m.user.id),
              message: m.message,
            ),
          ),
      onPeerGift: !isCaller.value
          ? (event) {
              SessionEarningsUtils.ingestIncomingGiftChat(
                tracker: sessionEarnings,
                chatMessage: event.message,
                giftCatalog: giftCatalog.toList(),
                earnsGift: true,
              );
            }
          : null,
    );
  }

  void _startSessionEarningsPolling() {
    if (isCaller.value) return;
    _sessionEarningsTimer?.cancel();
    unawaited(_refreshSessionEarnings());
    _sessionEarningsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_refreshSessionEarnings());
    });
  }

  void _stopSessionEarningsPolling() {
    _sessionEarningsTimer?.cancel();
    _sessionEarningsTimer = null;
  }

  Future<void> _refreshSessionEarnings() async {
    if (isCaller.value) return;
    final currentRoomId = roomId.value.trim();
    if (currentRoomId.isEmpty) return;

    final response = await _roomRepo.getSessionEarnings(
      roomId: currentRoomId,
      sessionType: 'call',
      isShowLoader: false,
    );
    SessionEarningsUtils.ingestApiEnvelope(sessionEarnings, response);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _startedAt;
      if (startedAt != null) {
        elapsedSeconds.value = DateTime.now().difference(startedAt).inSeconds;
      }
      final billingStartedAt = _billingStartedAt;
      if (billingStartedAt != null) {
        billableSeconds.value = DateTime.now()
            .difference(billingStartedAt)
            .inSeconds;
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${remainingMinutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${remainingMinutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String? _cleanText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  double? _positiveDouble(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  double? _currentUserCoinsPerSecond() {
    if (!Get.isRegistered<UserSessionController>()) return null;
    final data = Get.find<UserSessionController>().profileData;
    return _positiveDouble(
      data?['coinsPerSecond'] ?? data?['coins_per_second'],
    );
  }

  Future<Map<String, dynamic>?> _recordCallIfNeeded() async {
    if (_callRecorded || roomId.value.isEmpty) return null;

    final myId = _rawUserId;
    if (myId.isEmpty) return null;

    if (!_recordCallHistory) {
      await _callService.clearActiveCall(roomId.value, endedByUserId: myId);
      _callRecorded = true;
      LoggerUtils.logInfo(
        'ChatVoiceCallController: direct call ended — no history stored',
      );
      return null;
    }

    final startedAt = _peerJoined ? _billingStartedAt : _startedAt;
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
    final historyId = historyDocId.value.trim().isNotEmpty
        ? historyDocId.value.trim()
        : 'call_${endedAt.microsecondsSinceEpoch}';

    var recorded = await _callService.endCall(
      roomId.value,
      endedByUserId: myId,
      durationSeconds: durationSeconds,
      historyDocId: historyId,
      callStartedAt: _callStartedAtIso,
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
        zegoCallId: callId.value,
        historyDocId: historyId,
        callStartedAt: _callStartedAtIso,
      );
      recorded = true;
    }

    if (!recorded) return null;

    _callRecorded = true;

    final durationMinutes = ChatInboxPreviewType.durationMinutesFromSeconds(
      durationSeconds,
    );

    final summary = {
      'callId': historyId,
      'id': historyId,
      'zegoCallId': callId.value,
      'roomId': roomId.value,
      'callerId': callerId,
      'calleeId': calleeId,
      'type': isVideo.value ? 'video' : 'voice',
      'status': outcome,
      if (_callStartedAtIso != null && _callStartedAtIso!.isNotEmpty)
        'callStartedAt': _callStartedAtIso,
      'clientEndedAt': endedAt.toIso8601String(),
      if (durationSeconds != null &&
          durationSeconds > 0 &&
          outcome == 'completed')
        'durationSeconds': durationSeconds,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
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
    final startedAt = _billingStartedAt;
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
