import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/point_center_controller.dart';

class PointCenterView extends GetView<PointCenterController> {
  const PointCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(kImgBG),
          fit: BoxFit.cover,
        ),
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const CommonAppBarWidget(
            title: 'Point Center',
            useMaterialAppBar: true,
            backgroundColor: Colors.transparent,
            titleColor: kColorWhite,
            bottom: TabBar(
              tabs: [
                Tab(text: 'Daily Tasks'),
                Tab(text: 'Point Store'),
              ],
              labelColor: kColorWhite,
              unselectedLabelColor: Colors.white60,
              indicatorColor: kColorPrimary,
              indicatorWeight: 3,
            ),
          ),
          body: Column(
            children: [
              Spacing.v16,
              _buildPointsCard(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTasksTab(),
                    _buildStoreTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65C00), Color(0xFFF9D423)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: 'Available Points',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite.withOpacity(0.8),
                ),
                Spacing.v6,
                Obx(() => BoldText(
                      text: '${controller.pointsBalance.value}',
                      fontSize: 32,
                      color: kColorWhite,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kColorWhite.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: kColorWhite,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return Obx(() {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.tasks.length,
        separatorBuilder: (_, __) => Spacing.v12,
        itemBuilder: (context, index) {
          final task = controller.tasks[index];
          final bool isCompleted = task['isCompleted'] ?? false;
          final bool isClaimed = task['isClaimed'] ?? false;

          return Container(
            padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: task['title'],
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v6,
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.orange, size: 14),
                          Spacing.h4,
                          AppText(
                            text: '+${task['reward']} Points',
                            fontSize: TextStyles.k12FontSize,
                            color: Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Spacing.h12,
                SizedBox(
                  height: 32,
                  width: 80,
                  child: appButton(
                    onPressed: isCompleted && !isClaimed ? () => controller.claimPoints(index) : (){},
                    buttonText: isClaimed
                        ? 'Claimed'
                        : isCompleted
                            ? 'Claim'
                            : 'Go',
                    buttonColor: isClaimed
                        ? Colors.white12
                        : isCompleted
                            ? kColorPrimary
                            : Colors.transparent,
                    buttonBorderColor: !isCompleted ? kColorPrimary : Colors.transparent,
                    textColor: isClaimed
                        ? Colors.white38
                        : isCompleted
                            ? kColorWhite
                            : kColorPrimary,
                    borderRadius: 16,
                    textStyle: TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k12FontSize,
                      colors: isClaimed
                          ? Colors.white38
                          : isCompleted
                              ? kColorWhite
                              : kColorPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildStoreTab() {
    return Obx(() {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.storeItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = controller.storeItems[index];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kColorWhite.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kColorWhite.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SvgPicture.asset(
                      item['icon'],
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => const Icon(
                        Icons.card_giftcard_rounded,
                        color: kColorWhite,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Spacing.v12,
                SemiBoldText(
                  text: item['name'],
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  align: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: item['duration'],
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withOpacity(0.5),
                ),
                Spacing.v12,
                SizedBox(
                  height: 32,
                  child: appButton(
                    onPressed: () => controller.redeemItem(item),
                    buttonText: '${item['cost']} Pts',
                    buttonColor: kColorPrimary,
                    borderRadius: 16,
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
    });
  }
}
