import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:push_notification_service/push_notification_service.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/services/firebase/join_request_payload.dart';
import 'package:qobo_one_live/services/firebase/join_request_push_handler.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Foreground host dialog for pending viewer join requests.
abstract final class JoinRequestInAppBanner {
  JoinRequestInAppBanner._();

  static bool _isShowing = false;

  /// Returns true when the custom UI was shown (skip system tray).
  static Future<bool> tryShow(
    PushNotificationMessage message, {
    JoinRequestPushHandler? handler,
  }) async {
    final payload = JoinRequestPayload.fromMessage(message);
    if (payload == null || !payload.isHostRequest) return false;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return false;
    if (_isShowing) return true;

    _isShowing = true;
    final joinHandler = handler ?? JoinRequestPushHandler();

    try {
      await Get.dialog<void>(
        _JoinRequestBannerDialog(
          message: message,
          payload: payload,
          handler: joinHandler,
        ),
        barrierDismissible: true,
        barrierColor: kColorBlack.withValues(alpha: 0.55),
      );
    } finally {
      _isShowing = false;
    }
    return true;
  }

  static Future<bool> tryShowFromMap(
    Map<String, dynamic> data, {
    JoinRequestPushHandler? handler,
  }) {
    final normalized = Map<String, dynamic>.from(data);
    final type = normalized['type']?.toString().trim() ?? '';
    if (type.isEmpty) {
      normalized['type'] = PushNotificationTypes.joinRequest;
    }
    final payload = JoinRequestPayload.tryParse(normalized);
    if (payload == null) {
      return Future.value(false);
    }
    final message = PushNotificationMessage(
      messageId:
          'socket_join_${payload.requestId}_${DateTime.now().millisecondsSinceEpoch}',
      title: payload.bannerTitle,
      body: payload.bannerBody,
      data: normalized,
    );
    return tryShow(message, handler: handler);
  }
}

class _JoinRequestBannerDialog extends StatelessWidget {
  const _JoinRequestBannerDialog({
    required this.message,
    required this.payload,
    required this.handler,
  });

