import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_host_list_controller.dart';

class AgencyHostListView extends GetView<AgencyHostListController> {
  const AgencyHostListView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: CommonAppBarWidget(
        title: 'My Hosts',
        useMaterialAppBar: true,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(Routes.AGENCY_REVENUE),
            icon: Icon(
              Icons.account_balance_wallet_rounded,
              color: colors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: controller.refreshList,
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kColorPrimary),
          );
        }

        if (controller.hostList.isEmpty) {
          return _buildEmptyState(colors);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.hostList.length,
          separatorBuilder: (context, index) => Spacing.v12,
          itemBuilder: (context, index) {
            final host = controller.hostList[index];
            return _buildHostCard(colors, host);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 64, color: colors.iconMuted),
            Spacing.v16,
            SemiBoldText(
              text: 'No Hosts Yet',
              fontSize: TextStyles.k18FontSize,
              color: colors.textPrimary,
            ),
            Spacing.v8,
            AppText(
              text:
                  'Share your recruit link to invite hosts. Approved hosts will appear here once the host list API is connected.',
              fontSize: TextStyles.k14FontSize,
              color: colors.textSecondary,
              align: TextAlign.center,
            ),
            Spacing.v20,
            TextButton(
              onPressed: () => Get.toNamed(Routes.AGENCY_RECRUIT_LINK),
              child: const SemiBoldText(
                text: 'Open Recruit Link',
                fontSize: TextStyles.k14FontSize,
                color: kColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostCard(AppThemeColors colors, AgencyHostModel host) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          SafeNetworkAvatar(
            url: host.avatarUrl,
            size: 56,
            fallback: CircleAvatar(
              radius: 28,
              backgroundColor: colors.surfaceMuted,
              child: Icon(Icons.person, color: colors.iconMuted),
            ),
          ),
          Spacing.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: host.name,
                  fontSize: TextStyles.k16FontSize,
                  color: colors.textPrimary,
                ),
                Spacing.v4,
                AppText(
                  text: 'ID: ${host.id}',
                  fontSize: TextStyles.k12FontSize,
                  color: colors.textSecondary,
                ),
                Spacing.v6,
                Row(
                  children: [
                    const Icon(Icons.diamond_outlined, size: 14, color: Colors.orange),
                    Spacing.h4,
                    AppText(
                      text: '${host.totalEarnings} Diamonds',
                      fontSize: TextStyles.k12FontSize,
                      color: colors.textPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusBadge(host.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        break;
      case 'pending':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        break;
      case 'suspended':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        break;
      default:
        bgColor = kColorHint.withValues(alpha: 0.1);
        textColor = kColorHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText(
        text: status,
        fontSize: TextStyles.k10FontSize,
        color: textColor,
      ),
    );
  }
}
