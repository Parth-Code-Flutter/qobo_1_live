import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/repo/pk/pk_repo.dart';
import 'package:qobo_one_live/repo/pk/pk_v1_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_winner_celebration_overlay.dart';
import 'package:qobo_one_live/services/pk/pk_live_room_bridge.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

/// Which sub-screen of the PK arena is active.
enum PkArenaStage { selecting, waiting, starting, battling, finished }

/// Drives the whole host-vs-host PK Battle v1 flow: host selection → invite →
/// live battle (server-authoritative timer + score) → result.
///
/// The server is the single source of truth for timer, score and winner. This
/// controller never computes score locally; it only renders what the socket /
/// REST endpoints report.
class PkV1Controller extends GetxController {
  PkV1Controller({
    PkV1Repo? repo,
    PkRepo? legacyPkRepo,
    RoomRepo? roomRepo,
    UserSessionController? session,
  })  : _repo = repo ?? PkV1Repo(),
        _legacyPkRepo = legacyPkRepo ?? PkRepo(),
        _roomRepo = roomRepo ?? RoomRepo(),
        _session = session ??
            (Get.isRegistered<UserSessionController>()
                ? Get.find<UserSessionController>()
                : Get.put(UserSessionController(), permanent: true));

  final PkV1Repo _repo;
  final PkRepo _legacyPkRepo;
  final RoomRepo _roomRepo;
  final UserSessionController _session;

  // ---- identity / context -------------------------------------------------
  String selfUserId = '';
  String selfName = '';
  String selfAvatar = '';
  String selfRoomId = '';

  // ---- reactive state -----------------------------------------------------
  final stage = PkArenaStage.selecting.obs;
  final isLoading = false.obs;

  // Host selection
  final eligibleHosts = <PkEligibleHost>[].obs;
  final searchText = ''.obs;

  // Invitations
  final outgoingInvitation = Rxn<PkInvitation>();
  final incomingInvitation = Rxn<PkInvitation>();

  // Battle
  final session = Rxn<PkSession>();
  final scoreA = 0.obs;
  final scoreB = 0.obs;
  final remainingSeconds = 0.obs;
  final lastGift = Rxn<PkGiftEvent>();
  final connectionNote = ''.obs; // e.g. "Reconnecting..."

  /// Raw server state-machine stage (`COUNTDOWN`, `BATTLE_ACTIVE`, …).
  final machineState = ''.obs;

  /// 5s pre-battle countdown from `PK_COUNTDOWN_TICK`.
  final countdownRemainingSec = 0.obs;

  /// Latest `PK_RTC_BRIDGE` payload (stream ids / tokens). Cleared on unbridge.
  final rtcBridge = Rxn<PkRtcBridgePayload>();

  /// Latest `PK_STATE_TRANSITION` (winner side available during punishment).
  final lastStateTransition = Rxn<PkStateTransition>();

  /// Per-side room audience (from `sideA`/`sideB.audienceList` only).
  final sideAAudience = <PkAudienceMember>[].obs;
  final sideBAudience = <PkAudienceMember>[].obs;

  /// Per-side top gifters (from `side*.topContributors` / score events).
  final sideATopContributors = <PkAudienceMember>[].obs;
  final sideBTopContributors = <PkAudienceMember>[].obs;

  /// Host PK-session earnings (diamonds) for the top/host cards.
  final sideADiamonds = 0.obs;
  final sideBDiamonds = 0.obs;

  // Result
  final result = Rxn<PkResult>();

  // Gift catalog for the side gift picker.
  final giftCatalog = <PkGiftCatalogItem>[].obs;

  /// When true, battle UI is rendered inside the live room (not the arena route).
  final embeddedInLiveRoom = false.obs;

  Timer? _clockTimer;
  Timer? _resyncTimer;
  Timer? _exitAfterResultTimer;
  Duration _serverOffset = Duration.zero;
  int _giftSeq = 0;
  bool _resultHandled = false;

  /// Dedupes gift celebration when both PK_GIFT_RECEIVED and score.lastGift fire.
  final Set<String> _presentedGiftKeys = <String>{};
  DateTime _presentedGiftPrunedAt = DateTime.fromMillisecondsSinceEpoch(0);

