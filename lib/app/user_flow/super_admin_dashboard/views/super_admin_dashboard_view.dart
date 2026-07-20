import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/super_admin_dashboard_controller.dart';

class SuperAdminDashboardView extends GetView<SuperAdminDashboardController> {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kImgBG),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: kColorPrimary),
                      );
                    }
                    return RefreshIndicator(
                      color: kColorPrimary,
                      onRefresh: () =>
                          controller.loadDashboard(showLoader: false),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            sliver: SliverToBoxAdapter(child: _statsGrid()),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            sliver: SliverToBoxAdapter(child: _inviteCard()),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            sliver: SliverToBoxAdapter(child: _tabs()),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: true,
                            child: TabBarView(
                              children: [_agenciesTab(context), _hostsTab()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _iconButton(Icons.arrow_back_ios_new_rounded, Get.back),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Super Admin',
                  fontSize: TextStyles.k20FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Agencies, hosts, approvals',
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          _iconButton(Icons.refresh_rounded, () {
            controller.loadDashboard(showLoader: false);
          }),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: kColorWhite.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: kColorWhite, size: 20),
        ),
      ),
    );
  }

  Widget _statsGrid() {
    final stats = controller.stats.value;
    final items = [
      ('Agencies', stats?.totalAgencies ?? 0, Icons.business_rounded),
      (
        'Active Hosts',
        stats?.activeHosts ?? 0,
        Icons.video_camera_front_rounded,
      ),
      (
        'Pending Agencies',
        stats?.pendingAgencies ?? 0,
        Icons.pending_actions_rounded,
      ),
      ('Pending Hosts', stats?.pendingHosts ?? 0, Icons.person_add_alt_rounded),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        return _glassCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: kColorPrimary.withValues(alpha: 0.22),
                child: Icon(item.$3, color: kColorWhite, size: 20),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldText(
                      text: '${item.$2}',
                      fontSize: TextStyles.k20FontSize,
                      color: kColorWhite,
                    ),
                    AppText(
                      text: item.$1,
                      fontSize: TextStyles.k10FontSize,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inviteCard() {
    return _glassCard(
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFFFFD166), size: 30),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Invite Agency',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Generate link and share on WhatsApp',
                  fontSize: TextStyles.k10FontSize,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.generateAgencyLink,
            child: const SemiBoldText(
              text: 'Generate',
              fontSize: TextStyles.k12FontSize,
              color: Color(0xFFFFD166),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
      ),
      child: const TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [kColorPrimary, Color(0xFFFF6A4D)]),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: Colors.white60,
        tabs: [
          Tab(text: 'Agencies'),
          Tab(text: 'Track Hosts'),
        ],
      ),
    );
  }

  Widget _agenciesTab(BuildContext context) {
    return Obx(() {
      final agencies = controller.agencies;
      if (agencies.isEmpty) return _empty('No agencies found');
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: agencies.length,
        separatorBuilder: (_, __) => Spacing.v12,
        itemBuilder: (_, index) {
          final agency = agencies[index];
          final processing = controller.processingAgencyId.value == agency.id;
          return _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SafeNetworkAvatar(
                      url: agency.ownerAvatar,
                      size: 46,
                      fallback: CircleAvatar(
                        radius: 23,
                        backgroundColor: kColorPrimary,
                        child: Text(agency.ownerName.characters.first),
                      ),
                    ),
                    Spacing.h10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: agency.name,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                          ),
                          AppText(
                            text: '${agency.ownerName} • ${agency.code}',
                            fontSize: TextStyles.k10FontSize,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                    _statusPill(agency.status),
                  ],
                ),
                Spacing.v12,
                AppText(
                  text:
                      '${agency.hostCount} hosts • ${agency.pendingHostsCount} pending hosts',
                  fontSize: TextStyles.k12FontSize,
                  color: Colors.white70,
                ),
                if (agency.isPending) ...[
                  Spacing.v12,
                  Row(
                    children: [
                      Expanded(
                        child: _smallAction(
                          'Reject',
                          Colors.white12,
                          () => _confirmRejectAgency(context, agency),
                          disabled: processing,
                        ),
                      ),
                      Spacing.h10,
                      Expanded(
                        child: _smallAction(
                          processing ? 'Wait...' : 'Approve',
                          Colors.green,
                          () => controller.approveAgency(agency),
                          disabled: processing,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _hostsTab() {
    return Obx(() {
      final hosts = controller.trackedHosts;
      if (hosts.isEmpty) return _empty('No host activity found');
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: hosts.length,
        separatorBuilder: (_, __) => Spacing.v12,
        itemBuilder: (_, index) {
          final host = hosts[index];
          return _glassCard(
            child: Row(
              children: [
                SafeNetworkAvatar(
                  url: host.avatarUrl,
                  size: 48,
                  fallback: CircleAvatar(
                    radius: 24,
                    backgroundColor: kColorPrimary,
                    child: Text(host.name.characters.first),
                  ),
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: host.name,
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      AppText(
                        text: 'Agency ${host.agencyCode} • ${host.status}',
                        fontSize: TextStyles.k10FontSize,
                        color: Colors.white70,
                      ),
                      AppText(
                        text:
                            '${host.diamonds.toStringAsFixed(0)} diamonds • ${host.totalCommissionEarned.toStringAsFixed(0)} commission',
                        fontSize: TextStyles.k10FontSize,
                        color: const Color(0xFFFFD166),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> _confirmRejectAgency(
    BuildContext context,
    SuperAdminAgencyItem agency,
  ) async {
    final controllerText = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject agency?'),
        content: TextField(
          controller: controllerText,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Reason / feedback'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: controllerText.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null) {
      await controller.rejectAgency(agency, reason);
    }
  }

  Widget _statusPill(String status) {
    final approved =
        status.toLowerCase() == 'approved' || status.toLowerCase() == 'active';
    final color = approved ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        text: status,
        fontSize: TextStyles.k10FontSize,
        color: color,
      ),
    );
  }

  Widget _smallAction(
    String label,
    Color color,
    VoidCallback onTap, {
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SemiBoldText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }

  Widget _empty(String text) {
    return Center(
      child: AppText(
        text: text,
        fontSize: TextStyles.k14FontSize,
        color: Colors.white70,
      ),
    );
  }
}
