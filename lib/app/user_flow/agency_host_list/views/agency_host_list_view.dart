import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_host_list_controller.dart';

class AgencyHostListView extends GetView<AgencyHostListController> {
  const AgencyHostListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: kColorPrimary),
                    );
                  }
                  if (controller.hostList.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: controller.hostList.length,
                    separatorBuilder: (_, __) => Spacing.v12,
                    itemBuilder: (context, index) {
                      final host = controller.hostList[index];
                      final highlighted =
                          controller.highlightHostId.value == host.id;
                      return _buildHostCard(host, highlighted: highlighted);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kColorWhite, size: 18),
          ),
          const Expanded(
            child: Center(
              child: SemiBoldText(
                text: 'My Hosts',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Get.toNamed(Routes.AGENCY_REVENUE),
            icon: const Icon(Icons.account_balance_wallet_rounded, color: kColorWhite),
          ),
          IconButton(
            onPressed: controller.refreshList,
            icon: const Icon(Icons.refresh_rounded, color: kColorWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 64, color: kColorWhite.withValues(alpha: 0.5)),
            Spacing.v16,
            const SemiBoldText(
              text: 'No Hosts Yet',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Spacing.v8,
            AppText(
              text: 'Share your recruit link to invite hosts.',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostCard(AgencyHostModel host, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: highlighted ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? kColorPrimary.withValues(alpha: 0.8)
              : kColorWhite.withValues(alpha: 0.12),
          width: highlighted ? 1.5 : 1,
        ),
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
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v2,
                    AppText(
                      text: 'ID: ${host.id} · ${host.coinsPerSecond} coins/sec',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.65),
                    ),
                    AppText(
                      text: 'Last caller: ${host.lastViewer}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(host.status),
            ],
          ),
          Spacing.v12,
          Row(
            children: [
              Expanded(
                child: _statBox(
                  Icons.payments_rounded,
                  'Total earning',
                  controller.formatCoins(host.totalEarnings),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _statBox(
                  Icons.card_giftcard_rounded,
                  'Total gifts',
                  controller.formatCoins(host.totalGifts),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _statBox(
                  Icons.call_rounded,
                  'Calling spend',
                  controller.formatCoins(host.totalCallingSpend),
                ),
              ),
            ],
          ),
          Spacing.v10,
          AppText(
            text: '${host.callingMinutes} minutes on calls (gross viewer spend)',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: kColorPrimary),
          Spacing.v6,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.55),
          ),
          Spacing.v2,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