  UserRealtimeSocketService? get _socket =>
      Get.isRegistered<UserRealtimeSocketService>()
          ? Get.find<UserRealtimeSocketService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    _hydrateSelf();
    _readArguments();
    UserRealtimeSocketService.ensureConnected();
    _socket?.addPkBattleV1Listener(_onSocketEvent);
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _resyncTimer?.cancel();
    _exitAfterResultTimer?.cancel();
    PkWinnerCelebrationOverlay.dismiss();
    _socket?.removePkBattleV1Listener(_onSocketEvent);
    final pkId = session.value?.pkId;
    if (pkId != null && pkId.isNotEmpty) {
      _socket?.leavePkChannel(pkId);
    }
    super.onClose();
  }

  void _hydrateSelf() {
    selfUserId = _session.userId.trim();
    selfName = _session.displayName.trim();
    selfAvatar = (_session.displayPictureUrl ?? '').trim();
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is! Map) {
      _startAtSelection();
      return;
    }
    selfRoomId = (args['roomId'] ?? args['room_id'] ?? '').toString().trim();
    if ((args['selfName'] ?? '').toString().trim().isNotEmpty) {
      selfName = args['selfName'].toString().trim();
    }
    if ((args['selfAvatar'] ?? '').toString().trim().isNotEmpty) {
      selfAvatar = args['selfAvatar'].toString().trim();
    }

    final pkId = (args['pkId'] ?? args['pk_id'] ?? '').toString().trim();
    final invitationId =
        (args['invitationId'] ?? args['invitation_id'] ?? '').toString().trim();
    final selectionOnly = args['selectionOnly'] == true ||
        args['selection_only'] == true;

    if (pkId.isNotEmpty) {
      // Deep entry straight into an existing battle (accepted / watching).
      _enterBattleByPkId(pkId);
    } else if (invitationId.isNotEmpty && !selectionOnly) {
      // Accept an incoming invitation then enter the battle.
      acceptInvitationById(invitationId);
    } else {
      _startAtSelection();
    }
  }

  /// Hydrate identity from the live room without relying on Get.arguments.
  void bindLiveRoomContext({
    required String roomId,
    String? name,
    String? avatar,
  }) {
    selfRoomId = roomId.trim();
    if ((name ?? '').trim().isNotEmpty) selfName = name!.trim();
    if ((avatar ?? '').trim().isNotEmpty) selfAvatar = avatar!.trim();
  }

  /// Clears in-room PK mode and returns the live room to normal seats.
  void clearEmbeddedBattle() {
    _clockTimer?.cancel();
    _resyncTimer?.cancel();
    _exitAfterResultTimer?.cancel();
    _exitAfterResultTimer = null;
    PkWinnerCelebrationOverlay.dismiss();
    _resultHandled = false;
    final pkId = session.value?.pkId;
    if (pkId != null && pkId.isNotEmpty) {
      _socket?.leavePkChannel(pkId);
    }
    session.value = null;
    result.value = null;
    outgoingInvitation.value = null;
    scoreA.value = 0;
    scoreB.value = 0;
    remainingSeconds.value = 0;
    countdownRemainingSec.value = 0;
    machineState.value = '';
    rtcBridge.value = null;
    lastStateTransition.value = null;
    connectionNote.value = '';
    sideAAudience.clear();
    sideBAudience.clear();
    sideATopContributors.clear();
    sideBTopContributors.clear();
    sideADiamonds.value = 0;
    sideBDiamonds.value = 0;
    _presentedGiftKeys.clear();
    embeddedInLiveRoom.value = false;
    PkLiveRoomBridge.setActive(false);
    stage.value = PkArenaStage.selecting;
  }

  void _startAtSelection() {
    stage.value = PkArenaStage.selecting;
    loadEligibleHosts();
    loadGiftCatalog();
  }

  /// Temporary local-only preview of the in-room PK battle UI (no API).
  ///
  /// Used for design QA from live streaming. Call [clearEmbeddedBattle] or
  /// End PK on the overlay to dismiss.
  void loadUiPreview({
    String? selfName,
    String? selfAvatar,
    String? selfRoomId,
  }) {
    _clockTimer?.cancel();
    _resyncTimer?.cancel();
    _exitAfterResultTimer?.cancel();
    _resultHandled = false;

    // selfName kept for call-site API; preview always uses design-ref hosts.
    final avatarA = selfAvatar ?? this.selfAvatar;
    final roomA = (selfRoomId ?? this.selfRoomId).trim();
    assert(selfName == null || selfName is String);

    session.value = PkSession(
      pkId: 'ui_preview_${DateTime.now().millisecondsSinceEpoch}',
      status: PkSessionStatus.live,
      mode: 'ONE_VS_ONE',
      durationSec: 180,
      remainingSec: 165,
      startsAt: DateTime.now().toUtc().subtract(const Duration(seconds: 15)),
      endsAt: DateTime.now().toUtc().add(const Duration(seconds: 165)),
      serverTime: DateTime.now().toUtc(),
      currentUserSide: PkBattleSide.a,
      sideA: PkSideInfo(
        hostId: selfUserId.isEmpty ? 'preview_host_a' : selfUserId,
        // TEMP mock hosts for UI preview — matches design reference.
        displayName: 'Mike_Stream',
        avatarUrl: avatarA,
        roomId: roomA.isEmpty ? 'preview_room_a' : roomA,
        score: 215000,
        followerCount: 98000,
      ),
      sideB: const PkSideInfo(
        hostId: 'preview_host_b',
        displayName: 'Sarah_Live',
        avatarUrl: '',
        roomId: 'preview_room_b',
        score: 238000,
        followerCount: 105000,
      ),
    );
    scoreA.value = 215000;
    scoreB.value = 238000;
    sideADiamonds.value = 1200;
    sideBDiamonds.value = 980;
    remainingSeconds.value = 165;
    sideATopContributors.assignAll(const [
      PkAudienceMember(
        userId: 'g1',
        displayName: 'Alex',
        avatarUrl: '',
        points: 900,
        rank: 1,
      ),
      PkAudienceMember(
        userId: 'g2',
        displayName: 'Sam',
        avatarUrl: '',
        points: 700,
        rank: 2,
      ),
    ]);
    sideBTopContributors.assignAll(const [
      PkAudienceMember(
        userId: 'g4',
        displayName: 'Mia',
        avatarUrl: '',
        points: 1100,
        rank: 1,
      ),
      PkAudienceMember(
        userId: 'g5',
        displayName: 'Lee',
        avatarUrl: '',
        points: 500,
        rank: 2,
      ),
    ]);
    sideAAudience.assignAll(const [
      PkAudienceMember(
        userId: 'a1',
        displayName: 'ViewerA1',
        avatarUrl: '',
      ),
      PkAudienceMember(
        userId: 'a2',
        displayName: 'ViewerA2',
        avatarUrl: '',
      ),
    ]);
    sideBAudience.assignAll(const [
      PkAudienceMember(
        userId: 'b1',
        displayName: 'ViewerB1',
        avatarUrl: '',
      ),
    ]);
    stage.value = PkArenaStage.battling;
    embeddedInLiveRoom.value = true;
    PkLiveRoomBridge.setActive(true);
    _startClock();
  }

  /// Public entry used by the live room when opening the invite list again.
  void prepareHostSelection() {
    embeddedInLiveRoom.value = false;
    PkLiveRoomBridge.setActive(false);
    outgoingInvitation.value = null;
    incomingInvitation.value = null;
    result.value = null;
    _resultHandled = false;
    _startAtSelection();
  }

  // ========================================================================
  // Host selection + invitations
  // ========================================================================

  Future<void> loadEligibleHosts({String? search}) async {
    try {
      isLoading.value = true;
      final query = (search ?? searchText.value).trim();

      // 1) Preferred: /api/v1/pk/eligible-hosts
      final body = await _repo.getEligibleHosts(search: query);
      var hosts = _parseEligibleHosts(PkV1Repo.dataOf(body)['items'] ??
          PkV1Repo.dataOf(body)['hosts']);

      // 2) Fallback: /api/pk/search (legacy PK opponents)
      if (hosts.isEmpty && selfRoomId.isNotEmpty) {
        final legacy = await _legacyPkRepo.searchOpponents(
          roomId: selfRoomId,
          isShowLoader: false,
        );
        hosts = _hostsFromLegacySearch(legacy?['data'], query);
      }

      // 3) Fallback: /api/room/list — all active audio/video/live rooms
      if (hosts.isEmpty) {
        hosts = await _hostsFromActiveRooms(query);
      }

      // Never list our own room / self as an invite target.
      eligibleHosts.assignAll(
        hosts.where((h) {
          if (selfRoomId.isNotEmpty && h.roomId == selfRoomId) return false;
          if (selfUserId.isNotEmpty &&
              h.userId.isNotEmpty &&
              h.userId == selfUserId) {
            return false;
          }
          return h.roomId.isNotEmpty || h.userId.isNotEmpty;
        }).toList(),
      );
    } catch (e) {
      LoggerUtils.logWarning('PkV1: loadEligibleHosts failed — $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<PkEligibleHost> _parseEligibleHosts(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PkEligibleHost.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .where((h) => h.roomId.isNotEmpty || h.userId.isNotEmpty)
        .toList();
  }

  List<PkEligibleHost> _hostsFromLegacySearch(dynamic data, String query) {
    final list = <Map<String, dynamic>>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          list.add(item.map((k, v) => MapEntry(k.toString(), v)));
        }
      }
    } else if (data is Map) {
      final map = data.map((k, v) => MapEntry(k.toString(), v));
      final nested = map['rooms'] ?? map['opponents'] ?? map['items'];
      if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            list.add(item.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }
    }

    final hosts = list.map(_hostFromRoomLikeMap).toList();
    return _filterBySearch(hosts, query);
  }

  Future<List<PkEligibleHost>> _hostsFromActiveRooms(String query) async {
    final response = await _roomRepo.listActiveRooms(
      page: 1,
      limit: 40,
      isShowLoader: false,
    );
    final data = response?['data'];
    if (data is! List) return const [];

    final hosts = data
        .whereType<Map>()
        .map((e) => _hostFromRoomLikeMap(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .where((h) => h.roomId.isNotEmpty)
        .toList();
    return _filterBySearch(hosts, query);
  }

  PkEligibleHost _hostFromRoomLikeMap(Map<String, dynamic> map) {
    final host = map['host'] is Map
        ? (map['host'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};
    final userId = _firstNonEmpty([
      map['userId'],
      map['user_id'],
      map['hostId'],
      map['host_id'],
      host['id'],
      host['userId'],
      host['user_id'],
    ]);
    final displayName = _firstNonEmpty([
      map['displayName'],
      map['display_name'],
      map['hostName'],
      map['host_name'],
      host['name'],
      map['name'],
      map['title'],
    ], fallback: 'Host');
    final avatar = _firstNonEmpty([
      map['avatarUrl'],
      map['avatar_url'],
      map['avatar'],
      map['displayPicture'],
      host['displayPicture'],
      host['avatar'],
      map['coverImage'],
      map['image'],
    ]);
    final roomId = _firstNonEmpty([
      map['roomId'],
      map['room_id'],
      map['id'],
      map['_id'],
    ]);
    final viewers = map['viewerCount'] ??
        map['viewer_count'] ??
        map['onlineCount'] ??
        map['heatScore'] ??
        map['audienceCount'] ??
        0;
    final canReceive = map['canReceivePk'] ?? map['can_receive_pk'] ?? true;
    return PkEligibleHost(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatar,
      roomId: roomId,
      viewerCount: viewers is num
          ? viewers.toInt()
          : int.tryParse(viewers.toString()) ?? 0,
      status: _firstNonEmpty([map['status']], fallback: 'LIVE'),
      canReceivePk: canReceive != false && canReceive != 'false',
    );
  }

  List<PkEligibleHost> _filterBySearch(
    List<PkEligibleHost> hosts,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return hosts;
    return hosts
        .where((h) =>
            h.displayName.toLowerCase().contains(q) ||
            h.roomId.toLowerCase().contains(q))
        .toList();
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return fallback;
  }

  Future<void> loadGiftCatalog() async {
    try {
      final body = await _repo.getGiftCatalog();
      final data = PkV1Repo.dataOf(body);
      final items = (data['items'] as List?) ?? (body?['data'] as List?) ?? [];
      giftCatalog.assignAll(
        items
            .whereType<Map>()
            .map((e) => PkGiftCatalogItem.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList(),
      );
    } catch (e) {
      LoggerUtils.logWarning('PkV1: loadGiftCatalog failed — $e');
    }
  }

  Future<void> invite(PkEligibleHost host, {int durationSec = 180}) async {
    if (!host.canReceivePk) {
      _toast('Host is currently in another battle');
      return;
    }

    // Prefer v1 invitation API when we have a target user id.
    if (host.userId.isNotEmpty) {
      final body = await _repo.sendInvitation(
        targetUserId: host.userId,
        durationSec: durationSec,
      );
      if (PkV1Repo.isSuccess(body)) {
        final data = PkV1Repo.dataOf(body);
        outgoingInvitation.value = PkInvitation.fromJson({
          ...data,
          'toUserName': host.displayName,
          'toUserAvatar': host.avatarUrl,
          'toRoomId': host.roomId,
        });
        stage.value = PkArenaStage.waiting;
        return;
      }
      // If v1 is not deployed yet, fall through to legacy room challenge.
      LoggerUtils.logWarning(
        'PkV1: sendInvitation failed — ${PkV1Repo.messageOf(body)}',
      );
    }

    // Legacy: POST /api/pk/send-request with target_room_id.
    if (selfRoomId.isEmpty || host.roomId.isEmpty) {
      _toast('Could not send invitation');
      return;
    }
    final legacy = await _legacyPkRepo.sendPkRequest(
      roomId: selfRoomId,
      targetRoomId: host.roomId,
      duration: durationSec,
    );
    final ok = legacy != null &&
        (legacy['success'] == true ||
            legacy['statusCode'] == 1 ||
            legacy['statusCode'] == 201);
    if (!ok) {
      _toast(legacy?['message']?.toString().isNotEmpty == true
          ? legacy!['message'].toString()
          : 'Could not send invitation');
      return;
    }
    final data = legacy['data'] is Map
        ? (legacy['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};
    outgoingInvitation.value = PkInvitation.fromJson({
      ...data,
      'invitationId': data['invitationId'] ??
          data['invitation_id'] ??
          data['request_id'] ??
          data['requestId'] ??
          data['id'] ??
          '',
      'toUserId': host.userId,
      'toUserName': host.displayName,
      'toUserAvatar': host.avatarUrl,
      'toRoomId': host.roomId,
      'durationSec': durationSec,
      'status': data['status'] ?? 'PENDING',
    });
    stage.value = PkArenaStage.waiting;
  }

  Future<void> cancelOutgoing() async {
    final inv = outgoingInvitation.value;
    if (inv == null) {
      _startAtSelection();
      return;
    }
    await _repo.cancelInvitation(invitationId: inv.invitationId);
    outgoingInvitation.value = null;
    _startAtSelection();
  }

  Future<void> acceptInvitationById(String invitationId) async {
    stage.value = PkArenaStage.starting;
    final body = await _repo.acceptInvitation(invitationId: invitationId);
    if (!PkV1Repo.isSuccess(body)) {
      _toast(PkV1Repo.messageOf(body).isNotEmpty
          ? PkV1Repo.messageOf(body)
          : 'Could not accept invitation');
      _startAtSelection();
      return;
    }
    final data = PkV1Repo.dataOf(body);
    final pkSession = PkSession.fromJson(data);
    _applySession(pkSession);
    incomingInvitation.value = null;
  }

  Future<void> rejectInvitationById(String invitationId) async {
    await _repo.rejectInvitation(invitationId: invitationId);
    incomingInvitation.value = null;
  }

  // ========================================================================
  // Battle lifecycle
  // ========================================================================

  Future<void> _enterBattleByPkId(String pkId) async {
    stage.value = PkArenaStage.starting;
    await refreshSession(pkId);
  }

  Future<void> refreshSession(String pkId) async {
    final body = await _repo.getSession(pkId: pkId);
    if (!PkV1Repo.isSuccess(body)) {
      // Maybe the PK already ended while we were joining.
      await _loadResult(pkId);
      return;
    }
    _applySession(PkSession.fromJson(PkV1Repo.dataOf(body)));
  }

  void _applySession(PkSession s) {
    session.value = s;
    scoreA.value = s.sideA.score;
    scoreB.value = s.sideB.score;
    sideADiamonds.value =
        s.sideA.diamonds > 0 ? s.sideA.diamonds : s.sideA.earnings;
    sideBDiamonds.value =
        s.sideB.diamonds > 0 ? s.sideB.diamonds : s.sideB.earnings;
    machineState.value = s.status.name;
    outgoingInvitation.value = null;
    _applyAudiencesFromSession(s);

    // Server-authoritative clock offset.
    final serverTime = s.serverTime;
    if (serverTime != null) {
      _serverOffset = serverTime.difference(DateTime.now().toUtc());
    }

    _socket?.joinPkChannel(s.pkId);

    if (s.status == PkSessionStatus.ended ||
        s.status == PkSessionStatus.cancelled ||
        s.status == PkSessionStatus.expired ||
        s.status == PkSessionStatus.idle) {
      _loadResult(s.pkId);
      return;
    }

    // Map server state machine → existing arena stages (no UI rewrite).
    switch (s.status) {
      case PkSessionStatus.countdown:
      case PkSessionStatus.starting:
      case PkSessionStatus.accepted:
        stage.value = PkArenaStage.starting;
        break;
      case PkSessionStatus.matching:
      case PkSessionStatus.pending:
        stage.value = PkArenaStage.waiting;
        break;
      case PkSessionStatus.punishmentRound:
      case PkSessionStatus.battleActive:
      case PkSessionStatus.live:
      default:
        stage.value = PkArenaStage.battling;
        break;
    }

    connectionNote.value = '';
    _startClock();
    _startResync();
    _recomputeRemaining();
    _enterEmbeddedLiveRoomMode();
    _ensurePkHostVideoPublishing();
  }

  void _ensurePkHostVideoPublishing() {
    if (!Get.isRegistered<LiveBroadcastController>()) return;
    try {
      Get.find<LiveBroadcastController>().ensurePkHostVideoReady();
    } catch (_) {}
  }

  bool _idsMatch(String left, String right) {
    final a = left.trim();
    final b = right.trim();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b ||
        ZegoLiveIdUtils.sanitizeUserId(a) ==
            ZegoLiveIdUtils.sanitizeUserId(b);
  }

  bool _isPkHostUserId(String userId, PkSession? s) {
    final id = userId.trim();
    if (id.isEmpty) return false;
    if (_idsMatch(id, selfUserId)) return true;
    if (s == null) return false;
    return _idsMatch(id, s.sideA.hostId) || _idsMatch(id, s.sideB.hostId);
  }

  List<PkAudienceMember> _filterAudienceMembers(
    List<PkAudienceMember> members,
  ) {
    final s = session.value;
    return members
        .where((m) => m.userId.isNotEmpty && !_isPkHostUserId(m.userId, s))
        .toList();
  }

  void _applyAudiencesFromSession(PkSession s) {
    // Always sync (including empty) so stale avatars don't linger.
    sideAAudience.assignAll(_filterAudienceMembers(s.sideA.audience));
    sideBAudience.assignAll(_filterAudienceMembers(s.sideB.audience));
    sideATopContributors
        .assignAll(_filterAudienceMembers(s.sideA.topContributors));
    sideBTopContributors
        .assignAll(_filterAudienceMembers(s.sideB.topContributors));
  }

  /// Push the current live room's audience onto the local host's PK side.
  ///
  /// Opponent-room audience must come from the PK session / socket payload —
  /// this room only knows its own viewers.
  void syncLocalRoomAudience(List<PkAudienceMember> members) {
    final s = session.value;
    if (s == null) return;
    final cleaned = _filterAudienceMembers(members);
    if (_idsMatch(s.sideA.hostId, selfUserId) || s.sideA.roomId == selfRoomId) {
      sideAAudience.assignAll(cleaned);
    } else if (_idsMatch(s.sideB.hostId, selfUserId) ||
        s.sideB.roomId == selfRoomId) {
      sideBAudience.assignAll(cleaned);
    }
  }

  List<PkAudienceMember> audienceForSide(PkBattleSide side) {
    switch (side) {
      case PkBattleSide.a:
        return sideAAudience.toList();
      case PkBattleSide.b:
        return sideBAudience.toList();
      default:
        return const [];
    }
  }

  /// Converts the current live room into PK UI and closes the selection arena.
  void _enterEmbeddedLiveRoomMode() {
    embeddedInLiveRoom.value = true;
    PkLiveRoomBridge.setActive(true);
    // Pop the host-selection arena so the live room (with PK overlay) is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.currentRoute.contains('pk-v1-arena') &&
            (Get.key.currentState?.canPop() ?? false)) {
          Get.back();
        }
      } catch (_) {}
    });
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recomputeRemaining();
    });
  }

  void _startResync() {
    _resyncTimer?.cancel();
    // Periodic authoritative resync in case a socket event was missed.
    _resyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final pkId = session.value?.pkId;
      if (pkId == null || pkId.startsWith('ui_preview_')) return;
      if (stage.value == PkArenaStage.battling) {
        refreshSession(pkId);
      }
    });
  }

  void _recomputeRemaining() {
    final s = session.value;
    final endsAt = s?.endsAt;
    if (endsAt == null) {
      // Fall back to the reported remainingSec, decrementing locally.
      if (remainingSeconds.value > 0) {
        remainingSeconds.value = remainingSeconds.value - 1;
      }
      return;
    }
    final serverNow = DateTime.now().toUtc().add(_serverOffset);
    final remaining = endsAt.difference(serverNow).inSeconds;
    remainingSeconds.value = remaining > 0 ? remaining : 0;
    if (remaining <= 0 && stage.value == PkArenaStage.battling) {
      // Timer hit zero — server closes scoring; fetch authoritative result.
      _clockTimer?.cancel();
      _loadResult(s!.pkId);
    }
  }

  String get formattedTime {
    final total = remainingSeconds.value;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final sec = (total % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  /// Progress of side A (0..1) for the split score bar.
  double get sideAProgress {
    final total = scoreA.value + scoreB.value;
    if (total <= 0) return 0.5;
    return scoreA.value / total;
  }

  bool get isSelfSideA {
    final s = session.value;
    if (s == null) return true;
    if (s.currentUserSide == PkBattleSide.a) return true;
    if (s.currentUserSide == PkBattleSide.b) return false;
    return s.sideA.hostId == selfUserId;
  }

  bool get isSelfHost {
    final s = session.value;
    if (s == null) return false;
    return s.sideA.hostId == selfUserId || s.sideB.hostId == selfUserId;
  }

  // ========================================================================
  // Gifting to a side (viewer action)
  // ========================================================================

  String _newClientRequestId() {
    _giftSeq += 1;
    return 'pkg_${DateTime.now().millisecondsSinceEpoch}_${selfUserId}_$_giftSeq';
  }

  Future<void> sendGiftToSide({
    required PkGiftCatalogItem gift,
    required PkBattleSide side,
    int quantity = 1,
  }) async {
    if (isSelfHost) {
      _toast('Hosts can’t send gifts during PK Battle');
      return;
    }
    final s = session.value;
    if (s == null || side == PkBattleSide.none) return;
    final body = await _repo.sendGift(
      pkId: s.pkId,
      giftId: gift.id,
      quantity: quantity,
      targetSide: pkSideToApi(side),
      clientRequestId: _newClientRequestId(),
    );
    if (!PkV1Repo.isSuccess(body)) {
      final msg = PkV1Repo.messageOf(body);
      _toast(msg.isNotEmpty ? msg : 'Gift failed');
      return;
    }
    // Server returns the authoritative scores — apply immediately; the
    // PK_SCORE_UPDATE / PK_SCORE_UPDATED broadcast will confirm for everyone.
    final res = PkGiftSendResult.fromJson(PkV1Repo.dataOf(body));
    if (res.scoreA > 0 || res.scoreB > 0) {
      scoreA.value = res.scoreA;
      scoreB.value = res.scoreB;
    }
    if (res.hostADiamonds > 0) sideADiamonds.value = res.hostADiamonds;
    if (res.hostBDiamonds > 0) sideBDiamonds.value = res.hostBDiamonds;
    if (res.topContributorsA.isNotEmpty) {
      sideATopContributors
          .assignAll(_filterAudienceMembers(res.topContributorsA));
    }
    if (res.topContributorsB.isNotEmpty) {
      sideBTopContributors
          .assignAll(_filterAudienceMembers(res.topContributorsB));
    }

    final localEvent = PkGiftEvent(
      pkId: s.pkId,
      targetSide: side,
      giftId: gift.id,
      giftName: gift.name,
      iconUrl: gift.iconUrl,
      animationUrl: gift.animationUrl,
      soundUrl: gift.soundUrl,
      quantity: quantity,
      pkPoints: gift.pkPointValue * quantity,
      senderId: selfUserId,
      senderName: selfName.isEmpty ? 'You' : selfName,
      senderAvatar: selfAvatar,
    );
    _presentPkGift(localEvent);
  }

  /// Apply optional `pkBattle` block from `POST /gifts/send` without changing
  /// the live economy gift path — scores update when backend includes it.
  void applyEconomyGiftPkBattle(Map<String, dynamic>? responseData) {
    if (responseData == null || responseData.isEmpty) return;
    final raw = responseData['pkBattle'] ??
        responseData['pk_battle'] ??
        responseData['pk'];
    if (raw is! Map) return;
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    final pkId = (map['pkId'] ?? map['pk_id'] ?? '').toString().trim();
    final current = session.value?.pkId ?? '';
    if (pkId.isNotEmpty &&
        current.isNotEmpty &&
        !_idsMatch(pkId, current)) {
      return;
    }
    _handleScoreUpdate(Map<String, dynamic>.from(map));
  }

  /// Celebrate gift + push sender into Top Gifters for the supported side.
  void _presentPkGift(PkGiftEvent event) {
    if (!_claimGiftPresentation(event)) return;
    lastGift.value = event;
    _bumpTopGifter(
      side: event.targetSide,
      userId: event.senderId,
      name: event.senderName,
      avatar: event.senderAvatar,
    );
    unawaited(
      GiftMediaUtils.dismissSheetThenCelebrate(
        giftName: event.giftName,
        animationUrl: event.animationUrl,
        soundUrl: event.soundUrl,
      ),
    );
    // Keep banner visible briefly for the in-room PK stage toast.
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (lastGift.value?.giftId == event.giftId &&
          lastGift.value?.senderId == event.senderId) {
        lastGift.value = null;
      }
    });
  }

  bool _claimGiftPresentation(PkGiftEvent event) {
    final now = DateTime.now();
    if (now.difference(_presentedGiftPrunedAt) > const Duration(seconds: 20)) {
      _presentedGiftKeys.clear();
      _presentedGiftPrunedAt = now;
    }
    final key =
        '${event.giftId}|${event.senderId}|${event.quantity}|${pkSideToApi(event.targetSide)}';
    if (key.replaceAll('|', '').isEmpty) return true;
    return _presentedGiftKeys.add(key);
  }

  void _bumpTopGifter({
    required PkBattleSide side,
    required String userId,
    required String name,
    required String avatar,
  }) {
    final id = userId.trim();
    if (id.isEmpty || side == PkBattleSide.none) return;
    if (_isPkHostUserId(id, session.value)) return;
    final member = PkAudienceMember(
      userId: id,
      displayName: name.trim().isEmpty ? 'Viewer' : name.trim(),
      avatarUrl: avatar.trim(),
    );
    final list =
        side == PkBattleSide.b ? sideBTopContributors : sideATopContributors;
    list.removeWhere((m) => _idsMatch(m.userId, id));
    list.insert(0, member);
    while (list.length > 5) {
      list.removeLast();
    }
  }

  // ========================================================================
  // Leave / report / end
  // ========================================================================

  Future<void> leaveBattle({String reason = 'host_forfeit'}) async {
    final s = session.value;
    if (s == null) {
      _exitBattleUi();
      return;
    }
    final body = await _repo.leave(pkId: s.pkId, reason: reason);
    if (PkV1Repo.isSuccess(body)) {
      final data = PkV1Repo.dataOf(body);
      if (data.isNotEmpty) {
        // Server may return a forfeit/result — celebrate then restore room.
        _applyResult(PkResult.fromJson(data));
      } else {
        _exitBattleUi();
      }
    } else {
      // Don't leave the live room on API failure — only exit PK UI.
      _toast(PkV1Repo.messageOf(body).isNotEmpty
          ? PkV1Repo.messageOf(body)
          : 'Could not end PK — closing locally');
      _exitBattleUi();
    }
  }

  /// Ends in-room PK and restores normal seats/live UI (never ends the room).
  void _exitBattleUi() {
    if (embeddedInLiveRoom.value || PkLiveRoomBridge.isActive.value) {
      clearEmbeddedBattle();
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  /// Confirm + end PK from the live room overlay (hosts only).
  void confirmEndEmbeddedBattle() {
    final isPreview = session.value?.pkId.startsWith('ui_preview_') == true;
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isPreview ? 'Close PK preview?' : 'End PK Battle?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          isPreview
              ? 'This only hides the temporary PK UI preview.'
              : 'This ends the PK only. Your audio/video room stays open.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              isPreview ? 'Keep preview' : 'Keep battling',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (isPreview) {
                clearEmbeddedBattle();
              } else {
                leaveBattle(reason: 'host_forfeit');
              }
            },
            child: Text(
              isPreview ? 'Close preview' : 'End PK',
              style: const TextStyle(
                color: Color(0xFFFF5C7A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> report({required String reportedUserId, required String reason}) async {
    final s = session.value;
    if (s == null) return;
    final body = await _repo.report(
      pkId: s.pkId,
      reportedUserId: reportedUserId,
      reason: reason,
    );
    _toast(PkV1Repo.isSuccess(body) ? 'Report submitted' : 'Could not report');
  }

  Future<void> _loadResult(String pkId) async {
    final body = await _repo.getResult(pkId: pkId);
    if (PkV1Repo.isSuccess(body)) {
      _applyResult(PkResult.fromJson(PkV1Repo.dataOf(body)));
    } else {
      // Even without a result payload, freeze the battle UI.
      stage.value = PkArenaStage.finished;
    }
  }

  void _applyResult(PkResult r) {
    if (_resultHandled && result.value?.pkId == r.pkId) return;
    _resultHandled = true;

    result.value = r;
    scoreA.value = r.scoreA;
    scoreB.value = r.scoreB;
    stage.value = PkArenaStage.finished;
    embeddedInLiveRoom.value = true;
    PkLiveRoomBridge.setActive(true);
    _clockTimer?.cancel();
    _resyncTimer?.cancel();
    _exitAfterResultTimer?.cancel();

    final currentSession = session.value;
    PkWinnerCelebrationOverlay.show(
      result: r,
      session: currentSession,
      onFinished: () {
        if (!isClosed) {
          clearEmbeddedBattle();
        }
      },
    );
  }

  // ========================================================================
  // Socket event handling
  // ========================================================================

  void _onSocketEvent(String event, Map<String, dynamic> data) {
    final pkId = (data['pkId'] ?? data['pk_id'] ?? '').toString().trim();
    final currentPk = session.value?.pkId;
    // Ignore events for a different PK session (except invitation ones which
    // have no pkId yet).
    final isInvitationEvent = event.startsWith('PK_INVITATION');
    if (!isInvitationEvent &&
        currentPk != null &&
        currentPk.isNotEmpty &&
        pkId.isNotEmpty &&
        pkId != currentPk) {
      return;
    }

    switch (event) {
      case 'PK_INVITATION_ACCEPTED':
      case 'PK_STARTED':
        final id = pkId.isNotEmpty ? pkId : currentPk;
        if (id != null && id.isNotEmpty) {
          refreshSession(id);
        }
        break;
      case 'PK_INVITATION_REJECTED':
        _toast('Host declined the PK');
        outgoingInvitation.value = null;
        if (stage.value == PkArenaStage.waiting) _startAtSelection();
        break;
      case 'PK_INVITATION_TIMEOUT':
        _toast('PK invitation timed out');
        outgoingInvitation.value = null;
        incomingInvitation.value = null;
        if (stage.value == PkArenaStage.waiting) _startAtSelection();
        break;
      case 'PK_RTC_BRIDGE':
        _handleRtcBridge(data);
        break;
      case 'PK_RTC_UNBRIDGE':
        _handleRtcUnbridge(data);
        break;
      case 'PK_COUNTDOWN_TICK':
        _handleCountdownTick(data);
        break;
      case 'PK_STATE_TRANSITION':
        _handleStateTransition(data);
        break;
      case 'PK_STATE_SYNC':
        _handleStateSync(data);
        break;
      case 'PK_SCORE_UPDATE':
      case 'PK_SCORE_UPDATED':
        _handleScoreUpdate(data);
        break;
      case 'PK_GIFT_RECEIVED':
        try {
          _presentPkGift(PkGiftEvent.fromJson(data));
        } catch (e) {
          LoggerUtils.logWarning('PkV1: gift event parse error — $e');
        }
        break;
      case 'PK_ENDED':
        final id = pkId.isNotEmpty ? pkId : (currentPk ?? '');
        if (id.isNotEmpty) _loadResult(id);
        break;
      case 'PK_RESULT':
        _applyResult(PkResult.fromJson(data));
        break;
      case 'PK_CANCELLED':
        _toast('PK was cancelled');
        outgoingInvitation.value = null;
        if (stage.value == PkArenaStage.battling ||
            stage.value == PkArenaStage.starting) {
          final id = pkId.isNotEmpty ? pkId : (currentPk ?? '');
          if (id.isNotEmpty) {
            _loadResult(id);
          } else {
            stage.value = PkArenaStage.finished;
          }
        } else {
          _startAtSelection();
        }
        break;
      case 'PK_HOST_DISCONNECTED':
        connectionNote.value = 'Opponent reconnecting...';
        break;
      case 'PK_HOST_RECONNECTED':
        connectionNote.value = '';
        break;
      default:
        break;
    }
  }

  void _handleRtcBridge(Map<String, dynamic> data) {
    try {
      final bridge = PkRtcBridgePayload.fromJson(data);
      rtcBridge.value = bridge;
      if (bridge.pkId.isNotEmpty) {
        _socket?.joinPkChannel(bridge.pkId);
        if (bridge.bridgeChannel.isNotEmpty) {
          _socket?.joinPkChannel(bridge.bridgeChannel);
        }
      }
      // Ensure session is hydrated once bridge arrives (accept may only
      // return COUNTDOWN without a follow-up GET yet).
      if (session.value == null && bridge.pkId.isNotEmpty) {
        refreshSession(bridge.pkId);
      } else {
        _ensurePkHostVideoPublishing();
        _enterEmbeddedLiveRoomMode();
        if (stage.value == PkArenaStage.selecting ||
            stage.value == PkArenaStage.waiting) {
          stage.value = PkArenaStage.starting;
        }
      }
      LoggerUtils.logInfo(
        'PkV1: RTC bridge ready pk=${bridge.pkId} '
        'provider=${bridge.provider} channel=${bridge.bridgeChannel}',
      );
    } catch (e) {
      LoggerUtils.logWarning('PkV1: RTC bridge parse error — $e');
    }
  }

  void _handleRtcUnbridge(Map<String, dynamic> data) {
    rtcBridge.value = null;
    final id = (data['pkId'] ?? data['pk_id'] ?? session.value?.pkId ?? '')
        .toString()
        .trim();
    if (id.isNotEmpty) {
      _socket?.leavePkChannel(id);
    }
    LoggerUtils.logInfo('PkV1: RTC unbridge pk=$id');
  }

  void _handleCountdownTick(Map<String, dynamic> data) {
    final sec = _toInt(
      data['remainingCountdownSec'] ??
          data['remaining_countdown_sec'] ??
          data['remainingSec'] ??
          data['remaining_sec'],
    );
    countdownRemainingSec.value = sec;
    machineState.value = 'COUNTDOWN';
    if (stage.value != PkArenaStage.battling &&
        stage.value != PkArenaStage.finished) {
      stage.value = PkArenaStage.starting;
    }
    final serverMs = data['serverTime'] ?? data['server_time'];
    if (serverMs is num) {
      _serverOffset = DateTime.fromMillisecondsSinceEpoch(
            serverMs.toInt(),
            isUtc: true,
          ).difference(DateTime.now().toUtc());
    }
  }

  void _handleStateTransition(Map<String, dynamic> data) {
    try {
      final t = PkStateTransition.fromJson(data);
      lastStateTransition.value = t;
      machineState.value = t.toState;
      if (t.remainingSec > 0) {
        remainingSeconds.value = t.remainingSec;
      }
      final to = t.toState.toUpperCase();
      if (to == 'COUNTDOWN') {
        stage.value = PkArenaStage.starting;
        countdownRemainingSec.value =
            t.remainingSec > 0 ? t.remainingSec : countdownRemainingSec.value;
      } else if (to == 'BATTLE_ACTIVE' || to == 'LIVE') {
        countdownRemainingSec.value = 0;
        stage.value = PkArenaStage.battling;
        _enterEmbeddedLiveRoomMode();
        _ensurePkHostVideoPublishing();
        _startClock();
        _startResync();
      } else if (to == 'PUNISHMENT_ROUND' || to == 'PUNISHMENT') {
        stage.value = PkArenaStage.battling;
      } else if (to == 'ENDED' || to == 'IDLE') {
        final id = t.pkId.isNotEmpty ? t.pkId : (session.value?.pkId ?? '');
        if (id.isNotEmpty) {
          _loadResult(id);
        } else if (t.winnerSide != PkBattleSide.none) {
          _applyResult(
            PkResult(
              pkId: t.pkId,
              status: PkSessionStatus.ended,
              winnerSide: t.winnerSide,
              winnerId: t.winnerId,
              scoreA: scoreA.value,
              scoreB: scoreB.value,
              durationSec: t.durationSec,
            ),
          );
        }
      }
      // Keep session if we already have one; otherwise refresh.
      final current = session.value?.pkId ?? '';
      if (current.isEmpty && t.pkId.isNotEmpty) {
        refreshSession(t.pkId);
      }
    } catch (e) {
      LoggerUtils.logWarning('PkV1: state transition parse error — $e');
    }
  }

  void _handleStateSync(Map<String, dynamic> data) {
    try {
      _applySession(PkSession.fromJson(data));
    } catch (e) {
      LoggerUtils.logWarning('PkV1: state sync parse error — $e');
    }
  }

  void _handleScoreUpdate(Map<String, dynamic> data) {
    final sideA = data['sideA'] ?? data['side_a'];
    final sideB = data['sideB'] ?? data['side_b'];

    // Guide shape: hostA_score / hostB_score
    if (data['hostA_score'] != null || data['host_a_score'] != null) {
      scoreA.value = _toInt(data['hostA_score'] ?? data['host_a_score']);
    } else if (sideA is Map && sideA['score'] != null) {
      scoreA.value = _toInt(sideA['score']);
    } else if (data['scoreA'] != null || data['score_a'] != null) {
      scoreA.value = _toInt(data['scoreA'] ?? data['score_a']);
    }

    if (data['hostB_score'] != null || data['host_b_score'] != null) {
      scoreB.value = _toInt(data['hostB_score'] ?? data['host_b_score']);
    } else if (sideB is Map && sideB['score'] != null) {
      scoreB.value = _toInt(sideB['score']);
    } else if (data['scoreB'] != null || data['score_b'] != null) {
      scoreB.value = _toInt(data['scoreB'] ?? data['score_b']);
    }

    final diamondsA = _toInt(
      data['hostA_diamonds'] ??
          data['hostADiamonds'] ??
          data['host_a_diamonds'] ??
          data['hostA_earnings'] ??
          (sideA is Map ? (sideA['diamonds'] ?? sideA['earnings']) : null),
    );
    final diamondsB = _toInt(
      data['hostB_diamonds'] ??
          data['hostBDiamonds'] ??
          data['host_b_diamonds'] ??
          data['hostB_earnings'] ??
          (sideB is Map ? (sideB['diamonds'] ?? sideB['earnings']) : null),
    );
    if (diamondsA > 0) sideADiamonds.value = diamondsA;
    if (diamondsB > 0) sideBDiamonds.value = diamondsB;

    final rem = data['remainingSec'] ??
        data['remaining_sec'] ??
        data['remainingSeconds'];
    if (rem != null) {
      remainingSeconds.value = _toInt(rem);
    }
    final state = (data['state'] ?? data['status'] ?? '').toString().trim();
    if (state.isNotEmpty) {
      machineState.value = state;
    }

    // Top contributors stay separate from room audience.
    final contribA = PkAudienceMember.listFrom(
      data['topContributorsA'] ??
          data['top_contributors_a'] ??
          (sideA is Map
              ? (sideA['topContributors'] ?? sideA['top_contributors'])
              : null),
    );
    final contribB = PkAudienceMember.listFrom(
      data['topContributorsB'] ??
          data['top_contributors_b'] ??
          (sideB is Map
              ? (sideB['topContributors'] ?? sideB['top_contributors'])
              : null),
    );
    if (contribA.isNotEmpty) {
      sideATopContributors.assignAll(_filterAudienceMembers(contribA));
    }
    if (contribB.isNotEmpty) {
      sideBTopContributors.assignAll(_filterAudienceMembers(contribB));
    }

    final audienceA = PkAudienceMember.listFrom(
      sideA is Map
          ? (sideA['audienceList'] ?? sideA['audience_list'])
          : null,
    );
    final audienceB = PkAudienceMember.listFrom(
      sideB is Map
          ? (sideB['audienceList'] ?? sideB['audience_list'])
          : null,
    );
    // Only overwrite when the score payload includes side audience lists.
    if (sideA is Map &&
        (sideA.containsKey('audienceList') ||
            sideA.containsKey('audience_list'))) {
      sideAAudience.assignAll(_filterAudienceMembers(audienceA));
    }
    if (sideB is Map &&
        (sideB.containsKey('audienceList') ||
            sideB.containsKey('audience_list'))) {
      sideBAudience.assignAll(_filterAudienceMembers(audienceB));
    }

    // Prefer PK_GIFT_RECEIVED for animation; lastGift is a fallback only.
    final giftRaw = data['lastGift'] ?? data['last_gift'] ?? data['gift'];
    if (giftRaw is Map) {
      try {
        final event = PkGiftEvent.fromJson(
          Map<String, dynamic>.from(giftRaw),
        );
        if (event.giftId.isNotEmpty || event.giftName.isNotEmpty) {
          _presentPkGift(event);
        }
      } catch (_) {}
    }
  }

  int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  void _toast(String message) {
    if (message.trim().isEmpty) return;
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }
}