  final PushNotificationMessage message;
  final JoinRequestPayload payload;
  final JoinRequestPushHandler handler;

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
          boxShadow: [
            BoxShadow(
              color: LiveRoomUiColors.goLiveGradientStart.withValues(
                alpha: 0.28,
              ),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF355D), Color(0xFFFF3EA5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          size: 12, color: kColorWhite),
                      SizedBox(width: 5),
                      SemiBoldText(
                        text: 'JOIN',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Get.back<void>(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: kColorWhite.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
            Spacing.v12,
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white12,
                  backgroundImage: payload.requesterAvatar.isNotEmpty
                      ? NetworkImage(payload.requesterAvatar)
                      : null,
                  child: payload.requesterAvatar.isEmpty
                      ? const Icon(Icons.person, color: kColorWhite)
                      : null,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: payload.bannerTitle,
                        fontSize: TextStyles.k18FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v4,
                      AppText(
                        text: payload.bannerBody,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.78),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v16,
            _GradientActionButton(
              label: 'Add',
              icon: Icons.check_rounded,
              onTap: () async {
                Get.back<void>();
                await handler.respond(
                  payload,
                  action: 'approve',
                  sourceMessage: message,
                );
              },
            ),
            Spacing.v10,
            _OutlineActionButton(
              label: 'Reject',
              onTap: () async {
                Get.back<void>();
                await handler.respond(
                  payload,
                  action: 'reject',
                  sourceMessage: message,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Host sheet listing pending join requests for the current room.
abstract final class JoinRequestsSheet {
  JoinRequestsSheet._();

  static Future<void> show({
    required String roomId,
    JoinRequestPushHandler? handler,
  }) async {
    final joinHandler = handler ?? JoinRequestPushHandler();
    final repo = RoomRepo();
    await Get.bottomSheet(
      _JoinRequestsSheetBody(
        roomId: roomId,
        handler: joinHandler,
        roomRepo: repo,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _JoinRequestsSheetBody extends StatefulWidget {
  const _JoinRequestsSheetBody({
    required this.roomId,
    required this.handler,
    required this.roomRepo,
  });

  final String roomId;
  final JoinRequestPushHandler handler;
  final RoomRepo roomRepo;

  @override
  State<_JoinRequestsSheetBody> createState() => _JoinRequestsSheetBodyState();
}

class _JoinRequestsSheetBodyState extends State<_JoinRequestsSheetBody> {
  bool _loading = true;
  bool _togglingApproval = false;
  bool _approvalRequired = false;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LiveBroadcastController>()) {
      _approvalRequired =
          Get.find<LiveBroadcastController>().joinApprovalRequired.value;
    }
    _load();
  }

  Future<void> _toggleApproval(bool value) async {
    if (_togglingApproval) return;
    setState(() {
      _togglingApproval = true;
      _approvalRequired = value;
    });
    final response = await widget.roomRepo.updateRoomSettings(
      roomId: widget.roomId,
      joinApprovalRequired: value,
      isShowLoader: false,
    );
    if (!mounted) return;
    if (JoinApprovalService.isApiSuccess(response)) {
      if (Get.isRegistered<LiveBroadcastController>()) {
        Get.find<LiveBroadcastController>().setJoinApprovalRequired(value);
      }
    } else {
      setState(() => _approvalRequired = !value);
    }
    setState(() => _togglingApproval = false);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final response = await widget.roomRepo.listJoinRequests(
      roomId: widget.roomId,
      status: 'pending',
      isShowLoader: false,
    );
    final data = response?['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final raw = map['items'] ?? map['requests'] ?? data;
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    // Merge with in-memory host inbox when available.
    if (Get.isRegistered<LiveBroadcastController>()) {
      final live = Get.find<LiveBroadcastController>();
      for (final pending in live.pendingJoinRequests) {
        final id = pending['request_id']?.toString() ??
            pending['requestId']?.toString();
        if (id == null || id.isEmpty) continue;
        final exists = list.any(
          (e) =>
              (e['request_id']?.toString() ?? e['requestId']?.toString()) == id,
        );
        if (!exists) list.insert(0, pending);
      }
    }

    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _respond(Map<String, dynamic> item, String action) async {
    final payload = JoinRequestPayload.tryParse({
      ...item,
      'type': PushNotificationTypes.joinRequest,
      'room_id': widget.roomId,
    });
    if (payload == null) return;
    await widget.handler.respond(payload, action: action);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Spacing.v12,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: SemiBoldText(
                    text: 'Join Requests',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded, color: kColorWhite),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    text: 'Require approval to join',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.75),
                  ),
                ),
                Switch(
                  value: _approvalRequired,
                  onChanged: _togglingApproval ? null : _toggleApproval,
                  activeThumbColor: kColorWhite,
                  activeTrackColor: const Color(0xFFFF3EA5),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFFFF3EA5)),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: AppText(
                text: 'No pending join requests',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.65),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _items.length,
                separatorBuilder: (_, __) => Spacing.v10,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final payload = JoinRequestPayload.tryParse({
                    ...item,
                    'type': PushNotificationTypes.joinRequest,
                    'room_id': widget.roomId,
                  });
                  final name = payload?.requesterName.isNotEmpty == true
                      ? payload!.requesterName
                      : 'Viewer';
                  final avatar = payload?.requesterAvatar ?? '';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white12,
                          backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? const Icon(Icons.person, color: kColorWhite)
                              : null,
                        ),
                        Spacing.h10,
                        Expanded(
                          child: SemiBoldText(
                            text: name,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _respond(item, 'reject'),
                          child: const AppText(
                            text: 'Reject',
                            fontSize: TextStyles.k12FontSize,
                            color: Colors.redAccent,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _respond(item, 'approve'),
                          child: const AppText(
                            text: 'Add',
                            fontSize: TextStyles.k12FontSize,
                            color: Color(0xFFFF3EA5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF355D), Color(0xFFFF3EA5)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite, size: 20),
              Spacing.h8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: kColorWhite,
        side: BorderSide(color: kColorWhite.withValues(alpha: 0.28)),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: SemiBoldText(
        text: label,
        fontSize: TextStyles.k14FontSize,
        color: kColorWhite,
      ),
    );
  }
}
