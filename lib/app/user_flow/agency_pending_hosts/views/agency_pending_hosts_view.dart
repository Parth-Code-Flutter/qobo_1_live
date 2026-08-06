import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_host_list/controllers/agency_host_list_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/agency_host_review_actions.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_pending_hosts_controller.dart';

/// Pending host applications — agency owner review screen.
class AgencyPendingHostsView extends GetView<AgencyPendingHostsController> {
  const AgencyPendingHostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topBar(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: kColorPrimary),
                    );
                  }
                  if (controller.loadError.value.isNotEmpty &&
                      controller.applications.isEmpty) {
                    return _errorState();
                  }
                  if (controller.applications.isEmpty) {
                    return _emptyState();
                  }
                  return RefreshIndicator(
                    color: kColorPrimary,
                    onRefresh: () =>
                        controller.fetchPendingApplications(showLoader: false),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: controller.applications.length,
                        separatorBuilder: (_, __) => Spacing.v12,
                        itemBuilder: (_, index) {
                          final host = controller.applications[index];
                          return _PendingHostCard(
                            host: host,
                            isProcessing: controller.processingId.value ==
                                host.reviewApplicationId,
                            onApprove: () => controller.approveHost(host),
                            onReject: () async {
                              final reason =
                                  await showAgencyHostRejectReasonDialog(
                                context,
                              );
                              if (reason != null && reason.isNotEmpty) {
                                await controller.rejectHost(host, reason);
                              }
                            },
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          AdminAgencyUi.glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: controller.onBackPressed,
            accent: AdminAgencyUi.sky,
            size: 40,
            iconSize: 16,
          ),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Pending hosts',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Review and accept or reject applications',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
          Obx(() {
            final count = controller.applications.length;
            if (count == 0 && !controller.isLoading.value) {
              return const SizedBox.shrink();
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminAgencyUi.glowIcon(
                  icon: Icons.pending_actions_rounded,
                  accent: AdminAgencyUi.gold,
                  size: 36,
                  iconSize: 16,
                ),
                Spacing.h8,
                SemiBoldText(
                  text: '$count',
                  fontSize: TextStyles.k14FontSize,
                  color: AdminAgencyUi.gold,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: kColorWhite.withValues(alpha: 0.5),
            ),
            Spacing.v16,
            const SemiBoldText(
              text: 'No pending applications',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: 'New host applications will appear here for your review.',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text: controller.loadError.value,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.8),
              align: TextAlign.center,
            ),
            Spacing.v16,
            OutlinedButton(
              onPressed: controller.fetchPendingApplications,
              style: OutlinedButton.styleFrom(
                foregroundColor: kColorWhite,
                side: BorderSide(color: kColorWhite.withValues(alpha: 0.4)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingHostCard extends StatelessWidget {
  const _PendingHostCard({
    required this.host,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final AgencyHostModel host;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SafeNetworkAvatar(
                url: host.avatarUrl,
                size: 52,
                fallback: CircleAvatar(
                  radius: 26,
                  backgroundColor: kColorPrimary.withValues(alpha: 0.35),
                  child: SemiBoldText(
                    text: host.name.isNotEmpty ? host.name[0] : '?',
                    fontSize: TextStyles.k18FontSize,
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
                    if (host.phone.isNotEmpty) ...[
                      Spacing.v2,
                      AppText(
                        text: host.phone,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.65),
                      ),
                    ],
                    if (host.category.isNotEmpty) ...[
                      Spacing.v2,
                      AppText(
                        text: host.category,
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppText(
                  text: 'Pending',
                  fontSize: TextStyles.k10FontSize,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          if (host.gmail.isNotEmpty) ...[
            Spacing.v10,
            AppText(
              text: host.gmail,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.45),
            ),
          ],
          Spacing.v12,
          AgencyHostReviewActions(
            onApprove: onApprove,
            onReject: onReject,
            isProcessing: isProcessing,
          ),
        ],
      ),
    );
  }
}
