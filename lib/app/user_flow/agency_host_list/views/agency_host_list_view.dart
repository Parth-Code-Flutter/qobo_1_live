import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_action_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../../live_action/models/live_map_host.dart';
import '../controllers/agency_host_list_controller.dart';

/// Agency host constellation map (same layout as heart tab, standalone route).
class AgencyHostListView extends GetView<AgencyHostListController> {
  const AgencyHostListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF5C0A68).withValues(alpha: 0.52),
                const Color(0xFF170D59).withValues(alpha: 0.72),
              ],
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: kColorPrimary),
                );
              }
              return Column(
                children: [
                  _topBar(),
                  Expanded(child: _mapStage()),
                  _suggestionStrip(context),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
                ],
              );
            }),
          ),
        ),
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
          ),
        ],
      ),
    );
  }

  Widget _squareButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0x661B0F36),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: kColorWhite, size: 19),
        ),
      ),
    );
  }

  Widget _mapStage() {
    return GetBuilder<AgencyHostListController>(
      builder: (ctrl) {
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
            for (final host in hosts)
              Align(
                alignment: host.alignment,
                child: _MapUserNode(host: host),
              ),
          ],
        );
      },
    );
  }

  Widget _suggestionStrip(BuildContext context) {
    return GetBuilder<AgencyHostListController>(
      builder: (ctrl) {
        final images = ctrl.suggestionAssets;
        final hostCount = ctrl.hostList.length;
        final moreCount = hostCount > 7 ? '+${hostCount - 7}' : '+$hostCount';

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
                        const SemiBoldText(
                          text: 'Agency hosts',
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
                        for (final image in images)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SuggestionAvatar(imageAsset: image),
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
                            text: moreCount,
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

  void _openHostListSheet(BuildContext context) {
    final hosts = controller.hostList;
    showAppBottomSheet<void>(
      context: context,
      title: 'Agency hosts',
      subtitle: hosts.isEmpty
          ? 'No hosts yet'
          : '${hosts.length} host${hosts.length == 1 ? '' : 's'}',
      theme: AppBottomSheetTheme.dark,
      child: hosts.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 48,
                    color: kColorWhite.withValues(alpha: 0.4),
                  ),
                  Spacing.v12,
                  AppText(
                    text: 'Share your recruit link to invite hosts.',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite.withValues(alpha: 0.65),
                    align: TextAlign.center,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  for (var i = 0; i < hosts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _SheetHostTile(
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

class _SheetHostTile extends StatelessWidget {
  const _SheetHostTile({
    required this.host,
    required this.formatCoins,
    this.highlighted = false,
  });

  final AgencyHostModel host;
  final String Function(int) formatCoins;
  final bool highlighted;

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
              SafeNetworkAvatar(
                url: host.avatarUrl,
                size: 48,
                fallback: CircleAvatar(
                  radius: 24,
                  backgroundColor: kColorPrimary.withValues(alpha: 0.35),
                  child: SemiBoldText(
                    text: host.name.isNotEmpty ? host.name[0] : '?',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                ),
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
                  Icons.card_giftcard_rounded,
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
  const _MapUserNode({required this.host});

  final LiveMapHost host;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                    color: host.isAgencyHost ? kColorPrimary : kColorWhite,
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
                child: ClipOval(
                  child: Image.asset(host.imageAsset, fit: BoxFit.cover),
                ),
              ),
              if (host.isAgencyHost)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
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
              border: Border.all(
                color: host.isAgencyHost
                    ? kColorPrimary
                    : LiveActionColors.diamondGold,
              ),
            ),
            child: SemiBoldText(
              text: host.levelBadge,
              fontSize: 7,
              color:
                  host.isAgencyHost ? kColorWhite : LiveActionColors.diamondGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionAvatar extends StatelessWidget {
  const _SuggestionAvatar({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.85)),
      ),
      child: ClipOval(child: Image.asset(imageAsset, fit: BoxFit.cover)),
    );
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
