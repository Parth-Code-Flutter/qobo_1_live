import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/visitors_controller.dart';

class VisitorsView extends GetView<VisitorsController> {
  const VisitorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(kImgBG),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CommonAppBarWidget(
          title: 'Profile Visitors',
          useMaterialAppBar: true,
          backgroundColor: Colors.transparent,
          titleColor: kColorWhite,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
              ),
            );
          }

          if (controller.visitors.isEmpty) {
            return _buildEmptyState();
          }

          return _buildVisitorsList();
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kColorWhite.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility_off_rounded,
              color: kColorWhite,
              size: 64,
            ),
          ),
          Spacing.v24,
          const SemiBoldText(
            text: 'No Visitors Yet',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          AppText(
            text: 'Share your profile to attract more fans!',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withOpacity(0.6),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: controller.visitors.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final visitor = controller.visitors[index];
        final bool isFollowing = visitor['isFollowing'] ?? false;
        final String vipBadge = visitor['vip'] ?? '';
        final int level = visitor['level'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kColorWhite.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kColorWhite.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getVipColor(vipBadge).withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    visitor['avatar'] ?? kImgTemp2,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: kColorAvatarFallbackBg,
                      child: Icon(Icons.person, color: kColorWhite),
                    ),
                  ),
                ),
              ),
              Spacing.h12,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: SemiBoldText(
                            text: visitor['name'] ?? 'Unknown User',
                            fontSize: TextStyles.k16FontSize,
                            color: kColorWhite,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vipBadge.isNotEmpty) ...[
                          Spacing.h6,
                          _buildVipBadge(vipBadge),
                        ],
                      ],
                    ),
                    Spacing.v6,
                    Row(
                      children: [
                        // Level Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8F55FF), Color(0xFF6C5CFF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AppText(
                            text: 'Lv.$level',
                            fontSize: 10,
                            color: kColorWhite,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Spacing.h8,
                        // Time
                        AppText(
                          text: visitor['time'] ?? 'Just now',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Follow Button
              SizedBox(
                height: 32,
                width: 90,
                child: appButton(
                  onPressed: () => controller.toggleFollow(index),
                  buttonText: isFollowing ? 'Message' : 'Follow',
                  buttonColor: isFollowing ? Colors.transparent : kColorPrimary,
                  buttonBorderColor: isFollowing ? kColorPrimary : Colors.transparent,
                  borderRadius: 16,
                  buttonWidth: 90,
                  textStyle: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVipBadge(String vip) {
    final color = _getVipColor(vip);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: AppText(
        text: vip,
        fontSize: 9,
        color: color,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Color _getVipColor(String vip) {
    switch (vip) {
      case 'SVIP':
        return const Color(0xFFFFD700); // Gold
      case 'VIP':
        return const Color(0xFFC0C0C0); // Silver
      default:
        return Colors.transparent;
    }
  }
}
