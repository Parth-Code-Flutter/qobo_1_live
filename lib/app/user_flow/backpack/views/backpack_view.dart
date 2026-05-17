import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/backpack_controller.dart';

class BackpackView extends GetView<BackpackController> {
  const BackpackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Backpack',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildItemsGrid()),
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
            children: controller.categories.map((cat) {
              final isSelected = controller.selectedCategory.value == cat['id'];
              return GestureDetector(
                onTap: () => controller.selectCategory(cat['id'] as int),
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
                    text: cat['name'] as String,
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

  Widget _buildItemsGrid() {
    return Obx(() {
      final items = controller.mockItems[controller.selectedCategory.value] ?? [];
      
      if (items.isEmpty) {
        return Center(
          child: AppText(
            text: 'Empty category',
            color: kColorHint,
            fontSize: TextStyles.k14FontSize,
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            decoration: BoxDecoration(
              color: kColorWhite,
              borderRadius: BorderRadius.circular(12),
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
                SvgPicture.asset(
                  item['icon'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                Spacing.v12,
                SemiBoldText(
                  text: item['name'] as String,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorText,
                  align: TextAlign.center,
                ),
                Spacing.v4,
                AppText(
                  text: 'x${item['quantity']}',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
