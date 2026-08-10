import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/repo/pk/pk_v1_repo.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Which sub-screen of the PK arena is active.
enum PkArenaStage { selecting, waiting, starting, battling, finished }

/// Drives the whole host-vs-host PK Battle v1 flow: host selection → invite →
/// live battle (server-authoritative timer + score) → result.
///
/// The server is the single source of truth for timer, score and winner. This
/// controller never computes score locally; it only renders what the socket /
/// REST endpoints report.
class PkV1Controller extends GetxController {
  PkV1Controller({PkV1Repo? repo, UserSessionController? session})
      : _repo = repo ?? PkV1Repo(),
        _session = session ??
            (Get.isRegistered<UserSessionController>()
                ? Get.find<UserSessionController>()
                : Get.put(UserSessionController(), permanent: true));

  final PkV1Repo _repo;
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

  // Result
  final result = Rxn<PkResult>();

  // Gift catalog for the side gift picker.
  final giftCatalog = <PkGiftCatalogItem>[].obs;

  Timer? _clockTimer;
  Timer? _resyncTimer;
  Duration _serverOffset = Duration.zero;
  int _giftSeq = 0;

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

    if (pkId.isNotEmpty) {
      // Deep entry straight into an existing battle (accepted / watching).
      _enterBattleByPkId(pkId);
    } else if (invitationId.isNotEmpty) {
      // Accept an incoming invitation then enter the battle.
      acceptInvitationById(invitationId);
    } else {
      _startAtSelection();
    }
  }

  void _startAtSelection() {
    stage.value = PkArenaStage.selecting;
    loadEligibleHosts();
    loadGiftCatalog();
  }

  // ========================================================================
  // Host selection + invitations
  // ========================================================================

  Future<void> loadEligibleHosts({String? search}) async {
    try {
      isLoading.value = true;
      final body = await _repo.getEligibleHosts(
        search: search ?? searchText.value,
      );
      final data = PkV1Repo.dataOf(body);
      final items = (data['items'] as List?) ?? const [];
      eligibleHosts.assignAll(
        items
            .whereType<Map>()
            .map((e) => PkEligibleHost.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList(),
      );
    } catch (e) {
      LoggerUtils.logWarning('PkV1: loadEligibleHosts failed — $e');
    } finally {
      isLoading.value = false;
    }
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
    final body = await _repo.sendInvitation(
      targetUserId: host.userId,
      durationSec: durationSec,
    );
    if (!PkV1Repo.isSuccess(body)) {
      _toast(PkV1Repo.messageOf(body).isNotEmpty
          ? PkV1Repo.messageOf(body)
          : 'Could not send invitation');
      return;
    }
    final data = PkV1Repo.dataOf(body);
    outgoingInvitation.value = PkInvitation.fromJson({
      ...data,
      'toUserName': host.displayName,
      'toUserAvatar': host.avatarUrl,
      'toRoomId': host.roomId,
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
    outgoingInvitation.value = null;

    // Server-authoritative clock offset.
    final serverTime = s.serverTime;
    if (serverTime != null) {
      _serverOffset = serverTime.difference(DateTime.now().toUtc());
    }

    _socket?.joinPkChannel(s.pkId);

    if (s.status == PkSessionStatus.ended ||
        s.status == PkSessionStatus.cancelled ||
        s.status == PkSessionStatus.expired) {
      _loadResult(s.pkId);
      return;
    }

    stage.value = PkArenaStage.battling;
    connectionNote.value = '';
    _startClock();
    _startResync();
    _recomputeRemaining();
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
      if (pkId != null && stage.value == PkArenaStage.battling) {
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
    // PK_SCORE_UPDATED broadcast will confirm for everyone.
    final res = PkGiftSendResult.fromJson(PkV1Repo.dataOf(body));
    if (res.scoreA > 0 || res.scoreB > 0) {
      scoreA.value = res.scoreA;
      scoreB.value = res.scoreB;
    }
  }

  // ========================================================================
  // Leave / report / end
  // ========================================================================

  Future<void> leaveBattle({String reason = 'host_leave'}) async {
    final s = session.value;
    if (s == null) {
      Get.back();
      return;
    }
    final body = await _repo.leave(pkId: s.pkId, reason: reason);
    if (PkV1Repo.isSuccess(body)) {
      _applyResult(PkResult.fromJson(PkV1Repo.dataOf(body)));
    } else {
      Get.back();
    }
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
    result.value = r;
    scoreA.value = r.scoreA;
    scoreB.value = r.scoreB;
    stage.value = PkArenaStage.finished;
    _clockTimer?.cancel();
    _resyncTimer?.cancel();
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
      case 'PK_STATE_SYNC':
        _handleStateSync(data);
        break;
      case 'PK_SCORE_UPDATED':
        _handleScoreUpdate(data);
        break;
      case 'PK_GIFT_RECEIVED':
        lastGift.value = PkGiftEvent.fromJson(data);
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
    if (sideA is Map && sideA['score'] != null) {
      scoreA.value = _toInt(sideA['score']);
    } else if (data['scoreA'] != null) {
      scoreA.value = _toInt(data['scoreA']);
    }
    if (sideB is Map && sideB['score'] != null) {
      scoreB.value = _toInt(sideB['score']);
    } else if (data['scoreB'] != null) {
      scoreB.value = _toInt(data['scoreB']);
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
