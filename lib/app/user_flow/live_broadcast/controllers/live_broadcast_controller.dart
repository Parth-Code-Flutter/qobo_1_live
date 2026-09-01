import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/emoji/emoji_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_battle_widgets.dart';
import 'package:qobo_one_live/services/pk/pk_live_room_bridge.dart';
import 'package:qobo_one_live/services/pk/pk_v1_coordinator.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/join_request_in_app_banner.dart';
import 'package:qobo_one_live/utils/app_dialogs/audio_room_feedback_dialog.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/session_earnings_dialog.dart';
import 'package:qobo_one_live/utils/gift_share_economics.dart';
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/emoji_celebration_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_celebration_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_chat_celebration_tracker.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/coin_fly_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/avatar_fly_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/vip_entrance_overlay.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

import '../models/audio_room_models.dart';
import '../models/room_background_theme.dart';
import '../utils/live_room_profile_utils.dart';
import '../widgets/emoji_picker_bottom_sheet.dart';
import '../widgets/gifts_bottom_sheet.dart';
import '../widgets/follower_pk_gift_target_sheet.dart';
import '../widgets/live_filters_sheet.dart';
import '../widgets/live_viewers_sheet.dart';
import '../widgets/room_background_sheet.dart';

class LiveBroadcastController extends GetxController {
  LiveBroadcastController({
    EconomyRepo? economyRepo,
    AuthRepo? authRepo,
    RoomRepo? roomRepo,
    EmojiRepo? emojiRepo,
  }) : _economyRepo = economyRepo ?? EconomyRepo(),
       _authRepo = authRepo ?? AuthRepo(),
       _roomRepo = roomRepo ?? RoomRepo(),
       _emojiRepo = emojiRepo ?? EmojiRepo();

  final EconomyRepo _economyRepo;
  final AuthRepo _authRepo;
  final RoomRepo _roomRepo;
  final EmojiRepo _emojiRepo;

  final isHost = false.obs;

  /// Host-vs-host PK overlay is replacing the seat grid / live stage.
  final isPkBattleActive = false.obs;
  final roomType = 'VIDEO'.obs;
  final roomId = ''.obs;
  final receiverId = ''.obs;

  /// Sanitized Zego user id for the live host (resolved after room login).
  final hostZegoUserId = ''.obs;
  final hasExplicitStreamingId = false.obs;
  final connectionIssue = ''.obs;

  final streamTitle = ''.obs;
  final hostName = 'Live Host'.obs;
  final hostAvatarUrl = RxnString();
  final hostAvatarFrameUrl = RxnString();
  final likesLabel = '0'.obs;
  final viewerCount = 0.obs;
  final liveViewers = <Map<String, dynamic>>[].obs;
  final isFollowingHost = false.obs;
  final isZegoConnected = false.obs;

  /// Bumps when Zego user/stream list changes so seat cameras remount.
  final zegoMediaUsersTick = 0.obs;

  /// Active floating-heart animation tokens (live streaming reactions).
  final heartReactionTokens = <int>[].obs;
  var _heartReactionSeq = 0;

  final chatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  final coinsBalance = 0.obs;
  final diamondsBalance = 0.obs;

  /// Host-only session coins shown in the room AppBar (not audience wallet).
  final sessionEarnings = SessionEarningsTracker();

  /// Per-occupant coins earned while seated this visit. Leave + rejoin => 0.
  final seatSessionCoins = <String, int>{}.obs;

  /// Target for gullak-style coin fly animation into the host earnings pill.
  final sessionEarningsBadgeKey = GlobalKey(debugLabel: 'sessionEarningsBadge');

  /// Landing spots for audience coin-fly (one GlobalKey per seated user id).
  final Map<String, GlobalKey> _seatCoinFlyKeys = {};

  /// Target for floor-audience join fly animation into the AppBar people badge.
  final floorAudienceBadgeKey = GlobalKey(debugLabel: 'floorAudienceBadge');
  final giftCatalog = <Map<String, String>>[].obs;
  final isLoadingGifts = false.obs;
  final selectedGiftReceiverId = RxnString();
  final selectedGiftReceiverName = RxnString();
  final isRoomGiftMode = true.obs;
  final emojiCatalog = <Map<String, String>>[].obs;
  final emojiPackVersion = 1.obs;
  final isLoadingEmojis = false.obs;
  final activeSeatEmojis = <String, Map<String, String>>{}.obs;
  final selectedEmojiReceiverId = RxnString();
  final selectedEmojiReceiverName = RxnString();
  final audioRoomSeats = <AudioRoomSeatModel>[].obs;
  final floorAudience = <FloorAudienceUser>[].obs;

  /// Skip join-fly on the first floor snapshot so opening a room is quiet.
  bool _floorAudienceHydrated = false;
  final Set<String> _knownFloorAudienceIds = <String>{};
  final pendingSeatRequests = <PendingSeatRequest>[].obs;
  final viewerFollowsHost = false.obs;
  final myPlacement = 'floor'.obs; // seat | floor
  final audioInviteCandidates = <AudioRoomInviteCandidate>[].obs;
  final isLoadingAudioSeats = false.obs;
  final isLoadingInviteCandidates = false.obs;
  final liveBeautyEnabled = false.obs;
  final liveSmooth = 35.obs;
  final liveSkinTone = 25.obs;
  final liveBlush = 12.obs;
  final liveSharpen = 15.obs;

  /// Active room backdrop (audio rooms); synced via API + Socket.IO.
  final roomBackgroundUrl = RxnString();
  final roomBackgroundId = RxnString();
  final roomBackgroundCatalog = <RoomBackgroundTheme>[].obs;
  final isLoadingRoomBackgrounds = false.obs;
  final isChangingRoomBackground = false.obs;

  /// Host inbox for viewers waiting on join approval.
  final pendingJoinRequests = <Map<String, dynamic>>[].obs;
  final joinApprovalRequired = false.obs;

  Map<String, dynamic> _roomData = {};
  StreamSubscription<List<ZegoInRoomMessage>>? _messageSub;
  StreamSubscription<List<ZegoUIKitUser>>? _userSub;
  StreamSubscription<dynamic>? _mediaSub;
  void Function(Map<String, dynamic>)? _roomBackgroundSocketListener;
  void Function(Map<String, dynamic>)? _vipUserJoinedSocketListener;
  void Function(String event, Map<String, dynamic> data)?
  _liveStreamingSocketListener;

  /// Dedupes gift celebrations triggered by Zego gift chat events (all room kinds).
  final GiftChatCelebrationTracker _giftCelebrationTracker =
      GiftChatCelebrationTracker();

  /// Play VIP entrance SVGA only once per user for this room session.
  final Set<String> _vipEntrancePlayedUserIds = <String>{};
  var _vipSeatEntranceBaselineReady = false;
  final DateTime _liveScreenOpenedAtUtc = DateTime.now().toUtc();

  Timer? _seatRefreshTimer;
  Timer? _sessionEarningsTimer;
  Timer? _joinRequestPollTimer;
  final Set<String> _promptedJoinRequestIds = <String>{};
  VoidCallback? _viewerCountListener;
  Worker? _pkActiveWorker;
  var _exitReported = false;
  var _hostEndConfirmed = false;
  var _giftSendInFlight = false;
  var _emojiSendInFlight = false;
  final Set<String> _playedEmojiEventKeys = <String>{};
  final Map<String, Timer> _seatEmojiTimers = <String, Timer>{};

  /// True when PK forced the camera on (e.g. audio room → PK video panes).
  var _pkForcedCameraOn = false;

  /// After join, used to auto-close the room when seat sync shows removal/kick.
  var _roomMembershipConfirmed = false;
  var _currentUserOccupiedMicSeat = false;

