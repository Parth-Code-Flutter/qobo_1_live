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

const _agencyHostSheetTheme = AppBottomSheetTheme(
  backgroundColor: Color(0xFF160B29),
  titleColor: kColorWhite,
  subtitleColor: AdminAgencyUi.textMuted,
  handleColor: AdminAgencyUi.violet,
  dividerColor: Color(0x2EFFFFFF),
);

class AgencyHostListView extends GetView<AgencyHostListController> {
  const AgencyHostListView({
    super.key,
    this.embeddedInBottomNav = false,
    String? controllerTag,
  }) : _controllerTag = controllerTag;

  final bool embeddedInBottomNav;

  final String? _controllerTag;

  @override
  String? get tag => _controllerTag;

  static const double _bottomNavClearance = 94;

  @override
  Widget build(BuildContext context) {
    final body = _screenBody(context);
    if (embeddedInBottomNav) return body;
    return Scaffold(backgroundColor: Colors.transparent, body: body);
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _squareButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: controller.onBackPressed,
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SemiBoldText(
                      text: 'Agency Hosts',
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppText(
                      text: '${controller.agencyDisplayName} team',
                      fontSize: TextStyles.k10FontSize,
                      color: AdminAgencyUi.textMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Spacing.h8,
              _addHostButton(),
            ],
          ),
          Spacing.v12,
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: kColorBlack.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: kColorWhite.withValues(alpha: 0.68),
                ),
                Spacing.h10,
                Expanded(
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    style: TextStyles.kRegularPoppins(
                      fontSize: TextStyles.k12FontSize,
                      colors: kColorWhite,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search hosts',
                      isDense: true,
                      border: InputBorder.none,
                      hintStyle: TextStyles.kRegularPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: kColorWhite.withValues(alpha: 0.46),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addHostButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.openAddHost,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: AdminAgencyUi.goldButtonGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AdminAgencyUi.gold.withValues(alpha: 0.34),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: AdminAgencyUi.ctaInk,
                size: 17,
              ),
              SizedBox(width: 6),
              SemiBoldText(
                text: 'Add Host',
                fontSize: TextStyles.k10FontSize,
                color: AdminAgencyUi.ctaInk,
              ),
            ],
          ),
        ),
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminAgencyUi.glowIcon(
                    icon: Icons.person_add_alt_1_rounded,
                    accent: AdminAgencyUi.gold,
                    size: 64,
                    iconSize: 28,
                  ),
                  Spacing.v16,
                  const SemiBoldText(
                    text: 'Build your host team',
                    fontSize: TextStyles.k18FontSize,
                    color: kColorWhite,
                  ),
                  Spacing.v6,
                  AppText(
                    text:
                        'Add a host to your agency and submit their profile for review.',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.62),
                    align: TextAlign.center,
                  ),
                  Spacing.v20,
                  AdminGoldCtaButton(
                    label: 'Add Host',
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: ctrl.openAddHost,
                  ),
                ],
              ),
            ),
          );
        }

        final hosts = ctrl.mapHosts;
        if (hosts.isEmpty) {
          return _hostApplicationsList(context, ctrl);
        }
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

  Widget _hostApplicationsList(
    BuildContext context,
    AgencyHostListController ctrl,
  ) {
    final hosts = ctrl.hostList;
    final pendingCount = hosts.where((host) => host.isPending).length;
    final rejectedCount = hosts.where((host) => host.isRejected).length;

    return RefreshIndicator(
      color: AdminAgencyUi.gold,
      backgroundColor: const Color(0xFF25143F),
      onRefresh: () async => ctrl.refreshList(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF402267), Color(0xFF261641)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AdminAgencyUi.violet.withValues(alpha: 0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: kColorBlack.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                AdminAgencyUi.glowIcon(
                  icon: Icons.groups_rounded,
                  accent: AdminAgencyUi.violet,
                  size: 44,
                  iconSize: 21,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text:
                            '${hosts.length} host${hosts.length == 1 ? '' : 's'} registered',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v2,
                      AppText(
                        text: pendingCount > 0
                            ? '$pendingCount awaiting review'
                            : rejectedCount > 0
                            ? '$rejectedCount require attention'
                            : 'Host applications',
                        fontSize: TextStyles.k10FontSize,
                        color: AdminAgencyUi.textMuted,
                      ),
                    ],
                  ),
                ),
                Icon(
                  pendingCount > 0
                      ? Icons.hourglass_top_rounded
                      : Icons.verified_rounded,
                  color: pendingCount > 0
                      ? AdminAgencyUi.gold
                      : AdminAgencyUi.mint,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < hosts.length; index++) ...[
            if (index > 0) Spacing.v10,
            _HostSheetCard(
              host: hosts[index],
              formatCoins: ctrl.formatCoins,
              highlighted: ctrl.highlightHostId.value == hosts[index].id,
              onTap: () => _openHostDetailSheet(context, hosts[index]),
            ),
          ],
        ],
      ),
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
        final moreLabel = hiddenCount > 0
            ? '+$hiddenCount'
            : '+${overflow.length}';

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
      title: 'Host details',
      subtitle: 'Profile, performance, and application status',
      theme: _agencyHostSheetTheme,
      child: Obx(
        () => _HostSheetCard(
          host: host,
          formatCoins: controller.formatCoins,
          showHostId: true,
          showReviewActions: host.isPending,
          isProcessing:
              controller.processingReviewId.value == host.reviewApplicationId,
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
    );
  }

  void _openHostFromListSheet(BuildContext pageContext, AgencyHostModel host) {
    Navigator.of(pageContext).pop();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (pageContext.mounted) {
        _openHostDetailSheet(pageContext, host);
      }
    });
  }

  String _hostStatusSummary(List<AgencyHostModel> hosts) {
    final active = hosts.where((host) => host.isActive).length;
    final pending = hosts.where((host) => host.isPending).length;
    final parts = <String>[
      if (active > 0) '$active active',
      if (pending > 0) '$pending pending',
    ];
    return parts.isEmpty ? 'Tap a host to view details' : parts.join(' · ');
  }

  void _openHostListSheet(BuildContext context) {
    final hosts = controller.hostList;
    showAppBottomSheet<void>(
      context: context,
      title: '${controller.agencyDisplayName} hosts',
      subtitle: hosts.isEmpty
          ? 'No hosts registered yet'
          : _hostStatusSummary(hosts),
      theme: _agencyHostSheetTheme,
      child: hosts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  AdminAgencyUi.glowIcon(
                    icon: Icons.person_add_alt_1_rounded,
                    accent: AdminAgencyUi.gold,
                    size: 56,
                    iconSize: 25,
                  ),
                  const SizedBox(height: 14),
                  const SemiBoldText(
                    text: 'No hosts yet',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                  Spacing.v6,
                  const AppText(
                    text: 'Add your first host to start building the team.',
                    fontSize: TextStyles.k12FontSize,
                    color: AdminAgencyUi.textMuted,
                    align: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < hosts.length; i++) ...[
                  if (i > 0) Spacing.v10,
                  _HostSheetCard(
                    host: hosts[i],
                    formatCoins: controller.formatCoins,
                    highlighted:
                        controller.highlightHostId.value == hosts[i].id,
                    onTap: () => _openHostFromListSheet(context, hosts[i]),
                  ),
                ],
              ],
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
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  final AgencyHostModel host;
  final String Function(int) formatCoins;
  final bool highlighted;
  final bool showHostId;
  final bool showReviewActions;
  final bool isProcessing;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1748),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AdminAgencyUi.gold.withValues(alpha: 0.75)
              : _statusColor(host.status).withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppUserAvatar(
                name: host.name,
                imageUrl: host.avatarUrl,
                size: 54,
                backgroundColor: AdminAgencyUi.violet.withValues(alpha: 0.55),
                border: Border.all(
                  color: _statusColor(host.status).withValues(alpha: 0.85),
                  width: 1.5,
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
                      text: host.category.isNotEmpty
                          ? host.category
                          : '${host.coinsPerSecond} coins/sec',
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
                  'Earnings',
                  formatCoins(host.totalEarnings),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _metricChip(
                  kGiftIcon,
                  'Gifts',
                  formatCoins(host.totalGifts),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _metricChip(
                  Icons.call_rounded,
                  'Calls',
                  formatCoins(host.totalCallingSpend),
                ),
              ),
            ],
          ),
          Spacing.v6,
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: kColorWhite.withValues(alpha: 0.45),
              ),
              Spacing.h6,
              AppText(
                text: '${host.callingMinutes} min on calls',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.5),
              ),
              if (host.lastViewer.isNotEmpty &&
                  host.lastViewer.toLowerCase() != 'unknown') ...[
                const Spacer(),
                Flexible(
                  child: AppText(
                    text: 'Last: ${host.lastViewer}',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (showHostId) ...[
            Spacing.v12,
            Divider(height: 1, color: kColorWhite.withValues(alpha: 0.10)),
            Spacing.v8,
            if (host.phone.isNotEmpty)
              _detailRow(Icons.phone_outlined, 'Phone', host.phone),
            if (host.gmail.isNotEmpty)
              _detailRow(Icons.email_outlined, 'Email', host.gmail),
            if (host.id.isNotEmpty)
              _detailRow(Icons.badge_outlined, 'Host ID', host.id),
            if (host.createdAt.isNotEmpty)
              _detailRow(
                Icons.calendar_today_outlined,
                'Applied',
                host.createdAt,
              ),
            if (host.reason?.trim().isNotEmpty == true)
              _detailRow(
                Icons.info_outline_rounded,
                'Note',
                host.reason!.trim(),
                accent: AdminAgencyUi.rose,
              ),
          ],
          if (showReviewActions && onApprove != null && onReject != null) ...[
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

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: card,
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF190D2D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AdminAgencyUi.pink),
          Spacing.h6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: label,
                  fontSize: TextStyles.k8FontSize,
                  color: kColorWhite.withValues(alpha: 0.44),
                ),
                SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color accent = AdminAgencyUi.violet,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          Spacing.h8,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.48),
          ),
          Spacing.h10,
          Expanded(
            child: AppText(
              text: value,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.85),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return AdminAgencyUi.mint;
      case 'pending':
        return AdminAgencyUi.gold;
      case 'rejected':
      case 'suspended':
        return AdminAgencyUi.rose;
      default:
        return AdminAgencyUi.violet;
    }
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        bgColor = AdminAgencyUi.mint.withValues(alpha: 0.18);
        textColor = AdminAgencyUi.mint;
        break;
      case 'pending':
        bgColor = AdminAgencyUi.gold.withValues(alpha: 0.18);
        textColor = AdminAgencyUi.gold;
        break;
      case 'rejected':
      case 'suspended':
        bgColor = AdminAgencyUi.rose.withValues(alpha: 0.18);
        textColor = AdminAgencyUi.rose;
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
                  border: Border.all(color: kColorPrimary, width: 1.5),
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
                    color: host.isPending
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
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
