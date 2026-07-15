import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/routes/app_pages.dart';

import '../controllers/backpack_controller.dart';

class BackpackView extends GetView<BackpackController> {
  const BackpackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAppBackground,
      appBar: const CommonAppBarWidget(
        title: 'My Backpack',
        useMaterialAppBar: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEquippedSummaryCard(),
          _buildTabs(),
          Expanded(child: _buildItemsGrid()),
        ],
      ),
    );
  }

  Widget _buildEquippedSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF761B65), Color(0xFF410D37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.style, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              SemiBoldText(
                text: 'Active Customizations',
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _equippedSlot(
                'Frame',
                controller.equippedFrame,
                displayNameObs: controller.equippedFrameName,
              ),
              _equippedSlot('Entrance', controller.equippedEffect),
              _equippedSlot('Chat Bubble', controller.equippedBubble),
            ],
          ),
        ],
      ),
    );
  }

  Widget _equippedSlot(
    String label,
    RxnString equippedObs, {
    RxnString? displayNameObs,
  }) {
    return Obx(() {
      final itemId = equippedObs.value;
      final isActive = itemId != null;

      // Extract simple display name
      String displayName = displayNameObs?.value ?? 'None';
      if (isActive) {
        if (displayName == 'None') {
          if (itemId.contains('gold')) displayName = 'Golden Crown';
          if (itemId.contains('neon')) displayName = 'Neon Border';
          if (itemId.contains('vip')) displayName = 'VVIP';
          if (itemId.contains('dragon')) displayName = 'Dragon';
          if (itemId.contains('star')) displayName = 'Star Shower';
          if (itemId.contains('ocean')) displayName = 'Ocean';
          if (itemId.contains('love')) displayName = 'Love Heart';
        }
      } else {
        displayName = 'None';
      }

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.amber : Colors.white24,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              AppText(
                text: label,
                fontSize: 10,
                color: kColorWhite.withValues(alpha: 0.7),
              ),
              Spacing.v6,
              SemiBoldText(
                text: displayName,
                fontSize: TextStyles.k12FontSize,
                color: isActive ? Colors.amber : kColorWhite,
                align: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kColorPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? kColorPrimary
                          : kColorHint.withValues(alpha: 0.3),
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
      final categoryId = controller.selectedCategory.value;
      final items = controller.mockItems[categoryId] ?? [];

      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kColorPrimary),
        );
      }

      if (items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: kColorHint.withValues(alpha: 0.4),
                ),
                Spacing.v16,
                const SemiBoldText(
                  text: 'No Items Found',
                  fontSize: TextStyles.k16FontSize,
                  color: kColorText,
                ),
                Spacing.v8,
                const AppText(
                  text:
                      'You don\'t own any customizations in this category yet.',
                  color: kColorHint,
                  align: TextAlign.center,
                ),
                Spacing.v20,
                SizedBox(
                  height: 40,
                  width: 160,
                  child: appButton(
                    onPressed: () {
                      Get.toNamed(Routes.MALL);
                    },
                    buttonText: 'Visit Mall',
                    buttonColor: kColorPrimary,
                    borderRadius: 20,
                    textStyle: TextStyles.kSemiBoldPoppins(
                      fontSize: TextStyles.k12FontSize,
                      colors: kColorWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (categoryId == 2) {
        return _buildPurchasedFramesGrid(items);
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final itemId = item['id'] as String;

          // Check if equipped
          bool isEquipped = false;
          if (categoryId == 2) {
            isEquipped = controller.equippedFrame.value == itemId;
          }
          if (categoryId == 3) {
            isEquipped = controller.equippedEffect.value == itemId;
          }
          if (categoryId == 4) {
            isEquipped = controller.equippedBubble.value == itemId;
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kColorWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEquipped ? Colors.amber : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kColorBlack.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (categoryId == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kColorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'x${item['quantity']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: kColorPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (isEquipped)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.amber,
                        size: 18,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kColorPrimary.withValues(alpha: 0.05),
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
                Spacing.v8,
                SemiBoldText(
                  text: item['name'] as String,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorText,
                  align: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: item['description'] ?? '',
                  fontSize: 9,
                  color: kColorHint,
                  align: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v10,
                if (categoryId > 1)
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: appButton(
                      onPressed: () => controller.equipItem(categoryId, item),
                      buttonText: isEquipped ? 'Unequip' : 'Equip',
                      buttonColor: isEquipped
                          ? const Color(0xFFF3F3F3)
                          : kColorPrimary,
                      textColor: isEquipped ? kColorTextGrey : kColorWhite,
                      borderRadius: 16,
                      textStyle: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: isEquipped ? kColorTextGrey : kColorWhite,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: appButton(
                      onPressed: () {
                        Get.snackbar(
                          'Backpack',
                          'Rose can be gifted to streamers inside live rooms.',
                        );
                      },
                      buttonText: 'Send Gift',
                      buttonColor: kColorPrimary.withValues(alpha: 0.1),
                      textColor: kColorPrimary,
                      borderRadius: 16,
                      textStyle: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: kColorPrimary,
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

  /// Modern purchased-frame collection backed by `/api/frame/my-backpack`.
  Widget _buildPurchasedFramesGrid(List<Map<String, dynamic>> frames) {
    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: controller.fetchBackpack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760
              ? 4
              : constraints.maxWidth >= 520
              ? 3
              : 2;
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: frames.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final frame = frames[index];
              return _PurchasedFrameCard(
                frame: frame,
                onEquip: () => controller.equipItem(2, frame),
              );
            },
          );
        },
      ),
    );
  }
}

class _PurchasedFrameCard extends StatelessWidget {
  const _PurchasedFrameCard({required this.frame, required this.onEquip});

  final Map<String, dynamic> frame;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final isEquipped = frame['isEquipped'] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEquipped
              ? [const Color(0xFFFFF9E8), const Color(0xFFFFF1C1)]
              : [kColorWhite, const Color(0xFFF9F2F8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEquipped
              ? Colors.amber
              : kColorPrimary.withValues(alpha: 0.10),
          width: isEquipped ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isEquipped ? Colors.amber : kColorPrimary).withValues(
              alpha: 0.12,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isEquipped
                    ? Colors.green
                    : kColorPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                text: isEquipped ? 'ACTIVE' : 'OWNED',
                fontSize: 9,
                color: isEquipped ? kColorWhite : kColorPrimary,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _BackpackFramePreview(frame: frame, size: 104),
            ),
          ),
          SemiBoldText(
            text: frame['name']?.toString() ?? 'Avatar Frame',
            fontSize: TextStyles.k14FontSize,
            color: kColorText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v4,
          AppText(
            text: frame['description']?.toString() ?? 'Purchased frame',
            fontSize: 9,
            color: kColorHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v10,
          SizedBox(
            width: double.infinity,
            height: 34,
            child: appButton(
              onPressed: onEquip,
              buttonText: isEquipped ? 'Unequip' : 'Equip Frame',
              buttonColor: isEquipped ? const Color(0xFFF1E6B8) : kColorPrimary,
              textColor: isEquipped ? kColorText : kColorWhite,
              borderRadius: 17,
              textStyle: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: isEquipped ? kColorText : kColorWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackpackFramePreview extends StatelessWidget {
  const _BackpackFramePreview({required this.frame, required this.size});

  final Map<String, dynamic> frame;
  final double size;

  @override
  Widget build(BuildContext context) {
    final svgaUrl = frame['svgaUrl']?.toString().trim() ?? '';
    final imageUrl = frame['imageUrl']?.toString().trim() ?? '';
    final source = svgaUrl.isNotEmpty ? svgaUrl : imageUrl;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: size * 0.27,
            backgroundColor: kColorAvatarFallbackBg,
            child: const SemiBoldText(
              text: 'U',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
          ),
          if (source.isNotEmpty)
            _BackpackFrameMedia(source: source, size: size)
          else
            Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Plays purchased network SVGA frames and supports legacy static frame media.
class _BackpackFrameMedia extends StatelessWidget {
  const _BackpackFrameMedia({required this.source, required this.size});

  final String source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _staticMedia();
    if (_isKnownStaticMedia()) return fallback;

    return NetworkSvgaWidget(
      url: source,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallback: fallback,
    );
  }

  bool _isKnownStaticMedia() {
    final path = Uri.tryParse(source)?.path.toLowerCase() ?? '';
    return path.endsWith('.svg') ||
        path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  Widget _staticMedia() {
    final path = Uri.tryParse(source)?.path.toLowerCase() ?? '';
    if (path.endsWith('.svg')) {
      return SvgPicture.network(
        source,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Image.network(
      source,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
