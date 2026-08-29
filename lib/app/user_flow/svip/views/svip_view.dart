import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/svip_controller.dart';

class SvipView extends GetView<SvipController> {
  const SvipView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAppBackground,
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
          colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F), Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Glimmering Star
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFFFFD700),
              size: 56,
            ),
          ),
          Spacing.v12,
          const BoldText(
            text: 'SUPREME VIP',
            fontSize: TextStyles.k22FontSize,
            color: Color(0xFFFFD700),
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
                  ? const Color(0xFFFFD700)
                  : kColorWhite.withValues(alpha: 0.8),
              align: TextAlign.center,
              style: controller.isSvipActive.value
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      fontSize: TextStyles.k14FontSize,
                    )
                  : null,
            ),
          ),
          Spacing.v16,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppCoinIcon(size: 18, color: Colors.amber),
                Spacing.h6,
                Obx(
                  () => AppText(
                    text: 'Balance: ${controller.coinsBalance.value} Coins',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
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
              color: kColorText,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.privileges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              // Tall enough for a two-line title + two-line description.
              childAspectRatio: 0.98,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final privilege = controller.privileges[index];
              final Color color = privilege['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kColorBlack.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
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
                      color: kColorText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v4,
                    Flexible(
                      child: AppText(
                        text: privilege['desc'] as String,
                        fontSize: 11,
                        color: kColorHint,
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
            color: kColorText,
          ),
        ),
        // Plans come from the API and can be many — scroll horizontally
        // instead of squeezing them all into one row.
        SizedBox(
          height: 150,
          child: Obx(() {
            if (controller.isLoading.value && controller.plans.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
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
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: AppText(
            text: message,
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
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
              ? const Color(0xFFFFD700).withValues(alpha: 0.08)
              : kColorWhite,
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kColorBlack.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                    : const Color(0xFFF3F3F3),
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
                  color: isSelected ? const Color(0xFFD4AF37) : kColorHint,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Spacing.v10,
            SemiBoldText(
              text: plan['duration'] as String,
              fontSize: TextStyles.k14FontSize,
              color: kColorText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v6,
            BoldText(
              text: '${plan['price']}',
              fontSize: TextStyles.k16FontSize,
              color: const Color(0xFFD4AF37),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Spacing.v2,
            const AppText(text: 'Coins', fontSize: 10, color: kColorHint),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.04),
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
            buttonColor: isAlreadyActive
                ? const Color(0xFFF3F3F3)
                : const Color(0xFF1E1E1E),
            textColor: isAlreadyActive ? kColorHint : const Color(0xFFFFD700),
            borderRadius: 24,
          );
        }),
      ),
    );
  }
}
