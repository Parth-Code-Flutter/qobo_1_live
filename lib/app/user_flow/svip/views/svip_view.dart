import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/svip_controller.dart';

class SvipView extends GetView<SvipController> {
  const SvipView({super.key});

  static const _gold = AppLightUi.gold;
  static const _goldDeep = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      appBar: const CommonAppBarWidget(
        title: 'SVIP Center',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            _buildPrivilegesSection(),
            Spacing.v24,
            _buildPlansSection(),
            Spacing.v32,
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFF0D6), Color(0xFFFFE8C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _goldDeep.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: _goldDeep,
              size: 56,
            ),
          ),
          Spacing.v12,
          const BoldText(
            text: 'SUPREME VIP',
            fontSize: TextStyles.k22FontSize,
            color: _goldDeep,
            style: TextStyle(letterSpacing: 2),
          ),
          Spacing.v8,
          Obx(
            () => AppText(
              text: controller.isSvipActive.value
                  ? '★ Active Member (Expires in 30 days) ★'
                  : 'Unlock elite customizations and absolute immunity.',
              fontSize: TextStyles.k14FontSize,
              color: controller.isSvipActive.value
                  ? _goldDeep
                  : AppLightUi.body,
              align: TextAlign.center,
              style: controller.isSvipActive.value
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _goldDeep,
                      fontSize: TextStyles.k14FontSize,
                    )
                  : null,
            ),
          ),
          Spacing.v16,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppLightUi.card.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppLightUi.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppCoinIcon(size: 18, color: Colors.amber),
                Spacing.h6,
                Obx(
                  () => AppText(
                    text: 'Balance: ${controller.coinsBalance.value} Coins',
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.title,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: SemiBoldText(
              text: 'Exclusive Privileges',
              fontSize: TextStyles.k18FontSize,
              color: AppLightUi.title,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.privileges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.98,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final privilege = controller.privileges[index];
              final Color color = privilege['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: AppLightUi.cardDecoration(radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        privilege['icon'] as IconData,
                        color: color,
                        size: 20,
                      ),
                    ),
                    Spacing.v10,
                    SemiBoldText(
                      text: privilege['title'] as String,
                      fontSize: TextStyles.k14FontSize,
                      color: AppLightUi.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v4,
                    Flexible(
                      child: AppText(
                        text: privilege['desc'] as String,
                        fontSize: 11,
                        color: AppLightUi.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 12),
          child: SemiBoldText(
            text: 'Choose Your Membership',
            fontSize: TextStyles.k18FontSize,
            color: AppLightUi.title,
          ),
        ),
        SizedBox(
          height: 150,
          child: Obx(() {
            if (controller.isLoading.value && controller.plans.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _goldDeep),
              );
            }

            if (controller.plans.isEmpty) {
              return _emptyPlansCard();
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.plans.length,
              separatorBuilder: (_, __) => Spacing.h10,
              itemBuilder: (context, index) {
                final plan = controller.plans[index];
                return Obx(() {
                  final isSelected =
                      controller.selectedPlan.value == plan['id'].toString();
                  return _planCard(plan, isSelected);
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _emptyPlansCard() {
    final message = controller.packageError.value.isEmpty
        ? 'No active SVIP packages are available.'
        : controller.packageError.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: AppLightUi.cardDecoration(radius: 16),
        child: Center(
          child: AppText(
            text: message,
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
            align: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan, bool isSelected) {
    final saving = (plan['saving'] as String? ?? '').trim();
    final badgeLabel = saving.toLowerCase() == 'active'
        ? 'Popular'
        : saving.isEmpty
        ? 'Standard'
        : saving;

    return GestureDetector(
      onTap: () => controller.selectPlan(plan['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 116,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _gold.withValues(alpha: 0.12)
              : AppLightUi.card,
          border: Border.all(
            color: isSelected ? _gold : AppLightUi.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppLightUi.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? _gold.withValues(alpha: 0.18)
                    : AppLightUi.cardSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan['name']?.toString().isNotEmpty == true
                    ? plan['name'].toString()
                    : badgeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? _goldDeep : AppLightUi.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Spacing.v10,
            SemiBoldText(
              text: plan['duration'] as String,
              fontSize: TextStyles.k14FontSize,
              color: AppLightUi.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v6,
            BoldText(
              text: '${plan['price']}',
              fontSize: TextStyles.k16FontSize,
              color: _goldDeep,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v2,
            const AppText(text: 'Coins', fontSize: 10, color: AppLightUi.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppLightUi.card,
        border: const Border(top: BorderSide(color: AppLightUi.border)),
        boxShadow: [
          BoxShadow(
            color: AppLightUi.title.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final isAlreadyActive = controller.isSvipActive.value;
          final isBusy = controller.isBuying.value;
          final canBuy = controller.plans.isNotEmpty && !isBusy;
          return appButton(
            onPressed: isAlreadyActive || !canBuy
                ? () {}
                : controller.subscribe,
            buttonText: isAlreadyActive
                ? 'Membership Active'
                : isBusy
                ? 'Opening SVIP...'
                : 'Open SVIP Now',
            isGradient: !isAlreadyActive,
            gradientColors: isAlreadyActive
                ? null
                : const [Color(0xFFFFD700), Color(0xFFFF8A48)],
            buttonColor: isAlreadyActive ? AppLightUi.cardSoft : null,
            textColor: isAlreadyActive ? AppLightUi.muted : AppLightUi.title,
            borderRadius: 24,
          );
        }),
      ),
    );
  }
}
