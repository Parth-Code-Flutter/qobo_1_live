import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_broadcast_controller.dart';

class LiveViewersSheet extends GetView<LiveBroadcastController> {
  const LiveViewersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
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
          Spacing.v16,
          Obx(
            () => SemiBoldText(
              text:
                  '${controller.viewerCount.value} ${controller.viewerCount.value == 1 ? 'Viewer' : 'Viewers'}',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
          ),
          Spacing.v12,
          Flexible(
            child: Obx(() {
              final viewers = controller.liveViewers;
              if (viewers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: AppText(
                    text: 'No viewers in the room yet.',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorHint,
                    align: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: viewers.length,
                separatorBuilder: (_, __) => Spacing.v8,
                itemBuilder: (_, index) {
                  final viewer = viewers[index];
                  final name = viewer['name']?.toString() ?? 'Viewer';
                  final isHost = viewer['isHost'] == true;
                  final isCurrentUser = viewer['isCurrentUser'] == true;
                  return _ViewerListTile(
                    name: name,
                    avatarUrl: viewer['avatarUrl']?.toString(),
                    isHost: isHost,
                    isCurrentUser: isCurrentUser,
                    onTap: () => controller.openViewerProfile(viewer),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ViewerListTile extends StatelessWidget {
  const _ViewerListTile({
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isCurrentUser,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final bool isHost;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AppUserAvatar(name: name, imageUrl: avatarUrl, size: 40),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: isCurrentUser ? '$name (You)' : name,
                  fontSize: TextStyles.k14FontSize,
                  color: isCurrentUser
                      ? kColorWhite.withValues(alpha: 0.55)
                      : kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isHost)
                  const AppText(
                    text: 'Host',
                    fontSize: TextStyles.k10FontSize,
                    color: Color(0xFFFF79B4),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.account_circle_outlined,
            size: 18,
            color: kColorWhite.withValues(alpha: 0.45),
          ),
          if (!isCurrentUser) ...[
            Spacing.h8,
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: kColorWhite.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

class LiveViewerProfileDialog extends GetView<LiveBroadcastController> {
  const LiveViewerProfileDialog({super.key, required this.viewer});

  final Map<String, dynamic> viewer;

  @override
  Widget build(BuildContext context) {
    final name = viewer['name']?.toString().trim().isNotEmpty == true
        ? viewer['name'].toString()
        : 'Viewer';
    final avatarUrl = viewer['avatarUrl']?.toString();
    final isHost = viewer['isHost'] == true;
    final isCurrentUser = viewer['isCurrentUser'] == true;
    final role = isHost ? 'Host' : 'Viewer';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF251245), Color(0xFF111827)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: Get.back,
                child: Icon(
                  Icons.close_rounded,
                  color: kColorWhite.withValues(alpha: 0.72),
                  size: 22,
                ),
              ),
            ),
            AppUserAvatar(name: name, imageUrl: avatarUrl, size: 82),
            Spacing.v12,
            SemiBoldText(
              text: isCurrentUser ? '$name (You)' : name,
              fontSize: TextStyles.k20FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
            Spacing.v10,
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProfileBadge(
                  icon: isHost
                      ? Icons.workspace_premium_rounded
                      : Icons.remove_red_eye_rounded,
                  label: role,
                  color: isHost
                      ? const Color(0xFFFF79B4)
                      : const Color(0xFF75C7FF),
                ),
                if (isCurrentUser)
                  const _ProfileBadge(
                    icon: Icons.person_rounded,
                    label: 'You',
                    color: Color(0xFF7CF2AE),
                  ),
              ],
            ),
            Spacing.v16,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  _ProfileMetric(label: 'Room role', value: role),
                  Container(
                    width: 1,
                    height: 34,
                    color: kColorWhite.withValues(alpha: 0.10),
                  ),
                  _ProfileMetric(label: 'Status', value: 'Joined'),
                ],
              ),
            ),
            if (!isCurrentUser) ...[
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: _ProfileActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      onTap: () {
                        Get.back();
                        controller.openChatWithViewer(context, viewer);
                      },
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: _ProfileActionButton(
                      icon: kGiftIcon,
                      label: 'Gift',
                      isPrimary: true,
                      onTap: () {
                        // Target this viewer (user scope), same as audio seat Gift.
                        final receiverId =
                            viewer['targetId']?.toString().trim().isNotEmpty ==
                                true
                            ? viewer['targetId'].toString()
                            : viewer['id']?.toString() ?? '';
                        controller.openGiftsSheet(
                          receiverId: receiverId,
                          receiverName: name,
                          roomGift: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LiveHostProfileSheet extends GetView<LiveBroadcastController> {
  const LiveHostProfileSheet({super.key, required this.viewer});

  final Map<String, dynamic> viewer;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final name = viewer['name']?.toString().trim().isNotEmpty == true
        ? viewer['name'].toString().trim()
        : 'Host';
    final avatarUrl = viewer['avatarUrl']?.toString();
    final frameUrl = viewer['avatarFrameUrl']?.toString();
    final targetId = viewer['targetId']?.toString().trim().isNotEmpty == true
        ? viewer['targetId'].toString().trim()
        : viewer['id']?.toString().trim() ?? '';
    final isCurrentUser = viewer['isCurrentUser'] == true;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF251245), Color(0xFF111827)],
          ),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            FramedUserAvatar(
              name: name,
              imageUrl: avatarUrl,
              frameUrl: frameUrl,
              frameSeed: targetId.isNotEmpty ? targetId : name,
              size: 84,
              fontSize: TextStyles.k20FontSize,
            ),
            Spacing.v12,
            SemiBoldText(
              text: isCurrentUser ? '$name (You)' : name,
              fontSize: TextStyles.k20FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
            Spacing.v8,
            const _ProfileBadge(
              icon: Icons.workspace_premium_rounded,
              label: 'Host',
              color: Color(0xFFFF79B4),
            ),
            if (!isCurrentUser) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ProfileActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      onTap: () => _closeThen(
                        () => controller.openChatWithViewer(context, viewer),
                      ),
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: Obx(
                      () => _ProfileActionButton(
                        icon: controller.isFollowingHost.value
                            ? Icons.check_rounded
                            : Icons.person_add_alt_1_rounded,
                        label: controller.isFollowingHost.value
                            ? 'Following'
                            : 'Follow',
                        isPrimary: true,
                        onTap: () => _closeThen(controller.toggleFollowHost),
                      ),
                    ),
                  ),
                ],
              ),
              Spacing.v10,
              SizedBox(
                width: double.infinity,
                child: _ProfileActionButton(
                  icon: kGiftIcon,
                  label: 'Gift',
                  isPrimary: true,
                  onTap: () => _closeThen(
                    () => controller.openGiftsSheet(
                      receiverId: targetId,
                      receiverName: name,
                      roomGift: false,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              AppText(
                text: 'This is your live profile.',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.7),
                align: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _closeThen(FutureOr<void> Function() action) {
    Get.back<void>();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 120), () async {
        await action();
      }),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v4,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
        style: TextButton.styleFrom(
          foregroundColor: kColorWhite,
          backgroundColor: isPrimary
              ? const Color(0xFFE12BC5)
              : kColorWhite.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isPrimary
                  ? Colors.transparent
                  : kColorWhite.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }
}
