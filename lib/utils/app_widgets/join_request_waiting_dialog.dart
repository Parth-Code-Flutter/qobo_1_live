import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/services/firebase/join_request_payload.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Blocking dialog while a viewer waits for host join approval.
abstract final class JoinRequestWaitingDialog {
  JoinRequestWaitingDialog._();

  static Future<JoinRequestWaitOutcome> showAndWait({
    required String roomId,
    required String requestId,
    required String sessionType,
    DateTime? expiresAt,
    int pollAfterMs = 2000,
    RoomRepo? roomRepo,
  }) async {
    final completer = JoinRequestWaitRegistry.register(requestId);
    final repo = roomRepo ?? RoomRepo();

    unawaited(
      Get.dialog<void>(
        _JoinWaitingDialog(
          roomId: roomId,
          requestId: requestId,
          sessionType: sessionType,
          expiresAt: expiresAt,
          pollAfterMs: pollAfterMs,
          roomRepo: repo,
        ),
        barrierDismissible: false,
        barrierColor: kColorBlack.withValues(alpha: 0.62),
      ).then((_) {
        // If dialog closed without an outcome, treat as local cancel.
        JoinRequestWaitRegistry.completeIfPending(
          requestId,
          JoinRequestWaitOutcome(
            result: JoinRequestWaitResult.cancelled,
            requestId: requestId,
            roomId: roomId,
            sessionType: sessionType,
            message: 'Cancelled',
          ),
        );
      }),
    );

    final outcome = await completer.future;
    if (Get.isDialogOpen == true) {
      Get.back<void>();
    }
    return outcome;
  }
}

class _JoinWaitingDialog extends StatefulWidget {
  const _JoinWaitingDialog({
    required this.roomId,
    required this.requestId,
    required this.sessionType,
    required this.expiresAt,
    required this.pollAfterMs,
    required this.roomRepo,
  });

  final String roomId;
  final String requestId;
  final String sessionType;
  final DateTime? expiresAt;
  final int pollAfterMs;
  final RoomRepo roomRepo;

  @override
  State<_JoinWaitingDialog> createState() => _JoinWaitingDialogState();
}

class _JoinWaitingDialogState extends State<_JoinWaitingDialog> {
  Timer? _pollTimer;
  Timer? _expiryTimer;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    final pollMs = widget.pollAfterMs.clamp(1000, 10000);
    _pollTimer = Timer.periodic(Duration(milliseconds: pollMs), (_) {
      unawaited(_pollStatus());
    });
    if (widget.expiresAt != null) {
      final remaining = widget.expiresAt!.toUtc().difference(DateTime.now().toUtc());
      if (remaining.isNegative) {
        _completeExpired();
      } else {
        _expiryTimer = Timer(remaining, _completeExpired);
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollStatus() async {
    final response = await widget.roomRepo.getJoinRequestStatus(
      requestId: widget.requestId,
      isShowLoader: false,
    );
    if (!JoinApprovalService.isApiSuccess(response)) return;
    final data = response?['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final status = (map['status']?.toString() ?? '').toLowerCase();
    if (status == 'approved') {
      JoinRequestWaitRegistry.complete(
        widget.requestId,
        JoinRequestWaitOutcome(
          result: JoinRequestWaitResult.approved,
          requestId: widget.requestId,
          roomId: widget.roomId,
          sessionType: widget.sessionType,
        ),
      );
    } else if (status == 'rejected') {
      JoinRequestWaitRegistry.complete(
        widget.requestId,
        JoinRequestWaitOutcome(
          result: JoinRequestWaitResult.rejected,
          requestId: widget.requestId,
          roomId: widget.roomId,
          sessionType: widget.sessionType,
          message: response?['message']?.toString() ??
              'Host declined your request to join',
        ),
      );
    } else if (status == 'expired' || status == 'cancelled') {
      JoinRequestWaitRegistry.complete(
        widget.requestId,
        JoinRequestWaitOutcome(
          result: status == 'expired'
              ? JoinRequestWaitResult.expired
              : JoinRequestWaitResult.cancelled,
          requestId: widget.requestId,
          roomId: widget.roomId,
          sessionType: widget.sessionType,
          message: response?['message']?.toString() ??
              (status == 'expired'
                  ? 'Your join request expired. Try again.'
                  : 'Join request cancelled'),
        ),
      );
    }
  }

  void _completeExpired() {
    JoinRequestWaitRegistry.completeIfPending(
      widget.requestId,
      JoinRequestWaitOutcome(
        result: JoinRequestWaitResult.expired,
        requestId: widget.requestId,
        roomId: widget.roomId,
        sessionType: widget.sessionType,
        message: 'Your join request expired. Try again.',
      ),
    );
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    await widget.roomRepo.cancelJoinRequest(
      roomId: widget.roomId,
      requestId: widget.requestId,
      isShowLoader: false,
    );
    JoinRequestWaitRegistry.cancelLocal(widget.requestId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B1654), Color(0xFF171339)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Color(0xFFFF3EA5),
              ),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'Waiting for host approval…',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: 'You will enter the room once the host approves.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
            Spacing.v16,
            TextButton(
              onPressed: _cancelling ? null : _cancel,
              child: AppText(
                text: _cancelling ? 'Cancelling…' : 'Cancel request',
                fontSize: TextStyles.k12FontSize,
                color: LiveRoomUiColors.goLiveGradientStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
