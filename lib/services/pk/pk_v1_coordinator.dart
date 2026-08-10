import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/widgets/pk_v1_invitation_dialog.dart';
import 'package:qobo_one_live/repo/pk/pk_v1_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// App-wide coordinator that shows the incoming PK invitation popup (with a
/// countdown) whenever a `PK_INVITATION_RECEIVED` socket event arrives, no
/// matter which screen the host is on.
///
/// Modeled on [ChatIncomingCallCoordinator] behaviourally.
class PkV1Coordinator extends GetxService {
  PkV1Coordinator({PkV1Repo? repo}) : _repo = repo ?? PkV1Repo();

  final PkV1Repo _repo;

  bool _listening = false;
  bool _dialogOpen = false;
  String? _lastHandledInvitationId;

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

  void _startListening() {
    if (_listening) return;
    final socket = _socket;
    if (socket == null) return;
    socket.addPkBattleV1Listener(_onEvent);
    _listening = true;
    LoggerUtils.logInfo('PkV1Coordinator: listening for invitations');
  }

  void _onEvent(String event, Map<String, dynamic> data) {
    if (event != 'PK_INVITATION_RECEIVED') return;
    try {
      final invitation = PkInvitation.fromJson(data);
      _showInvitation(invitation);
    } catch (e) {
      LoggerUtils.logWarning('PkV1Coordinator: invitation parse error — $e');
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
        Get.toNamed(
          Routes.PK_V1_ARENA,
          arguments: {'invitationId': invitation.invitationId},
        );
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
    _socket?.removePkBattleV1Listener(_onEvent);
    _listening = false;
    super.onClose();
  }
}
