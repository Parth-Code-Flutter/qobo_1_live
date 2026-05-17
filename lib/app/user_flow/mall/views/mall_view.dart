import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/mall_controller.dart';

class MallView extends GetView<MallController> {
  const MallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Mall',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildStoreGrid()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: kColorWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.tabs.map((tab) {
              final isSelected = controller.selectedTab.value == tab['id'];
              return GestureDetector(
                onTap: () => controller.selectTab(tab['id'] as int),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? kColorPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? kColorPrimary : kColorHint.withOpacity(0.3),
                    ),
                  ),
                  child: AppText(
                    text: tab['name'] as String,
                    fontSize: TextStyles.k14FontSize,
                    color: isSelected ? kColorWhite : kColorHint,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildStoreGrid() {
    return Obx(() {
      final items = controller.storeItems[controller.selectedTab.value] ?? [];
      
      if (items.isEmpty) {
        return Center(
          child: AppText(
            text: 'No items available',
            color: kColorHint,
            fontSize: TextStyles.k14FontSize,
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kColorWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kColorBlack.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SvgPicture.asset(
                      item['icon'] as String,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Spacing.v12,
                SemiBoldText(
                  text: item['name'] as String,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorText,
                  align: TextAlign.center,
                ),
                Spacing.v4,
                AppText(
                  text: item['duration'] as String,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
                Spacing.v12,
                SizedBox(
                  height: 36,
                  child: appButton(
                    onPressed: () => controller.buyItem(item),
                    buttonText: '${item['price']} Coins',
                    buttonColor: kColorPrimary,
                    borderRadius: 18,
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
