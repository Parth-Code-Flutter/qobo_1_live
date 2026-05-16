import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: CommonAppBarWidget(
        title: 'My Hosts',
        useMaterialAppBar: true,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/agency-revenue'),
            icon: const Icon(Icons.account_balance_wallet_rounded, color: kColorText),
          ),
          IconButton(
            onPressed: controller.refreshList,
            icon: const Icon(Icons.refresh_rounded, color: kColorText),
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
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.hostList.length,
          separatorBuilder: (context, index) => Spacing.v12,
          itemBuilder: (context, index) {
            final host = controller.hostList[index];
            return _buildHostCard(host);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off_rounded, size: 64, color: kColorHint),
          Spacing.v16,
          const SemiBoldText(
            text: 'No Hosts Yet',
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
          Spacing.v8,
          const AppText(
            text: 'Share your recruit link to invite hosts to your agency.',
            fontSize: TextStyles.k14FontSize,
            color: kColorHint,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard(AgencyHostModel host) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorHint.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          SafeNetworkAvatar(
            url: host.avatarUrl,
            size: 56,
            fallback: CircleAvatar(
              radius: 28,
              backgroundColor: kColorHint.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: kColorHint),
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
                  color: kColorText,
                ),
                Spacing.v4,
                AppText(
                  text: 'ID: ${host.id}',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
                Spacing.v6,
                Row(
                  children: [
                    const Icon(Icons.diamond_outlined, size: 14, color: Colors.orange),
                    Spacing.h4,
                    AppText(
                      text: '${host.totalEarnings} Diamonds',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorText,
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
