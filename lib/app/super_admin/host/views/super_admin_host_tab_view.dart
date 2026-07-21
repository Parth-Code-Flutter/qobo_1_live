import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Host tab — `GET /api/super-admin/hosts/track`.
class SuperAdminHostTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminHostTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SuperAdminTabHeader(
              icon: Icons.mic_rounded,
              title: 'Host',
              subtitle: 'Track host activity across all agencies',
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingHosts.value &&
                    controller.trackedHosts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                final hosts = controller.trackedHosts;
                if (hosts.isEmpty) {
                  return RefreshIndicator(
                    color: kColorPrimary,
                    onRefresh: () =>
                        controller.loadTrackedHosts(showLoader: false),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        SuperAdminEmptyState(
                          icon: Icons.podcasts_rounded,
                          title: 'No host activity found',
                          subtitle: 'Pull down to refresh host tracking data',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: kColorPrimary,
                  onRefresh: () =>
                      controller.loadTrackedHosts(showLoader: false),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: hosts.length,
                    separatorBuilder: (_, __) => Spacing.v12,
                    itemBuilder: (_, index) {
                      final host = hosts[index];
                      return SuperAdminGlassCard(
                        child: Row(
                          children: [
                            SafeNetworkAvatar(
                              url: host.avatarUrl,
                              size: 48,
                              fallback: CircleAvatar(
                                radius: 24,
                                backgroundColor: kColorPrimary,
                                child: Text(
                                  host.name.isNotEmpty
                                      ? host.name.characters.first
                                      : 'H',
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
                                    fontSize: TextStyles.k14FontSize,
                                    color: kColorWhite,
                                  ),
                                  Spacing.v2,
                                  AppText(
                                    text:
                                        'Agency ${host.agencyCode.isEmpty ? '—' : host.agencyCode} • ${host.status}',
                                    fontSize: TextStyles.k10FontSize,
                                    color: Colors.white70,
                                  ),
                                  Spacing.v6,
                                  AppText(
                                    text:
                                        '💎 ${host.diamonds.toStringAsFixed(0)}  ·  🪙 ${host.coins.toStringAsFixed(0)}  ·  ⏱ ${_formatSeconds(host.totalStreamSeconds)}',
                                    fontSize: TextStyles.k10FontSize,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFD166,
                                ).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD166,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: SemiBoldText(
                                text: host.totalCommissionEarned
                                    .toStringAsFixed(1),
                                fontSize: TextStyles.k12FontSize,
                                color: const Color(0xFFFFD166),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(double seconds) {
    if (seconds <= 0) return '0h';
    final hours = seconds / 3600;
    if (hours >= 1) return '${hours.toStringAsFixed(1)}h';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(0)}m';
  }
}
