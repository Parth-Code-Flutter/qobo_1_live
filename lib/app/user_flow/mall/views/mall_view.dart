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
      backgroundColor: kColorAppBackground,
      appBar: const CommonAppBarWidget(
        title: 'Virtual Mall',
        useMaterialAppBar: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBalance(),
          _buildPreviewSection(),
          _buildTabs(),
          Expanded(child: _buildStoreGrid()),
        ],
      ),
    );
  }

  Widget _buildHeaderBalance() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: kColorWhite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
              Spacing.h8,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Your Balance',
                    fontSize: 10,
                    color: kColorHint,
                  ),
                  Obx(() => SemiBoldText(
                        text: '${controller.coinsBalance.value} Coins',
                        fontSize: TextStyles.k16FontSize,
                        color: kColorText,
                      )),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 32,
            width: 90,
            child: appButton(
              onPressed: () {
                Get.snackbar('Recharge', 'Redirecting to coin recharge packages...');
              },
              buttonText: 'Recharge',
              buttonColor: const Color(0xFFFF8A48),
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
  }

  Widget _buildPreviewSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1141), Color(0xFF1E0B2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF672C5C), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background grid decor
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),
          
          Obx(() {
            final item = controller.selectedPreviewItem.value;
            if (item == null) {
              return const Center(
                child: AppText(
                  text: 'Select an item below to preview',
                  color: kColorWhite,
                ),
              );
            }

            final tabId = controller.selectedTab.value;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: _buildItemPreview(tabId, item),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SemiBoldText(
                        text: 'Preview: ${item['name']}',
                        fontSize: TextStyles.k12FontSize,
                        color: Colors.amber,
                      ),
                      Spacing.v2,
                      AppText(
                        text: item['description'] ?? '',
                        fontSize: 10,
                        color: kColorWhite.withOpacity(0.8),
                        align: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemPreview(int tabId, Map<String, dynamic> item) {
    if (tabId == 1) {
      // Avatar Frames Preview
      Color frameColor = Colors.amber;
      if (item['id'] == 'frame_neon') {
        frameColor = const Color(0xFFFF5EA7);
      } else if (item['id'] == 'frame_vip') {
        frameColor = const Color(0xFF8F55FF);
      }
      
      return Stack(
        alignment: Alignment.center,
        children: [
          // User Avatar fallback
          const CircleAvatar(
            radius: 40,
            backgroundColor: kColorAvatarFallbackBg,
            child: Text('User', style: TextStyle(color: kColorWhite, fontWeight: FontWeight.bold)),
          ),
          // Interactive Border Frame
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: frameColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: frameColor.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Small badge
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: frameColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: kColorWhite, size: 10),
            ),
          ),
        ],
      );
    } else if (tabId == 2) {
      // Entrance Effects Preview
      final isDragon = item['id'] == 'effect_dragon';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDragon ? const Color(0xFFFF8A48).withOpacity(0.2) : const Color(0xFF2FA9FF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDragon ? const Color(0xFFFF8A48) : const Color(0xFF2FA9FF),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDragon ? Icons.local_fire_department : Icons.stars,
              color: isDragon ? const Color(0xFFFF8A48) : const Color(0xFF2FA9FF),
            ),
            Spacing.h8,
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldText(
                  text: 'SuperStar John Doe',
                  fontSize: 12,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Entered the room with a burst of glory!',
                  fontSize: 10,
                  color: kColorWhite,
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Chat Bubbles Preview
      final isOcean = item['id'] == 'bubble_ocean';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOcean ? const Color(0xFF4DD5FF).withOpacity(0.2) : const Color(0xFFFF5EA7).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOcean ? const Color(0xFF4DD5FF) : const Color(0xFFFF5EA7),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: isOcean ? const Color(0xFF4DD5FF) : const Color(0xFFFF5EA7),
                  child: const Text('J', style: TextStyle(fontSize: 6, color: kColorWhite)),
                ),
                Spacing.h6,
                const SemiBoldText(
                  text: 'John Doe',
                  fontSize: 10,
                  color: Colors.amber,
                ),
              ],
            ),
            Spacing.v4,
            const AppText(
              text: 'This is a premium chat bubble message preview!',
              fontSize: 11,
              color: kColorWhite,
            ),
          ],
        ),
      );
    }
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
      final activePreview = controller.selectedPreviewItem.value;
      
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
          childAspectRatio: 0.76,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = activePreview != null && activePreview['id'] == item['id'];
          
          return GestureDetector(
            onTap: () => controller.selectedPreviewItem.value = item,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? kColorPrimary : Colors.transparent,
                  width: 1.5,
                ),
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kColorPrimary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          item['icon'] as String,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Spacing.v10,
                  SemiBoldText(
                    text: item['name'] as String,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorText,
                    align: TextAlign.center,
                  ),
                  Spacing.v2,
                  AppText(
                    text: 'Validity: ${item['duration']}',
                    fontSize: 10,
                    color: kColorHint,
                  ),
                  Spacing.v10,
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: appButton(
                      onPressed: () => controller.buyItem(item),
                      buttonText: '${item['price']} Coins',
                      buttonColor: isSelected ? kColorPrimary : const Color(0xFFF0E5EE),
                      textColor: isSelected ? kColorWhite : kColorPrimary,
                      borderRadius: 18,
                      textStyle: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: isSelected ? kColorWhite : kColorPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// Background Grid Painter for Preview Panel
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
