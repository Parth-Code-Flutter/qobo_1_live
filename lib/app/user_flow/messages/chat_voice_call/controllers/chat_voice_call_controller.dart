import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_detail/controllers/chat_detail_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
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
import 'package:qobo_one_live/utils/app_widgets/session_earnings_dialog.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/security/screen_capture_guard.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/coin_fly_overlay.dart';
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
  /// Caller spend rate (doc: 2 coins/sec). Keep separate from host earn rate.
  final coinsPerSecond = 2.0.obs;
  /// Callee earn rate (doc: 1 coin/sec = 50% of caller spend).
  final earnCoinsPerSecond = 1.0.obs;
  final sessionEarnings = SessionEarningsTracker();
  /// Target for per-second billing coin fly animation in the call top bar.
  final callBillingBadgeKey = GlobalKey(debugLabel: 'callBillingBadge');
  final giftCatalog = <Map<String, String>>[].obs;
  final isLoadingGifts = false.obs;

  /// Last successful `calling/charge` payload (coins spent / host diamonds).
  final lastChargeTotalCoinsDeducted = 0.obs;
  final lastChargeHostEarnedDiamonds = 0.obs;

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
  Timer? _walletRefreshTimer;
  int _lastBillingAnimationSecond = 0;
  int _lastBillingAnimShownAtSecond = 0;
  int _pendingAnimCoins = 0;
  bool _billingAnimInFlight = false;
  int _callTimeCoinsEarned = 0;
  int _callTimeCoinsSpent = 0;
  /// Dialog display tracker (callee earnings or caller spend).
  final callCoinsDialogTracker = SessionEarningsTracker();

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
      isCaller.value = _parseIsCaller(args['isCaller']);
      isVideo.value = _parseBool(args['isVideo']);
      // Earning rule: caller earns, receiver pays (2 coins/sec spend, 1/sec earn).
      final passedRate = _positiveDouble(args['coinsPerSecond']) ??
          _currentUserCoinsPerSecond();
      coinsPerSecond.value = passedRate ?? 2;
      earnCoinsPerSecond.value =
          _positiveDouble(args['earnCoinsPerSecond']) ??
          (passedRate != null ? (passedRate / 2).clamp(0.5, passedRate) : 1);
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
    // Caller earns → poll session earnings; both sides refresh wallet.
    if (isEarningSide) {
      _startSessionEarningsPolling();
    }
    _startWalletRefreshPolling();
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

  /// Caller pays; only explicit false / 0 / "false" means callee.
  static bool _parseIsCaller(dynamic value) {
    if (value == false || value == 0) return false;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'false' || normalized == '0' || normalized == 'callee') {
        return false;
      }
    }
    return true;
  }

  /// Caller earns; receiver (acceptor) pays.
  bool get isSpendingSide => !isCaller.value;
  bool get isEarningSide => isCaller.value;

  String get formattedDuration =>
      hasPeerJoined.value ? _formatDuration(billableSeconds.value) : 'Ringing';

  int get estimatedRemainingCoins {
    // Live wallet already decrements per tick for the spending side (receiver).
    return coinsBalance.value < 0 ? 0 : coinsBalance.value;
  }

  int get estimatedCoinDelta {
    final rate = isSpendingSide
        ? coinsPerSecond.value
        : earnCoinsPerSecond.value;
    return (billableSeconds.value * rate).ceil();
  }

  int get sessionGiftCoinsEarned => sessionEarnings.displayCoins;

  int get sessionTotalCoinsEarned {
    if (isSpendingSide) return 0;
    // Includes per-second call ticks + gift credits already applied to tracker.
    return sessionEarnings.displayCoins;
  }

  String get billingRoleLabel => hasPeerJoined.value
      ? (isSpendingSide ? 'Spending' : 'Earning')
      : 'Starts after answer';

  String get billingAmountLabel {
    if (!hasPeerJoined.value) return '0';
    if (isSpendingSide) {
      return SessionEarningsUtils.formatAmountForPill(estimatedRemainingCoins);
    }
    return SessionEarningsUtils.formatAmountForPill(coinsBalance.value);
  }

  String get billingDeltaLabel {
    if (!hasPeerJoined.value) return '';
    if (isSpendingSide) {
      return '-${SessionEarningsUtils.formatAmountForPill(_callTimeCoinsSpent > 0 ? _callTimeCoinsSpent : estimatedCoinDelta)}';
    }
    return '+${SessionEarningsUtils.formatAmountForPill(sessionTotalCoinsEarned)}';
  }

  String get sessionEarningsSubtitle {
    if (isSpendingSide) {
      return '${coinsPerSecond.value.toStringAsFixed(0)}/s · spent ${SessionEarningsUtils.formatAmountForPill(_callTimeCoinsSpent > 0 ? _callTimeCoinsSpent : estimatedCoinDelta)}';
    }
    return '${earnCoinsPerSecond.value.toStringAsFixed(0)}/s · call ${SessionEarningsUtils.formatAmountForPill(_callTimeCoinsEarned > 0 ? _callTimeCoinsEarned : estimatedCoinDelta)}';
  }

  String get callChargeSummaryLabel {
    if (isSpendingSide) {
      final spent = lastChargeTotalCoinsDeducted.value > 0
          ? lastChargeTotalCoinsDeducted.value
          : estimatedCoinDelta;
      return 'Spent ${SessionEarningsUtils.formatAmountForPill(spent)} coins';
    }
    final earned = lastChargeHostEarnedDiamonds.value > 0
        ? lastChargeHostEarnedDiamonds.value
        : estimatedCoinDelta;
    return 'Earned ${SessionEarningsUtils.formatAmountForPill(earned)} coins';
  }

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
    _lastBillingAnimationSecond = 0;
    _lastBillingAnimShownAtSecond = 0;
    _pendingAnimCoins = 0;
    _billingAnimInFlight = false;
    _callTimeCoinsEarned = 0;
    _callTimeCoinsSpent = 0;
    callCoinsDialogTracker.reset();
    // Engine is usually ready once the peer is in — (re)bind gift messages.
    _bindGiftMessageListener(force: true);
  }

  void onZegoError(Object error) {
    LoggerUtils.logWarning('ChatVoiceCallController: $error');
  }

  /// Records call + returns summary for chat thread (WhatsApp-style log row).
  Future<Map<String, dynamic>?> finishCall({bool refreshInbox = true}) async {
    // Charge first so the history summary can include spent/earned amounts.
    await _chargeCallIfNeeded();
    final summary = await _recordCallIfNeeded();
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
    _stopWalletRefreshPolling();
    CoinFlyOverlay.dismiss();
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
      sessionType: 'call',
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
      giftCatalog: giftCatalog.toList(),
      onPeerGift: (event) {
              final earned = SessionEarningsUtils.ingestIncomingGiftChat(
                tracker: sessionEarnings,
                chatMessage: event.message,
                giftCatalog: giftCatalog.toList(),
                earnsGift: true,
              );
              if (earned > 0) {
                coinsBalance.value =
                    (coinsBalance.value + earned).clamp(0, 1 << 30);
                if (isEarningSide) {
                  callCoinsDialogTracker.setFromTotals(
                    coins: sessionTotalCoinsEarned,
                    diamonds: sessionTotalCoinsEarned,
                  );
                }
                _playBillingCoinAnimation(
                  amount: earned,
                  isDeduction: false,
                );
              }
            },
    );
  }

  void _startSessionEarningsPolling() {
    if (!isEarningSide) return;
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

  void _startWalletRefreshPolling() {
    _walletRefreshTimer?.cancel();
    _walletRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(loadWalletBalance());
    });
  }

  void _stopWalletRefreshPolling() {
    _walletRefreshTimer?.cancel();
    _walletRefreshTimer = null;
  }

  void _onBillableSecondAdvanced(int seconds) {
    if (!_peerJoined || seconds <= _lastBillingAnimationSecond) return;
    _lastBillingAnimationSecond = seconds;

    // Caller earns; receiver pays.
    if (isSpendingSide) {
      final spent = coinsPerSecond.value.ceil();
      _callTimeCoinsSpent += spent;
      coinsBalance.value =
          (coinsBalance.value - spent).clamp(0, 1 << 30);
      callCoinsDialogTracker.setFromTotals(
        coins: _callTimeCoinsSpent,
        diamonds: _callTimeCoinsSpent,
      );
      _queueBillingCoinAnimation(amount: spent, isDeduction: true);
      return;
    }

    final earned = earnCoinsPerSecond.value.ceil();
    _callTimeCoinsEarned += earned;
    sessionEarnings.applyDelta(coins: earned, diamonds: earned);
    callCoinsDialogTracker.setFromTotals(
      coins: sessionTotalCoinsEarned,
      diamonds: sessionTotalCoinsEarned,
    );
    coinsBalance.value = (coinsBalance.value + earned).clamp(0, 1 << 30);
    _queueBillingCoinAnimation(amount: earned, isDeduction: false);
  }

  /// Batch per-second ticks so overlays don't stack on the video PIP.
  void _queueBillingCoinAnimation({
    required int amount,
    required bool isDeduction,
  }) {
    if (amount <= 0) return;
    _pendingAnimCoins += amount;
    final secondsSinceLast =
        _lastBillingAnimationSecond - _lastBillingAnimShownAtSecond;
    if (_billingAnimInFlight) return;
    // Show at most every 3s with accumulated coins.
    if (secondsSinceLast < 3 && _lastBillingAnimShownAtSecond > 0) return;
    final showAmount = _pendingAnimCoins;
    _pendingAnimCoins = 0;
    _lastBillingAnimShownAtSecond = _lastBillingAnimationSecond;
    _playBillingCoinAnimation(amount: showAmount, isDeduction: isDeduction);
  }

  void _playBillingCoinAnimation({
    required int amount,
    required bool isDeduction,
  }) {
    if (amount <= 0) return;
    _billingAnimInFlight = true;
    final visualCount = (3 + (amount / 3).ceil()).clamp(3, 8);
    unawaited(
      CoinFlyOverlay.show(
        targetKey: callBillingBadgeKey,
        coinCount: visualCount,
        earnedAmount: amount,
        isDeduction: isDeduction,
        delay: const Duration(milliseconds: 40),
      ).whenComplete(() {
        _billingAnimInFlight = false;
        if (_pendingAnimCoins > 0 && _peerJoined) {
          final leftover = _pendingAnimCoins;
          _pendingAnimCoins = 0;
          _lastBillingAnimShownAtSecond = _lastBillingAnimationSecond;
          _playBillingCoinAnimation(
            amount: leftover,
            isDeduction: isSpendingSide,
          );
        }
      }),
    );
  }

  /// Same glass coins dialog as audio-room earnings badge (caller / earning side only).
  void openCallCoinsDialog() {
    if (isSpendingSide) return;

    if (!hasPeerJoined.value) {
      Get.snackbar(
        'Call billing',
        'Coins start after the call is answered.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isEarningSide) {
      callCoinsDialogTracker.setFromTotals(
        coins: sessionTotalCoinsEarned,
        diamonds: sessionTotalCoinsEarned,
      );
      SessionEarningsDialog.show(
        tracker: callCoinsDialogTracker,
        onWithdraw: openWithdrawalWallet,
        unitLabel: 'coins',
        title: 'Call earnings',
        subtitle: 'Coins earned on this call so far',
        noteWithBalance:
            'You earn ${earnCoinsPerSecond.value.toStringAsFixed(0)} coin/sec while the call is connected. Withdraw anytime from wallet.',
        noteEmpty: 'Stay on the call to start earning coins.',
      );
      return;
    }

    callCoinsDialogTracker.setFromTotals(
      coins: _callTimeCoinsSpent > 0 ? _callTimeCoinsSpent : estimatedCoinDelta,
      diamonds: _callTimeCoinsSpent > 0 ? _callTimeCoinsSpent : estimatedCoinDelta,
    );
    SessionEarningsDialog.show(
      tracker: callCoinsDialogTracker,
      onWithdraw: openWithdrawalWallet,
      unitLabel: 'coins',
      title: 'Call spending',
      subtitle: 'Coins spent on this call so far',
      noteWithBalance:
          'You are charged ${coinsPerSecond.value.toStringAsFixed(0)} coins/sec. Wallet left: ${SessionEarningsUtils.formatAmountForPill(estimatedRemainingCoins)}.',
      noteEmpty: 'Spending starts after the call is answered.',
      showWithdraw: true,
      primaryLabel: 'Wallet',
    );
  }

  void openWithdrawalWallet() {
    Get.to(
      () => const WalletView(openWithdrawOnLoad: true),
      binding: WalletBinding(),
    );
  }

  Future<void> _refreshSessionEarnings() async {
    if (!isEarningSide) return;
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
        final nextBillable = DateTime.now()
            .difference(billingStartedAt)
            .inSeconds;
        if (nextBillable != billableSeconds.value) {
          billableSeconds.value = nextBillable;
          _onBillableSecondAdvanced(nextBillable);
        }
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
      'coinsPerSecond': coinsPerSecond.value,
      'earnCoinsPerSecond': earnCoinsPerSecond.value,
      if (lastChargeTotalCoinsDeducted.value > 0)
        'totalCoinsDeducted': lastChargeTotalCoinsDeducted.value,
      if (lastChargeHostEarnedDiamonds.value > 0)
        'hostEarnedDiamonds': lastChargeHostEarnedDiamonds.value,
      'billingSummary': callChargeSummaryLabel,
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
    // Receiver pays the caller (earner). hostId on callee screen is the caller.
    if (_charged || isCaller.value || hostId.value.trim().isEmpty) return;
    if (!_peerJoined) return;
    _charged = true;
    final startedAt = _billingStartedAt;
    if (startedAt == null) return;
    final durationSeconds = DateTime.now().difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return;

    try {
      final response = await _callingRepo.chargeCall(
        hostId: hostId.value.trim(),
        durationSeconds: durationSeconds,
        isShowLoader: false,
      );
      if (!isEconomyApiSuccess(response)) return;
      final data = response?['data'];
      if (data is! Map) return;
      final deducted = parseWalletAmount(
        data['totalCoinsDeducted'] ??
            data['total_coins_deducted'] ??
            data['coinsDeducted'] ??
            data['coins_deducted'],
      );
      final hostEarned = parseWalletAmount(
        data['hostEarnedDiamonds'] ??
            data['host_earned_diamonds'] ??
            data['hostEarnedCoins'] ??
            data['host_earned_coins'],
      );
      if (deducted > 0) lastChargeTotalCoinsDeducted.value = deducted;
      if (hostEarned > 0) lastChargeHostEarnedDiamonds.value = hostEarned;
      unawaited(loadWalletBalance());
    } catch (e) {
      LoggerUtils.logWarning('ChatVoiceCallController: charge failed — $e');
    }
  }
}
