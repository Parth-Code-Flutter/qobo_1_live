import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
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
import 'package:qobo_one_live/utils/session_earnings_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_celebration_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_chat_celebration_tracker.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/coin_fly_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/avatar_fly_overlay.dart';
import 'package:qobo_one_live/utils/ui_utils/vip_entrance_overlay.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

import '../models/audio_room_models.dart';
import '../models/room_background_theme.dart';
import '../utils/live_room_profile_utils.dart';
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
  }) : _economyRepo = economyRepo ?? EconomyRepo(),
       _authRepo = authRepo ?? AuthRepo(),
       _roomRepo = roomRepo ?? RoomRepo();

  final EconomyRepo _economyRepo;
  final AuthRepo _authRepo;
  final RoomRepo _roomRepo;

  final isHost = false.obs;
  /// Host-vs-host PK overlay is replacing the seat grid / live stage.
  final isPkBattleActive = false.obs;
  final roomType = 'VIDEO'.obs;
  final roomId = ''.obs;
  final receiverId = ''.obs;
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

  final chatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  final coinsBalance = 0.obs;
  final diamondsBalance = 0.obs;
  final sessionEarnings = SessionEarningsTracker();

  /// Target for gullak-style coin fly animation into the host earnings pill.
  final sessionEarningsBadgeKey = GlobalKey(debugLabel: 'sessionEarningsBadge');

  /// Target for floor-audience join fly animation into the AppBar people badge.
  final floorAudienceBadgeKey = GlobalKey(debugLabel: 'floorAudienceBadge');
  final giftCatalog = <Map<String, String>>[].obs;
  final isLoadingGifts = false.obs;
  final selectedGiftReceiverId = RxnString();
  final selectedGiftReceiverName = RxnString();
  final isRoomGiftMode = true.obs;
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
  void Function(Map<String, dynamic>)? _roomBackgroundSocketListener;
  void Function(Map<String, dynamic>)? _vipUserJoinedSocketListener;

  /// Dedupes gift celebrations triggered by Zego gift chat events (all room kinds).
  final GiftChatCelebrationTracker _giftCelebrationTracker =
      GiftChatCelebrationTracker();

  /// Play VIP entrance SVGA only once per user for this room session.
  final Set<String> _vipEntrancePlayedUserIds = <String>{};
  var _vipSeatEntranceBaselineReady = false;

  Timer? _seatRefreshTimer;
  Timer? _sessionEarningsTimer;
  Timer? _joinRequestPollTimer;
  final Set<String> _promptedJoinRequestIds = <String>{};
  VoidCallback? _viewerCountListener;
  Worker? _pkActiveWorker;
  var _exitReported = false;
  var _hostEndConfirmed = false;

  /// True when PK forced the camera on (e.g. audio room → PK video panes).
  var _pkForcedCameraOn = false;

  /// After join, used to auto-close the room when seat sync shows removal/kick.
  var _roomMembershipConfirmed = false;
  var _currentUserOccupiedMicSeat = false;

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
        final backendRoomId = _extractBackendRoomId(_roomData);
        final rawId = _isAudioVideoRoomPayload()
            ? (backendRoomId ?? streamingId ?? '')
            : (streamingId ?? backendRoomId ?? '');
        roomId.value = ZegoLiveIdUtils.sanitize(rawId);
      }
    }
    joinApprovalRequired.value = JoinApprovalService.isApprovalRequired(
      _roomData,
    );
    _hydrateHostProfile();
    _hydrateRoomBackground();
    _seedSessionEarningsFromRoom();
    _validateStreamingInput();
    loadWalletBalance();
    loadGiftCatalog();
    _pkActiveWorker = ever<bool>(PkLiveRoomBridge.isActive, (active) {
      if (active) {
        _syncPkLocalAudience();
        ensurePkHostVideoReady();
      } else {
        restoreCameraAfterPk();
      }
    });
    if (isHost.value) {
      _startSessionEarningsPolling();
    }
    if (isAudioVideoRoom) {
      // Open join + seat-request realtime for host and guests.
      unawaited(_bootstrapPartyRoomRealtime());
      final initialSeats = _parseAudioSeats(_roomData);
      if (initialSeats.isNotEmpty) {
        audioRoomSeats.assignAll(initialSeats);
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
    final backendRoomId = _extractBackendRoomId(_roomData)?.trim();
    if (backendRoomId == null || backendRoomId.isEmpty) return;
    final joinRequestId =
        _roomData['join_request_id']?.toString().trim() ??
        _roomData['joinRequestId']?.toString().trim();
    unawaited(
      _roomRepo
          .joinRoom(
            roomId: backendRoomId,
            joinRequestId: (joinRequestId != null && joinRequestId.isNotEmpty)
                ? joinRequestId
                : null,
            sessionType: 'live_stream',
            isShowLoader: false,
          )
          .catchError((_) => null),
    );
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
      active: status == 'waiting_opponent' ||
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
      audioRoomSeats.assignAll(next);
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
      addMember(
        userId: user.userId,
        name: user.name,
        avatar: user.avatarUrl,
      );
    }
    for (final seat in audioRoomSeats) {
      if (!seat.occupied) continue;
      if (seat.role.toLowerCase() == 'host') continue;
      if (isExcluded(seat.userId)) continue;
      addMember(
        userId: seat.userId,
        name: seat.name,
        avatar: seat.avatarUrl,
      );
    }
    for (final viewer in liveViewers) {
      if (viewer['isHost'] == true) continue;
      if (isHost.value && viewer['isCurrentUser'] == true) continue;
      final viewerId = (viewer['targetId'] ??
              viewer['userId'] ??
              viewer['user_id'] ??
              viewer['id'] ??
              '')
          .toString();
      if (isExcluded(viewerId)) continue;
      addMember(
        userId: viewerId,
        name: (viewer['name'] ??
                viewer['displayName'] ??
                viewer['username'] ??
                'Viewer')
            .toString(),
        avatar: (viewer['avatarUrl'] ??
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
  }

  String get _sessionEarningsType {
    if (isLiveStreamingSession) return 'live_stream';
    if (isVideoRoom) return 'video_room';
    return 'audio_room';
  }

  void _startSessionEarningsPolling() {
    if (!isHost.value) return;
    _sessionEarningsTimer?.cancel();
    unawaited(_refreshSessionEarnings());
    _sessionEarningsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_exitReported || !isHost.value) {
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
    if (!isHost.value || _exitReported) return;
    final roomApiId = audioRoomApiId;
    if (roomApiId.isEmpty) return;

    final response = await _roomRepo.getSessionEarnings(
      roomId: roomApiId,
      sessionType: _sessionEarningsType,
      isShowLoader: false,
    );
    SessionEarningsUtils.ingestApiEnvelope(sessionEarnings, response);
  }

  void _applySessionEarningsFromGiftResponse({
    required Map<String, dynamic>? response,
    required int fallbackGiftPrice,
    required String scope,
    String? receiverId,
  }) {
    final myId = _currentUserId();
    final hostId = resolveHostId(_roomData) ?? this.receiverId.value.trim();
    if (myId.isEmpty) return;

    // Sender never earns from their own gift. Room gifts credit peers only.
    final normalized = scope.trim().toLowerCase();
    if (normalized == 'room') return;

    SessionEarningsUtils.ingestGiftResponse(
      tracker: sessionEarnings,
      response: response,
      hostUserId: hostId,
      earnerUserId: myId,
      hostReceivesRoomGifts: false,
      roomParticipantsEarn: false,
      fallbackGiftPrice: fallbackGiftPrice,
      scope: scope,
      receiverId: receiverId,
    );
  }

  /// Whether the local user earns from this gift.
  ///
  /// - `room`: seated participants only (floor audience excluded).
  /// - `user`: only the targeted receiver.
  /// When [creditedUserIds] is present (backend gift_sent), that list wins.
  bool _localUserEarnsGift({
    required String scope,
    String? receiverId,
    String? senderId,
    List<String>? creditedUserIds,
  }) {
    final myId = _currentUserId();
    if (myId.isEmpty) return false;
    final from = senderId?.trim() ?? '';
    if (from.isNotEmpty && _userIdsMatch(from, myId)) {
      // Sender pays — they do not earn.
      return false;
    }

    if (creditedUserIds != null && creditedUserIds.isNotEmpty) {
      return creditedUserIds.any((id) => _userIdsMatch(id, myId));
    }

    final normalized = scope.trim().toLowerCase();
    if (normalized == 'room') {
      // Room gifts credit mic seats only — not floor audience.
      return audioRoomSeats.any(
        (seat) => seat.occupied && _userIdsMatch(seat.userId, myId),
      );
    }
    final to = receiverId?.trim() ?? '';
    return to.isNotEmpty && _userIdsMatch(to, myId);
  }

  /// Optimistic seat diamond bump for gift recipients.
  ///
  /// Room gifts credit occupied seats except [excludeUserId] (sender).
  /// Floor audience is never bumped.
  void _bumpSeatDiamonds({
    required String scope,
    String? receiverId,
    required int amount,
    String? excludeUserId,
    List<String>? creditedUserIds,
  }) {
    if (amount <= 0 || !isAudioVideoRoom) return;
    final normalized = scope.trim().toLowerCase();
    final exclude = excludeUserId?.trim() ?? '';
    final credited = creditedUserIds
        ?.map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final targetId = normalized == 'room' ? '' : (receiverId?.trim() ?? '');
    if (normalized != 'room' &&
        targetId.isEmpty &&
        (credited == null || credited.isEmpty)) {
      return;
    }

    var changed = false;
    final next = audioRoomSeats.map((seat) {
      if (!seat.occupied) return seat;
      if (exclude.isNotEmpty && _userIdsMatch(seat.userId, exclude)) {
        return seat;
      }
      final matchCredited =
          credited != null &&
          credited.isNotEmpty &&
          credited.any((id) => _userIdsMatch(id, seat.userId));
      final matchRoom =
          normalized == 'room' && (credited == null || credited.isEmpty);
      final matchUser =
          normalized != 'room' && _userIdsMatch(seat.userId, targetId);
      if (matchCredited || matchRoom || matchUser) {
        changed = true;
        return seat.copyWith(diamonds: seat.diamonds + amount);
      }
      return seat;
    }).toList();
    if (changed) {
      audioRoomSeats.assignAll(next);
    }
  }

  Future<void> _playCoinFlyAfterGift({required int earnedCoins}) async {
    await GiftCelebrationOverlay.waitUntilIdle();
    if (_exitReported) return;
    _playEarningsCoinFlyAnimation(earnedCoins);
  }

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

  /// Shows session earnings dialog; Withdraw navigates to wallet withdraw.
  void openSessionEarningsDialog() {
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

  bool get canOpenZego => connectionIssue.value.isEmpty;

  void setConnectionIssue(String message) {
    connectionIssue.value = message;
  }

  void clearConnectionIssue() {
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

  /// True when room-scoped gifts have at least one other seated recipient.
  ///
  /// Party-room gifts credit **mic seats only** (not floor audience).
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
            ? 'This gift will be shared with everyone on a mic seat.'
            : 'This gift will be shared with everyone in the room.')
      : 'This gift will be sent privately to $giftTargetLabel.';

  /// Called after Zego room login — ensures host camera publishes and binds chat/users.
  void onZegoRoomLogined() {
    isZegoConnected.value = true;
    _bindZegoListeners();

    if (!isHost.value || !isVideoRoom) return;
    _turnOnHostMedia();
    Future.delayed(const Duration(milliseconds: 700), _turnOnHostMedia);
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
    _userSub = zego.user.stream(includeFakeUser: false).listen(_syncViewers);

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

  void _syncViewers(List<ZegoUIKitUser> users) {
    final normalizedHostId = ZegoLiveIdUtils.sanitizeUserId(receiverId.value);
    final hostTargetId = receiverId.value.trim();
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final mySanitized = ZegoLiveIdUtils.sanitizeUserId(
      session?.userId.isNotEmpty == true ? session!.userId : '',
    );

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
      messages.map((message) => _mapZegoMessage(message, myId)),
    );

    // When someone else shares a gift in the room, play the celebration.
    _maybeCelebrateIncomingGift(messages, myId);
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
      onPeerGift: (event) {
        unawaited(
          _handlePeerGiftEarnings(event.message, senderId: event.senderId),
        );
      },
    );
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
    // Room gifts: prefer per-seat amount_each; fall back to catalog price.
    final creditAmount = (amountEach != null && amountEach > 0)
        ? amountEach
        : price;

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

    final iEarn = _localUserEarnsGift(
      scope: scope,
      receiverId: receiverId,
      senderId: fromId,
      creditedUserIds: creditedIds,
    );
    if (!iEarn || _exitReported) return;

    final before = sessionEarnings.displayCoins;
    var earned = SessionEarningsUtils.ingestIncomingGiftChat(
      tracker: sessionEarnings,
      chatMessage: chatMessage,
      giftCatalog: giftCatalog.toList(),
      earnsGift: true,
    );

    if (earned <= 0 && creditAmount > 0) {
      sessionEarnings.applyDelta(coins: creditAmount);
      earned = creditAmount;
    } else if (earned <= 0) {
      await _refreshSessionEarnings();
      earned = sessionEarnings.displayCoins - before;
    }

    await GiftCelebrationOverlay.waitUntilIdle();
    if (_exitReported) return;
    _playEarningsCoinFlyAnimation(
      earned > 0 ? earned : (creditAmount > 0 ? creditAmount : 0),
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
    Get.snackbar(
      'Live stream',
      connectionIssue.value,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
      duration: const Duration(seconds: 4),
    );
  }

  void onGroupCallRoomConnected({bool bindMessages = true}) {
    isZegoConnected.value = true;
    connectionIssue.value = '';
    if (bindMessages) {
      _bindGroupCallMessageListener();
    }
    _bindGroupCallUserListener();
  }

  /// Keep viewer/participant count reactive for gift visibility in video rooms.
  void _bindGroupCallUserListener() {
    _userSub?.cancel();
    try {
      final kit = ZegoUIKit();
      _syncGroupCallUsers(kit.getAllUsers());
      _userSub = kit.getUserListStream().listen(_syncGroupCallUsers);
    } catch (_) {
      // Zego user stream may not be ready yet on first connect.
    }
  }

  void _syncGroupCallUsers(List<ZegoUIKitUser> users) {
    viewerCount.value = users.length;
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
    Get.snackbar(
      'Room call',
      connectionIssue.value,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
      duration: const Duration(seconds: 4),
    );
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
      final sent = isGroupCallRoom
          ? await ZegoUIKit().sendInRoomMessage(moderatedText)
          : await ZegoUIKitPrebuiltLiveStreamingController().message.send(
              moderatedText,
            );
      if (!sent) {
        Get.snackbar(
          'Message not sent',
          'Unable to send message to the room.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Message not sent',
        'Chat is not ready yet. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
    }

    if (containsBadWord) {
      Get.snackbar(
        'Moderation Filter',
        'Your comment was automatically filtered to keep the room safe.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber.shade900,
        colorText: kColorWhite,
        duration: const Duration(seconds: 3),
      );
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

    Get.snackbar(
      'Translation',
      'This message is already in your native language.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black26,
      colorText: kColorWhite,
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

  Future<void> sendGift(Map<String, String> gift) async {
    final int price = int.tryParse(gift['price'] ?? '0') ?? 0;
    if (coinsBalance.value < price) {
      Get.snackbar(
        'Insufficient Coins',
        'You need ${price - coinsBalance.value} more coins to send this gift.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
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
    final seatedRecipients = scope == 'room' && isAudioVideoRoom
        ? _seatedGiftRecipientIds(excludeUserId: myId)
        : const <String>[];

    // Room gift ("everyone on seats") — need another seated user with a real id.
    if (scope == 'room' && isAudioVideoRoom) {
      if (seatedRecipients.isEmpty) {
        Get.snackbar(
          'No audience',
          'No other seated users can receive this gift. Wait until someone is on a mic seat.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
        );
        return;
      }
      final totalCost = price * seatedRecipients.length;
      if (coinsBalance.value < totalCost) {
        Get.snackbar(
          'Insufficient Coins',
          'Room gifts are shared with ${seatedRecipients.length} seated users '
              '($totalCost coins). You need ${totalCost - coinsBalance.value} more.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: const Color(0xFFFFFFFF),
        );
        return;
      }
    } else if (scope == 'room' && !hasGiftAudience) {
      Get.snackbar(
        'No audience',
        "There's no audience to share gifts. Please wait for someone to join",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (giftId.isEmpty ||
        currentRoomId.isEmpty ||
        (scope == 'user' && currentReceiverId.isEmpty)) {
      Get.snackbar(
        'Gift not sent',
        scope == 'room'
            ? 'Gift or room id is missing from live room data.'
            : 'Gift, receiver, or room id is missing from live room data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }

    final sessionType = isAudioVideoRoom
        ? (isVideoRoom ? 'video_room' : 'audio_room')
        : 'live_stream';

    Map<String, dynamic>? response;

    if (scope == 'room' && isAudioVideoRoom && seatedRecipients.isNotEmpty) {
      // Party-room backend often returns "No seated users..." for scope=room
      // even when seats are occupied. Deliver via seated user gifts instead,
      // and still show a single "to the Room" chat celebration.
      response = await _sendRoomGiftViaSeatedFanOut(
        giftId: giftId,
        roomId: currentRoomId,
        recipientIds: seatedRecipients,
        sessionType: sessionType,
        price: price,
      );

      // If fan-out failed entirely, one last try at native room scope.
      if (!isEconomyApiSuccess(response)) {
        response = await _economyRepo.sendGift(
          receiverId: null,
          giftId: giftId,
          roomId: currentRoomId,
          scope: 'room',
          seatedUserIds: seatedRecipients,
          sessionType: sessionType,
          isShowLoader: true,
        );
      }
    } else {
      response = await _economyRepo.sendGift(
        receiverId: scope == 'room' ? null : currentReceiverId,
        giftId: giftId,
        roomId: currentRoomId,
        scope: scope,
        seatedUserIds: scope == 'room' ? seatedRecipients : null,
        sessionType: sessionType,
        isShowLoader: true,
      );
    }

    if (isEconomyApiSuccess(response)) {
      await _handleGiftSendSuccess(
        gift: gift,
        price: price,
        scope: scope,
        myId: myId,
        currentReceiverId: currentReceiverId,
        response: response,
        creditedFallbackIds: seatedRecipients,
      );
      return;
    }

    Get.snackbar(
      'Gift not sent',
      response?['message']?.toString() ?? 'Unable to send this gift.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: const Color(0xFFFFFFFF),
    );
  }

  /// Delivers a party-room "everyone" gift as per-seat user gifts.
  Future<Map<String, dynamic>?> _sendRoomGiftViaSeatedFanOut({
    required String giftId,
    required String roomId,
    required List<String> recipientIds,
    required String sessionType,
    required int price,
  }) async {
    Map<String, dynamic>? lastSuccess;
    final credited = <String>[];
    for (var i = 0; i < recipientIds.length; i++) {
      final targetId = recipientIds[i];
      final response = await _economyRepo.sendGift(
        receiverId: targetId,
        giftId: giftId,
        roomId: roomId,
        scope: 'user',
        sessionType: sessionType,
        isShowLoader: i == 0,
      );
      if (isEconomyApiSuccess(response)) {
        credited.add(targetId);
        lastSuccess = response;
      }
    }
    if (credited.isEmpty) return lastSuccess;
    // Normalize as a room-gift success so chat/UI use room wording + credited list.
    final data = <String, dynamic>{
      if (lastSuccess?['data'] is Map)
        ...Map<String, dynamic>.from(lastSuccess!['data'] as Map),
      'scope': 'room',
      'credited_user_ids': credited,
      'creditedUserIds': credited,
      'amount_each': price,
      'amountEach': price,
      'receiver': null,
    };
    return <String, dynamic>{
      'statusCode': 1,
      'success': true,
      'message': 'Gift sent successfully',
      'data': data,
    };
  }

  Future<void> _handleGiftSendSuccess({
    required Map<String, String> gift,
    required int price,
    required String scope,
    required String myId,
    required String currentReceiverId,
    required Map<String, dynamic>? response,
    List<String> creditedFallbackIds = const [],
  }) async {
    final beforeEarnings = sessionEarnings.displayCoins;
    // Direct gifts only — room gifts credit peers via the chat broadcast.
    _applySessionEarningsFromGiftResponse(
      response: response,
      fallbackGiftPrice: price,
      scope: scope,
      receiverId: currentReceiverId.isEmpty ? null : currentReceiverId,
    );
    final earnedDelta = (sessionEarnings.displayCoins - beforeEarnings).clamp(
      0,
      1 << 30,
    );

    var creditedIds = _parseCreditedUserIdsFromGiftResponse(response);
    if (creditedIds.isEmpty &&
        scope == 'room' &&
        creditedFallbackIds.isNotEmpty) {
      creditedIds = creditedFallbackIds;
    }
    final amountEach = _parseAmountEachFromGiftResponse(response);
    final creditAmount = (amountEach != null && amountEach > 0)
        ? amountEach
        : price;

    // Room → seated users only; user → targeted seat.
    _bumpSeatDiamonds(
      scope: scope,
      receiverId: currentReceiverId.isEmpty ? null : currentReceiverId,
      amount: creditAmount,
      excludeUserId: myId,
      creditedUserIds: creditedIds,
    );
    if (isAudioVideoRoom) {
      unawaited(loadAudioRoomSeats());
    }

    final animationUrl = GiftMediaUtils.animationUrlFromResponse(
      response,
      gift,
    );
    final soundUrl = GiftMediaUtils.soundUrlFromResponse(response, gift);

    // Same timing as audio rooms for video / live / group: close the sheet
    // first so it never covers the SVGA celebration on either side.
    unawaited(
      GiftMediaUtils.dismissSheetThenCelebrate(
        giftName: gift['name'],
        animationUrl: animationUrl,
        soundUrl: soundUrl,
      ),
    );

    // Coin-fly only when this device earned (direct gift to self).
    // Room gifts: peers earn via [_handlePeerGiftEarnings].
    if (earnedDelta > 0) {
      unawaited(_playCoinFlyAfterGift(earnedCoins: earnedDelta));
    }

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
      giftPrice: price,
      creditedUserIds: creditedIds,
      amountEach: amountEach ?? (scope == 'room' ? price : null),
    );
    // Always try the base UIKit bus. The live-streaming facade
    // (`message.send`) can silently no-op when its chat relay is unwired.
    unawaited(
      ZegoUIKit()
          .sendInRoomMessage(giftLabel)
          .then((sent) {
            if (sent) return;
            chatMessages.add({
              'sender': 'You',
              'message': stripGiftAnimMarker(giftLabel),
              'translation': '',
              'isTranslated': false,
              'isSystem': true,
            });
          })
          .catchError((_) {
            chatMessages.add({
              'sender': 'You',
              'message': stripGiftAnimMarker(giftLabel),
              'translation': '',
              'isTranslated': false,
              'isSystem': true,
            });
          }),
    );
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
      Get.snackbar(
        'PK Battle',
        'Hosts can’t send gifts during PK. Viewers support a side with gifts.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    // Host-vs-host PK: gift to Side A / Side B instead of room-wide gifts.
    if (roomGift &&
        isInRoomPkActive &&
        Get.isRegistered<PkV1Controller>()) {
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
      Get.snackbar(
        'Background',
        'Only the host or room admins can change the room background.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
      Get.snackbar(
        'Background',
        'Room id is missing for this background change.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: kColorWhite,
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
        Get.snackbar(
          'Background',
          'Room background updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
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
    if (apiRoomId.isEmpty) return;

    _unbindRoomBackgroundSocket();
    _vipUserJoinedSocketListener = _buildVipUserJoinedListener(apiRoomId);

    unawaited(() async {
      await UserRealtimeSocketService.ensureConnected();
      if (!Get.isRegistered<UserRealtimeSocketService>()) return;
      final socket = Get.find<UserRealtimeSocketService>();
      final vipListener = _vipUserJoinedSocketListener;
      if (vipListener != null) {
        socket.addVipUserJoinedListener(vipListener);
      }
      await socket.joinRoomChannel(apiRoomId);
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
    _roomBackgroundSocketListener = null;
    _vipUserJoinedSocketListener = null;
    if (!Get.isRegistered<UserRealtimeSocketService>()) return;
    final socket = Get.find<UserRealtimeSocketService>();
    if (bgListener != null) {
      socket.removeRoomBackgroundListener(bgListener);
    }
    if (vipListener != null) {
      socket.removeVipUserJoinedListener(vipListener);
    }
    unawaited(socket.leaveRoomChannel());
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
      Get.snackbar(
        'Filters',
        'Unable to apply filters on this device right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
      audioRoomSeats.assignAll(_buildFallbackAudioSeats());
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
        audioRoomSeats.assignAll(
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
        return;
      }

      if (_shouldTreatSeatsResponseAsRemoved(response)) {
        await _forceLeaveRoomBecauseRemoved(
          message: response?['message']?.toString(),
        );
        return;
      }

      if (audioRoomSeats.isEmpty) {
        audioRoomSeats.assignAll(_buildFallbackAudioSeats());
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

    await ZegoEngineUtils.resetForRoomProject().timeout(
      const Duration(milliseconds: 700),
      onTimeout: () {},
    );

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
        Get.snackbar(
          'Invite users',
          'Room id is missing, so followers cannot be loaded.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: kColorWhite,
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
      Get.snackbar(
        'Invite sent',
        '${user.name} has been invited to seat $seatNo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
      Get.snackbar(
        'Remove from seat',
        seatNo <= 1
            ? 'The host seat cannot be cleared this way.'
            : 'This seat has no user to remove.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
      Get.snackbar(
        'Removed from seat',
        memberName.isNotEmpty
            ? '$memberName was moved back to the floor.'
            : 'User was moved back to the floor.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
      Get.snackbar(
        'Seat',
        seatNo <= 1
            ? 'Pick a guest seat (2+), not the host seat.'
            : 'User id is missing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    final occupied = audioRoomSeats.any(
      (s) => s.seatNo == seatNo && s.occupied,
    );
    if (occupied) {
      Get.snackbar(
        'Seat',
        'Seat $seatNo is already taken.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
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
      Get.snackbar(
        'Seated',
        '$displayName joined seat $seatNo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
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
          audioRoomSeats.assignAll(seats);
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
      Get.snackbar(
        'Request',
        'No open mic seats are available right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }
    await requestSeatForSeatNo(targetSeat.seatNo);
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
      Get.snackbar(
        'Seat',
        'You are already on a seat.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
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
      Get.snackbar(
        'Request sent',
        'Waiting for the host to allow seat $seatNo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      await loadAudioRoomSeats();
      return;
    }

    final code =
        response?['code']?.toString() ??
        response?['errorCode']?.toString() ??
        '';
    if (code.toUpperCase() == 'FOLLOW_REQUIRED_FOR_SEAT') {
      Get.snackbar(
        'Follow required',
        response?['message']?.toString() ??
            'Follow the host to take a seat, or request one.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: kColorWhite,
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
    Get.snackbar(
      action == 'approve' ? 'Allowed' : 'Rejected',
      action == 'approve'
          ? '${request.name} can join seat ${request.seatNo}.'
          : 'Seat request rejected.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
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
        Get.snackbar(
          'Seat approved',
          'Host allowed you on a seat.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
        return;
      }

      if (event == 'seat_request_rejected') {
        Get.snackbar(
          'Seat request rejected',
          'Host declined your seat request.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
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
      if (seatListener != null) {
        socket.addSeatRequestListener(seatListener);
      }
      if (floorListener != null) {
        socket.addFloorAudienceListener(floorListener);
      }
      if (kickListener != null) {
        socket.addUserKickedListener(kickListener);
      }
      await socket.joinRoomChannel(apiRoomId);
    }());
  }

  void _unbindSeatRequestSocket() {
    if (!Get.isRegistered<UserRealtimeSocketService>()) {
      _seatRequestSocketListener = null;
      _floorAudienceSocketListener = null;
      _userKickedSocketListener = null;
      return;
    }
    final socket = Get.find<UserRealtimeSocketService>();
    final seatListener = _seatRequestSocketListener;
    final floorListener = _floorAudienceSocketListener;
    final kickListener = _userKickedSocketListener;
    if (seatListener != null) {
      socket.removeSeatRequestListener(seatListener);
    }
    if (floorListener != null) {
      socket.removeFloorAudienceListener(floorListener);
    }
    if (kickListener != null) {
      socket.removeUserKickedListener(kickListener);
    }
    _seatRequestSocketListener = null;
    _floorAudienceSocketListener = null;
    _userKickedSocketListener = null;
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
        Get.snackbar(
          label,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
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
    Get.snackbar(
      title,
      _seatManageErrorMessage(response, fallback),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: kColorWhite,
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
      Get.snackbar(
        'Follow',
        'Host profile is not available for this room.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
      Get.snackbar(
        following ? 'Following' : 'Unfollowed',
        following
            ? 'You are now following ${hostName.value}.'
            : 'You unfollowed ${hostName.value}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    Get.snackbar(
      'Follow',
      response?['message']?.toString() ?? 'Unable to update follow status.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
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
      Get.snackbar(
        'PK Battle',
        'A PK battle is already in progress in this room.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }
    final roomApiId = audioRoomApiId.trim().isNotEmpty
        ? audioRoomApiId.trim()
        : roomId.value.trim();
    if (roomApiId.isEmpty) {
      Get.snackbar(
        'PK Battle',
        'Room id is missing. Rejoin the room and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
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
                  Get.snackbar(
                    'Link Copied!',
                    'Room URL copied to clipboard: $roomUrl',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: kColorWhite,
                  );
                }),
                _shareOption(
                  Icons.wechat_rounded,
                  'WhatsApp',
                  Colors.green,
                  () {
                    Get.back();
                    Get.snackbar(
                      'Shared',
                      'Room shared successfully to WhatsApp!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _shareOption(
                  Icons.facebook_rounded,
                  'Facebook',
                  Colors.indigo,
                  () {
                    Get.back();
                    Get.snackbar(
                      'Shared',
                      'Room shared successfully to Facebook!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _shareOption(
                  Icons.message_rounded,
                  'Messages',
                  Colors.orange,
                  () {
                    Get.back();
                    Get.snackbar(
                      'Shared',
                      'Room shared successfully via SMS!',
                      snackPosition: SnackPosition.BOTTOM,
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
        response = await _roomRepo.endLiveStreaming(
          liveStreamingId: liveStreamingId,
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
    Get.snackbar(
      'Live stream closed',
      response?['message']?.toString() ?? fallback,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
    );
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
      Get.snackbar(
        'End room',
        'Room id is missing, so this room cannot be ended.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: kColorWhite,
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
      Get.snackbar(
        'End room',
        'Room id is missing, so this room cannot be ended.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: kColorWhite,
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
    _giftCelebrationTracker.reset();
    GiftCelebrationOverlay.dismiss();
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
