import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_invitation_dialog.dart';
import 'package:qobo_one_live/repo/pk/pk_v1_repo.dart';
import 'package:qobo_one_live/services/pk/pk_invitation_inbox.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// App-wide coordinator that shows the incoming PK invitation popup (with a
/// countdown) whenever a `PK_INVITATION_RECEIVED` socket event arrives, no
/// matter which screen the host is on.
///
/// Modeled on [ChatIncomingCallCoordinator] behaviourally.
class PkV1Coordinator extends GetxService with WidgetsBindingObserver {
  PkV1Coordinator({PkV1Repo? repo}) : _repo = repo ?? PkV1Repo();

  final PkV1Repo _repo;

  bool _listening = false;
  bool _pollStarted = false;
  bool _pollInFlight = false;
  bool _appResumed = true;
  bool _dialogOpen = false;
  String? _lastHandledInvitationId;
  Timer? _pollTimer;

  UserRealtimeSocketService? get _socket =>
      Get.isRegistered<UserRealtimeSocketService>()
          ? Get.find<UserRealtimeSocketService>()
          : null;

  /// Registers the singleton and starts listening for PK invitations.
  static Future<void> ensureStarted() async {
    final coordinator = Get.isRegistered<PkV1Coordinator>()
        ? Get.find<PkV1Coordinator>()
        : Get.put(PkV1Coordinator(), permanent: true);
    await UserRealtimeSocketService.ensureConnected();
    coordinator._startListening();
  }

  /// Shared PK controller used by the live-room overlay + invitation flow.
  static PkV1Controller ensureController() {
    if (Get.isRegistered<PkV1Controller>()) {
      return Get.find<PkV1Controller>();
    }
    return Get.put(PkV1Controller(), permanent: true);
  }

  void _startListening() {
    _startIncomingPoll();
    if (_listening) return;
    final socket = _socket;
    if (socket == null) return;
    socket.addPkBattleV1Listener(_onEvent);
    _listening = true;
    LoggerUtils.logInfo('PkV1Coordinator: listening for invitations');
  }

  /// Shows the Accept / Decline dialog for a socket or push payload.
  void presentIncoming(Map<String, dynamic> data) {
    try {
      final invitation = PkInvitation.fromJson(pkInvitationFields(data));
      _showInvitation(invitation);
    } catch (e) {
      LoggerUtils.logWarning('PkV1Coordinator: invitation parse error — $e');
    }
  }

  void _onEvent(String event, Map<String, dynamic> data) {
    if (event != 'PK_INVITATION_RECEIVED') return;
    presentIncoming(data);
  }

  /// While a host is in a live room, also read pending invites from the API.
  ///
  /// The Accept dialog used to depend only on the socket event. If that
  /// connection is down, the other host still sees the challenge.
  void _startIncomingPoll() {
    if (_pollStarted) return;
    _pollStarted = true;
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pollIncomingInvitations());
    });
    unawaited(_pollIncomingInvitations());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
  }

  bool get _hostIsInLiveRoom {
    if (!Get.isRegistered<LiveBroadcastController>()) return false;
    final live = Get.find<LiveBroadcastController>();
    return live.audioRoomApiId.trim().isNotEmpty ||
        live.roomId.value.trim().isNotEmpty ||
        live.liveStreamingApiId.trim().isNotEmpty;
  }

  Future<void> _pollIncomingInvitations() async {
    if (!_appResumed || _dialogOpen || _pollInFlight || !_hostIsInLiveRoom) {
      return;
    }
    _pollInFlight = true;
    try {
      final body = await _repo.getInvitations(
        type: 'incoming',
        isShowLoader: false,
      );
      for (final invitation in pendingIncomingPkInvitations(body)) {
        _showInvitation(invitation);
        if (_dialogOpen) break;
      }
    } catch (e) {
      LoggerUtils.logWarning('PkV1Coordinator: incoming poll failed — $e');
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _showInvitation(PkInvitation invitation) async {
    if (invitation.invitationId.isEmpty) return;
    if (_dialogOpen) return;
    if (_lastHandledInvitationId == invitation.invitationId) return;
    _lastHandledInvitationId = invitation.invitationId;
    _dialogOpen = true;

    // Wait for the overlay to be ready, then present the popup.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accepted = await Get.dialog<bool>(
        PkV1InvitationDialog(invitation: invitation),
        barrierDismissible: false,
      );
      _dialogOpen = false;

      if (accepted == true) {
        // Stay in the live room — accept and convert the room into PK UI.
        final pk = ensureController();
        unawaited(pk.acceptInvitationById(invitation.invitationId));
      } else {
        // Explicit reject or auto-expire → tell the server (best effort).
        unawaited(
          _repo.rejectInvitation(
            invitationId: invitation.invitationId,
            isShowLoader: false,
          ),
        );
      }
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _pollStarted = false;
    WidgetsBinding.instance.removeObserver(this);
    _socket?.removePkBattleV1Listener(_onEvent);
    _listening = false;
    super.onClose();
  }
}
