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
                  Obx(
                    () => SemiBoldText(
                      text: '${controller.coinsBalance.value} Coins',
                      fontSize: TextStyles.k16FontSize,
                      color: kColorText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 32,
            width: 90,
            child: appButton(
              onPressed: () {
                Get.snackbar(
                  'Recharge',
                  'Redirecting to coin recharge packages...',
                );
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
            color: kColorBlack.withValues(alpha: 0.15),
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
              child: CustomPaint(painter: _GridPainter()),
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
                Expanded(child: Center(child: _buildItemPreview(tabId, item))),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                        color: kColorWhite.withValues(alpha: 0.8),
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
      final frameSource =
          item['svgaUrl']?.toString() ?? item['imageUrl']?.toString();
      return Stack(
        alignment: Alignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: kColorAvatarFallbackBg,
            child: Text(
              'User',
              style: TextStyle(color: kColorWhite, fontWeight: FontWeight.bold),
            ),
          ),
          if (frameSource != null && frameSource.isNotEmpty)
            _FrameMedia(source: frameSource, size: 124)
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          if (item['isEquipped'] == true)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: kColorWhite, size: 12),
              ),
            ),
        ],
      );
    } else if (tabId == 4) {
      final imageUrl = item['imageUrl']?.toString() ?? '';
      return Container(
        width: 150,
        height: 106,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.55)),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: imageUrl.isEmpty
              ? const LinearGradient(
                  colors: [Color(0xFF8922C2), Color(0xFF151C68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                kColorBlack.withValues(alpha: 0.1),
                kColorBlack.withValues(alpha: 0.42),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: CircleAvatar(
              radius: 26,
              backgroundColor: kColorAvatarFallbackBg,
              child: Text(
                'U',
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (tabId == 2) {
      // Entrance Effects Preview
      final isDragon = item['id'] == 'effect_dragon';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDragon
              ? const Color(0xFFFF8A48).withValues(alpha: 0.2)
              : const Color(0xFF2FA9FF).withValues(alpha: 0.2),
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
              color: isDragon
                  ? const Color(0xFFFF8A48)
                  : const Color(0xFF2FA9FF),
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
          color: isOcean
              ? const Color(0xFF4DD5FF).withValues(alpha: 0.2)
              : const Color(0xFFFF5EA7).withValues(alpha: 0.2),
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
                  backgroundColor: isOcean
                      ? const Color(0xFF4DD5FF)
                      : const Color(0xFFFF5EA7),
                  child: const Text(
                    'J',
                    style: TextStyle(fontSize: 6, color: kColorWhite),
                  ),
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
      final isFrameTab = controller.selectedTab.value == 1;
      final isBackgroundTab = controller.selectedTab.value == 4;

      if (controller.isLoading.value && (isFrameTab || isBackgroundTab)) {
        return const Center(child: CircularProgressIndicator());
      }

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
          final isSelected =
              activePreview != null && activePreview['id'] == item['id'];
          final isOwned = item['isOwned'] == true;
          final isEquipped = item['isEquipped'] == true;
          final isExpired = item['isExpired'] == true;
          final isPlaceholder = item['isPlaceholder'] == true;
          final usesBackpackFlow = isFrameTab || isBackgroundTab;
          final buttonText = isPlaceholder
              ? 'Unavailable'
              : usesBackpackFlow
              ? isExpired
                    ? '${item['price']} Coins'
                    : isOwned
                    ? 'Open Backpack'
                    : '${item['price']} Coins'
              : '${item['price']} Coins';

          return GestureDetector(
            onTap: isPlaceholder
                ? null
                : () => controller.selectedPreviewItem.value = item,
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
                    color: kColorBlack.withValues(alpha: 0.04),
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
                      child: _StoreItemVisual(
                        item: item,
                        isFrame: isFrameTab,
                        isBackground: isBackgroundTab,
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
                  if (usesBackpackFlow) ...[
                    Spacing.v2,
                    AppText(
                      text: item['category']?.toString() ?? 'Premium',
                      fontSize: 10,
                      color: isEquipped
                          ? Colors.green
                          : isExpired
                          ? const Color(0xFFE57373)
                          : kColorHint,
                    ),
                  ],
                  Spacing.v2,
                  AppText(
                    text: 'Validity: ${item['duration']}',
                    fontSize: 10,
                    color: isExpired ? const Color(0xFFE57373) : kColorHint,
                  ),
                  Spacing.v10,
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: appButton(
                      onPressed: isPlaceholder
                          ? () {}
                          : () => controller.buyItem(item),
                      buttonText: buttonText,
                      buttonColor: isEquipped
                          ? Colors.green
                          : isSelected
                          ? kColorPrimary
                          : const Color(0xFFF0E5EE),
                      textColor: isEquipped || isSelected
                          ? kColorWhite
                          : kColorPrimary,
                      borderRadius: 18,
                      textStyle: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: isEquipped || isSelected
                            ? kColorWhite
                            : kColorPrimary,
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

class _StoreItemVisual extends StatelessWidget {
  const _StoreItemVisual({
    required this.item,
    required this.isFrame,
    required this.isBackground,
  });

  final Map<String, dynamic> item;
  final bool isFrame;
  final bool isBackground;

  @override
  Widget build(BuildContext context) {
    final frameSource =
        item['svgaUrl']?.toString() ?? item['imageUrl']?.toString();
    if (isFrame && frameSource != null && frameSource.isNotEmpty) {
      return SizedBox(
        width: 86,
        height: 86,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const CircleAvatar(
              radius: 29,
              backgroundColor: kColorAvatarFallbackBg,
              child: Text(
                'U',
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _FrameMedia(source: frameSource, size: 86),
            if (item['isOwned'] == true)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: item['isEquipped'] == true
                        ? Colors.green
                        : kColorPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: kColorWhite, width: 1.5),
                  ),
                  child: Icon(
                    item['isEquipped'] == true
                        ? Icons.check
                        : Icons.shopping_bag,
                    size: 12,
                    color: kColorWhite,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final backgroundUrl = item['imageUrl']?.toString() ?? '';
    if (isBackground && backgroundUrl.isNotEmpty) {
      return Container(
        width: 96,
        height: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(backgroundUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: item['isEquipped'] == true ? Colors.green : kColorWhite,
            width: item['isEquipped'] == true ? 2 : 1,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                kColorBlack.withValues(alpha: 0.02),
                kColorBlack.withValues(alpha: 0.42),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: kColorAvatarFallbackBg,
              child: Text(
                'U',
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
    );
  }
}

/// Displays frame-shop media, including API-hosted SVGA animations.
///
/// Explicit static image extensions bypass SVGA parsing. Extensionless and
/// `.svga` URLs use the reusable network player, then fall back to image/SVG.
class _FrameMedia extends StatelessWidget {
  const _FrameMedia({required this.source, required this.size});

  final String source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final staticFallback = _staticMedia();
    if (_isKnownStaticMedia(source)) return staticFallback;

    return NetworkSvgaWidget(
      url: source,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallback: staticFallback,
    );
  }

  bool _isKnownStaticMedia(String value) {
    final path = Uri.tryParse(value.trim())?.path.toLowerCase() ?? '';
    return path.endsWith('.svg') ||
        path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  Widget _staticMedia() {
    final path = Uri.tryParse(source.trim())?.path.toLowerCase() ?? '';
    if (path.endsWith('.svg')) {
      return SvgPicture.network(
        source,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _loading(),
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

  Widget _loading() {
    return SizedBox(
      width: size,
      height: size,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        ),
      ),
    );
  }
}

// Background Grid Painter for Preview Panel
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
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
