import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/agency_host_review_actions.dart';
import 'package:qobo_one_live/utils/app_widgets/app_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../../live_action/models/live_map_host.dart';
import '../controllers/agency_host_list_controller.dart';

class AgencyHostListView extends GetView<AgencyHostListController> {
  AgencyHostListView({
    super.key,
    this.embeddedInBottomNav = false,
    String? controllerTag,
  }) : tag = controllerTag;

  final bool embeddedInBottomNav;

  @override
  final String? tag;

  static const double _bottomNavClearance = 94;

  @override
  Widget build(BuildContext context) {
    final body = _screenBody(context);
    if (embeddedInBottomNav) return body;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
    );
  }

  Widget _screenBody(BuildContext context) {
    return AppShellBackground(
      child: SafeArea(
          bottom: !embeddedInBottomNav,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: kColorPrimary),
              );
            }
            final bottomPad = embeddedInBottomNav
                ? MediaQuery.paddingOf(context).bottom + _bottomNavClearance
                : MediaQuery.paddingOf(context).bottom + 16;
            return Column(
              children: [
                _topBar(),
                Expanded(child: _mapStage(context)),
                if (controller.hasOverflowHosts) _overflowHostStrip(context),
                SizedBox(height: bottomPad),
              ],
            );
          }),
        ),
      );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _squareButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: controller.onBackPressed,
          ),
          Spacing.h10,
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kColorBlack.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 17, color: kColorHint),
                  Spacing.h8,
                  Expanded(
                    child: TextField(
                      textInputAction: TextInputAction.search,
                      style: TextStyles.kRegularPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: kColorText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        isDense: true,
                        border: InputBorder.none,
                        hintStyle: TextStyles.kRegularPoppins(
                          fontSize: TextStyles.k10FontSize,
                          colors: kColorHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Spacing.h10,
          _squareButton(
            icon: Icons.refresh_rounded,
            onTap: controller.refreshList,
            accent: AdminAgencyUi.mint,
          ),
        ],
      ),
    );
  }

  Widget _squareButton({
    required IconData icon,
    required VoidCallback onTap,
    Color accent = AdminAgencyUi.sky,
  }) {
    return AdminAgencyUi.glassIconButton(
      icon: icon,
      onTap: onTap,
      accent: accent,
      size: 40,
      iconSize: 16,
    );
  }
  Widget _mapStage(BuildContext context) {
    return GetBuilder<AgencyHostListController>(
      tag: tag,
      builder: (ctrl) {
        if (!ctrl.hasHosts) {
          return const Center(
            child: SemiBoldText(
              text: 'No host found',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
          );
        }

        final hosts = ctrl.mapHosts;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LiveMapPainter(
                  users: hosts.map((h) => h.alignment).toList(),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.15, -0.05),
                    radius: 0.75,
                    colors: [
                      kColorWhite.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openHostListSheet(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kColorPrimary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kColorWhite.withValues(alpha: 0.24),
                        ),
                      ),
                      child: SemiBoldText(
                        text: '${ctrl.agencyDisplayName} hosts',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final host in hosts)
              Align(
                alignment: host.alignment,
                child: _MapUserNode(
                  host: host,
                  onTap: host.isPlaceholder || host.hostId == null
                      ? null
                      : () {
                          final data = ctrl.hostById(host.hostId);
                          if (data != null) {
                            _openHostDetailSheet(context, data);
                          }
                        },
                ),
              ),
          ],
        );
      },
    );
  }

  /// Horizontal strip for hosts ranked below the top 10 tree slots.
  Widget _overflowHostStrip(BuildContext context) {
    return GetBuilder<AgencyHostListController>(
      tag: tag,
      builder: (ctrl) {
        final overflow = ctrl.overflowHosts;
        if (overflow.isEmpty) return const SizedBox.shrink();

        // Show up to 7 avatars; badge counts any remaining in the strip.
        const visibleAvatarLimit = 7;
        final visible = overflow.take(visibleAvatarLimit).toList();
        final hiddenCount = overflow.length - visible.length;
        final moreLabel = hiddenCount > 0 ? '+$hiddenCount' : '+${overflow.length}';

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openHostListSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 148,
                      height: 1,
                      color: kColorWhite.withValues(alpha: 0.78),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: kColorWhite,
                          size: 18,
                        ),
                        Spacing.h8,
                        SemiBoldText(
                          text: 'More hosts (${overflow.length})',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: kColorWhite.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ],
                    ),
                    Spacing.v10,
                    Row(
                      children: [
                        for (final host in visible)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _OverflowHostAvatar(
                              host: host,
                              onTap: () => _openHostDetailSheet(context, host),
                            ),
                          ),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: kColorPrimary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kColorPrimary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: SemiBoldText(
                            text: moreLabel,
                            fontSize: TextStyles.k10FontSize,
                            color: kColorWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Single-host detail from API data (tree node or overflow avatar tap).
  void _openHostDetailSheet(BuildContext context, AgencyHostModel host) {
    showAppBottomSheet<void>(
      context: context,
      title: host.name,
      subtitle: 'LV.${host.coinsPerSecond} · ${host.status}',
      theme: AppBottomSheetTheme.dark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Obx(
          () => _HostSheetCard(
            host: host,
            formatCoins: controller.formatCoins,
            showHostId: true,
            showReviewActions: host.isPending,
            isProcessing: controller.processingReviewId.value ==
                host.reviewApplicationId,
            onApprove: () async {
              final ok = await controller.approveHostApplication(host);
              if (ok && context.mounted) Navigator.of(context).pop();
            },
            onReject: () async {
              final reason = await showAgencyHostRejectReasonDialog(context);
              if (reason == null || reason.isEmpty) return;
              final ok = await controller.rejectHostApplication(host, reason);
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _openHostListSheet(BuildContext context) {
    final hosts = controller.hostList;
    showAppBottomSheet<void>(
      context: context,
      title: 'Agency hosts',
      subtitle: hosts.isEmpty
          ? 'No host found'
          : '${hosts.length} host${hosts.length == 1 ? '' : 's'}',
      theme: AppBottomSheetTheme.dark,
      child: hosts.isEmpty
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 32),
              child: Center(
                child: SemiBoldText(
                  text: 'No host found',
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  for (var i = 0; i < hosts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _HostSheetCard(
                      host: hosts[i],
                      formatCoins: controller.formatCoins,
                      highlighted:
                          controller.highlightHostId.value == hosts[i].id,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Host stats card used in list + single-host detail bottom sheets.
class _HostSheetCard extends StatelessWidget {
  const _HostSheetCard({
    required this.host,
    required this.formatCoins,
    this.highlighted = false,
    this.showHostId = false,
    this.showReviewActions = false,
    this.isProcessing = false,
    this.onApprove,
    this.onReject,
  });

  final AgencyHostModel host;
  final String Function(int) formatCoins;
  final bool highlighted;
  final bool showHostId;
  final bool showReviewActions;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: highlighted ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? kColorPrimary.withValues(alpha: 0.75)
              : kColorWhite.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppUserAvatar(
                name: host.name,
                imageUrl: host.avatarUrl,
                size: 48,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: host.name,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v2,
                    AppText(
                      text: '${host.coinsPerSecond} coins/sec · ${host.lastViewer}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              _statusBadge(host.status),
            ],
          ),
          Spacing.v10,
          Row(
            children: [
              Expanded(
                child: _metricChip(
                  Icons.payments_rounded,
                  formatCoins(host.totalEarnings),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _metricChip(
                  kGiftIcon,
                  formatCoins(host.totalGifts),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _metricChip(
                  Icons.call_rounded,
                  formatCoins(host.totalCallingSpend),
                ),
              ),
            ],
          ),
          Spacing.v6,
          AppText(
            text: '${host.callingMinutes} min on calls',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.5),
          ),
          if (showHostId && host.id.isNotEmpty) ...[
            Spacing.v8,
            AppText(
              text: 'Host ID: ${host.id}',
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.45),
            ),
          ],
          if (showReviewActions &&
              onApprove != null &&
              onReject != null) ...[
            Spacing.v12,
            AgencyHostReviewActions(
              onApprove: onApprove!,
              onReject: onReject!,
              isProcessing: isProcessing,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kColorPrimary),
          Spacing.h6,
          Expanded(
            child: SemiBoldText(
              text: value,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.greenAccent;
        break;
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orangeAccent;
        break;
      default:
        bgColor = kColorWhite.withValues(alpha: 0.1);
        textColor = kColorWhite.withValues(alpha: 0.7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AppText(
        text: status,
        fontSize: TextStyles.k10FontSize,
        color: textColor,
      ),
    );
  }
}

class _MapUserNode extends StatelessWidget {
  const _MapUserNode({required this.host, this.onTap});

  final LiveMapHost host;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (host.isPlaceholder) {
      return _blankTreeSlot();
    }

    final node = SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kColorPrimary,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kColorBlack.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: AppUserAvatar(
                  name: host.name,
                  imageUrl: host.avatarUrl,
                  size: 54,
                  fontSize: TextStyles.k12FontSize,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: host.isPending ? Colors.orangeAccent : Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: kColorWhite, width: 1),
                  ),
                ),
              ),
            ],
          ),
          Spacing.v4,
          SemiBoldText(
            text: host.name,
            fontSize: 9,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2D0D58).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kColorPrimary),
            ),
            child: SemiBoldText(
              text: host.levelBadge,
              fontSize: 7,
              color: kColorWhite,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return node;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: node,
      ),
    );
  }

  /// Empty tree node — dashed ring only, no label (fills sparse layouts).
  Widget _blankTreeSlot() {
    return SizedBox(
      width: 58,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kColorWhite.withValues(alpha: 0.04),
          border: Border.all(
            color: kColorWhite.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB875FF).withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowHostAvatar extends StatelessWidget {
  const _OverflowHostAvatar({required this.host, this.onTap});

  final AgencyHostModel host;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.85)),
      ),
      child: AppUserAvatar(
        name: host.name,
        imageUrl: host.avatarUrl,
        size: 27,
        fontSize: TextStyles.k8FontSize,
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class _LiveMapPainter extends CustomPainter {
  const _LiveMapPainter({required this.users});

  final List<Alignment> users;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kColorWhite.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final nodes = users.map((alignment) {
      return Offset(
        size.width * (alignment.x + 1) / 2,
        size.height * (alignment.y + 1) / 2,
      );
    }).toList();

    for (var i = 0; i < nodes.length - 1; i++) {
      final path = Path()
        ..moveTo(nodes[i].dx, nodes[i].dy)
        ..quadraticBezierTo(
          size.width * (i.isEven ? 0.24 : 0.76),
          (nodes[i].dy + nodes[i + 1].dy) / 2,
          nodes[i + 1].dx,
          nodes[i + 1].dy,
        );
      _drawDashedPath(canvas, path, paint);
    }

    final accent = Paint()
      ..color = const Color(0xFFB875FF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final node in nodes) {
      canvas.drawCircle(node, 18, accent);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 7.0;
      const gap = 6.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) {
    if (oldDelegate.users.length != users.length) return true;
    for (var i = 0; i < users.length; i++) {
      if (oldDelegate.users[i] != users[i]) return true;
    }
    return false;
  }
}