  /// True when the user entered via push notification or in-app invite dialog.
  /// These users auto-seat on join; listing/discover users go to floor instead.
  var _joinedViaInvite = false;
  var _autoSeatAttempted = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('isHost')) isHost.value = args['isHost'];
      if (args.containsKey('roomType')) roomType.value = args['roomType'];
      if (args.containsKey('roomData') && args['roomData'] != null) {
        _roomData = Map<String, dynamic>.from(args['roomData']);
        receiverId.value = _extractReceiverId(_roomData) ?? '';
        final streamingId = _extractStreamingId(_roomData);
        hasExplicitStreamingId.value = streamingId != null;
        // Live streams: Zego liveID = zegoLiveId / liveStreamingId (ls_…).
        // Backend room UUID is for REST only (see LIVE_STREAMING API doc).
        final channel = ZegoLiveIdUtils.resolveLiveChannelId(_roomData) ?? '';
        if (channel.isNotEmpty) {
          ZegoLiveIdUtils.applyLiveChannelId(_roomData);
        }
        roomId.value = channel.isNotEmpty
            ? channel
            : ZegoLiveIdUtils.sanitize(
                streamingId ?? _extractBackendRoomId(_roomData) ?? '',
              );
      }
    }
    _joinedViaInvite = _roomData['joinedViaInvite'] == true;
    joinApprovalRequired.value = JoinApprovalService.isApprovalRequired(
      _roomData,
    );
    _hydrateHostProfile();
    if (isLiveStreamingSession) {
      final seeded = ZegoLiveIdUtils.sanitizeUserId(receiverId.value);
      if (seeded.isNotEmpty) hostZegoUserId.value = seeded;
    }
    _hydrateRoomBackground();
    _seedSessionEarningsFromRoom();
    _restoreHostSessionIfNeeded();
    _validateStreamingInput();
    loadWalletBalance();
    loadGiftCatalog();
    loadEmojiCatalog();
    _pkActiveWorker = ever<bool>(PkLiveRoomBridge.isActive, (active) {
      if (active) {
        _syncPkLocalAudience();
        ensurePkHostVideoReady();
      } else {
        restoreCameraAfterPk();
      }
    });
    // Host + audience both read the host session total for the AppBar pill.
    _startSessionEarningsPolling();
    if (isAudioVideoRoom) {
      // Open join + seat-request realtime for host and guests.
      unawaited(_bootstrapPartyRoomRealtime());
      var initialSeats = _parseAudioSeats(_roomData);
      if (initialSeats.isEmpty) {
        initialSeats = _buildFallbackAudioSeats();
      }
      if (initialSeats.isNotEmpty) {
        _setAudioRoomSeats(initialSeats);
        _seedVipEntranceBaselineFromSeats(initialSeats);
      }
      if (!isHost.value) {
        _roomMembershipConfirmed = true;
      }
      _startSeatRefreshPolling();
      _bindRoomBackgroundSocket();
    } else {
      // Live stream: still listen for VIP join entrance (gift-style overlay).
      _bindVipEntranceSocketOnly();
      if (!isHost.value) {
        // Live-stream audience: report the join so backend viewer/heat counts
        // move. Group-call rooms already do this via joinTypedRoom.
        _reportLiveStreamViewerJoin();
      }
    }
    chatMessages.clear();
  }

  void _reportLiveStreamViewerJoin() {
    // Standalone live streaming has its own `/api/live-streaming/join` flow
    // before this screen opens. Do not call `/api/room/join` here: that is for
    // audio/video rooms and was causing duplicate/incorrect room joins.
  }

  void upsertPendingJoinRequest(Map<String, dynamic> request) {
    final requestId =
        request['request_id']?.toString().trim() ??
        request['requestId']?.toString().trim() ??
        '';
    if (requestId.isEmpty) return;
    final next = List<Map<String, dynamic>>.from(pendingJoinRequests);
    final index = next.indexWhere(
      (item) =>
          (item['request_id']?.toString() ?? item['requestId']?.toString()) ==
          requestId,
    );
    if (index >= 0) {
      next[index] = {...next[index], ...request};
    } else {
      next.insert(0, Map<String, dynamic>.from(request));
    }
    pendingJoinRequests.assignAll(next);
  }

  void removePendingJoinRequest(String requestId) {
    final id = requestId.trim();
    if (id.isEmpty) return;
    pendingJoinRequests.removeWhere(
      (item) =>
          (item['request_id']?.toString() ?? item['requestId']?.toString()) ==
          id,
    );
    _promptedJoinRequestIds.remove(id);
  }

  void markJoinRequestPrompted(String requestId) {
    final id = requestId.trim();
    if (id.isEmpty) return;
    _promptedJoinRequestIds.add(id);
  }

  Future<void> openJoinRequestsSheet() async {
    final roomApiId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (roomApiId.isEmpty) return;
    await JoinRequestsSheet.show(roomId: roomApiId);
  }

  void setJoinApprovalRequired(bool value) {
    joinApprovalRequired.value = value;
    _roomData['joinApprovalRequired'] = value;
  }

  /// Party rooms: open join (no join-approval). Connect socket + poll seat requests.
  Future<void> _bootstrapPartyRoomRealtime() async {
    // Join accept/reject is intentionally disabled for audio/video rooms.
    joinApprovalRequired.value = false;
    _roomData['joinApprovalRequired'] = false;

    await UserRealtimeSocketService.ensureConnected();
    final apiRoomId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (apiRoomId.isNotEmpty && Get.isRegistered<UserRealtimeSocketService>()) {
      await Get.find<UserRealtimeSocketService>().joinRoomChannel(apiRoomId);
    }
    _bindSeatRequestSocket();
    if (isHost.value) {
      _startSeatRequestPolling();
    }
  }

  Timer? _seatRequestPollTimer;
  final Set<String> _promptedSeatRequestIds = <String>{};
  void Function(Map<String, dynamic>)? _seatRequestSocketListener;
  void Function(Map<String, dynamic>)? _floorAudienceSocketListener;
  void Function(Map<String, dynamic>)? _userKickedSocketListener;
  void Function(String event, Map<String, dynamic> data)? _emojiSocketListener;

  void _startSeatRequestPolling() {
    if (!isHost.value) return;
    _seatRequestPollTimer?.cancel();
    unawaited(_pollPendingSeatRequests(showDialogForNew: true));
    _seatRequestPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_exitReported || !isHost.value) {
        _stopSeatRequestPolling();
        return;
      }
      unawaited(_pollPendingSeatRequests(showDialogForNew: true));
    });
  }

  void _stopSeatRequestPolling() {
    _seatRequestPollTimer?.cancel();
    _seatRequestPollTimer = null;
  }

  Future<void> _pollPendingSeatRequests({bool showDialogForNew = false}) async {
    if (!isHost.value || _exitReported) return;
    final apiRoomId = audioRoomApiId.trim();
    if (apiRoomId.isEmpty) return;

    Map<String, dynamic>? response;
    try {
      response = await _roomRepo.listSeatRequests(
        roomId: apiRoomId,
        isShowLoader: false,
      );
    } catch (_) {
      return;
    }
    if (response == null) return;

    final data = response['data'];
    final raw = data is List
        ? data
        : (data is Map
              ? (data['items'] ?? data['requests'] ?? data['data'])
              : null);
    final list = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (e) => PendingSeatRequest.fromMap(Map<String, dynamic>.from(e)),
              )
              .where((e) => e.requestId.isNotEmpty)
              .toList()
        : <PendingSeatRequest>[];

    pendingSeatRequests.assignAll(list);
    if (!showDialogForNew) return;

    for (final item in list) {
      if (_promptedSeatRequestIds.contains(item.requestId)) continue;
      _promptedSeatRequestIds.add(item.requestId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(showSeatRequestHostDialog(item));
      });
    }
  }

  void _applySeatsMeta(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);

    final hostId =
        map['host_id']?.toString().trim() ??
        map['hostId']?.toString().trim() ??
        '';
    if (hostId.isNotEmpty && receiverId.value.trim().isEmpty) {
      receiverId.value = hostId;
    }

    if (map.containsKey('viewer_follows_host') ||
        map.containsKey('viewerFollowsHost')) {
      viewerFollowsHost.value =
          map['viewer_follows_host'] == true ||
          map['viewerFollowsHost'] == true;
      isFollowingHost.value = viewerFollowsHost.value;
    }

    final placement =
        (map['my_placement'] ?? map['myPlacement'])?.toString().trim() ?? '';
    if (placement.isNotEmpty) {
      myPlacement.value = placement.toLowerCase();
    } else if (map.containsKey('my_placement') ||
        map.containsKey('myPlacement')) {
      myPlacement.value = '';
    }

    final floorRaw = map['floor_audience'] ?? map['floorAudience'];
    if (floorRaw is List) {
      _applyFloorAudience(
        floorRaw
            .whereType<Map>()
            .map((e) => FloorAudienceUser.fromMap(Map<String, dynamic>.from(e)))
            .where((e) => e.userId.isNotEmpty)
            .toList(),
      );
    }

    final pendingRaw =
        map['pending_seat_requests'] ?? map['pendingSeatRequests'];
    if (pendingRaw is List) {
      final parsed = pendingRaw
          .whereType<Map>()
          .map((e) => PendingSeatRequest.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.requestId.isNotEmpty)
          .toList();
      pendingSeatRequests.assignAll(parsed);
      if (isHost.value) {
        for (final item in parsed) {
          if (_promptedSeatRequestIds.contains(item.requestId)) continue;
          _promptedSeatRequestIds.add(item.requestId);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(showSeatRequestHostDialog(item));
          });
        }
      }
    }

    // Room-level follower PK block (badge restore when seat.pkBattle is absent).
    _applyActiveFollowerPkMeta(
      map['active_follower_pk'] ?? map['activeFollowerPk'],
    );

    SessionEarningsUtils.ingestRoomData(sessionEarnings, map);
    if (sessionEarnings.displayCoins > 0) {
      _rememberHostSessionIfNeeded();
    }
  }

  /// Mirrors `active_follower_pk` onto the challenger's seat when seats lag.
  void _applyActiveFollowerPkMeta(dynamic raw) {
    if (raw is! Map) return;
    final meta = Map<String, dynamic>.from(raw);
    final battleId =
        (meta['battle_id'] ?? meta['battleId'] ?? meta['id'])
            ?.toString()
            .trim() ??
        '';
    final challengerId =
        (meta['challenger_user_id'] ??
                meta['challengerUserId'] ??
                meta['challenger_id'])
            ?.toString()
            .trim() ??
        '';
    final status = (meta['status']?.toString().trim() ?? '').toLowerCase();
    if (battleId.isEmpty || challengerId.isEmpty || status.isEmpty) return;

    final badge = AudioRoomPkBattleInfo(
      battleId: battleId,
      status: status,
      mode: 'audio_follower_pk',
      active:
          status == 'waiting_opponent' ||
          status == 'duration_pending' ||
          status == 'active',
      canJoin: status == 'waiting_opponent',
    );

    var changed = false;
    final next = audioRoomSeats.map((seat) {
      if (!_userIdsMatch(seat.userId, challengerId)) return seat;
      if (seat.pkBattle?.battleId == badge.battleId &&
          seat.pkBattle?.status == badge.status &&
          seat.pkBattle?.canJoin == badge.canJoin) {
        return seat;
      }
      changed = true;
      return seat.copyWith(pkBattle: badge);
    }).toList();
    if (changed) {
      _setAudioRoomSeats(next);
    }
  }

  /// Updates [floorAudience] and flies new joiners into the AppBar people badge.
  void _applyFloorAudience(List<FloorAudienceUser> next) {
    final previousIds = Set<String>.from(_knownFloorAudienceIds);
    final nextIds = next
        .map((e) => e.userId.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    floorAudience.assignAll(next);
    _knownFloorAudienceIds
      ..clear()
      ..addAll(nextIds);

    _syncPkLocalAudience();

    if (!_floorAudienceHydrated) {
      _floorAudienceHydrated = true;
      return;
    }

    final myId = _currentUserId();
    final newcomers = next.where((user) {
      final id = user.userId.trim();
      if (id.isEmpty || previousIds.contains(id)) return false;
      // Don't animate yourself joining into your own badge.
      if (myId.isNotEmpty && _userIdsMatch(id, myId)) return false;
      return true;
    }).toList();

    for (final user in newcomers.take(2)) {
      unawaited(_playFloorJoinFlyAnimation(user));
    }
  }

  /// Feeds this room's audience into the local PK side (opponent side needs API).
  void _syncPkLocalAudience() {
    if (!isInRoomPkActive || !Get.isRegistered<PkV1Controller>()) return;
    final pk = Get.find<PkV1Controller>();
    final pkSession = pk.session.value;
    final members = <PkAudienceMember>[];
    final seen = <String>{};

    final excludeIds = <String>{
      receiverId.value.trim(),
      _currentUserId(),
      pk.selfUserId,
      if (pkSession != null) pkSession.sideA.hostId,
      if (pkSession != null) pkSession.sideB.hostId,
    }.where((id) => id.isNotEmpty).toList();

    bool isExcluded(String userId) {
      final id = userId.trim();
      if (id.isEmpty) return true;
      for (final excluded in excludeIds) {
        if (_userIdsMatch(id, excluded)) return true;
      }
      return false;
    }

    void addMember({
      required String userId,
      required String name,
      String? avatar,
    }) {
      final id = userId.trim();
      if (id.isEmpty || seen.contains(id) || isExcluded(id)) return;
      seen.add(id);
      members.add(
        PkAudienceMember(
          userId: id,
          displayName: name.trim().isEmpty ? 'Viewer' : name.trim(),
          avatarUrl: (avatar ?? '').trim(),
        ),
      );
    }

    for (final user in floorAudience) {
      if (isExcluded(user.userId)) continue;
      addMember(userId: user.userId, name: user.name, avatar: user.avatarUrl);
    }
    for (final seat in audioRoomSeats) {
      if (!seat.occupied) continue;
      if (seat.role.toLowerCase() == 'host') continue;
      if (isExcluded(seat.userId)) continue;
      addMember(userId: seat.userId, name: seat.name, avatar: seat.avatarUrl);
    }
    for (final viewer in liveViewers) {
      if (viewer['isHost'] == true) continue;
      if (isHost.value && viewer['isCurrentUser'] == true) continue;
      final viewerId =
          (viewer['targetId'] ??
                  viewer['userId'] ??
                  viewer['user_id'] ??
                  viewer['id'] ??
                  '')
              .toString();
      if (isExcluded(viewerId)) continue;
      addMember(
        userId: viewerId,
        name:
            (viewer['name'] ??
                    viewer['displayName'] ??
                    viewer['username'] ??
                    'Viewer')
                .toString(),
        avatar:
            (viewer['avatarUrl'] ??
                    viewer['avatar'] ??
                    viewer['displayPicture'] ??
                    '')
                .toString(),
      );
    }

    pk.syncLocalRoomAudience(members);
  }

  /// Ensures the host camera/mic publish when PK battle starts.
  ///
  /// Audio rooms join without camera — PK needs video panes, so we force the
  /// local camera on for the host (group-call or live-stream engine).
  void ensurePkHostVideoReady() {
    if (!isHost.value) return;
    _turnOnPkHostMedia();
    Future.delayed(const Duration(milliseconds: 400), _turnOnPkHostMedia);
    Future.delayed(const Duration(milliseconds: 1000), _turnOnPkHostMedia);
    Future.delayed(const Duration(milliseconds: 2000), _turnOnPkHostMedia);
  }

  void _turnOnPkHostMedia() {
    if (!isHost.value) return;
    try {
      if (isAudioVideoRoom) {
        // Party rooms use the group-call Zego engine (not live-streaming).
        ZegoUIKit().turnCameraOn(true);
        ZegoUIKit().turnMicrophoneOn(true);
        isCameraOff.value = false;
        isMicMuted.value = false;
        // Audio rooms normally keep camera off — remember so we can restore.
        if (!isVideoRoom) {
          _pkForcedCameraOn = true;
        }
        return;
      }
      // Live-stream host path.
      final av = ZegoUIKitPrebuiltLiveStreamingController().audioVideo;
      av.camera.turnOn(true);
      av.microphone.turnOn(true);
      isCameraOff.value = false;
      isMicMuted.value = false;
      _pkForcedCameraOn = true;
    } catch (_) {
      // Engine may still be warming up; retries from ensurePkHostVideoReady cover it.
    }
  }

  /// After PK ends, turn camera back off for audio rooms (voice-only again).
  void restoreCameraAfterPk() {
    if (!_pkForcedCameraOn) return;
    _pkForcedCameraOn = false;
    if (isVideoRoom) return;
    try {
      if (isAudioVideoRoom) {
        ZegoUIKit().turnCameraOn(false);
      } else {
        ZegoUIKitPrebuiltLiveStreamingController().audioVideo.camera.turnOn(
          false,
        );
      }
      isCameraOff.value = true;
    } catch (_) {}
  }

  Future<void> _playFloorJoinFlyAnimation(FloorAudienceUser user) async {
    try {
      await AvatarFlyOverlay.show(
        targetKey: floorAudienceBadgeKey,
        name: user.name.trim().isEmpty ? 'Guest' : user.name.trim(),
        avatarUrl: user.avatarUrl,
      );
    } catch (_) {}
  }

  /// Host: turn on join approval + poll pending join requests.
  /// Kept for live-stream / legacy; party rooms use [_bootstrapPartyRoomRealtime].
  // ignore: unused_element
  Future<void> _bootstrapHostJoinApproval() async {
    await _ensureJoinApprovalEnabled();
    await UserRealtimeSocketService.ensureConnected();
    final apiRoomId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (apiRoomId.isNotEmpty && Get.isRegistered<UserRealtimeSocketService>()) {
      await Get.find<UserRealtimeSocketService>().joinRoomChannel(apiRoomId);
    }
    _startJoinRequestPolling();
  }

  Future<void> _ensureJoinApprovalEnabled() async {
    final apiRoomId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (apiRoomId.isEmpty) return;

    if (!joinApprovalRequired.value) {
      joinApprovalRequired.value = true;
      _roomData['joinApprovalRequired'] = true;
    }

    try {
      final response = await _roomRepo.updateRoomSettings(
        roomId: apiRoomId,
        joinApprovalRequired: true,
        isShowLoader: false,
      );
      if (JoinApprovalService.isApiSuccess(response)) {
        setJoinApprovalRequired(true);
      }
    } catch (_) {
      // Settings API may be unavailable; polling + create flag still help.
    }
  }

  void _startJoinRequestPolling() {
    if (!isHost.value) return;
    _joinRequestPollTimer?.cancel();
    unawaited(_pollPendingJoinRequests(showDialogForNew: true));
    _joinRequestPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_exitReported || !isHost.value) {
        _stopJoinRequestPolling();
        return;
      }
      unawaited(_pollPendingJoinRequests(showDialogForNew: true));
    });
  }

  void _stopJoinRequestPolling() {
    _joinRequestPollTimer?.cancel();
    _joinRequestPollTimer = null;
  }

  Future<void> _pollPendingJoinRequests({bool showDialogForNew = false}) async {
    if (!isHost.value || _exitReported) return;
    final apiRoomId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (apiRoomId.isEmpty) return;

    Map<String, dynamic>? response;
    try {
      response = await _roomRepo.listJoinRequests(
        roomId: apiRoomId,
        status: 'pending',
        isShowLoader: false,
      );
    } catch (_) {
      return;
    }
    if (response == null) return;

    final data = response['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final raw = map['items'] ?? map['requests'] ?? data;
    final list = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    for (final item in list) {
      final requestId =
          item['request_id']?.toString().trim() ??
          item['requestId']?.toString().trim() ??
          '';
      if (requestId.isEmpty) continue;

      upsertPendingJoinRequest({
        ...item,
        'request_id': requestId,
        'room_id':
            item['room_id']?.toString() ??
            item['roomId']?.toString() ??
            apiRoomId,
        'status': 'pending',
        'type': 'join_request',
      });

      if (!showDialogForNew || _promptedJoinRequestIds.contains(requestId)) {
        continue;
      }
      _promptedJoinRequestIds.add(requestId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          JoinRequestInAppBanner.tryShowFromMap({
            ...item,
            'type': 'join_request',
            'request_id': requestId,
            'room_id':
                item['room_id']?.toString() ??
                item['roomId']?.toString() ??
                apiRoomId,
          }),
        );
      });
    }
  }

  void _hydrateRoomBackground() {
    final url = ApiImageUtils.normalize(
      readRoomField(_roomData, [
        'backgroundImage',
        'background_image',
        'backgroundUrl',
        'background_url',
      ]),
    );
    final id = readRoomField(_roomData, ['backgroundId', 'background_id']);
    roomBackgroundUrl.value = (url != null && url.isNotEmpty) ? url : null;
    roomBackgroundId.value = (id != null && id.isNotEmpty) ? id : null;
  }

  void _hydrateHostProfile() {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;

    hostName.value = resolveHostName(
      isHost: isHost.value,
      sessionName: session?.displayName ?? '',
      roomData: _roomData,
    );
    hostAvatarUrl.value = resolveHostAvatarUrl(
      isHost: isHost.value,
      sessionAvatarUrl: session?.displayPictureUrl,
      roomData: _roomData,
    );
    hostAvatarFrameUrl.value = resolveHostAvatarFrameUrl(
      isHost: isHost.value,
      sessionFrameUrl: session?.profileFrameUrl,
      roomData: _roomData,
    );
    streamTitle.value =
        readRoomField(_roomData, ['name', 'title', 'streamName']) ??
        hostName.value;

    final engagement = readEngagementCount(_roomData);
    likesLabel.value = formatCompactCount(engagement);

    if (receiverId.value.trim().isEmpty) {
      final hostId = resolveHostId(_roomData);
      if (hostId != null) receiverId.value = hostId;
    }
    if (isHost.value && session != null && receiverId.value.trim().isEmpty) {
      receiverId.value = session.userId;
    }

    final following =
        _roomData['isFollowing'] == true ||
        _roomData['isFollowed'] == true ||
        readNestedHost(_roomData)?['isFollowing'] == true;
    isFollowingHost.value = following;
  }

  Future<void> loadWalletBalance() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (isEconomyApiSuccess(response) && data is Map) {
      coinsBalance.value = parseWalletAmount(
        data['coins'] ?? data['coin'] ?? data['balance'] ?? data['coinBalance'],
      );
      diamondsBalance.value = parseWalletAmount(
        data['diamonds'] ?? data['diamond'] ?? data['diamondBalance'],
      );
    }
  }

  void _seedSessionEarningsFromRoom() {
    SessionEarningsUtils.ingestRoomData(sessionEarnings, _roomData);
    _rememberHostSessionIfNeeded();
  }

  void _rememberHostSessionIfNeeded() {
    final coins = sessionEarnings.displayCoins;
    if (coins <= 0) return;
    HostSessionRoomStore.remember(audioRoomApiId, coins);
    HostSessionRoomStore.remember(roomId.value, coins);
  }

  /// Audience leave/rejoin creates a new tracker at 0 — restore host AppBar total.
  void _restoreHostSessionIfNeeded() {
    if (sessionEarnings.displayCoins > 0) {
      _rememberHostSessionIfNeeded();
      return;
    }
    final cached = [
      HostSessionRoomStore.peek(audioRoomApiId),
      HostSessionRoomStore.peek(roomId.value),
    ].fold<int>(0, (max, value) => value > max ? value : max);
    if (cached <= 0) return;
    sessionEarnings.setFromTotals(
      coins: cached,
      diamonds: sessionEarnings.diamondsEarned.value,
    );
  }

  String get _sessionEarningsType {
    if (isLiveStreamingSession) return 'live_stream';
    if (isVideoRoom) return 'video_room';
    return 'audio_room';
  }

  String _resolvedHostId() {
    return resolveHostId(_roomData) ?? receiverId.value.trim();
  }

  bool _seatIsRoomHost(AudioRoomSeatModel seat) {
    if (seat.isHost) return true;
    return _userIdsMatch(seat.userId, _resolvedHostId());
  }

  int _sessionCoinsForUserId(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return 0;
    final direct = seatSessionCoins[id];
    if (direct != null) return direct;
    for (final entry in seatSessionCoins.entries) {
      if (_userIdsMatch(entry.key, id)) return entry.value;
    }
    return 0;
  }

  /// Seat chip: 0 on join, then this-visit gift credits. Host stays on seat 1.
  int sessionCoinsForSeat(AudioRoomSeatModel seat) {
    if (!shouldShowSeatSessionCoins(seat)) return 0;
    return _sessionCoinsForUserId(seat.userId);
  }

  bool shouldShowSeatSessionCoins(AudioRoomSeatModel seat) {
    return seat.occupied && seat.userId.trim().isNotEmpty;
  }

  void _setAudioRoomSeats(List<AudioRoomSeatModel> seats) {
    audioRoomSeats.assignAll(seats);
    _syncSeatSessionOccupants(seats);
  }

  /// Drop audience coins when they leave so a rejoin starts at 0.
  /// Host AppBar / host seat session is never cleared here.
  void _syncSeatSessionOccupants(List<AudioRoomSeatModel> seats) {
    final present = <String>{};
    for (final seat in seats) {
      final id = seat.userId.trim();
      if (seat.occupied && id.isNotEmpty) present.add(id);
    }
    final hostId = _resolvedHostId();

    var changed = false;
    final stale = seatSessionCoins.keys
        .where((id) => !present.any((live) => _userIdsMatch(live, id)))
        .toList();
    for (final id in stale) {
      if (hostId.isNotEmpty && _userIdsMatch(id, hostId)) continue;
      seatSessionCoins.remove(id);
      _seatCoinFlyKeys.remove(id);
      changed = true;
    }
    for (final id in present) {
      final already = seatSessionCoins.keys.any(
        (existing) => _userIdsMatch(existing, id),
      );
      if (!already) {
        seatSessionCoins[id] = 0;
        changed = true;
      }
    }
    if (changed) seatSessionCoins.refresh();
  }

  void _addSeatSessionCoins(String userId, int amount) {
    if (amount <= 0) return;
    final id = userId.trim();
    if (id.isEmpty) return;
    var key = id;
    for (final existing in seatSessionCoins.keys) {
      if (_userIdsMatch(existing, id)) {
        key = existing;
        break;
      }
    }
    seatSessionCoins[key] = (seatSessionCoins[key] ?? 0) + amount;
  }

  void _startSessionEarningsPolling() {
    _sessionEarningsTimer?.cancel();
    unawaited(_refreshSessionEarnings());
    _sessionEarningsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_exitReported) {
        _stopSessionEarningsPolling();
        return;
      }
      unawaited(_refreshSessionEarnings());
    });
  }

  void _stopSessionEarningsPolling() {
    _sessionEarningsTimer?.cancel();
    _sessionEarningsTimer = null;
  }

  Future<void> _refreshSessionEarnings() async {
    if (_exitReported) return;
    final roomIds = _sessionEarningsRoomIds();
    if (roomIds.isEmpty) return;

    // Spec: room_id may be backend UUID or Zego live id — try both if needed.
    for (final roomApiId in roomIds) {
      if (_exitReported) return;
      final response = await _roomRepo.getSessionEarnings(
        roomId: roomApiId,
        sessionType: _sessionEarningsType,
        isShowLoader: false,
      );
      SessionEarningsUtils.ingestApiEnvelope(sessionEarnings, response);
      debugPrint(
        '[session-earnings] room=$roomApiId type=$_sessionEarningsType '
        'display=${sessionEarnings.displayCoins} raw=$response',
      );
      if (sessionEarnings.displayCoins > 0) break;
    }
    if (sessionEarnings.displayCoins > 0) {
      _rememberHostSessionIfNeeded();
    } else {
      _restoreHostSessionIfNeeded();
    }
  }

  /// Ids the session-earnings GET may accept (UUID first, then Zego channel).
  List<String> _sessionEarningsRoomIds() {
    final ids = <String>[];
    void add(String? value) {
      final id = value?.trim() ?? '';
      if (id.isEmpty || ids.contains(id)) return;
      ids.add(id);
    }

    add(audioRoomApiId);
    add(_extractBackendRoomId(_roomData));
    add(_roomData['room_id']?.toString());
    add(_roomData['roomId']?.toString());
    add(_roomData['zegoLiveId']?.toString());
    add(_roomData['channelName']?.toString());
    add(roomId.value);
    return ids;
  }

  void _applySessionEarningsFromGiftResponse({
    required Map<String, dynamic>? response,
    required int fallbackGiftPrice,
    required String scope,
    String? receiverId,
  }) {
    // Party rooms credit the host pill via [_bumpSeatDiamonds].
    if (isAudioVideoRoom) return;

    final hostId = _resolvedHostId();
    if (hostId.isEmpty) return;

    // Sender never earns. Room gifts credit peers via chat on live streams.
    final normalized = scope.trim().toLowerCase();
    if (normalized == 'room') return;

    SessionEarningsUtils.ingestGiftResponse(
      tracker: sessionEarnings,
      response: response,
      hostUserId: hostId,
      earnerUserId: hostId,
      hostReceivesRoomGifts: false,
      roomParticipantsEarn: false,
      fallbackGiftPrice: fallbackGiftPrice,
      scope: scope,
      receiverId: receiverId,
    );
  }

  /// Whether the room host earns from this gift (AppBar host session).
  bool _hostEarnsGift({
    required String scope,
    String? receiverId,
    String? senderId,
    List<String>? creditedUserIds,
  }) {
    final hostId = _resolvedHostId();
    if (hostId.isEmpty) return false;
    final from = senderId?.trim() ?? '';
    if (from.isNotEmpty && _userIdsMatch(from, hostId)) {
      return false;
    }

    if (creditedUserIds != null && creditedUserIds.isNotEmpty) {
      return creditedUserIds.any((id) => _userIdsMatch(id, hostId));
    }

    final normalized = scope.trim().toLowerCase();
    if (normalized == 'room') {
      if (isAudioVideoRoom) {
        return audioRoomSeats.any(
          (seat) => seat.occupied && _seatIsRoomHost(seat),
        );
      }
      return true;
    }
    final to = receiverId?.trim() ?? '';
    return to.isNotEmpty && _userIdsMatch(to, hostId);
  }

  /// Whether this occupied seat should receive this gift credit.
  bool _seatMatchesGiftCredit(
    AudioRoomSeatModel seat, {
    required String scope,
    String? receiverId,
    String? excludeUserId,
    List<String>? creditedUserIds,
  }) {
    if (!seat.occupied) return false;
    final exclude = excludeUserId?.trim() ?? '';
    if (exclude.isNotEmpty && _userIdsMatch(seat.userId, exclude)) {
      return false;
    }
    final credited = creditedUserIds
        ?.map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final normalized = scope.trim().toLowerCase();
    final targetId = normalized == 'room' ? '' : (receiverId?.trim() ?? '');
    if (normalized != 'room' &&
        targetId.isEmpty &&
        (credited == null || credited.isEmpty)) {
      return false;
    }
    final matchCredited =
        credited != null &&
        credited.isNotEmpty &&
        credited.any((id) => _userIdsMatch(id, seat.userId));
    final matchRoom =
        normalized == 'room' && (credited == null || credited.isEmpty);
    final matchUser =
        normalized != 'room' && _userIdsMatch(seat.userId, targetId);
    return matchCredited || matchRoom || matchUser;
  }

  /// Audience (non-host) seats that earned from this gift — coin-fly targets.
  List<String> _creditedAudienceSeatUserIds({
    required String scope,
    String? receiverId,
    String? excludeUserId,
    List<String>? creditedUserIds,
  }) {
    if (!isAudioVideoRoom) return const [];
    final hostId = _resolvedHostId();
    final ids = <String>[];
    for (final seat in audioRoomSeats) {
      if (!_seatMatchesGiftCredit(
        seat,
        scope: scope,
        receiverId: receiverId,
        excludeUserId: excludeUserId,
        creditedUserIds: creditedUserIds,
      )) {
        continue;
      }
      final userId = seat.userId.trim();
      if (userId.isEmpty) continue;
      if (hostId.isNotEmpty && _userIdsMatch(userId, hostId)) continue;
      if (ids.any((id) => _userIdsMatch(id, userId))) continue;
      ids.add(userId);
    }
    return ids;
  }

  /// Key on the on-stage tile so coins can land on that audience seat.
  GlobalKey seatCoinFlyKeyFor(String userId) {
    final id = userId.trim();
    return _seatCoinFlyKeys.putIfAbsent(
      id,
      () => GlobalKey(debugLabel: 'seatCoinFly_$id'),
    );
  }

  /// Optimistic in-visit seat coins for gift recipients (not lifetime diamonds).
  ///
  /// Room gifts credit occupied seats except [excludeUserId] (sender).
  /// Floor audience is never bumped. Host credits also update the AppBar pill.
  void _bumpSeatDiamonds({
    required String scope,
    String? receiverId,
    required int amount,
    String? excludeUserId,
    List<String>? creditedUserIds,
  }) {
    if (amount <= 0 || !isAudioVideoRoom) return;

    var hostCredited = false;
    var seatedCredit = false;
    for (final seat in audioRoomSeats) {
      if (!_seatMatchesGiftCredit(
        seat,
        scope: scope,
        receiverId: receiverId,
        excludeUserId: excludeUserId,
        creditedUserIds: creditedUserIds,
      )) {
        continue;
      }
      seatedCredit = true;
      _addSeatSessionCoins(seat.userId, amount);
      if (_seatIsRoomHost(seat)) {
        hostCredited = true;
      }
    }
    if (seatedCredit) seatSessionCoins.refresh();
    if (hostCredited) {
      sessionEarnings.applyDelta(coins: amount, diamonds: amount);
      _rememberHostSessionIfNeeded();
    }
  }

  /// Host AppBar coin-fly. Do not change target / timing — audience uses seats.
  void _playEarningsCoinFlyAnimation(int earnedCoins) {
    final visualCount = earnedCoins > 0
        ? (6 + (earnedCoins / 15).ceil()).clamp(6, 16)
        : 10;
    unawaited(
      CoinFlyOverlay.show(
        targetKey: sessionEarningsBadgeKey,
        coinCount: visualCount,
        earnedAmount: earnedCoins,
        delay: const Duration(milliseconds: 220),
      ),
    );
  }

  /// After the gift SVGA: host AppBar fly (unchanged) then audience-seat flies.
  Future<void> _playGiftCoinFliesAfterCelebration({
    required int hostEarnedCoins,
    required List<String> audienceUserIds,
    required int amountEach,
  }) async {
    final playHostFly = isHost.value && hostEarnedCoins > 0;
    if (!playHostFly && audienceUserIds.isEmpty) return;

    await GiftCelebrationOverlay.waitUntilIdle();
    if (_exitReported) return;
    if (playHostFly) {
      _playEarningsCoinFlyAnimation(hostEarnedCoins);
    }

    if (!isAudioVideoRoom || amountEach <= 0 || audienceUserIds.isEmpty) {
      return;
    }
    var enqueue = playHostFly;
    for (final userId in audienceUserIds) {
      _playAudienceSeatCoinFly(
        userId: userId,
        earnedCoins: amountEach,
        enqueueIfBusy: enqueue,
      );
      enqueue = true;
    }
  }

  /// Coins rise from the bottom and land on that audience member's seat.
  void _playAudienceSeatCoinFly({
    required String userId,
    required int earnedCoins,
    required bool enqueueIfBusy,
  }) {
    if (userId.trim().isEmpty) return;
    if (_userIdsMatch(userId, _resolvedHostId())) return;
    final visualCount = earnedCoins > 0
        ? (6 + (earnedCoins / 15).ceil()).clamp(6, 16)
        : 10;
    unawaited(
      CoinFlyOverlay.show(
        targetKey: seatCoinFlyKeyFor(userId),
        coinCount: visualCount,
        earnedAmount: earnedCoins,
        delay: const Duration(milliseconds: 220),
        enqueueIfBusy: enqueueIfBusy,
        fallbackIfMissing: false,
      ),
    );
  }

  /// Host-only session earnings dialog. Audience taps on the AppBar are ignored.
  void openSessionEarningsDialog() {
    if (!isHost.value) return;
    SessionEarningsDialog.show(
      tracker: sessionEarnings,
      onWithdraw: openWithdrawalWallet,
      unitLabel: 'coins',
    );
  }

  void openWithdrawalWallet() {
    Get.to(
      () => const WalletView(openWithdrawOnLoad: true),
      binding: WalletBinding(),
    );
  }

  List<String> get giftCategories {
    if (giftCatalog.isEmpty) return const [];
    final categories = <String>{};
    for (final gift in giftCatalog) {
      final category = gift['category']?.trim();
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    final sorted = categories.toList()..sort();
    return sorted.isEmpty ? const ['Gifts'] : sorted;
  }

  List<Map<String, String>> giftsForCategory(String category) {
    if (giftCatalog.isEmpty) return const [];
    final normalized = category.trim().toLowerCase();
    if (normalized == 'gifts' || normalized == 'all') {
      return giftCatalog.toList();
    }
    final filtered = giftCatalog
        .where((gift) => (gift['category'] ?? '').toLowerCase() == normalized)
        .toList();
    return filtered.isNotEmpty ? filtered : giftCatalog.toList();
  }

  Future<void> loadEmojiCatalog() async {
    isLoadingEmojis.value = true;
    try {
      final response = await _emojiRepo.getEmojiCatalog(isShowLoader: false);
      final data = response?['data'];
      if (data is Map) {
        final version = int.tryParse(data['packVersion']?.toString() ?? '');
        if (version != null && version > 0) {
          emojiPackVersion.value = version;
        }
      }
      final parsed = _parseEmojiList(response?['data']);
      emojiCatalog.assignAll(parsed.isEmpty ? _fallbackEmojiCatalog() : parsed);
    } catch (_) {
      if (emojiCatalog.isEmpty) {
        emojiCatalog.assignAll(_fallbackEmojiCatalog());
      }
    } finally {
      isLoadingEmojis.value = false;
    }
  }

  List<Map<String, String>> _parseEmojiList(dynamic raw) {
    final list = raw is List
        ? raw
        : raw is Map
        ? (raw['emojis'] ?? raw['items'] ?? raw['list'])
        : null;
    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map((item) {
          final id = _readEmojiField(item, const ['id', '_id', 'emojiId']);
          final image = _readEmojiField(item, const [
            'image',
            'emojiImage',
            'gifUrl',
            'gif_url',
            'previewUrl',
            'preview_url',
            'url',
            'icon',
            'svg',
          ]);
          final code = _readEmojiField(item, const [
            'code',
            'unicode',
            'emoji',
          ]);
          return <String, String>{
            'id': id ?? '',
            'name':
                _readEmojiField(item, const ['name', 'title', 'label']) ??
                'Emoji',
            'image': image ?? code ?? '😊',
            'code': code ?? '',
            'packVersion':
                _readEmojiField(item, const ['packVersion', 'pack_version']) ??
                emojiPackVersion.value.toString(),
            'category':
                _readEmojiField(item, const ['category', 'type']) ?? 'emoji',
          };
        })
        .where((emoji) => (emoji['id'] ?? '').isNotEmpty)
        .toList();
  }

  List<Map<String, String>> _fallbackEmojiCatalog() {
    const seeds = [
      ('heart_eyes', 'Heart Eyes', '😍', 'expressive'),
      ('joy', 'Laughing Tears', '😂', 'expressive'),
      ('rose', 'Rose', '🌹', 'reaction'),
      ('fire', 'Fire', '🔥', 'trending'),
      ('clap', 'Clap', '👏', 'reaction'),
      ('heart', 'Heart', '❤️', 'reaction'),
      ('party', 'Party', '🥳', 'celebration'),
      ('sparkles', 'Sparkles', '✨', 'vip'),
    ];
    return seeds
        .map(
          (seed) => {
            'id': seed.$1,
            'name': seed.$2,
            'image': seed.$3,
            'code': seed.$3,
            'category': seed.$4,
          },
        )
        .toList();
  }

  String? _readEmojiField(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  void openEmojiSheet({String? receiverId, String? receiverName}) {
    final senderId = _currentUserId();
    if (senderId.isEmpty) {
      _showRoomToast(
        'Emoji not available',
        'Your user id is missing from the room member data.',
        isError: true,
      );
      return;
    }

    selectedEmojiReceiverId.value = receiverId?.trim();
    selectedEmojiReceiverName.value = receiverName?.trim().isNotEmpty == true
        ? receiverName!.trim()
        : null;

    if (emojiCatalog.isEmpty && !isLoadingEmojis.value) {
      unawaited(loadEmojiCatalog());
    }

    if (Get.isDialogOpen == true) Get.back<void>();
    if (Get.isBottomSheetOpen == true) Get.back<void>();

    Future.delayed(const Duration(milliseconds: 140), () {
      Get.bottomSheet(
        const EmojiPickerBottomSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.58),
      );
    });
  }

  Future<void> sendEmoji(Map<String, String> emoji) async {
    if (_emojiSendInFlight) return;

    final emojiId = emoji['id']?.trim() ?? '';
    final senderId = _currentUserId();
    final currentRoomId = audioRoomApiId.isNotEmpty
        ? audioRoomApiId
        : roomId.value.trim();
    final liveEmojiStreamId = liveStreamingApiId.trim();
    final targetSessionId = isLiveStreamingSession
        ? liveEmojiStreamId
        : currentRoomId;
    if (emojiId.isEmpty || senderId.isEmpty || targetSessionId.isEmpty) {
      _showRoomToast(
        'Emoji not sent',
        'Emoji, sender, or room id is missing.',
        isError: true,
      );
      return;
    }

    final clientReqId = 'emoji_${DateTime.now().microsecondsSinceEpoch}';
    final packVersion =
        int.tryParse(emoji['packVersion'] ?? '') ?? emojiPackVersion.value;
    final sessionType = isVideoRoom ? 'video_room' : 'audio_room';

    _emojiSendInFlight = true;
    try {
      final response = isLiveStreamingSession
          ? await _emojiRepo.sendLiveStreamingEmoji(
              liveStreamingId: liveEmojiStreamId,
              emojiId: emojiId,
              packVersion: packVersion,
              clientEventId: clientReqId,
            )
          : await _emojiRepo.sendRoomEmoji(
              roomId: currentRoomId,
              emojiId: emojiId,
              sessionType: sessionType,
              packVersion: packVersion,
              clientEventId: clientReqId,
            );

      if (!isEconomyApiSuccess(response)) {
        _showRoomToast(
          'Emoji not sent',
          response?['message']?.toString() ?? 'Unable to send this emoji.',
          isError: true,
        );
        return;
      }

      if (Get.isBottomSheetOpen == true) Get.back<void>();
      final sentEmoji = _emojiFromResponse(response) ?? Map.of(emoji);
      sentEmoji['packVersion'] = packVersion.toString();
      _showSeatEmojiReaction(senderId: senderId, emoji: sentEmoji);
      unawaited(_broadcastEmojiMarker(sentEmoji, clientReqId));
    } finally {
      _emojiSendInFlight = false;
    }
  }

  Map<String, String>? _emojiFromResponse(Map<String, dynamic>? response) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final data = asMap(response?['data']) ?? const <String, dynamic>{};
    final emoji =
        asMap(data['emoji']) ??
        asMap(response?['emoji']) ??
        asMap(data['data']);
    final source = emoji ?? data;

    final id = _readEmojiField(source, const ['id', '_id', 'emojiId']) ?? '';
    final image =
        _readEmojiField(source, const [
          'image',
          'emojiImage',
          'emoji_image',
          'gifUrl',
          'gif_url',
          'previewUrl',
          'preview_url',
          'url',
          'icon',
          'svg',
        ]) ??
        _readEmojiField(source, const ['code', 'unicode', 'emoji']) ??
        '😊';
    return {
      'id': id,
      'name':
          _readEmojiField(source, const [
            'name',
            'emojiName',
            'emoji_name',
            'title',
            'label',
          ]) ??
          'Emoji',
      'image': image,
      'code': _readEmojiField(source, const ['code', 'unicode', 'emoji']) ?? '',
      'packVersion':
          _readEmojiField(source, const ['packVersion', 'pack_version']) ??
          emojiPackVersion.value.toString(),
      'category':
          _readEmojiField(source, const ['category', 'type']) ?? 'emoji',
    };
  }

  Map<String, String>? seatEmojiFor(String userId) {
    final key = _seatEmojiKey(userId);
    if (key.isEmpty) return null;
    return activeSeatEmojis[key];
  }

  void _showSeatEmojiReaction({
    required String senderId,
    required Map<String, String> emoji,
  }) {
    final key = _seatEmojiKey(senderId);
    if (key.isEmpty) return;

    activeSeatEmojis[key] = Map<String, String>.from(emoji);
    _seatEmojiTimers.remove(key)?.cancel();
    _seatEmojiTimers[key] = Timer(const Duration(milliseconds: 2600), () {
      activeSeatEmojis.remove(key);
      _seatEmojiTimers.remove(key);
    });
  }

  String _seatEmojiKey(String userId) {
    final raw = userId.trim();
    if (raw.isEmpty) return '';
    return ZegoLiveIdUtils.sanitizeUserId(raw);
  }

  Future<void> _broadcastEmojiMarker(
    Map<String, String> emoji,
    String clientReqId,
  ) async {
    final label = _buildEmojiMarker(emoji: emoji, clientReqId: clientReqId);
    try {
      await ZegoUIKit().sendInRoomMessage(label);
    } catch (_) {
      // Socket events remain the primary delivery channel; Zego chat is fallback.
    }
  }

  String _buildEmojiMarker({
    required Map<String, String> emoji,
    required String clientReqId,
  }) {
    final fields = <String, String>{
      'clientReqId': clientReqId,
      'senderId': _currentUserId(),
      'roomId': audioRoomApiId.isNotEmpty ? audioRoomApiId : roomId.value,
      'emojiId': emoji['id'] ?? '',
      'code': emoji['code'] ?? '',
      'packVersion': emoji['packVersion'] ?? emojiPackVersion.value.toString(),
      'name': emoji['name'] ?? 'Emoji',
    };
    final marker = fields.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join(';');
    return '[emoji_anim:$marker]';
  }

  bool _isEmojiMarker(String message) {
    return message.contains('[emoji_anim:');
  }

  Map<String, String> _parseEmojiMarker(String message) {
    final start = message.indexOf('[emoji_anim:');
    if (start < 0) return const {};
    final end = message.indexOf(']', start);
    if (end < 0) return const {};
    final raw = message.substring(start + '[emoji_anim:'.length, end);
    final result = <String, String>{};
    for (final pair in raw.split(';')) {
      final equals = pair.indexOf('=');
      if (equals <= 0) continue;
      result[pair.substring(0, equals)] = Uri.decodeComponent(
        pair.substring(equals + 1),
      );
    }
    return result;
  }

  Map<String, String>? _emojiById(String emojiId) {
    final id = emojiId.trim();
    if (id.isEmpty) return null;
    for (final emoji in emojiCatalog) {
      if ((emoji['id'] ?? '').trim() == id) return emoji;
    }
    return null;
  }

  bool get canOpenZego => connectionIssue.value.isEmpty;

  Map<String, dynamic> get liveZegoStreamingData {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final nested =
        asMap(_roomData['room']) ??
        asMap(_roomData['liveStreaming']) ??
        asMap(_roomData['live_streaming']) ??
        const <String, dynamic>{};

    return asMap(_roomData['zegoStreaming']) ??
        asMap(_roomData['zego_streaming']) ??
        asMap(nested['zegoStreaming']) ??
        asMap(nested['zego_streaming']) ??
        const <String, dynamic>{};
  }

  int get liveZegoAppId {
    final zego = liveZegoStreamingData;
    final raw =
        zego['appId'] ??
        zego['appID'] ??
        zego['app_id'] ??
        _roomData['appId'] ??
        _roomData['appID'] ??
        _roomData['app_id'];
    final backendAppId = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (backendAppId == ZegoConfig.liveAppId) return backendAppId!;
    return ZegoConfig.liveAppId;
  }

  String get liveZegoAppSign {
    final sign = _liveZegoRawAppSign;
    final backendAppId =
        int.tryParse(
          (liveZegoStreamingData['appId'] ??
                  liveZegoStreamingData['appID'] ??
                  liveZegoStreamingData['app_id'] ??
                  '')
              .toString(),
        ) ??
        ZegoConfig.liveAppId;
    final backendMatchesMobileProject = backendAppId == ZegoConfig.liveAppId;
    return backendMatchesMobileProject && _isValidZegoAppSign(sign)
        ? sign
        : ZegoConfig.liveAppSign;
  }

  String get _liveZegoRawAppSign {
    final zego = liveZegoStreamingData;
    final value =
        zego['appSign'] ??
        zego['app_sign'] ??
        zego['appSignature'] ??
        _roomData['appSign'] ??
        _roomData['app_sign'];
    return value?.toString().trim() ?? '';
  }

  bool _isValidZegoAppSign(String value) {
    return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value.trim());
  }

  bool get liveZegoUseAppSignMode {
    final zego = liveZegoStreamingData;
    final raw =
        zego['appSignMode'] ??
        zego['app_sign_mode'] ??
        zego['useAppSignMode'] ??
        zego['use_app_sign_mode'] ??
        _roomData['appSignMode'] ??
        _roomData['app_sign_mode'] ??
        _roomData['useAppSignMode'] ??
        _roomData['use_app_sign_mode'];
    if (raw is bool) return raw;
    final text = raw?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;

    // Backend may return both AppSign and Token04 without an explicit mode flag.
    // In that case prefer AppSign mode; sending Token04 while token auth is off
    // in ZEGOCLOUD console causes room login failed (1001004).
    if (_isValidZegoAppSign(_liveZegoRawAppSign)) return true;
    return liveZegoToken.isEmpty;
  }

  bool get liveZegoUseTokenMode {
    // New ZEGOCLOUD live-streaming project is configured for AppSign mode.
    // Backend may still return stale/old Token04 values while it catches up;
    // using those tokens causes room auth failures like 1002033.
    if (_isValidZegoAppSign(liveZegoAppSign)) return false;

    final zego = liveZegoStreamingData;
    final raw =
        zego['tokenMode'] ??
        zego['token_mode'] ??
        zego['useTokenMode'] ??
        zego['use_token_mode'] ??
        zego['tokenAuthEnabled'] ??
        zego['token_auth_enabled'] ??
        _roomData['tokenMode'] ??
        _roomData['token_mode'] ??
        _roomData['useTokenMode'] ??
        _roomData['use_token_mode'] ??
        _roomData['tokenAuthEnabled'] ??
        _roomData['token_auth_enabled'];
    if (raw is bool) return raw;
    final text = raw?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return !liveZegoUseAppSignMode && liveZegoToken.isNotEmpty;
  }

  String get liveZegoUserId {
    final zego = liveZegoStreamingData;
    final value =
        zego['userId'] ??
        zego['user_id'] ??
        zego['zegoUserId'] ??
        zego['zego_user_id'] ??
        _roomData['userId'] ??
        _roomData['user_id'];
    final rawUserId = value?.toString().trim() ?? '';
    if (rawUserId.isNotEmpty && rawUserId != 'null') return rawUserId;

    final userId = ZegoLiveIdUtils.sanitizeUserId(rawUserId);
    if (userId.isNotEmpty) return userId;
    return _currentUserId();
  }

  String get liveZegoRoomId {
    final zego = liveZegoStreamingData;
    final zegoRoomId =
        (zego['roomId'] ??
                zego['room_id'] ??
                zego['liveId'] ??
                zego['live_id'] ??
                zego['zegoLiveId'] ??
                zego['zego_live_id'] ??
                zego['channelName'] ??
                zego['channel_name'])
            ?.toString()
            .trim();
    if (zegoRoomId != null && zegoRoomId.isNotEmpty && zegoRoomId != 'null') {
      return ZegoLiveIdUtils.sanitize(zegoRoomId);
    }
    return roomId.value.trim();
  }

  String get liveZegoToken {
    final zego = liveZegoStreamingData;
    final value =
        zego['token'] ??
        zego['zegoToken'] ??
        zego['zego_token'] ??
        _roomData['zegoToken'] ??
        _roomData['zego_token'];
    return value?.toString().trim() ?? '';
  }

  String get liveHostStreamId {
    final zego = liveZegoStreamingData;
    final value =
        zego['hostStreamId'] ??
        zego['host_stream_id'] ??
        zego['playStreamId'] ??
        zego['play_stream_id'] ??
        zego['streamId'] ??
        zego['stream_id'] ??
        _roomData['hostStreamId'] ??
        _roomData['host_stream_id'];
    final streamId = value?.toString().trim() ?? '';
    if (streamId.isNotEmpty) return streamId;
    return _fallbackLiveStreamId(_resolvedHostId());
  }

  String get livePublishStreamId {
    final zego = liveZegoStreamingData;
    final value =
        zego['publishStreamId'] ??
        zego['publish_stream_id'] ??
        zego['streamId'] ??
        zego['stream_id'] ??
        zego['zegoStreamId'] ??
        zego['zego_stream_id'] ??
        _roomData['publishStreamId'] ??
        _roomData['publish_stream_id'];
    final streamId = value?.toString().trim() ?? '';
    if (streamId.isNotEmpty) return streamId;
    return _fallbackLiveStreamId(_currentUserId());
  }

  String get livePlayStreamId {
    final zego = liveZegoStreamingData;
    final value =
        zego['playStreamId'] ??
        zego['play_stream_id'] ??
        zego['hostStreamId'] ??
        zego['host_stream_id'] ??
        zego['streamId'] ??
        zego['stream_id'] ??
        _roomData['playStreamId'] ??
        _roomData['play_stream_id'] ??
        _roomData['hostStreamId'] ??
        _roomData['host_stream_id'];
    final streamId = value?.toString().trim() ?? '';
    if (streamId.isNotEmpty) return streamId;
    return _fallbackLiveStreamId(_resolvedHostId());
  }

  String _fallbackLiveStreamId(String userId) {
    final room = liveZegoRoomId.trim();
    final user = ZegoLiveIdUtils.sanitizeUserId(userId);
    if (room.isEmpty || user.isEmpty) return '';
    return 'stream_${room}_$user';
  }

  void setConnectionIssue(String message) {
    connectionIssue.value = message;
  }

  void clearConnectionIssue() {
    if (connectionIssue.value.isEmpty) return;
    connectionIssue.value = '';
  }

  /// Live streaming (one-to-many Zego live) — not an audio/video party room.
  bool get isLiveStreamingSession {
    final nav = _normalizedNavRoomType;
    if (nav == 'LIVE_STREAM' || nav == 'LIVESTREAM') return true;
    return _isLiveStreamPayloadType(
      readRoomField(_roomData, ['type', 'roomType'])?.toLowerCase(),
    );
  }

  /// Video party room (group call with camera) — false for audio rooms and
  /// true for live streams only so the live overlay hides the audio stage.
  bool get isVideoRoom {
    if (isLiveStreamingSession) return true;
    if (!isAudioVideoRoom) return roomType.value.toUpperCase() != 'AUDIO';
    if (_normalizedNavRoomType == 'AUDIO') return false;
    if (_normalizedNavRoomType == 'VIDEO') return true;
    final payloadType = readRoomField(_roomData, [
      'type',
      'roomType',
    ])?.toLowerCase();
    return payloadType != 'audio';
  }

  /// Audio / video party rooms use Zego group-call UI — never live streaming.
  bool get isAudioVideoRoom => _isAudioVideoRoomPayload();

  bool get isAudioRoom => isAudioVideoRoom && !isVideoRoom;

  bool get isGroupCallRoom => isAudioVideoRoom;

  /// True when the logged-in user occupies a mic seat marked admin by
  /// `GET /api/room/seats` (`isAdmin: true`).
  bool get isCurrentUserRoomAdmin {
    final myId = _currentUserId();
    if (myId.isEmpty) return false;
    for (final seat in audioRoomSeats) {
      if (!seat.occupied || !seat.isAdmin) continue;
      if (_userIdsMatch(seat.userId, myId)) return true;
    }
    return false;
  }

  /// Host or room admin — can mute/kick/manage members and change background.
  bool get canManageAudioRoomMembers => isHost.value || isCurrentUserRoomAdmin;

  String get _normalizedNavRoomType =>
      roomType.value.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');

  /// Gift icon stays visible for host and audience even when alone.
  /// Send is still gated by [hasGiftAudience] inside [sendGift].
  bool get canSendGifts => true;

  /// Party-room gifts credit **mic seats only** (not floor audience).
  List<String> _roomGiftRecipientIds({String? excludeUserId}) {
    if (isAudioVideoRoom) {
      return _seatedGiftRecipientIds(excludeUserId: excludeUserId);
    }
    final exclude = excludeUserId?.trim() ?? '';
    final ids = <String>[];
    void addId(String raw) {
      final id = raw.trim();
      if (id.isEmpty) return;
      if (exclude.isNotEmpty && _userIdsMatch(id, exclude)) return;
      if (ids.any((existing) => _userIdsMatch(existing, id))) return;
      ids.add(id);
    }

    final hostId = receiverId.value.trim();
    if (hostId.isNotEmpty) addId(hostId);
    for (final viewer in liveViewers) {
      addId((viewer['targetId'] ?? viewer['id'])?.toString() ?? '');
    }
    return ids;
  }

  bool get hasGiftAudience {
    if (isAudioVideoRoom) {
      return _seatedGiftRecipientIds(
        excludeUserId: _currentUserId(),
      ).isNotEmpty;
    }
    if (hasOtherParticipantsBesideHost) return true;
    // Live-stream guest already joined — host is the receive target.
    if (!isHost.value) return true;
    return false;
  }

  /// Seated user ids that can receive a room gift (non-empty id, not [excludeUserId]).
  List<String> _seatedGiftRecipientIds({String? excludeUserId}) {
    final exclude = excludeUserId?.trim() ?? '';
    final ids = <String>[];
    for (final seat in audioRoomSeats) {
      final id = seat.userId.trim();
      if (id.isEmpty) continue;
      if (!seat.occupied) continue;
      if (exclude.isNotEmpty && _userIdsMatch(id, exclude)) continue;
      if (ids.any((existing) => _userIdsMatch(existing, id))) continue;
      ids.add(id);
    }
    return ids;
  }

  /// True when at least one non-host person is present (seat, viewer, or Zego user).
  bool get hasOtherParticipantsBesideHost {
    if (viewerCount.value > 1) return true;

    for (final viewer in liveViewers) {
      if (viewer['isHost'] == true) continue;
      return true;
    }

    final hostId = receiverId.value.trim();
    for (final seat in audioRoomSeats) {
      if (!seat.occupied) continue;
      if (seat.isHost) continue;
      if (hostId.isNotEmpty && _userIdsMatch(seat.userId, hostId)) continue;
      return true;
    }

    return false;
  }

  /// Zego can emit call-end lifecycle events during participant changes.
  /// Hosts may leave the route only after explicitly confirming room end.
  bool get canProcessGroupCallEnd =>
      !isHost.value || (_hostEndConfirmed && _exitReported);

  String get giftTargetLabel {
    if (isRoomGiftMode.value) return 'Everyone in this room';
    final name = selectedGiftReceiverName.value?.trim();
    return name?.isNotEmpty == true ? name! : hostName.value;
  }

  String get giftSheetDescription => isRoomGiftMode.value
      ? (isAudioVideoRoom
            ? 'Shared equally with others on a mic seat after a 20% fee. You are not included.'
            : 'Shared equally with everyone else in this live after a 20% fee. You are not included.')
      : 'Sent to $giftTargetLabel. They receive 80% after a 20% platform fee.';

  /// Called after Zego room login — ensures host camera publishes and binds chat/users.
  void onZegoRoomLogined() {
    isZegoConnected.value = true;
    _bindZegoListeners();
    _refreshHostZegoUserId();

    if (isLiveStreamingSession) return;
    if (!isHost.value || !isVideoRoom) return;
    _turnOnHostMedia();
    Future.delayed(const Duration(milliseconds: 700), _turnOnHostMedia);
  }

  void onExpressLiveRoomLogined() {
    isZegoConnected.value = true;
    clearConnectionIssue();
  }

  void onExpressLiveRoomDisconnected(String message) {
    isZegoConnected.value = false;
    setConnectionIssue(message);
  }

  void _turnOnHostMedia() {
    try {
      final av = ZegoUIKitPrebuiltLiveStreamingController().audioVideo;
      av.camera.turnOn(true);
      av.microphone.turnOn(true);
      isCameraOff.value = false;
      isMicMuted.value = false;
    } catch (_) {
      // Zego controller not ready yet — turnOnCameraWhenJoining handles it.
    }
  }

  void _bindZegoListeners() {
    final zego = ZegoUIKitPrebuiltLiveStreamingController();

    // Listen on the base UIKit message bus instead of the prebuilt facade
    // (`zego.message.stream()`): the facade's internal relay can bind before
    // the Zego core streams exist (engine re-init between room/live App IDs),
    // which silently drops peer chat + gift events for everyone in the live.
    // Binding here is safe because this runs after the room is logged in.
    _messageSub?.cancel();
    final kit = ZegoUIKit();
    _messageSub = kit.getInRoomMessageListStream().listen(_syncChatFromZego);
    _syncChatFromZego(kit.getInRoomMessages());

    _userSub?.cancel();
    _mediaSub?.cancel();
    _userSub = zego.user.stream(includeFakeUser: false).listen(_syncViewers);
    _mediaSub = kit.getAudioVideoListStream().listen((_) {
      zegoMediaUsersTick.value++;
    });

    if (_viewerCountListener != null) {
      zego.user.countNotifier.removeListener(_viewerCountListener!);
    }
    _viewerCountListener = _onViewerCountChanged;
    zego.user.countNotifier.addListener(_viewerCountListener!);
    _onViewerCountChanged();

    Future.microtask(() {
      try {
        _syncViewers(ZegoUIKit().getAllUsers());
      } catch (_) {}
    });
  }

  /// Group-call rooms share the same Zego message bus but not the live-stream
  /// controller facade. Subscribe through the base UIKit for peer gift events.
  void _bindGroupCallMessageListener() {
    _messageSub?.cancel();
    final zego = ZegoUIKit();
    _messageSub = zego.getInRoomMessageListStream().listen(_syncChatFromZego);
    _syncChatFromZego(zego.getInRoomMessages());
  }

  void _onViewerCountChanged() {
    viewerCount.value =
        ZegoUIKitPrebuiltLiveStreamingController().user.countNotifier.value;
  }

  /// Keeps the Zego host id in sync for [LiveHostVideoFill] on audience devices.
  void _refreshHostZegoUserId([List<ZegoUIKitUser>? users]) {
    if (!isLiveStreamingSession) return;

    final payloadHost = ZegoLiveIdUtils.sanitizeUserId(_resolvedHostId());
    if (payloadHost.isNotEmpty) {
      hostZegoUserId.value = payloadHost;
      return;
    }

    try {
      final localId = ZegoUIKit().getLocalUser().id;
      final avUsers = users ?? ZegoUIKit().getAudioVideoList();
      for (final user in avUsers) {
        if (user.id == localId) continue;
        hostZegoUserId.value = ZegoLiveIdUtils.sanitizeUserId(user.id);
        return;
      }
      final allUsers = users ?? ZegoUIKit().getAllUsers();
      for (final user in allUsers) {
        if (user.id == localId) continue;
        hostZegoUserId.value = ZegoLiveIdUtils.sanitizeUserId(user.id);
        return;
      }
    } catch (_) {}
  }

  void _syncViewers(List<ZegoUIKitUser> users) {
    _refreshHostZegoUserId(users);
    final normalizedHostId = ZegoLiveIdUtils.sanitizeUserId(
      hostZegoUserId.value.isNotEmpty ? hostZegoUserId.value : receiverId.value,
    );
    final hostTargetId = receiverId.value.trim();
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final mySanitized = ZegoLiveIdUtils.sanitizeUserId(
      session?.userId.isNotEmpty == true ? session!.userId : '',
    );

    zegoMediaUsersTick.value++;
    liveViewers.assignAll(
      users.map((user) {
        final normalizedUserId = ZegoLiveIdUtils.sanitizeUserId(user.id);
        final isHost =
            normalizedHostId.isNotEmpty && normalizedUserId == normalizedHostId;
        final isCurrentUser =
            mySanitized.isNotEmpty && normalizedUserId == mySanitized;
        return <String, dynamic>{
          'id': user.id,
          'targetId': isHost && hostTargetId.isNotEmpty
              ? hostTargetId
              : user.id,
          'name': user.name.isNotEmpty ? user.name : 'Viewer',
          'avatarUrl': isHost ? hostAvatarUrl.value : null,
          'isHost': isHost,
          'isCurrentUser': isCurrentUser,
        };
      }),
    );
    _syncPkLocalAudience();
  }

  void _syncChatFromZego(List<ZegoInRoomMessage> messages) {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final myId = ZegoLiveIdUtils.sanitizeUserId(
      session?.userId.isNotEmpty == true
          ? session!.userId
          : 'user_${session?.hashCode ?? 0}',
    );

    chatMessages.assignAll(
      messages
          .where((message) => !_isEmojiMarker(message.message))
          .map((message) => _mapZegoMessage(message, myId)),
    );

    // When someone else shares a gift in the room, play the celebration.
    _maybeCelebrateIncomingGift(messages, myId);
    _maybeCelebrateIncomingEmoji(messages, myId);
  }

  /// Plays the gift SVGA/sound for peer (non-self) gift chat events in any room
  /// (audio, video, live stream). Same protocol as 1:1 calls.
  void _maybeCelebrateIncomingGift(
    List<ZegoInRoomMessage> messages,
    String myUserId,
  ) {
    _giftCelebrationTracker.onGiftMessages(
      myUserId: myUserId,
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
        unawaited(
          _handlePeerGiftEarnings(event.message, senderId: event.senderId),
        );
      },
    );
  }

  void _maybeCelebrateIncomingEmoji(
    List<ZegoInRoomMessage> messages,
    String myUserId,
  ) {
    for (final message in messages) {
      final text = message.message;
      if (!_isEmojiMarker(text)) continue;
      final marker = _parseEmojiMarker(text);
      if (marker.isEmpty) continue;

      final senderId = marker['senderId'] ?? message.user.id;
      if (_userIdsMatch(senderId, myUserId)) continue;

      final key =
          marker['clientReqId'] ??
          '${message.messageID}_${message.timestamp}_$senderId';
      if (!_playedEmojiEventKeys.add(key)) continue;

      final emoji =
          _emojiById(marker['emojiId'] ?? '') ??
          {
            'id': marker['emojiId'] ?? '',
            'name': marker['name'] ?? 'Emoji',
            'image': marker['code']?.isNotEmpty == true
                ? marker['code']!
                : '😊',
            'code': marker['code'] ?? '',
            'category': 'emoji',
          };
      _showSeatEmojiReaction(senderId: senderId, emoji: emoji);
    }
  }

  /// Updates seat diamonds + local session earnings when a peer gift arrives.
  Future<void> _handlePeerGiftEarnings(
    String chatMessage, {
    required String senderId,
  }) async {
    final scope = parseGiftScope(chatMessage);
    final receiverId = parseGiftReceiverId(chatMessage);
    final fromId = parseGiftSenderId(chatMessage) ?? senderId;
    final price =
        parseGiftPrice(chatMessage) ??
        _giftPriceFromCatalogMessage(chatMessage);
    final creditedIds = parseGiftCreditedUserIds(chatMessage);
    final amountEach = parseGiftAmountEach(chatMessage);
    final creditAmount = GiftShareEconomics.creditAmount(
      coinsSpent: price,
      isRoomShare: scope == 'room',
      recipientCount: creditedIds.isNotEmpty
          ? creditedIds.length
          : _roomGiftRecipientIds(excludeUserId: fromId).length,
      apiAmountEach: amountEach,
    );

    // Room → seated users only (or credited_user_ids when present).
    if (creditAmount > 0) {
      _bumpSeatDiamonds(
        scope: scope,
        receiverId: receiverId,
        amount: creditAmount,
        excludeUserId: fromId,
        creditedUserIds: creditedIds,
      );
    }
    if (isAudioVideoRoom) {
      unawaited(loadAudioRoomSeats());
    }

    final hostEarns = _hostEarnsGift(
      scope: scope,
      receiverId: receiverId,
      senderId: fromId,
      creditedUserIds: creditedIds,
    );
    var hostEarned = 0;
    if (hostEarns && !_exitReported) {
      if (!isAudioVideoRoom) {
        final before = sessionEarnings.displayCoins;
        hostEarned = SessionEarningsUtils.ingestIncomingGiftChat(
          tracker: sessionEarnings,
          chatMessage: chatMessage,
          giftCatalog: giftCatalog.toList(),
          earnsGift: true,
        );
        if (hostEarned <= 0 && creditAmount > 0) {
          sessionEarnings.applyDelta(coins: creditAmount);
          hostEarned = creditAmount;
        } else if (hostEarned <= 0) {
          await _refreshSessionEarnings();
          hostEarned = sessionEarnings.displayCoins - before;
        }
      } else {
        hostEarned = creditAmount;
      }
    }

    unawaited(
      _playGiftCoinFliesAfterCelebration(
        hostEarnedCoins: hostEarned > 0
            ? hostEarned
            : (hostEarns && creditAmount > 0 ? creditAmount : 0),
        audienceUserIds: _creditedAudienceSeatUserIds(
          scope: scope,
          receiverId: receiverId,
          excludeUserId: fromId,
          creditedUserIds: creditedIds,
        ),
        amountEach: creditAmount,
      ),
    );
  }

  int _giftPriceFromCatalogMessage(String chatMessage) {
    final name = GiftMediaUtils.giftNameFromChatLabel(
      chatMessage,
    ).toLowerCase();
    if (name.isNotEmpty && name != 'gift') {
      for (final gift in giftCatalog) {
        if ((gift['name'] ?? '').trim().toLowerCase() == name) {
          return int.tryParse(gift['price'] ?? '0') ?? 0;
        }
      }
    }
    return 0;
  }

  Map<String, dynamic> _mapZegoMessage(
    ZegoInRoomMessage message,
    String myUserId,
  ) {
    final senderName = message.user.name.isNotEmpty
        ? message.user.name
        : 'Viewer';
    final isMine = message.user.id == myUserId;
    final text = message.message;
    final isGift = text.startsWith('🎁 ');

    return {
      'sender': isMine ? 'You' : senderName,
      // Hide the embedded animation marker from the chat bubble.
      'message': isGift ? stripGiftAnimMarker(text) : text,
      'translation': '',
      'isTranslated': false,
      'isSystem': isGift,
    };
  }

  void handleZegoLoginFailed(int errorCode) {
    isZegoConnected.value = false;
    connectionIssue.value =
        'Could not join live room (error $errorCode). '
        'Verify Zego App ID / App Sign in the console.';
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    _showRoomToast('Live stream', connectionIssue.value, isError: true);
  }

  void onGroupCallRoomConnected({bool bindMessages = true}) {
    isZegoConnected.value = true;
    if (connectionIssue.value.isNotEmpty) {
      connectionIssue.value = '';
    }
    if (bindMessages) {
      _bindGroupCallMessageListener();
    }
    _bindGroupCallUserListener();
  }

  /// Keep viewer/participant count reactive for gift visibility in video rooms.
  void _bindGroupCallUserListener() {
    _userSub?.cancel();
    _mediaSub?.cancel();
    try {
      final kit = ZegoUIKit();
      _syncGroupCallUsers(kit.getAllUsers());
      _userSub = kit.getUserListStream().listen(_syncGroupCallUsers);
      _mediaSub = kit.getAudioVideoListStream().listen((_) {
        zegoMediaUsersTick.value++;
      });
    } catch (_) {
      // Zego user stream may not be ready yet on first connect.
    }
  }

  void _syncGroupCallUsers(List<ZegoUIKitUser> users) {
    viewerCount.value = users.length;
    zegoMediaUsersTick.value++;
    _syncViewers(users);
  }

  void handleGroupCallRoomLoginFailed(int errorCode) {
    if (isZegoConnected.value) return;
    _showGroupCallLoginError(errorCode: errorCode);
  }

  void handleGroupCallRoomError(ZegoUIKitError error) {
    final method = error.method.toLowerCase();
    final isLoginError =
        error.code == ZegoUIKitErrorCode.roomLoginError ||
        method.contains('loginroom') ||
        method.contains('joinroom');

    // The prebuilt call error stream also reports participant media/device
    // errors. Those are not local room-login failures and must not alarm hosts.
    if (!isLoginError || isZegoConnected.value) return;
    _showGroupCallLoginError(errorCode: error.code);
  }

  void _showGroupCallLoginError({required int errorCode}) {
    isZegoConnected.value = false;
    connectionIssue.value =
        'Could not join room (error $errorCode). Please try again.';
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    _showRoomToast('Room call', connectionIssue.value, isError: true);
  }

  void _validateStreamingInput() {
    final liveId = roomId.value.trim();
    if (liveId.isEmpty || liveId == 'test_room' || liveId == 'null') {
      connectionIssue.value = isGroupCallRoom
          ? 'Room id is missing. Please ask backend to return room_id, roomId, zegoLiveId, or channelName.'
          : 'Live stream id is missing. Please ask backend to return zegoLiveId or channelName for this room.';
      return;
    }

    // Hosts publish live streams on the backend room id, so audience payloads
    // that only carry a backend room id can still join the right Zego channel.
    connectionIssue.value = '';
  }

  String? _extractStreamingId(Map<String, dynamic> roomData) {
    const keys = [
      'zegoLiveId',
      'zego_live_id',
      'zegoRoomId',
      'zego_room_id',
      'channelName',
      'channel_name',
      'liveStreamingId',
      'livestreamingId',
      'live_streaming_id',
      'liveStreamId',
      'live_id',
      'liveId',
    ];

    return _firstNonEmpty(roomData, keys);
  }

  String? _extractBackendRoomId(Map<String, dynamic> roomData) {
    const keys = ['room_id', 'roomId', '_id', 'id'];

    return _firstNonEmpty(roomData, keys);
  }

  String? _extractReceiverId(Map<String, dynamic> roomData) {
    return resolveHostId(roomData);
  }

  String? _firstNonEmpty(Map<String, dynamic> roomData, List<String> keys) {
    return readRoomField(roomData, keys);
  }

  /// WhatsApp-status-style heart burst (live streaming only).
  void triggerHeartReaction() {
    if (!isLiveStreamingSession) return;
    _heartReactionSeq++;
    heartReactionTokens.add(_heartReactionSeq);
    // Spawn a small cluster per tap, like status reactions.
    for (var i = 0; i < 2; i++) {
      Future<void>.delayed(Duration(milliseconds: 90 * (i + 1)), () {
        if (!isClosed) {
          _heartReactionSeq++;
          heartReactionTokens.add(_heartReactionSeq);
        }
      });
    }
  }

  void removeHeartReactionToken(int token) {
    heartReactionTokens.remove(token);
  }

  Future<void> sendMessage() async {
    final text = chatTextController.text.trim();
    if (text.isEmpty) return;

    final badWords = ['bad', 'scam', 'spam', 'abuse', 'hate', 'cheat', 'fraud'];
    var moderatedText = text;
    var containsBadWord = false;

    for (final word in badWords) {
      if (moderatedText.toLowerCase().contains(word)) {
        containsBadWord = true;
        final replacement = '*' * word.length;
        moderatedText = moderatedText.replaceAll(
          RegExp(word, caseSensitive: false),
          replacement,
        );
      }
    }

    chatTextController.clear();

    if (!isZegoConnected.value) {
      chatMessages.add({
        'sender': 'You',
        'message': moderatedText,
        'translation': '',
        'isTranslated': false,
        'isSystem': false,
      });
      return;
    }

    try {
      // Group-call (audio/video) rooms have no live-streaming facade mounted,
      // so their chat must go through the base UIKit message bus directly.
      final sent = isLiveStreamingSession
          ? await _sendExpressLiveMessage(moderatedText)
          : isGroupCallRoom
          ? await ZegoUIKit().sendInRoomMessage(moderatedText)
          : await ZegoUIKitPrebuiltLiveStreamingController().message.send(
              moderatedText,
            );
      if (!sent) {
        _showRoomToast(
          'Message not sent',
          'Unable to send message to the room.',
          isError: true,
        );
      }
    } catch (_) {
      _showRoomToast(
        'Message not sent',
        'Chat is not ready yet. Please try again.',
        isError: true,
      );
    }

    if (containsBadWord) {
      _showRoomToast(
        'Moderation Filter',
        'Your comment was automatically filtered to keep the room safe.',
        isWarning: true,
      );
    }
  }

  Future<bool> _sendExpressLiveMessage(String message) async {
    final room = liveZegoRoomId.trim();
    if (room.isEmpty) return false;
    final result = await ZegoExpressEngine.instance.sendBroadcastMessage(
      room,
      message,
    );
    final sent = result.errorCode == 0;
    if (sent) {
      chatMessages.add({
        'sender': 'You',
        'message': message,
        'translation': '',
        'isTranslated': false,
        'isSystem': false,
      });
    }
    return sent;
  }

  void receiveExpressLiveMessages(List<ZegoBroadcastMessageInfo> messages) {
    if (messages.isEmpty) return;
    final localId = ZegoLiveIdUtils.sanitizeUserId(_currentUserId());
    final incoming = <Map<String, dynamic>>[];
    for (final message in messages) {
      final senderId = ZegoLiveIdUtils.sanitizeUserId(message.fromUser.userID);
      if (senderId.isNotEmpty && senderId == localId) continue;
      incoming.add({
        'sender': message.fromUser.userName.trim().isEmpty
            ? 'Viewer'
            : message.fromUser.userName.trim(),
        'message': message.message,
        'translation': '',
        'isTranslated': false,
        'isSystem': false,
      });
    }
    if (incoming.isNotEmpty) {
      chatMessages.addAll(incoming);
    }
  }

  Future<void> translateMessage(int index) async {
    if (index < 0 || index >= chatMessages.length) return;
    final msg = chatMessages[index];
    final text = msg['message']?.toString() ?? '';
    if (text.isEmpty || msg['isSystem'] == true) return;

    if (msg['translation'] != null &&
        msg['translation'].toString().isNotEmpty) {
      final currentVal = msg['isTranslated'] ?? false;
      chatMessages[index] = {...msg, 'isTranslated': !currentVal};
      return;
    }

    try {
      final response = await _roomRepo.translateText(
        text: text,
        targetLang: 'en',
        isShowLoader: false,
      );
      final translated =
          response?['data']?['translatedText']?.toString() ??
          response?['data']?['text']?.toString();
      if (translated != null && translated.isNotEmpty) {
        chatMessages[index] = {
          ...msg,
          'translation': translated,
          'isTranslated': true,
        };
        return;
      }
    } catch (_) {}

    _showRoomToast(
      'Translation',
      'This message is already in your native language.',
      isWarning: true,
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
                (raw) => GiftMediaUtils.mapGiftFromApi(
                  Map<String, dynamic>.from(raw),
                ),
              )
              .where((gift) => (gift['id'] ?? '').isNotEmpty)
              .toList(),
        );
      }
    } finally {
      isLoadingGifts.value = false;
    }
  }

  Future<void> sendGift(Map<String, String> gift, {int comboCount = 1}) async {
    if (_giftSendInFlight) return;
    final count = comboCount < 1 ? 1 : comboCount;
    final int price = int.tryParse(gift['price'] ?? '0') ?? 0;
    final totalCost = price * count;
    if (coinsBalance.value < totalCost) {
      _showRoomToast(
        'Insufficient Coins',
        'You need ${totalCost - coinsBalance.value} more coins to send this gift.',
        isError: true,
      );
      return;
    }

    final giftId = gift['id']?.trim() ?? '';
    // Backend gift API needs the real room id (with dashes), not the
    // sanitized Zego channel id.
    final currentRoomId = audioRoomApiId.isNotEmpty
        ? audioRoomApiId
        : roomId.value.trim();
    final scope = isRoomGiftMode.value ? 'room' : 'user';
    final currentReceiverId = scope == 'room'
        ? ''
        : (selectedGiftReceiverId.value?.trim().isNotEmpty == true
              ? selectedGiftReceiverId.value!.trim()
              : receiverId.value.trim());

    // Keep seats fresh so room-gift gating matches backend seated recipients.
    if (scope == 'room' && isAudioVideoRoom) {
      await loadAudioRoomSeats(showErrors: false);
    }

    final myId = _currentUserId();
    final seatedRecipients = scope == 'room'
        ? _roomGiftRecipientIds(excludeUserId: myId)
        : const <String>[];

    // Share-to-all: sender pays the catalog price once; 80% is split among others.
    if (scope == 'room') {
      if (seatedRecipients.isEmpty) {
        _showRoomToast(
          'No audience',
          isAudioVideoRoom
              ? 'No other seated users can receive this gift. Wait until someone is on a mic seat.'
              : "There's no audience to share gifts. Please wait for someone to join",
          isWarning: true,
        );
        return;
      }
    }

    if (giftId.isEmpty ||
        currentRoomId.isEmpty ||
        (scope == 'user' && currentReceiverId.isEmpty)) {
      _showRoomToast(
        'Gift not sent',
        scope == 'room'
            ? 'Gift or room id is missing from live room data.'
            : 'Gift, receiver, or room id is missing from live room data.',
        isError: true,
      );
      return;
    }

    final sessionType = isAudioVideoRoom
        ? (isVideoRoom ? 'video_room' : 'audio_room')
        : 'live_stream';

    _giftSendInFlight = true;
    var sent = 0;
    try {
      for (var i = 0; i < count; i++) {
        var response = await _economyRepo.sendGift(
          receiverId: scope == 'room' ? null : currentReceiverId,
          giftId: giftId,
          roomId: currentRoomId,
          scope: scope,
          seatedUserIds: scope == 'room' ? seatedRecipients : null,
          sessionType: sessionType,
          isShowLoader: i == 0,
        );

        // Backend `scope=room` often ignores seatedUserIds and says no seats even
        // when we sent them. One other seated user == individual gift economically
        // (80% to that person). Do not fan-out N user gifts — that charges N× price.
        if (!isEconomyApiSuccess(response) &&
            scope == 'room' &&
            seatedRecipients.length == 1 &&
            _isNoSeatedUsersGiftError(response)) {
          response = await _economyRepo.sendGift(
            receiverId: seatedRecipients.first,
            giftId: giftId,
            roomId: currentRoomId,
            scope: 'user',
            sessionType: sessionType,
            isShowLoader: false,
          );
        }

        if (!isEconomyApiSuccess(response)) {
          _showRoomToast(
            sent == 0 ? 'Gift not sent' : 'Combo stopped',
            sent == 0
                ? (response?['message']?.toString() ??
                      'Unable to send this gift.')
                : 'Sent $sent of $count. ${response?['message'] ?? 'Unable to send the rest.'}',
            isError: true,
          );
          break;
        }

        sent++;
        await _handleGiftSendSuccess(
          gift: gift,
          price: price,
          scope: scope,
          myId: myId,
          currentReceiverId: currentReceiverId,
          response: response,
          creditedFallbackIds: seatedRecipients,
          playCelebration: false,
          comboIndex: sent,
          comboTotal: count,
        );

        // Sender overlay: close the sheet on the first hit, then queue N SVGA
        // plays so they stay in sync with the peer broadcasts above.
        if (sent == 1) {
          if (Get.isBottomSheetOpen == true) {
            Get.back<void>();
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        GiftMediaUtils.showCelebration(
          giftName: gift['name'],
          animationUrl: GiftMediaUtils.animationUrlFromResponse(response, gift),
          soundUrl: GiftMediaUtils.soundUrlFromResponse(response, gift),
          enqueueIfBusy: sent > 1,
        );
      }
    } finally {
      _giftSendInFlight = false;
    }
  }

  bool _isNoSeatedUsersGiftError(Map<String, dynamic>? response) {
    final message = (response?['message'] ?? '').toString().toLowerCase();
    return message.contains('no seated user');
  }

  Future<void> _handleGiftSendSuccess({
    required Map<String, String> gift,
    required int price,
    required String scope,
    required String myId,
    required String currentReceiverId,
    required Map<String, dynamic>? response,
    List<String> creditedFallbackIds = const [],
    bool playCelebration = true,
    int comboIndex = 1,
    int comboTotal = 1,
  }) async {
    final beforeEarnings = sessionEarnings.displayCoins;
    // Direct gifts only — room gifts credit peers via the chat broadcast.
    _applySessionEarningsFromGiftResponse(
      response: response,
      fallbackGiftPrice: price,
      scope: scope,
      receiverId: currentReceiverId.isEmpty ? null : currentReceiverId,
    );

    var creditedIds = _parseCreditedUserIdsFromGiftResponse(response);
    if (creditedIds.isEmpty &&
        scope == 'room' &&
        creditedFallbackIds.isNotEmpty) {
      creditedIds = creditedFallbackIds;
    }
    final amountEachFromApi = _parseAmountEachFromGiftResponse(response);
    final creditAmount = GiftShareEconomics.creditAmount(
      coinsSpent: price,
      isRoomShare: scope == 'room',
      recipientCount: creditedIds.isNotEmpty
          ? creditedIds.length
          : (scope == 'room' ? creditedFallbackIds.length : 1),
      apiAmountEach: amountEachFromApi,
    );
    final amountEach = creditAmount;

    // Room → seated users only; user → targeted seat.
    _bumpSeatDiamonds(
      scope: scope,
      receiverId: currentReceiverId.isEmpty ? null : currentReceiverId,
      amount: creditAmount,
      excludeUserId: myId,
      creditedUserIds: creditedIds,
    );
    final earnedDelta = (sessionEarnings.displayCoins - beforeEarnings).clamp(
      0,
      1 << 30,
    );
    if (isAudioVideoRoom) {
      unawaited(loadAudioRoomSeats());
    }

    final animationUrl = GiftMediaUtils.animationUrlFromResponse(
      response,
      gift,
    );
    final soundUrl = GiftMediaUtils.soundUrlFromResponse(response, gift);

    if (playCelebration) {
      // Same timing as audio rooms for video / live / group: close the sheet
      // first so it never covers the SVGA celebration on either side.
      unawaited(
        GiftMediaUtils.dismissSheetThenCelebrate(
          giftName: gift['name'],
          animationUrl: animationUrl,
          soundUrl: soundUrl,
        ),
      );
    }

    // Host AppBar fly stays the same. Audience credits land on their seats.
    unawaited(
      _playGiftCoinFliesAfterCelebration(
        hostEarnedCoins: playCelebration ? earnedDelta : 0,
        audienceUserIds: _creditedAudienceSeatUserIds(
          scope: scope,
          receiverId: currentReceiverId.isEmpty ? null : currentReceiverId,
          excludeUserId: myId,
          creditedUserIds: creditedIds,
        ),
        amountEach: amountEach,
      ),
    );

    unawaited(loadWalletBalance());

    // Broadcast gift markers so every peer in the Zego room can celebrate.
    final giftLabel = GiftMediaUtils.buildChatLabel(
      giftName: gift['name'],
      giftIcon: gift['icon'],
      animationUrl: animationUrl,
      soundUrl: soundUrl,
      scope: scope,
      senderId: myId,
      receiverId: scope == 'room' ? null : currentReceiverId,
      giftId: gift['id'],
      giftPrice: price,
      creditedUserIds: creditedIds,
      amountEach: amountEach,
      comboIndex: comboIndex,
      comboTotal: comboTotal,
    );
    // Await so peers receive each combo hit (Zego drops unawaited bursts).
    try {
      final sentOk = await ZegoUIKit().sendInRoomMessage(giftLabel);
      if (!sentOk) {
        chatMessages.add({
          'sender': 'You',
          'message': stripGiftAnimMarker(giftLabel),
          'translation': '',
          'isTranslated': false,
          'isSystem': true,
        });
      }
    } catch (_) {
      chatMessages.add({
        'sender': 'You',
        'message': stripGiftAnimMarker(giftLabel),
        'translation': '',
        'isTranslated': false,
        'isSystem': true,
      });
    }
  }

  void openViewersSheet() {
    Get.bottomSheet(
      const LiveViewersSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openViewerProfile(Map<String, dynamic> viewer) {
    Get.dialog(
      LiveViewerProfileDialog(viewer: viewer),
      barrierColor: Colors.black.withValues(alpha: 0.68),
    );
  }

  void openGiftsSheet({
    String? receiverId,
    String? receiverName,
    bool roomGift = true,
    bool skipFollowerPkTargetPicker = false,
  }) {
    // Hosts cannot gift during an active host-vs-host PK.
    if (isInRoomPkActive && isHost.value) {
      _showRoomToast(
        'PK Battle',
        'Hosts can’t send gifts during PK. Viewers support a side with gifts.',
        isWarning: true,
      );
      return;
    }

    // Host-vs-host PK: gift to Side A / Side B instead of room-wide gifts.
    if (roomGift && isInRoomPkActive && Get.isRegistered<PkV1Controller>()) {
      final pk = Get.find<PkV1Controller>();
      final session = pk.session.value;
      Get.bottomSheet(
        PkGiftPickerSheet(
          controller: pk,
          sideA: session?.sideA ?? PkSideInfo.empty,
          sideB: session?.sideB ?? PkSideInfo.empty,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
      );
      return;
    }

    final pkPlayers = audioRoomSeats
        .where(
          (seat) =>
              seat.occupied &&
              seat.pkBattle?.active == true &&
              seat.pkBattle?.mode == 'audio_follower_pk' &&
              seat.pkBattle?.status == 'active',
        )
        .toList();
    if (roomGift &&
        !skipFollowerPkTargetPicker &&
        !isVideoRoom &&
        pkPlayers.isNotEmpty) {
      Get.bottomSheet(
        FollowerPkGiftTargetSheet(
          players: pkPlayers.take(2).toList(),
          onSelected: (player) {
            Get.back();
            Future.delayed(const Duration(milliseconds: 120), () {
              openGiftsSheet(
                receiverId: player.userId,
                receiverName: player.name,
                roomGift: false,
                skipFollowerPkTargetPicker: true,
              );
            });
          },
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.6),
      );
      return;
    }

    isRoomGiftMode.value = roomGift;
    // Room gifts have no single receiver (backend: receiver null + credited_user_ids).
    selectedGiftReceiverId.value = roomGift ? null : receiverId;
    selectedGiftReceiverName.value = roomGift
        ? 'Everyone in this room'
        : receiverName;

    if (Get.isDialogOpen == true) Get.back();
    if (Get.isBottomSheetOpen == true) Get.back();

    Future.delayed(const Duration(milliseconds: 140), () {
      Get.bottomSheet(
        const GiftsBottomSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    });
  }

  void openLiveFiltersSheet() {
    if (!isHost.value || !isVideoRoom) return;
    Get.bottomSheet(
      const LiveFiltersSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openRoomBackgroundSheet() {
    if (!canManageAudioRoomMembers || !isAudioVideoRoom) {
      _showRoomToast(
        'Background',
        'Only the host or room admins can change the room background.',
        isWarning: true,
      );
      return;
    }
    if (Get.isBottomSheetOpen == true) Get.back();
    Future.delayed(const Duration(milliseconds: 120), () {
      Get.bottomSheet(
        const RoomBackgroundSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    });
  }

  Future<void> loadRoomBackgroundCatalog() async {
    if (isLoadingRoomBackgrounds.value) return;
    isLoadingRoomBackgrounds.value = true;
    try {
      final response = await _roomRepo.getRoomBackgrounds(isShowLoader: false);
      if (_isApiSuccess(response)) {
        roomBackgroundCatalog.assignAll(
          RoomBackgroundTheme.listFromResponse(response?['data'] ?? response),
        );
      }
    } finally {
      isLoadingRoomBackgrounds.value = false;
    }
  }

  Future<void> applyRoomBackground(RoomBackgroundTheme theme) async {
    if (!canManageAudioRoomMembers || isChangingRoomBackground.value) return;
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty || theme.id.isEmpty) {
      _showRoomToast(
        'Background',
        'Room id is missing for this background change.',
        isError: true,
      );
      return;
    }

    isChangingRoomBackground.value = true;
    try {
      final response = await _roomRepo.changeRoomBackground(
        roomId: apiRoomId,
        backgroundId: theme.id,
        isShowLoader: false,
      );
      if (_isApiSuccess(response)) {
        final data = response?['data'];
        if (data is Map) {
          _applyRoomBackgroundFromMap(Map<String, dynamic>.from(data));
        } else {
          roomBackgroundUrl.value = theme.imageUrl;
          roomBackgroundId.value = theme.id;
        }
        if (Get.isBottomSheetOpen == true) Get.back();
        _showRoomToast('Background', 'Room background updated');
      } else {
        _showRoomApiError(
          'Background',
          response,
          'Unable to update room background.',
        );
      }
    } finally {
      isChangingRoomBackground.value = false;
    }
  }

  void _bindRoomBackgroundSocket() {
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty) return;

    _unbindRoomBackgroundSocket();
    _roomBackgroundSocketListener = (data) {
      final eventRoomId =
          (data['roomId'] ?? data['room_id'])?.toString().trim() ?? '';
      final localZegoId = roomId.value.trim();
      if (eventRoomId.isNotEmpty &&
          eventRoomId != apiRoomId &&
          eventRoomId != localZegoId) {
        return;
      }
      _applyRoomBackgroundFromMap(data);
    };

    _vipUserJoinedSocketListener = _buildVipUserJoinedListener(apiRoomId);

    unawaited(() async {
      await UserRealtimeSocketService.ensureConnected();
      if (!Get.isRegistered<UserRealtimeSocketService>()) return;
      final socket = Get.find<UserRealtimeSocketService>();
      final bgListener = _roomBackgroundSocketListener;
      final vipListener = _vipUserJoinedSocketListener;
      if (bgListener != null) {
        socket.addRoomBackgroundListener(bgListener);
      }
      if (vipListener != null) {
        socket.addVipUserJoinedListener(vipListener);
      }
      await socket.joinRoomChannel(apiRoomId);
    }());
  }

  /// Live streams have no seat poll — VIP entrance comes from the socket only.
  void _bindVipEntranceSocketOnly() {
    final apiRoomId =
        _extractBackendRoomId(_roomData)?.trim() ?? audioRoomApiId;
    final liveStreamId = liveStreamingApiId.trim();
    final channelId = liveStreamId.isNotEmpty ? liveStreamId : apiRoomId;
    if (channelId.isEmpty) return;

    _unbindRoomBackgroundSocket();
    _vipUserJoinedSocketListener = _buildVipUserJoinedListener(channelId);
    _liveStreamingSocketListener = _handleLiveStreamingSocketEvent;

    unawaited(() async {
      await UserRealtimeSocketService.ensureConnected();
      if (!Get.isRegistered<UserRealtimeSocketService>()) return;
      final socket = Get.find<UserRealtimeSocketService>();
      final vipListener = _vipUserJoinedSocketListener;
      if (vipListener != null) {
        socket.addVipUserJoinedListener(vipListener);
      }
      final liveListener = _liveStreamingSocketListener;
      if (liveListener != null) {
        socket.addLiveStreamEventListener(liveListener);
      }
      await socket.joinLiveStreamChannel(channelId);
    }());
  }

  void Function(Map<String, dynamic>) _buildVipUserJoinedListener(
    String apiRoomId,
  ) {
    return (data) {
      final eventRoomId =
          (data['roomId'] ?? data['room_id'])?.toString().trim() ?? '';
      final localZegoId = roomId.value.trim();
      if (eventRoomId.isNotEmpty &&
          eventRoomId != apiRoomId &&
          eventRoomId != localZegoId) {
        return;
      }
      final userId =
          (data['user_id'] ?? data['userId'] ?? data['id'])
              ?.toString()
              .trim() ??
          '';
      final userName =
          (data['user_name'] ?? data['userName'] ?? data['name'])
              ?.toString()
              .trim() ??
          'VIP Member';
      final avatar =
          (data['avatar'] ?? data['displayPicture'] ?? data['display_picture'])
              ?.toString();
      final frameUrl =
          (data['vip_frame_url'] ??
                  data['vipFrameUrl'] ??
                  data['frame_url'] ??
                  data['frameUrl'])
              ?.toString();
      final pattiStyle =
          (data['patti_style'] ?? data['pattiStyle'])?.toString().trim() ?? '';
      _playVipEntranceOnce(
        userId: userId.isNotEmpty
            ? userId
            : '$userName|${frameUrl ?? ''}|$pattiStyle',
        userName: userName,
        avatarUrl: avatar,
        vipFrameUrl: frameUrl,
        pattiStyle: pattiStyle,
      );
    };
  }

  bool _seatHasEntranceEffect(AudioRoomSeatModel seat) {
    final frameUrl = seat.vipFrameUrl?.trim() ?? '';
    final hasVipFrame = seat.isVip && frameUrl.isNotEmpty;
    return hasVipFrame || seat.hasCustomPattiStyle;
  }

  /// First seats snapshot only seeds dedupe — skip people already in the room.
  void _seedVipEntranceBaselineFromSeats(List<AudioRoomSeatModel> seats) {
    for (final seat in seats) {
      final userId = seat.userId.trim();
      if (userId.isEmpty) continue;
      if (!_seatHasEntranceEffect(seat)) continue;
      _vipEntrancePlayedUserIds.add(userId);
    }
    _vipSeatEntranceBaselineReady = true;
  }

  /// After baseline, play entrance for VIPs / patti users who newly appear.
  void _maybePlayVipEntrancesFromSeats(List<AudioRoomSeatModel> seats) {
    if (!_vipSeatEntranceBaselineReady) {
      _seedVipEntranceBaselineFromSeats(seats);
      return;
    }

    final presentIds = seats
        .map((s) => s.userId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    // Allow a re-join to animate again after the VIP leaves the seat grid.
    _vipEntrancePlayedUserIds.removeWhere((id) => !presentIds.contains(id));

    for (final seat in seats) {
      final userId = seat.userId.trim();
      if (userId.isEmpty || !_seatHasEntranceEffect(seat)) continue;
      _playVipEntranceOnce(
        userId: userId,
        userName: seat.name,
        avatarUrl: seat.avatarUrl,
        vipFrameUrl: seat.vipFrameUrl,
        pattiStyle: seat.pattiStyle,
      );
    }
  }

  void _playVipEntranceOnce({
    required String userId,
    required String userName,
    String? avatarUrl,
    String? vipFrameUrl,
    String? pattiStyle,
  }) {
    final id = userId.trim();
    final frame =
        ApiImageUtils.normalize(vipFrameUrl?.trim())?.trim() ??
        vipFrameUrl?.trim() ??
        '';
    final patti = pattiStyle?.trim() ?? '';
    if (id.isEmpty) return;
    // Socket / seats may send VIP frame only, patti only, or both.
    if (frame.isEmpty && patti.isEmpty) return;
    if (!_vipEntrancePlayedUserIds.add(id)) return;

    VipEntranceOverlay.show(
      userName: userName,
      avatarUrl: avatarUrl,
      vipFrameUrl: frame.isEmpty ? null : frame,
      pattiStyle: patti.isEmpty ? null : patti,
    );
  }

  void _unbindRoomBackgroundSocket() {
    final bgListener = _roomBackgroundSocketListener;
    final vipListener = _vipUserJoinedSocketListener;
    final liveListener = _liveStreamingSocketListener;
    _roomBackgroundSocketListener = null;
    _vipUserJoinedSocketListener = null;
    _liveStreamingSocketListener = null;
    if (!Get.isRegistered<UserRealtimeSocketService>()) return;
    final socket = Get.find<UserRealtimeSocketService>();
    if (bgListener != null) {
      socket.removeRoomBackgroundListener(bgListener);
    }
    if (vipListener != null) {
      socket.removeVipUserJoinedListener(vipListener);
    }
    if (liveListener != null) {
      socket.removeLiveStreamEventListener(liveListener);
      unawaited(socket.leaveLiveStreamChannel());
    } else {
      unawaited(socket.leaveRoomChannel());
    }
  }

  void _handleLiveStreamingSocketEvent(
    String event,
    Map<String, dynamic> data,
  ) {
    if (!_matchesCurrentLiveStreamEvent(data)) return;

    final normalizedEvent = (data['event'] ?? data['type'] ?? event)
        .toString()
        .toLowerCase();
    if (normalizedEvent.contains('viewer_joined')) {
      _upsertLiveViewerFromSocket(data);
      _updateLiveViewerCountFromSocket(data);
      return;
    }
    if (normalizedEvent.contains('viewer_left')) {
      _removeLiveViewerFromSocket(data);
      _updateLiveViewerCountFromSocket(data);
      return;
    }
    if (normalizedEvent.contains('ended')) {
      if (!isHost.value) {
        unawaited(_closeLiveStreamLocally());
      }
      return;
    }
    if (normalizedEvent.contains('gift_sent')) {
      _celebrateLiveGiftFromSocket(data);
    }
  }

  void _handleEmojiSocketEvent(String event, Map<String, dynamic> data) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final payload = asMap(data['data']) ?? data;
    final eventRoom =
        readRoomField(payload, const [
          'roomId',
          'room_id',
          'liveStreamingId',
          'live_streaming_id',
        ]) ??
        readRoomField(data, const ['roomId', 'room_id']);
    final currentRoom = audioRoomApiId.isNotEmpty
        ? audioRoomApiId
        : roomId.value.trim();
    if (eventRoom != null &&
        eventRoom.trim().isNotEmpty &&
        currentRoom.isNotEmpty &&
        eventRoom.trim() != currentRoom &&
        ZegoLiveIdUtils.sanitize(eventRoom) !=
            ZegoLiveIdUtils.sanitize(currentRoom)) {
      return;
    }

    final myId = _currentUserId();
    final sender =
        readRoomField(payload, const ['senderId', 'sender_id']) ??
        readRoomField(asMap(payload['sender']) ?? const {}, const [
          'id',
          '_id',
          'userId',
          'user_id',
        ]);
    if (sender == null || sender.trim().isEmpty) return;
    if (_userIdsMatch(sender, myId)) return;

    final eventKey =
        readRoomField(payload, const ['clientReqId', 'client_req_id', 'id']) ??
        '$event:${payload.hashCode}';
    if (!_playedEmojiEventKeys.add(eventKey)) return;

    final emoji =
        _emojiFromResponse({'data': payload}) ??
        _emojiById(readRoomField(payload, const ['emojiId', 'emoji_id']) ?? '');
    if (emoji == null) return;
    _showSeatEmojiReaction(senderId: sender, emoji: emoji);
  }

  bool _matchesCurrentLiveStreamEvent(Map<String, dynamic> data) {
    final eventId =
        readRoomField(data, const [
          'liveStreamingId',
          'live_streaming_id',
          'liveId',
          'live_id',
          'roomId',
          'room_id',
          'zegoLiveId',
          'zego_live_id',
        ]) ??
        readRoomField(
          (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'] as Map)
              : const <String, dynamic>{},
          const [
            'liveStreamingId',
            'live_streaming_id',
            'liveId',
            'live_id',
            'roomId',
            'room_id',
            'zegoLiveId',
            'zego_live_id',
          ],
        );
    if (eventId == null || eventId.isEmpty) return true;

    final localIds = <String>{
      liveStreamingApiId,
      liveZegoRoomId,
      roomId.value,
      _extractBackendRoomId(_roomData) ?? '',
    }.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    return localIds.contains(eventId.trim());
  }

  void _updateLiveViewerCountFromSocket(Map<String, dynamic> data) {
    final raw =
        data['viewerCount'] ??
        data['viewer_count'] ??
        data['count'] ??
        data['onlineCount'] ??
        data['online_count'];
    final count = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    if (count != null && count >= 0) {
      viewerCount.value = count;
    }
  }

  void _upsertLiveViewerFromSocket(Map<String, dynamic> data) {
    final viewer = _liveViewerFromSocket(data);
    if (viewer == null) return;
    final id = viewer['id']?.toString().trim() ?? '';
    if (id.isEmpty) return;
    final next = liveViewers.toList();
    final index = next.indexWhere((item) => item['id']?.toString() == id);
    if (index >= 0) {
      next[index] = {...next[index], ...viewer};
    } else {
      next.add(viewer);
    }
    liveViewers.assignAll(next);
    viewerCount.value = next.length;
  }

  void _removeLiveViewerFromSocket(Map<String, dynamic> data) {
    final viewer = _liveViewerFromSocket(data);
    final id =
        viewer?['id']?.toString().trim() ??
        readRoomField(data, const [
          'userId',
          'user_id',
          'viewerId',
          'viewer_id',
        ]);
    if (id == null || id.isEmpty) return;
    liveViewers.removeWhere((item) => item['id']?.toString() == id);
    viewerCount.value = liveViewers.length;
  }

  Map<String, dynamic>? _liveViewerFromSocket(Map<String, dynamic> data) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final viewer =
        asMap(data['viewer']) ??
        asMap(data['user']) ??
        asMap(data['data']) ??
        data;
    final id = readRoomField(viewer, const [
      'id',
      'userId',
      'user_id',
      'viewerId',
      'viewer_id',
    ]);
    if (id == null || id.isEmpty) return null;
    return <String, dynamic>{
      'id': id,
      'targetId': id,
      'name':
          readRoomField(viewer, const ['name', 'userName', 'user_name']) ??
          'Viewer',
      'avatarUrl': ApiImageUtils.normalize(
        readRoomField(viewer, const [
          'avatar',
          'avatarUrl',
          'avatar_url',
          'displayPicture',
          'display_picture',
        ]),
      ),
      'isHost': false,
      'isCurrentUser': _userIdsMatch(id, _currentUserId()),
    };
  }

  void _celebrateLiveGiftFromSocket(Map<String, dynamic> data) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final senderId =
        readRoomField(data, const ['senderId', 'sender_id', 'fromUserId']) ??
        readRoomField(asMap(data['sender']) ?? const {}, const [
          'id',
          'userId',
        ]);
    if (senderId != null && _userIdsMatch(senderId, _currentUserId())) {
      return;
    }

    final gift = asMap(data['gift']) ?? asMap(data['data']?['gift']);
    final giftName =
        readRoomField(gift ?? const {}, const ['name', 'title']) ??
        readRoomField(data, const ['giftName', 'gift_name']) ??
        'Gift';
    final animationUrl =
        ApiImageUtils.normalize(
          readRoomField(gift ?? const {}, const [
                'animationUrl',
                'animation_url',
                'svgaUrl',
              ]) ??
              readRoomField(data, const [
                'animationUrl',
                'animation_url',
                'svgaUrl',
              ]),
        ) ??
        '';
    final soundUrl =
        ApiImageUtils.normalize(
          readRoomField(gift ?? const {}, const [
                'soundUrl',
                'sound_url',
                'audioUrl',
                'audio_url',
              ]) ??
              readRoomField(data, const [
                'soundUrl',
                'sound_url',
                'audioUrl',
                'audio_url',
              ]),
        ) ??
        '';
    GiftMediaUtils.showCelebration(
      giftName: giftName,
      animationUrl: animationUrl,
      soundUrl: soundUrl,
      enqueueIfBusy: true,
    );
  }

  void _applyRoomBackgroundFromMap(Map<String, dynamic> data) {
    final url = ApiImageUtils.normalize(
      readRoomField(data, [
        'backgroundImage',
        'background_image',
        'backgroundUrl',
        'background_url',
        'image',
      ]),
    );
    final id = readRoomField(data, ['backgroundId', 'background_id']);
    if (url != null && url.isNotEmpty) {
      roomBackgroundUrl.value = url;
    }
    if (id != null && id.isNotEmpty) {
      roomBackgroundId.value = id;
    }
  }

  void _hydrateBackgroundFromSeatsPayload(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final nested = map['room'];
    if (nested is Map) {
      _applyRoomBackgroundFromMap(Map<String, dynamic>.from(nested));
    }
    _applyRoomBackgroundFromMap(map);
  }

  Future<void> setLiveBeautyEnabled(bool value) async {
    liveBeautyEnabled.value = value;
    await _applyLiveBeauty();
  }

  Future<void> updateLiveFilter({
    int? smooth,
    int? skinTone,
    int? blush,
    int? sharpen,
  }) async {
    if (smooth != null) liveSmooth.value = smooth;
    if (skinTone != null) liveSkinTone.value = skinTone;
    if (blush != null) liveBlush.value = blush;
    if (sharpen != null) liveSharpen.value = sharpen;
    if (!liveBeautyEnabled.value) {
      liveBeautyEnabled.value = true;
    }
    await _applyLiveBeauty();
  }

  Future<void> resetLiveFilters() async {
    liveBeautyEnabled.value = false;
    liveSmooth.value = 35;
    liveSkinTone.value = 25;
    liveBlush.value = 12;
    liveSharpen.value = 15;
    try {
      await ZegoUIKit().resetBeautyEffect();
      await ZegoUIKit().enableBeauty(false);
    } catch (_) {}
  }

  Future<void> _applyLiveBeauty() async {
    try {
      await ZegoUIKit().startEffectsEnv();
      await ZegoUIKit().enableBeauty(liveBeautyEnabled.value);
      if (!liveBeautyEnabled.value) return;
      ZegoUIKit().setBeautifyValue(liveSkinTone.value, BeautyEffectType.whiten);
      ZegoUIKit().setBeautifyValue(liveBlush.value, BeautyEffectType.rosy);
      ZegoUIKit().setBeautifyValue(liveSmooth.value, BeautyEffectType.smooth);
      ZegoUIKit().setBeautifyValue(liveSharpen.value, BeautyEffectType.sharpen);
    } catch (_) {
      _showRoomToast(
        'Filters',
        'Unable to apply filters on this device right now.',
        isWarning: true,
      );
    }
  }

  /// Opens 1:1 chat with an audio-room seat member from the member sheet.
  Future<void> openChatWithSeatMember(
    BuildContext context, {
    required AudioRoomSeatModel seat,
  }) async {
    await openChatWithViewer(context, {
      'targetId': seat.userId,
      'name': seat.name,
      'avatarUrl': seat.avatarUrl,
    });
  }

  /// Opens 1:1 chat with a viewer/host from the live room list.
  Future<void> openChatWithViewer(
    BuildContext context,
    Map<String, dynamic> viewer,
  ) async {
    if (viewer['isCurrentUser'] == true) return;

    final targetId =
        viewer['targetId']?.toString().trim() ??
        viewer['id']?.toString().trim() ??
        '';
    if (targetId.isEmpty) {
      _showToast(context, 'User profile is not available', isError: true);
      return;
    }

    if (_isViewerCurrentUser(targetId)) return;

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    final launchContext = Get.context ?? context;
    await ChatNavigationHelper.openDirectChat(
      launchContext,
      targetId: targetId,
      name: viewer['name']?.toString() ?? 'User',
      imageUrl: viewer['avatarUrl']?.toString(),
    );
  }

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    if (isError) {
      AppToast.showError(context, message);
    } else {
      AppToast.showSuccess(context, message);
    }
  }

  void _showRoomToast(
    String title,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    final context = Get.context ?? Get.key.currentContext;
    if (context != null && context.mounted) {
      if (isError) {
        AppToast.showError(context, message, title: title);
      } else if (isWarning) {
        AppToast.showWarning(context, message, title: title);
      } else {
        AppToast.showSuccess(context, message, title: title);
      }
      return;
    }

    // Fallback for rare controller-only paths where no BuildContext is mounted.
    Get.rawSnackbar(
      titleText: Text(
        title,
        style: TextStyles.kSemiBoldPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorWhite,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k12FontSize,
          colors: kColorWhite.withValues(alpha: 0.82),
        ),
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 20,
      backgroundColor: const Color(0xFF15101F).withValues(alpha: 0.94),
      duration: const Duration(seconds: 4),
    );
  }

  bool _isViewerCurrentUser(String targetId) {
    if (!Get.isRegistered<UserSessionController>()) return false;
    final myId = Get.find<UserSessionController>().userId.trim();
    if (myId.isEmpty) return false;
    return myId == targetId ||
        ZegoLiveIdUtils.sanitizeUserId(myId) ==
            ZegoLiveIdUtils.sanitizeUserId(targetId);
  }

  String get audioRoomApiId {
    final fromPayload = _extractBackendRoomId(_roomData)?.trim() ?? '';
    if (fromPayload.isNotEmpty) return fromPayload;
    // Prefer dashed UUID over sanitized Zego channel id when both exist.
    final raw = readRoomField(_roomData, const [
      'backendRoomId',
      'backend_room_id',
      'roomUuid',
      'room_uuid',
    ])?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return roomId.value.trim();
  }

  void _startSeatRefreshPolling() {
    _seatRefreshTimer?.cancel();
    unawaited(loadAudioRoomSeats());
    _seatRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_exitReported || !isAudioVideoRoom) {
        _stopSeatRefreshPolling();
        return;
      }
      unawaited(loadAudioRoomSeats());
    });
  }

  void _stopSeatRefreshPolling() {
    _seatRefreshTimer?.cancel();
    _seatRefreshTimer = null;
  }

  Future<void> loadAudioRoomSeats({bool showErrors = false}) async {
    if (!isAudioVideoRoom || _exitReported) return;
    if (isLoadingAudioSeats.value) return;
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty) {
      _setAudioRoomSeats(_buildFallbackAudioSeats());
      return;
    }

    isLoadingAudioSeats.value = true;
    try {
      final response = await _roomRepo.getRoomSeats(
        roomId: apiRoomId,
        isShowLoader: false,
      );
      if (_isApiSuccess(response)) {
        final seats = _parseAudioSeats(response?['data']);
        _setAudioRoomSeats(
          seats.isNotEmpty ? seats : _buildFallbackAudioSeats(),
        );
        _applySeatsMeta(response?['data']);
        _hydrateBackgroundFromSeatsPayload(response?['data']);
        _maybePlayVipEntrancesFromSeats(
          seats.isNotEmpty ? seats : audioRoomSeats.toList(),
        );
        await _syncRoomMembershipFromSeatsResponse(
          response?['data'],
          seats.isNotEmpty ? seats : audioRoomSeats.toList(),
        );
        _tryAutoSeatForInvitedUser();
        return;
      }

      if (_shouldTreatSeatsResponseAsRemoved(response)) {
        await _forceLeaveRoomBecauseRemoved(
          message: response?['message']?.toString(),
        );
        return;
      }

      if (audioRoomSeats.isEmpty) {
        _setAudioRoomSeats(_buildFallbackAudioSeats());
      }
      if (showErrors) {
        _showRoomApiError('Seats', response, 'Unable to fetch room seats.');
      }
    } finally {
      isLoadingAudioSeats.value = false;
    }
  }

  /// Polls seat API to detect when the current viewer was kicked/removed.
  Future<void> _syncRoomMembershipFromSeatsResponse(
    dynamic data,
    List<AudioRoomSeatModel> seats,
  ) async {
    if (isHost.value || _exitReported) return;

    final myId = _currentUserId();
    final onMicSeat =
        myId.isNotEmpty &&
        seats.any((seat) => seat.occupied && _userIdsMatch(seat.userId, myId));

    if (onMicSeat) {
      _currentUserOccupiedMicSeat = true;
      _roomMembershipConfirmed = true;
      return;
    }

    final inRoom = _parseCurrentUserInRoomFromSeatsData(data, seats);
    if (inRoom == true) {
      // Floor audience still counts as in-room (not kicked).
      _currentUserOccupiedMicSeat = false;
      _roomMembershipConfirmed = true;
      return;
    }

    if (!_roomMembershipConfirmed) return;

    // Explicit not-in-room (floor list / placement / kick flags).
    if (inRoom == false) {
      await _forceLeaveRoomBecauseRemoved();
      return;
    }

    // Mic speaker kicked off the stage — no longer appears on any seat.
    if (_currentUserOccupiedMicSeat) {
      await _forceLeaveRoomBecauseRemoved();
      return;
    }

    // Floor guest: seats payload included floor_audience and we are gone from it.
    // Older parse path returned null here, so kicked floor users never exited.
    if (data is Map &&
        (data.containsKey('floor_audience') ||
            data.containsKey('floorAudience'))) {
      final stillOnFloor = floorAudience.any(
        (user) => _userIdsMatch(user.userId, myId),
      );
      if (!stillOnFloor) {
        await _forceLeaveRoomBecauseRemoved();
      }
    }
  }

  bool? _parseCurrentUserInRoomFromSeatsData(
    dynamic data,
    List<AudioRoomSeatModel> seats,
  ) {
    final myId = _currentUserId();
    if (myId.isEmpty) return null;

    for (final seat in seats) {
      if (seat.occupied && _userIdsMatch(seat.userId, myId)) {
        return true;
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      for (final key in const [
        'isInRoom',
        'inRoom',
        'currentUserInRoom',
        'isParticipant',
      ]) {
        if (map.containsKey(key)) {
          return _coerceNullableBool(map[key]);
        }
      }

      for (final key in const [
        'kickedId',
        'kicked_id',
        'removedUserId',
        'removed_user_id',
        'targetUserId',
        'target_user_id',
      ]) {
        final removedId = map[key]?.toString().trim() ?? '';
        if (removedId.isNotEmpty && _userIdsMatch(removedId, myId)) {
          return false;
        }
      }

      final placement =
          (map['my_placement'] ?? map['myPlacement'])
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';
      if (placement == 'removed' ||
          placement == 'kicked' ||
          placement == 'left' ||
          placement == 'none' ||
          placement == 'out' ||
          placement == 'not_in_room') {
        return false;
      }

      // When backend sends floor_audience, absence from that list means not in room
      // (unless already seated above). Do not trust a stale my_placement=floor alone.
      final hasFloorKey =
          map.containsKey('floor_audience') || map.containsKey('floorAudience');
      if (hasFloorKey) {
        final floorRaw = map['floor_audience'] ?? map['floorAudience'];
        if (floorRaw is List) {
          for (final item in floorRaw.whereType<Map>()) {
            final id =
                item['userId']?.toString() ??
                item['user_id']?.toString() ??
                item['id']?.toString() ??
                '';
            if (id.isNotEmpty && _userIdsMatch(id, myId)) {
              return true;
            }
          }
          return false;
        }
      }

      if (placement == 'floor' || placement == 'seat') {
        return true;
      }

      final room = map['room'];
      if (room is Map) {
        final status = room['status']?.toString().toLowerCase();
        if (status == 'ended' || status == 'closed') return false;
      }

      final currentUser =
          map['currentUser'] ?? map['participant'] ?? map['membership'];
      if (currentUser is Map) {
        final userMap = Map<String, dynamic>.from(currentUser);
        if (userMap['kicked'] == true || userMap['removed'] == true) {
          return false;
        }
        for (final key in const [
          'isInRoom',
          'inRoom',
          'isActive',
          'isParticipant',
        ]) {
          if (userMap.containsKey(key)) {
            return _coerceNullableBool(userMap[key]);
          }
        }
      }

      for (final key in const [
        'participants',
        'members',
        'usersInRoom',
        'onlineUsers',
        'listeners',
        'viewers',
      ]) {
        final list = map[key];
        if (list is! List || list.isEmpty) continue;

        final ids = <String>{};
        for (final item in list) {
          if (item is Map) {
            final id = _readParticipantId(Map<String, dynamic>.from(item));
            if (id != null) ids.add(id);
          } else {
            final id = item?.toString().trim();
            if (id != null && id.isNotEmpty) ids.add(id);
          }
        }
        if (ids.isNotEmpty) {
          return ids.any((id) => _userIdsMatch(id, myId));
        }
      }
    }

    return null;
  }

  bool _shouldTreatSeatsResponseAsRemoved(Map<String, dynamic>? response) {
    if (isHost.value || !_roomMembershipConfirmed || _exitReported) {
      return false;
    }

    final message = response?['message']?.toString().toLowerCase() ?? '';
    const keywords = [
      'kick',
      'removed',
      'not in room',
      'not a member',
      'no longer',
      'forbidden',
      'access denied',
    ];
    return keywords.any(message.contains);
  }

  Future<void> _forceLeaveRoomBecauseRemoved({String? message}) async {
    if (_exitReported || isHost.value) return;
    _exitReported = true;
    _stopSeatRefreshPolling();
    _stopSeatRequestPolling();
    _unbindSeatRequestSocket();

    if (Get.isBottomSheetOpen == true) Get.back();
    if (Get.isDialogOpen == true) Get.back();

    if (Get.isRegistered<UserRealtimeSocketService>()) {
      unawaited(
        Get.find<UserRealtimeSocketService>().leaveRoomChannel(audioRoomApiId),
      );
    }

    await ZegoEngineUtils.resetForRoomProject();

    await Future<void>.delayed(const Duration(milliseconds: 80));
    final poppedLiveRoute = _popLiveBroadcastRoute();
    if (!poppedLiveRoute) {
      Get.offAllNamed(Routes.BOTTOM_NAV);
    }

    // Show after leaving the room so the dialog appears on the destination screen.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _showRemovedFromRoomDialog(message);
  }

  void _showRemovedFromRoomDialog(String? message) {
    _showCommonFeedbackDialog(
      title: 'Removed from room',
      message: message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'You were removed from this room.',
      barrierDismissible: false,
      tone: AudioRoomFeedbackTone.removed,
    );
  }

  void _showCommonFeedbackDialog({
    required String title,
    required String message,
    bool barrierDismissible = true,
    AudioRoomFeedbackTone tone = AudioRoomFeedbackTone.moderation,
  }) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    AudioRoomFeedbackDialog.show(
      context,
      title: title,
      message: message,
      tone: tone,
      barrierDismissible: barrierDismissible,
    );
  }

  String _currentUserId() {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId.trim();
  }

  String? _readParticipantId(Map<String, dynamic> raw) {
    for (final key in const [
      'userId',
      'user_id',
      'id',
      '_id',
      'targetUserId',
      'target_user_id',
    ]) {
      final value = raw[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  bool _userIdsMatch(String left, String right) {
    final a = left.trim();
    final b = right.trim();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b ||
        ZegoLiveIdUtils.sanitizeUserId(a) == ZegoLiveIdUtils.sanitizeUserId(b);
  }

  bool? _coerceNullableBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  Future<void> loadAudioInviteCandidates({
    String search = '',
    bool showErrors = true,
  }) async {
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty) {
      audioInviteCandidates.clear();
      if (showErrors) {
        _showRoomToast(
          'Invite users',
          'Room id is missing, so followers cannot be loaded.',
          isError: true,
        );
      }
      return;
    }

    isLoadingInviteCandidates.value = true;
    try {
      final response = await _roomRepo.getInviteCandidates(
        roomId: apiRoomId,
        search: search,
        isShowLoader: false,
      );
      if (_isApiSuccess(response)) {
        audioInviteCandidates.assignAll(
          _parseInviteCandidates(response?['data']),
        );
        return;
      }

      audioInviteCandidates.clear();
      if (showErrors) {
        _showRoomApiError(
          'Invite users',
          response,
          'Unable to fetch followers for invite.',
        );
      }
    } finally {
      isLoadingInviteCandidates.value = false;
    }
  }

  Future<void> inviteUserToAudioSeat({
    required int seatNo,
    required AudioRoomInviteCandidate user,
  }) async {
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty || user.id.trim().isEmpty) return;

    final response = await _roomRepo.inviteUserToSeat(
      roomId: apiRoomId,
      targetUserId: user.id,
      seatId: seatNo,
      message: '${hostName.value} invited you to join the mic',
      isShowLoader: true,
    );

    if (_isApiSuccess(response)) {
      if (Get.isBottomSheetOpen == true) Get.back();
      _showRoomToast(
        'Invite sent',
        '${user.name} has been invited to seat $seatNo.',
      );
      return;
    }

    _showRoomApiError('Invite failed', response, 'Unable to send invite.');
  }

  Future<void> updateAudioSeatMic({
    required AudioRoomSeatModel seat,
    required bool mute,
  }) async {
    await _runSeatAction(
      label: mute ? 'Mute' : 'Unmute',
      action: () => _roomRepo.micAction(
        roomId: audioRoomApiId,
        seatId: seat.seatNo,
        targetUserId: seat.userId,
        action: mute ? 'mute' : 'unmute',
        isShowLoader: true,
      ),
    );
  }

  /// Host/admin: move seated user back to floor (still in room). Not a full kick.
  Future<void> removeUserFromAudioSeat(AudioRoomSeatModel seat) async {
    if (!canManageAudioRoomMembers) return;
    final seatNo = seat.seatNo;
    final targetId = seat.userId.trim();
    if (seatNo <= 1 || targetId.isEmpty) {
      _showRoomToast(
        'Remove from seat',
        seatNo <= 1
            ? 'The host seat cannot be cleared this way.'
            : 'This seat has no user to remove.',
        isWarning: true,
      );
      return;
    }

    final memberName = seat.name.trim();
    // Canonical action confirmed by backend (aliases also supported server-side).
    final response = await _roomRepo.micAction(
      roomId: audioRoomApiId,
      seatId: seatNo,
      targetUserId: targetId,
      action: 'remove_from_seat',
      isShowLoader: true,
    );

    if (_isApiSuccess(response)) {
      await _applyMicActionSeatsResponse(response);
      _showRoomToast(
        'Removed from seat',
        memberName.isNotEmpty
            ? '$memberName was moved back to the floor.'
            : 'User was moved back to the floor.',
      );
      return;
    }

    _showRoomApiError(
      'Remove from seat',
      response,
      'Unable to remove this user from the seat.',
    );
  }

  /// Host/admin: place a floor-audience user directly onto an empty mic seat.
  Future<void> placeFloorUserOnSeat({
    required FloorAudienceUser user,
    required int seatNo,
  }) async {
    if (!canManageAudioRoomMembers) return;
    final targetId = user.userId.trim();
    if (targetId.isEmpty || seatNo <= 1) {
      _showRoomToast(
        'Seat',
        seatNo <= 1
            ? 'Pick a guest seat (2+), not the host seat.'
            : 'User id is missing.',
        isWarning: true,
      );
      return;
    }

    final occupied = audioRoomSeats.any(
      (s) => s.seatNo == seatNo && s.occupied,
    );
    if (occupied) {
      _showRoomToast('Seat', 'Seat $seatNo is already taken.', isWarning: true);
      return;
    }

    final displayName = user.name.trim().isEmpty ? 'User' : user.name.trim();
    // Canonical action confirmed by backend (aliases also supported server-side).
    final response = await _roomRepo.micAction(
      roomId: audioRoomApiId,
      seatId: seatNo,
      targetUserId: targetId,
      action: 'approve_speaker',
      isShowLoader: true,
    );

    if (_isApiSuccess(response)) {
      await _applyMicActionSeatsResponse(response);
      _showRoomToast('Seated', '$displayName joined seat $seatNo.');
      return;
    }

    _showRoomApiError(
      'Put on seat',
      response,
      'Unable to place this user on seat $seatNo.',
    );
  }

  /// Prefer hydrated `data` from mic-action; fall back to seats GET.
  Future<void> _applyMicActionSeatsResponse(
    Map<String, dynamic>? response,
  ) async {
    if (Get.isBottomSheetOpen == true) Get.back();

    final data = response?['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final hasHydratedSeats =
          map['seats'] is List ||
          map.containsKey('floor_audience') ||
          map.containsKey('floorAudience') ||
          map.containsKey('my_placement') ||
          map.containsKey('myPlacement');

      if (hasHydratedSeats) {
        final seats = _parseAudioSeats(map);
        if (seats.isNotEmpty) {
          _setAudioRoomSeats(seats);
        }
        _applySeatsMeta(map);
        await _syncRoomMembershipFromSeatsResponse(
          map,
          seats.isNotEmpty ? seats : audioRoomSeats.toList(),
        );
        return;
      }
    }

    await loadAudioRoomSeats();
  }

  Future<void> kickAudioRoomUser(AudioRoomSeatModel seat) async {
    final memberName = seat.name.trim();
    await _runSeatAction(
      label: 'Kick off',
      action: () => _roomRepo.kickParticipant(
        roomId: audioRoomApiId,
        targetUserId: seat.userId,
        isShowLoader: true,
      ),
      successMessage: memberName.isNotEmpty
          ? '$memberName was removed from the room.'
          : 'Member was removed from the room.',
      showSuccessDialog: true,
    );
  }

  Future<void> setAudioRoomAdmin({
    required AudioRoomSeatModel seat,
    required bool makeAdmin,
  }) async {
    await _runSeatAction(
      label: makeAdmin ? 'Make admin' : 'Remove admin',
      action: () => _roomRepo.adminAction(
        roomId: audioRoomApiId,
        targetUserId: seat.userId,
        action: makeAdmin ? 'make_admin' : 'remove_admin',
        isShowLoader: true,
      ),
    );
  }

  Future<void> requestAudioSeat() async {
    AudioRoomSeatModel? targetSeat;
    for (final seat in audioRoomSeats) {
      if (!seat.occupied && !seat.isLocked) {
        targetSeat = seat;
        break;
      }
    }
    if (targetSeat == null) {
      _showRoomToast(
        'Request',
        'No open mic seats are available right now.',
        isWarning: true,
      );
      return;
    }
    await requestSeatForSeatNo(targetSeat.seatNo);
  }

  /// Auto-seats users who joined via push notification or in-app invite.
  /// Users from the room listing go to the floor instead and must manually
  /// tap a seat (follower → instant, non-follower → host approval).
  void _tryAutoSeatForInvitedUser() {
    if (_autoSeatAttempted || !_joinedViaInvite || isHost.value) return;
    _autoSeatAttempted = true;

    final myId = _currentUserId();
    if (myId.isEmpty) return;

    // Already seated (e.g. backend placed them on accept).
    final alreadySeated = audioRoomSeats.any(
      (s) => s.occupied && _userIdsMatch(s.userId, myId),
    );
    if (alreadySeated) return;

    // Defer slightly so the UI has rendered before seat action runs.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_exitReported) return;
      requestAudioSeat();
    });
  }

  /// Follower take-seat / non-follower seat-request for a specific empty seat.
  Future<void> requestSeatForSeatNo(int seatNo) async {
    if (seatNo <= 0) return;
    final apiRoomId = audioRoomApiId.trim();
    if (apiRoomId.isEmpty) return;

    // Already seated — nothing to do.
    final myId = _currentUserId();
    if (myId.isNotEmpty &&
        audioRoomSeats.any(
          (s) => s.occupied && _userIdsMatch(s.userId, myId),
        )) {
      _showRoomToast('Seat', 'You are already on a seat.', isWarning: true);
      return;
    }

    if (viewerFollowsHost.value || isHost.value) {
      await _runSeatAction(
        label: 'Take seat',
        action: () => _roomRepo.micAction(
          roomId: apiRoomId,
          seatId: seatNo,
          action: 'take_seat',
          isShowLoader: true,
        ),
        successMessage: 'You joined seat $seatNo.',
      );
      // Fallback if backend still expects request_to_speak.
      return;
    }

    // Non-follower → seat request for host Allow/Reject.
    final response = await _roomRepo.createSeatRequest(
      roomId: apiRoomId,
      seatId: seatNo,
      isShowLoader: true,
    );
    if (_isApiSuccess(response) ||
        response?['success'] == true ||
        (response?['request'] is Map)) {
      _showRoomToast(
        'Request sent',
        'Waiting for the host to allow seat $seatNo.',
      );
      await loadAudioRoomSeats();
      return;
    }

    final code =
        response?['code']?.toString() ??
        response?['errorCode']?.toString() ??
        '';
    if (code.toUpperCase() == 'FOLLOW_REQUIRED_FOR_SEAT') {
      _showRoomToast(
        'Follow required',
        response?['message']?.toString() ??
            'Follow the host to take a seat, or request one.',
        isError: true,
      );
      return;
    }
    _showRoomApiError('Seat request', response, 'Unable to request this seat.');
  }

  Future<void> respondToPendingSeatRequest(
    PendingSeatRequest request, {
    required String action,
  }) async {
    final apiRoomId = audioRoomApiId.trim();
    if (apiRoomId.isEmpty || request.requestId.isEmpty) return;
    final response = await _roomRepo.respondToSeatRequest(
      roomId: apiRoomId,
      requestId: request.requestId,
      action: action,
      isShowLoader: true,
    );
    if (!_isApiSuccess(response) && response?['success'] != true) {
      _showRoomApiError(
        action == 'approve' ? 'Allow' : 'Reject',
        response,
        'Unable to update seat request.',
      );
      return;
    }
    pendingSeatRequests.removeWhere((e) => e.requestId == request.requestId);
    _promptedSeatRequestIds.remove(request.requestId);
    await loadAudioRoomSeats();
    _showRoomToast(
      action == 'approve' ? 'Allowed' : 'Rejected',
      action == 'approve'
          ? '${request.name} can join seat ${request.seatNo}.'
          : 'Seat request rejected.',
    );
  }

  Future<void> showSeatRequestHostDialog(PendingSeatRequest request) async {
    if (!isHost.value && !canManageAudioRoomMembers) return;
    if (Get.isDialogOpen == true) return;

    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B1654), Color(0xFF171339)],
            ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SemiBoldText(
                text: 'Seat request',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
              Spacing.v12,
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white12,
                    backgroundImage: (request.avatarUrl ?? '').trim().isNotEmpty
                        ? NetworkImage(request.avatarUrl!.trim())
                        : null,
                    child: (request.avatarUrl ?? '').trim().isEmpty
                        ? const Icon(Icons.person, color: kColorWhite)
                        : null,
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: request.name,
                          fontSize: TextStyles.k16FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v4,
                        AppText(
                          text: 'Wants to sit on seat ${request.seatNo}',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back<void>();
                        unawaited(
                          respondToPendingSeatRequest(
                            request,
                            action: 'reject',
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kColorWhite,
                        side: BorderSide(
                          color: kColorWhite.withValues(alpha: 0.35),
                        ),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back<void>();
                        unawaited(
                          respondToPendingSeatRequest(
                            request,
                            action: 'approve',
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3EA5),
                        foregroundColor: kColorWhite,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Allow'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  List<String> _parseCreditedUserIdsFromGiftResponse(
    Map<String, dynamic>? response,
  ) {
    if (response == null) return const [];
    final data = response['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(response);
    final raw =
        map['credited_user_ids'] ??
        map['creditedUserIds'] ??
        response['credited_user_ids'];
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int? _parseAmountEachFromGiftResponse(Map<String, dynamic>? response) {
    if (response == null) return null;
    final data = response['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(response);
    final raw =
        map['amount_each'] ??
        map['amountEach'] ??
        response['amount_each'] ??
        response['amountEach'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '');
  }

  void _bindSeatRequestSocket() {
    _unbindSeatRequestSocket();
    final apiRoomId = audioRoomApiId.trim();
    if (apiRoomId.isEmpty) return;

    _seatRequestSocketListener = (data) {
      final eventRoom =
          (data['room_id'] ?? data['roomId'])?.toString().trim() ?? '';
      if (eventRoom.isNotEmpty &&
          eventRoom != apiRoomId &&
          eventRoom != roomId.value.trim()) {
        return;
      }
      final event =
          (data['event'] ?? data['type'] ?? data['name'])
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

      if (event == 'seat_request' || data['request_id'] != null) {
        final req = PendingSeatRequest.fromMap(data);
        if (req.requestId.isEmpty) return;
        final exists = pendingSeatRequests.any(
          (e) => e.requestId == req.requestId,
        );
        if (!exists) {
          pendingSeatRequests.insert(0, req);
        }
        if (isHost.value && !_promptedSeatRequestIds.contains(req.requestId)) {
          _promptedSeatRequestIds.add(req.requestId);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(showSeatRequestHostDialog(req));
          });
        }
        return;
      }

      if (event == 'seat_request_approved') {
        unawaited(loadAudioRoomSeats());
        _showRoomToast('Seat approved', 'Host allowed you on a seat.');
        return;
      }

      if (event == 'seat_request_rejected') {
        _showRoomToast(
          'Seat request rejected',
          'Host declined your seat request.',
          isWarning: true,
        );
        return;
      }

      if (event == 'seat_request_cancelled' ||
          event == 'floor_audience_updated') {
        unawaited(loadAudioRoomSeats());
      }
    };

    _floorAudienceSocketListener = (data) {
      unawaited(loadAudioRoomSeats());
    };

    _emojiSocketListener = (event, data) {
      _handleEmojiSocketEvent(event, data);
    };

    _userKickedSocketListener = (data) {
      if (isHost.value || _exitReported) return;
      final apiRoomId = audioRoomApiId.trim();
      final eventRoom =
          (data['room_id'] ?? data['roomId'])?.toString().trim() ?? '';
      if (eventRoom.isNotEmpty &&
          eventRoom != apiRoomId &&
          eventRoom != roomId.value.trim()) {
        return;
      }

      final myId = _currentUserId();
      if (myId.isEmpty) return;

      final targetId =
          (data['targetUserId'] ??
                  data['target_user_id'] ??
                  data['kickedId'] ??
                  data['kicked_id'] ??
                  data['userId'] ??
                  data['user_id'] ??
                  data['removedUserId'])
              ?.toString()
              .trim() ??
          '';
      // If payload names a target, only that user should leave.
      if (targetId.isNotEmpty && !_userIdsMatch(targetId, myId)) {
        unawaited(loadAudioRoomSeats());
        return;
      }

      unawaited(
        _forceLeaveRoomBecauseRemoved(
          message:
              data['message']?.toString() ?? 'You were removed from this room.',
        ),
      );
    };

    unawaited(() async {
      await UserRealtimeSocketService.ensureConnected();
      if (!Get.isRegistered<UserRealtimeSocketService>()) return;
      final socket = Get.find<UserRealtimeSocketService>();
      final seatListener = _seatRequestSocketListener;
      final floorListener = _floorAudienceSocketListener;
      final kickListener = _userKickedSocketListener;
      final emojiListener = _emojiSocketListener;
      if (seatListener != null) {
        socket.addSeatRequestListener(seatListener);
      }
      if (floorListener != null) {
        socket.addFloorAudienceListener(floorListener);
      }
      if (kickListener != null) {
        socket.addUserKickedListener(kickListener);
      }
      if (emojiListener != null) {
        socket.addEmojiEventListener(emojiListener);
      }
      await socket.joinRoomChannel(apiRoomId);
    }());
  }

  void _unbindSeatRequestSocket() {
    if (!Get.isRegistered<UserRealtimeSocketService>()) {
      _seatRequestSocketListener = null;
      _floorAudienceSocketListener = null;
      _userKickedSocketListener = null;
      _emojiSocketListener = null;
      return;
    }
    final socket = Get.find<UserRealtimeSocketService>();
    final seatListener = _seatRequestSocketListener;
    final floorListener = _floorAudienceSocketListener;
    final kickListener = _userKickedSocketListener;
    final emojiListener = _emojiSocketListener;
    if (seatListener != null) {
      socket.removeSeatRequestListener(seatListener);
    }
    if (floorListener != null) {
      socket.removeFloorAudienceListener(floorListener);
    }
    if (kickListener != null) {
      socket.removeUserKickedListener(kickListener);
    }
    if (emojiListener != null) {
      socket.removeEmojiEventListener(emojiListener);
    }
    _seatRequestSocketListener = null;
    _floorAudienceSocketListener = null;
    _userKickedSocketListener = null;
    _emojiSocketListener = null;
  }

  Future<void> _runSeatAction({
    required String label,
    required Future<Map<String, dynamic>?> Function() action,
    String? successMessage,
    bool showSuccessDialog = false,
  }) async {
    final response = await action();
    if (_isApiSuccess(response)) {
      await _applyMicActionSeatsResponse(response);
      final message = successMessage ?? '$label updated successfully.';
      if (showSuccessDialog) {
        _showCommonFeedbackDialog(title: label, message: message);
      } else {
        _showRoomToast(label, message);
      }
      return;
    }

    _showRoomApiError(label, response, 'Unable to complete this action.');
  }

  List<AudioRoomSeatModel> _parseAudioSeats(dynamic data) {
    final seatConfig = _readSeatConfig(data);
    final rawSeats = data is Map ? data['seats'] : data;
    final parsed = rawSeats is List
        ? rawSeats
              .whereType<Map>()
              .map(
                (raw) =>
                    AudioRoomSeatModel.fromMap(Map<String, dynamic>.from(raw)),
              )
              .where((seat) => seat.seatNo > 0)
              .toList()
        : <AudioRoomSeatModel>[];

    final seatsByNo = <int, AudioRoomSeatModel>{
      for (final seat in _withCurrentUserFrame(parsed)) seat.seatNo: seat,
    };
    final maxSeat = seatConfig > 0
        ? seatConfig
        : seatsByNo.keys.fold<int>(
            16,
            (max, value) => value > max ? value : max,
          );

    final hostSeat = _pinHostToFirstSeat(seatsByNo.values.toList());
    final hostUserId = hostSeat.userId.trim().isNotEmpty
        ? hostSeat.userId.trim()
        : receiverId.value.trim();

    // Whoever was wrongly sitting in API seat 1 (not the host) gets moved
    // to the first free seat so the host always owns seat 1 in the UI.
    AudioRoomSeatModel? displacedSeat1;
    final apiSeat1 = seatsByNo[1];
    if (apiSeat1 != null &&
        apiSeat1.occupied &&
        !_isSameRoomUser(apiSeat1.userId, hostUserId)) {
      displacedSeat1 = apiSeat1;
    }

    final seats = <AudioRoomSeatModel>[hostSeat];
    for (var seatNo = 2; seatNo <= maxSeat; seatNo++) {
      final seat = seatsByNo[seatNo] ?? AudioRoomSeatModel.empty(seatNo);
      if (_isSameRoomUser(seat.userId, hostUserId)) {
        seats.add(AudioRoomSeatModel.empty(seatNo));
        continue;
      }
      seats.add(seat);
    }

    if (displacedSeat1 != null) {
      final emptyIndex = seats.indexWhere(
        (seat) => seat.seatNo > 1 && !seat.occupied,
      );
      if (emptyIndex >= 0) {
        final emptySeatNo = seats[emptyIndex].seatNo;
        seats[emptyIndex] = displacedSeat1.copyWith(
          seatNo: emptySeatNo,
          role: displacedSeat1.role.toLowerCase() == 'host'
              ? 'speaker'
              : displacedSeat1.role,
        );
      }
    }

    if (hostSeat.occupied) {
      if (hostSeat.name.trim().isNotEmpty) hostName.value = hostSeat.name;
      if (hostSeat.avatarUrl?.trim().isNotEmpty == true) {
        hostAvatarUrl.value = hostSeat.avatarUrl;
      }
      if (hostSeat.avatarFrameUrl?.trim().isNotEmpty == true) {
        hostAvatarFrameUrl.value = hostSeat.avatarFrameUrl;
      }
      if (receiverId.value.trim().isEmpty &&
          hostSeat.userId.trim().isNotEmpty) {
        receiverId.value = hostSeat.userId;
      }
    }

    return seats;
  }

  /// Always place the room host in seat 1 for host and audience UIs.
  AudioRoomSeatModel _pinHostToFirstSeat(List<AudioRoomSeatModel> occupied) {
    final knownHostId = receiverId.value.trim();
    final myId = _currentUserId();

    AudioRoomSeatModel? hostFromSeats;
    for (final seat in occupied) {
      if (!seat.occupied) continue;
      // When I am the room host, my mic seat is always seat 1.
      if (isHost.value && myId.isNotEmpty && _userIdsMatch(seat.userId, myId)) {
        hostFromSeats = seat;
        break;
      }
    }
    if (hostFromSeats == null) {
      for (final seat in occupied) {
        if (!seat.occupied) continue;
        if (seat.role.toLowerCase() == 'host') {
          hostFromSeats = seat;
          break;
        }
      }
    }
    if (hostFromSeats == null && knownHostId.isNotEmpty) {
      for (final seat in occupied) {
        if (!seat.occupied) continue;
        if (_userIdsMatch(seat.userId, knownHostId)) {
          hostFromSeats = seat;
          break;
        }
      }
    }

    if (hostFromSeats != null) {
      return hostFromSeats.copyWith(seatNo: 1, role: 'host');
    }

    if (isHost.value && myId.isNotEmpty) {
      final session = Get.isRegistered<UserSessionController>()
          ? Get.find<UserSessionController>()
          : null;
      return AudioRoomSeatModel(
        seatNo: 1,
        userId: myId,
        name: (session?.displayName.trim().isNotEmpty == true)
            ? session!.displayName
            : (hostName.value.trim().isNotEmpty ? hostName.value : 'Host'),
        avatarUrl: session?.displayPictureUrl ?? hostAvatarUrl.value,
        avatarFrameUrl: session?.profileFrameUrl.trim().isNotEmpty == true
            ? session!.profileFrameUrl
            : hostAvatarFrameUrl.value,
        role: 'host',
        isAdmin: true,
      );
    }

    return _resolveHostSeat(null);
  }

  bool _isSameRoomUser(String left, String right) {
    final a = left.trim();
    final b = right.trim();
    if (a.isEmpty || b.isEmpty) return false;
    return _userIdsMatch(a, b);
  }

  AudioRoomSeatModel _resolveHostSeat(AudioRoomSeatModel? apiHostSeat) {
    if (apiHostSeat != null && apiHostSeat.occupied) {
      return apiHostSeat.copyWith(seatNo: 1, role: 'host');
    }

    final hostId = receiverId.value.trim();
    final name = hostName.value.trim();
    if (hostId.isNotEmpty || name.isNotEmpty) {
      return AudioRoomSeatModel(
        seatNo: 1,
        userId: hostId,
        name: name.isNotEmpty ? name : 'Host',
        avatarUrl: hostAvatarUrl.value,
        avatarFrameUrl: hostAvatarFrameUrl.value,
        role: 'host',
      );
    }

    return AudioRoomSeatModel.empty(1);
  }

  List<AudioRoomSeatModel> _withCurrentUserFrame(
    List<AudioRoomSeatModel> seats,
  ) {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final currentUserId = session?.userId.trim() ?? '';
    final currentFrameUrl = session == null
        ? ''
        : session.profileFrameUrl.trim();
    if (currentUserId.isEmpty || currentFrameUrl.isEmpty) return seats;

    return seats
        .map(
          (seat) =>
              seat.userId == currentUserId &&
                  (seat.avatarFrameUrl?.trim().isEmpty ?? true)
              ? seat.copyWith(avatarFrameUrl: currentFrameUrl)
              : seat,
        )
        .toList();
  }

  int _readSeatConfig(dynamic data) {
    final value = data is Map
        ? data['seatConfig'] ?? data['maxSeats'] ?? data['seat_count']
        : null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    final roomConfig =
        _roomData['seatConfig'] ?? _roomData['maxSeats'] ?? _roomData['seats'];
    if (roomConfig is int) return roomConfig;
    if (roomConfig is num) return roomConfig.toInt();
    return int.tryParse(roomConfig?.toString() ?? '') ?? 16;
  }

  List<AudioRoomInviteCandidate> _parseInviteCandidates(dynamic data) {
    final users = data is Map ? data['users'] ?? data['data'] : data;
    if (users is! List) return const [];
    return users
        .whereType<Map>()
        .map(
          (raw) =>
              AudioRoomInviteCandidate.fromMap(Map<String, dynamic>.from(raw)),
        )
        .where((user) => user.id.trim().isNotEmpty && !user.isInRoom)
        .toList();
  }

  List<AudioRoomSeatModel> _buildFallbackAudioSeats() {
    final maxSeats = _readSeatConfig(_roomData);
    final seats = <AudioRoomSeatModel>[_pinHostToFirstSeat(const [])];
    var seatNo = 2;
    final hostUserId = receiverId.value.trim();

    for (final viewer in liveViewers) {
      if (seatNo > maxSeats) break;
      if (viewer['isHost'] == true) continue;
      final viewerId =
          viewer['targetId']?.toString() ?? viewer['id']?.toString() ?? '';
      if (_isSameRoomUser(viewerId, hostUserId)) continue;
      seats.add(
        AudioRoomSeatModel(
          seatNo: seatNo,
          userId: viewerId,
          name: viewer['name']?.toString() ?? 'Member',
          avatarUrl: viewer['avatarUrl']?.toString(),
          diamonds: 0,
        ),
      );
      seatNo++;
    }

    while (seatNo <= maxSeats) {
      seats.add(AudioRoomSeatModel.empty(seatNo));
      seatNo++;
    }
    return seats;
  }

  bool _isApiSuccess(Map<String, dynamic>? response) {
    return response?['statusCode'] == 1 || response?['success'] == true;
  }

  void _showRoomApiError(
    String title,
    Map<String, dynamic>? response,
    String fallback,
  ) {
    _showRoomToast(
      title,
      _seatManageErrorMessage(response, fallback),
      isError: true,
    );
  }

  String _seatManageErrorMessage(
    Map<String, dynamic>? response,
    String fallback,
  ) {
    final data = response?['data'];
    final code =
        (response?['code'] ??
                response?['errorCode'] ??
                response?['error_code'] ??
                (data is Map
                    ? (data['code'] ?? data['errorCode'] ?? data['error_code'])
                    : null))
            ?.toString()
            .trim()
            .toUpperCase();

    switch (code) {
      case 'CANNOT_REMOVE_HOST_SEAT':
        return 'The host seat cannot be cleared this way.';
      case 'SEAT_OCCUPIED':
        return 'That seat is already taken.';
      case 'SEAT_LOCKED':
        return 'That seat is locked.';
      case 'USER_NOT_ON_SEAT':
        return 'This user is not on that seat.';
      case 'USER_ALREADY_SEATED':
        return 'This user is already on a seat.';
      case 'NOT_IN_ROOM':
        return 'This user is not in the room.';
      case 'NOT_HOST':
      case 'FORBIDDEN':
        return 'Only the host or room admin can do this.';
      case 'INVALID_ACTION':
        return 'This seat action is not supported yet.';
    }

    final message = response?['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    return fallback;
  }

  Future<void> toggleFollowHost() async {
    if (isHost.value) return;
    final targetId = receiverId.value.trim();
    if (targetId.isEmpty) {
      _showRoomToast(
        'Follow',
        'Host profile is not available for this room.',
        isError: true,
      );
      return;
    }

    final action = isFollowingHost.value ? 'unfollow' : 'follow';
    final response = await _authRepo.followUnfollow(
      targetId: targetId,
      action: action,
      isShowLoader: true,
    );

    if (response != null && response['statusCode'] == 1) {
      final data = response['data'];
      final following = data is Map
          ? data['isFollowing'] == true
          : action == 'follow';
      isFollowingHost.value = following;
      _showRoomToast(
        following ? 'Following' : 'Unfollowed',
        following
            ? 'You are now following ${hostName.value}.'
            : 'You unfollowed ${hostName.value}.',
      );
      return;
    }

    _showRoomToast(
      'Follow',
      response?['message']?.toString() ?? 'Unable to update follow status.',
      isError: true,
    );
  }

  /// Opens PK Battle host selection — pick a live audio/video host, then invite.
  ///
  /// Never auto-starts a battle. Seat-badge follower joins still use
  /// [joinFollowerPkFromSeat].
  void openPkBattle() => openPkV1Arena();

  /// Opens the host-vs-host PK arena on the eligible-hosts selection screen.
  /// Once a battle starts, the arena pops and this live room converts to PK UI.
  void openPkV1Arena() {
    if (isInRoomPkActive) {
      _showRoomToast(
        'PK Battle',
        'A PK battle is already in progress in this room.',
        isWarning: true,
      );
      return;
    }
    final roomApiId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (roomApiId.isEmpty) {
      _showRoomToast(
        'PK Battle',
        'Room id is missing. Rejoin the room and try again.',
        isError: true,
      );
      return;
    }

    // Keep a shared controller so the in-room overlay can reuse the same session.
    final pk = PkV1Coordinator.ensureController();
    pk.bindLiveRoomContext(
      roomId: roomApiId,
      name: hostName.value,
      avatar: hostAvatarUrl.value,
    );
    // Always reopen on the host-selection list (never auto-start).
    pk.prepareHostSelection();

    Get.toNamed(
      Routes.PK_V1_ARENA,
      arguments: {
        'roomId': roomApiId,
        'room_id': roomApiId,
        'selfName': hostName.value,
        'selfAvatar': hostAvatarUrl.value ?? '',
        'selectionOnly': true,
      },
    );
  }

  /// True when host-vs-host PK should replace the seat grid in this room.
  bool get isInRoomPkActive {
    // Bridge flag is always readable by Obx (stable rebuild trigger).
    if (PkLiveRoomBridge.isActive.value || isPkBattleActive.value) {
      if (!Get.isRegistered<PkV1Controller>()) return true;
      final pk = Get.find<PkV1Controller>();
      return pk.stage.value == PkArenaStage.battling ||
          pk.stage.value == PkArenaStage.starting ||
          pk.stage.value == PkArenaStage.finished;
    }
    if (!Get.isRegistered<PkV1Controller>()) return false;
    final pk = Get.find<PkV1Controller>();
    if (!pk.embeddedInLiveRoom.value) return false;
    return pk.stage.value == PkArenaStage.battling ||
        pk.stage.value == PkArenaStage.starting ||
        pk.stage.value == PkArenaStage.finished;
  }

  void setPkBattleActive(bool active) {
    isPkBattleActive.value = active;
    PkLiveRoomBridge.setActive(active);
    if (active) {
      _syncPkLocalAudience();
    }
  }

  void joinFollowerPkFromSeat(AudioRoomSeatModel seat) {
    final battle = seat.pkBattle;
    final roomApiId = audioRoomApiId.trim();
    if (battle == null || battle.battleId.isEmpty || roomApiId.isEmpty) return;
    Get.toNamed(
      Routes.PK_BATTLE,
      arguments: {
        'mode': 'audio_follower_pk',
        'room_id': roomApiId,
        'battle_id': battle.battleId,
        'join_from_room': true,
        'title': streamTitle.value,
        'name': hostName.value,
      },
    );
  }

  Future<void> shareRoom() async {
    final shareId = audioRoomApiId.isNotEmpty ? audioRoomApiId : 'room';
    var roomUrl = 'https://qobo.live/room/$shareId';
    final response = await _roomRepo.getShareLink(
      roomId: shareId,
      isShowLoader: false,
    );
    if (_isApiSuccess(response)) {
      final data = response?['data'];
      if (data is Map) {
        final backendLink =
            data['link']?.toString() ??
            data['url']?.toString() ??
            data['shareUrl']?.toString();
        if (backendLink != null && backendLink.trim().isNotEmpty) {
          roomUrl = backendLink.trim();
        }
      }
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SemiBoldText(
                text: 'Share Room Link',
                fontSize: 16,
                color: kColorWhite,
              ),
            ),
            Spacing.v20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(Icons.copy_rounded, 'Copy Link', Colors.blue, () {
                  Clipboard.setData(ClipboardData(text: roomUrl));
                  Get.back();
                  _showRoomToast(
                    'Link Copied!',
                    'Room URL copied to clipboard: $roomUrl',
                  );
                }),
                _shareOption(
                  Icons.wechat_rounded,
                  'WhatsApp',
                  Colors.green,
                  () {
                    Get.back();
                    _showRoomToast(
                      'Shared',
                      'Room shared successfully to WhatsApp!',
                    );
                  },
                ),
                _shareOption(
                  Icons.facebook_rounded,
                  'Facebook',
                  Colors.indigo,
                  () {
                    Get.back();
                    _showRoomToast(
                      'Shared',
                      'Room shared successfully to Facebook!',
                    );
                  },
                ),
                _shareOption(
                  Icons.message_rounded,
                  'Messages',
                  Colors.orange,
                  () {
                    Get.back();
                    _showRoomToast(
                      'Shared',
                      'Room shared successfully via SMS!',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _shareOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Spacing.v6,
          AppText(text: label, fontSize: 10, color: kColorWhite),
        ],
      ),
    );
  }

  void toggleMic() {
    if (isLiveStreamingSession) {
      final nextMuted = !isMicMuted.value;
      isMicMuted.value = nextMuted;
      try {
        unawaited(ZegoExpressEngine.instance.muteMicrophone(nextMuted));
      } catch (_) {}
      return;
    }
    try {
      final mic =
          ZegoUIKitPrebuiltLiveStreamingController().audioVideo.microphone;
      mic.switchState();
      isMicMuted.value = !mic.localState;
    } catch (_) {
      isMicMuted.value = !isMicMuted.value;
    }
  }

  void toggleCamera() {
    if (!isVideoRoom) return;
    if (isLiveStreamingSession) {
      final nextOff = !isCameraOff.value;
      isCameraOff.value = nextOff;
      try {
        unawaited(ZegoExpressEngine.instance.enableCamera(!nextOff));
      } catch (_) {}
      return;
    }
    try {
      // Party video rooms use the group-call Zego engine (not live-streaming).
      if (isAudioVideoRoom) {
        final userId = ZegoUIKit().getLocalUser().id;
        final isOn = ZegoUIKit().getCameraStateNotifier(userId).value;
        ZegoUIKit().turnCameraOn(!isOn);
        isCameraOff.value = isOn;
        return;
      }
      final camera =
          ZegoUIKitPrebuiltLiveStreamingController().audioVideo.camera;
      camera.switchState();
      isCameraOff.value = !camera.localState;
    } catch (_) {
      isCameraOff.value = !isCameraOff.value;
    }
  }

  /// Flip front/back camera for video party rooms.
  void flipGroupCallCamera() {
    if (!isVideoRoom || !isAudioVideoRoom) return;
    try {
      final userId = ZegoUIKit().getLocalUser().id;
      final isFront = ZegoUIKit()
          .getUseFrontFacingCameraStateNotifier(userId)
          .value;
      unawaited(ZegoUIKit().useFrontFacingCamera(!isFront));
    } catch (_) {}
  }

  void leaveRoom() {
    if (isHost.value) {
      if (isAudioVideoRoom) {
        confirmEndRoom();
      } else {
        confirmEndLiveStream();
      }
      return;
    }
    _stopSeatRefreshPolling();
    unawaited(_reportAudioVideoRoomExit());
    Get.back();
  }

  void confirmEndRoom() {
    final isVideo = isVideoRoom;
    final title = isVideo ? 'End video room?' : 'End audio room?';
    final body = isVideo
        ? 'This will end the video room for everyone and close the session.'
        : 'This will end the audio room for everyone and close the session.';
    CommonAppDialog.showGet(
      title: title,
      message: body,
      icon: Icons.meeting_room_rounded,
      iconAccent: AdminAgencyUi.rose,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'End Room',
          isPrimary: true,
          isDestructive: true,
          onPressed: endRoomForEveryone,
        ),
      ],
    );
  }

  void confirmEndLiveStream() {
    CommonAppDialog.showGet(
      title: 'End live stream?',
      message:
          'This will end your live stream for all viewers and close the session.',
      icon: Icons.videocam_off_rounded,
      iconAccent: AdminAgencyUi.rose,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'End Live',
          isPrimary: true,
          isDestructive: true,
          onPressed: endLiveStreamForEveryone,
        ),
      ],
    );
  }

  Future<void> endLiveStreamForEveryone() async {
    if (_exitReported) return;
    final liveStreamingId = liveStreamingApiId;
    Map<String, dynamic>? response;

    // Live streaming and audio/video rooms use different backend resources.
    // Keep this path isolated so closing a Go Live stream never calls room APIs.
    if (liveStreamingId.isNotEmpty) {
      try {
        final endedAt = DateTime.now().toUtc();
        final startedAt = _resolveLiveStartedAtUtc();
        final durationSeconds = endedAt
            .difference(startedAt)
            .inSeconds
            .clamp(0, 1 << 31);
        response = await _roomRepo.endLiveStreaming(
          liveStreamingId: liveStreamingId,
          startedAt: startedAt.toIso8601String(),
          endedAt: endedAt.toIso8601String(),
          durationSeconds: durationSeconds,
          isShowLoader: true,
        );
      } catch (_) {
        response = null;
      }
    }

    final apiConfirmed = liveStreamingId.isNotEmpty && _isApiSuccess(response);
    await _closeLiveStreamLocally();

    if (apiConfirmed) return;

    final fallback = liveStreamingId.isEmpty
        ? 'Live stream id was missing, but the stream was closed on this device.'
        : 'Backend could not confirm the end request, but the stream was closed on this device.';
    _showRoomToast(
      'Live stream closed',
      response?['message']?.toString() ?? fallback,
      isWarning: true,
    );
  }

  DateTime _resolveLiveStartedAtUtc() {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final nested =
        asMap(_roomData['room']) ??
        asMap(_roomData['liveStreaming']) ??
        asMap(_roomData['live_streaming']);
    final raw =
        readRoomField(_roomData, const [
          'startedAt',
          'started_at',
          'createdAt',
          'created_at',
        ]) ??
        (nested == null
            ? null
            : readRoomField(nested, const [
                'startedAt',
                'started_at',
                'createdAt',
                'created_at',
              ]));
    final parsed = DateTime.tryParse(raw ?? '');
    return parsed?.toUtc() ?? _liveScreenOpenedAtUtc;
  }

  Future<void> _closeLiveStreamLocally() async {
    _exitReported = true;
    _stopSeatRefreshPolling();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final poppedLiveRoute = _popLiveBroadcastRoute();
    if (!poppedLiveRoute) {
      Get.offAllNamed(Routes.BOTTOM_NAV);
    }
  }

  bool _popLiveBroadcastRoute() {
    final navigator = Get.key.currentState;
    if (navigator == null) return false;

    if (Get.currentRoute == Routes.LIVE_BROADCAST) {
      if (!navigator.canPop()) return false;
      navigator.pop();
      return true;
    }

    var removedLiveBroadcast = false;
    if (navigator.canPop()) {
      navigator.popUntil((route) {
        if (route.settings.name == Routes.LIVE_BROADCAST) {
          removedLiveBroadcast = true;
          return false;
        }
        return removedLiveBroadcast || route.isFirst;
      });
    }

    // If GetX/Zego placed the page on an unnamed route, still leave the
    // current live screen after the backend confirms the stream has ended.
    if (!removedLiveBroadcast && navigator.canPop()) {
      navigator.pop();
      return true;
    }

    return removedLiveBroadcast;
  }

  Future<void> endRoomForEveryone() async {
    if (_exitReported) return;
    final backendRoomId = audioRoomApiId;
    if (backendRoomId.isEmpty) {
      Get.back();
      _showRoomToast(
        'End room',
        'Room id is missing, so this room cannot be ended.',
        isError: true,
      );
      return;
    }

    final response = await _roomRepo.endRoom(
      roomId: backendRoomId,
      isShowLoader: true,
    );

    if (_isApiSuccess(response)) {
      _hostEndConfirmed = true;
      _exitReported = true;
      _stopSeatRefreshPolling();
      if (Get.isDialogOpen == true) Get.back();
      Get.back();
      return;
    }

    if (Get.isDialogOpen == true) Get.back();
    _showRoomApiError('End room', response, 'Unable to end this room.');
  }

  /// Ends a host room only after Zego's hang-up confirmation was accepted.
  ///
  /// This deliberately does not navigate; returning `true` lets the prebuilt
  /// call widget perform its normal, single route exit.
  Future<bool> endRoomAfterConfirmedHangUp() async {
    if (!isHost.value || !_isAudioVideoRoomPayload()) return true;
    if (_exitReported) return true;

    final backendRoomId = audioRoomApiId;
    if (backendRoomId.isEmpty) {
      _showRoomToast(
        'End room',
        'Room id is missing, so this room cannot be ended.',
        isError: true,
      );
      return false;
    }

    final response = await _roomRepo.endRoom(
      roomId: backendRoomId,
      isShowLoader: true,
    );
    if (!_isApiSuccess(response)) {
      _showRoomApiError('End room', response, 'Unable to end this room.');
      return false;
    }

    _exitReported = true;
    _hostEndConfirmed = true;
    _stopSeatRefreshPolling();
    return true;
  }

  void reportRoomExit() {
    // Host room termination must only happen through an explicit confirmed
    // action, never from Zego lifecycle/rebuild callbacks.
    if (isHost.value) return;
    unawaited(_reportAudioVideoRoomExit());
  }

  String get liveStreamingApiId {
    // The Zego channel now runs on the backend room id, so the
    // `/api/live-streaming/end` resource id must be read from the dedicated
    // liveStreamingId keys before any Zego channel keys.
    final apiId = _firstNonEmpty(_roomData, const [
      'liveStreamingId',
      'livestreamingId',
      'live_streaming_id',
      'liveStreamId',
      'live_id',
      'liveId',
    ]);
    return (apiId ?? _extractStreamingId(_roomData) ?? roomId.value).trim();
  }

  /// Reports audience leave for group-call rooms and live streams so backend
  /// viewer/heat counts stay in sync with joins.
  Future<void> _reportAudioVideoRoomExit() async {
    if (isHost.value || _exitReported) return;
    _exitReported = true;
    _stopSeatRefreshPolling();

    if (isLiveStreamingSession) {
      final liveId = liveStreamingApiId.trim();
      final backendRoomId = _extractBackendRoomId(_roomData);
      await _roomRepo.leaveLiveStreaming(
        roomId: backendRoomId,
        liveStreamingId: liveId.isNotEmpty ? liveId : null,
        isShowLoader: false,
      );
      return;
    }

    final backendRoomId = _extractBackendRoomId(_roomData);
    if (backendRoomId == null || backendRoomId.trim().isEmpty) return;

    await _roomRepo.leaveRoom(roomId: backendRoomId, isShowLoader: false);
  }

  bool _isLiveStreamPayloadType(String? type) {
    return type == 'live_stream' ||
        type == 'livestream' ||
        type == 'live-stream';
  }

  /// Party rooms (AUDIO/VIDEO) use group-call UI. Live streams use the separate
  /// live-streaming UI. Navigation `roomType` AUDIO/VIDEO wins when the create
  /// API omits `type` / `roomId` keys; explicit `live_stream` payload still
  /// forces live UI for list/push joins that pass a generic VIDEO nav type.
  bool _isAudioVideoRoomPayload() {
    final type = readRoomField(_roomData, ['type', 'roomType'])?.toLowerCase();
    if (_isLiveStreamPayloadType(type)) return false;

    final nav = _normalizedNavRoomType;
    if (nav == 'LIVE_STREAM' || nav == 'LIVESTREAM') return false;
    if (nav == 'AUDIO' || nav == 'VIDEO') return true;

    return type == 'audio' || type == 'video';
  }

  @override
  void onClose() {
    _pkActiveWorker?.dispose();
    _pkActiveWorker = null;
    CoinFlyOverlay.dismiss();
    AvatarFlyOverlay.dismiss();
    _stopSeatRefreshPolling();
    _stopSessionEarningsPolling();
    _stopJoinRequestPolling();
    _stopSeatRequestPolling();
    _promptedJoinRequestIds.clear();
    _promptedSeatRequestIds.clear();
    _knownFloorAudienceIds.clear();
    _floorAudienceHydrated = false;
    _unbindSeatRequestSocket();
    _unbindRoomBackgroundSocket();
    _vipEntrancePlayedUserIds.clear();
    _vipSeatEntranceBaselineReady = false;
    VipEntranceOverlay.dismiss();
    _messageSub?.cancel();
    _userSub?.cancel();
    _mediaSub?.cancel();
    _giftCelebrationTracker.reset();
    GiftCelebrationOverlay.dismiss();
    EmojiCelebrationOverlay.dismiss();
    for (final timer in _seatEmojiTimers.values) {
      timer.cancel();
    }
    _seatEmojiTimers.clear();
    activeSeatEmojis.clear();
    if (_viewerCountListener != null) {
      try {
        ZegoUIKitPrebuiltLiveStreamingController().user.countNotifier
            .removeListener(_viewerCountListener!);
      } catch (_) {}
    }
    chatTextController.dispose();
    super.onClose();
  }
}
