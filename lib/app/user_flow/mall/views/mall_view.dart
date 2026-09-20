import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/mall_controller.dart';

class MallView extends GetView<MallController> {
  const MallView({super.key});

  static const _equipped = Color(0xFF1B8A5A);
  static const _expired = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Virtual Mall',
        subtitle: 'Frames, effects & premium looks',
        trailingIcon: Icons.storefront_rounded,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _balanceBar(),
          _previewSection(),
          _tabs(),
          Expanded(child: _storeGrid()),
        ],
      ),
    );
  }

  Widget _balanceBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: AppLightUi.cardDecoration(radius: 18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: AppLightUi.iconTileDecoration(AppLightUi.gold),
              child: const Center(
                child: AppCoinIcon(size: 24, color: AppLightUi.gold),
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Your Balance',
                    fontSize: TextStyles.k10FontSize,
                    color: AppLightUi.subtitle,
                  ),
                  Obx(
                    () => SemiBoldText(
                      text: '${controller.coinsBalance.value} Coins',
                      fontSize: TextStyles.k16FontSize,
                      color: AppLightUi.title,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Get.snackbar(
                    'Recharge',
                    'Redirecting to coin recharge packages...',
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppLightUi.familyCtaGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppLightUi.pink.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SemiBoldText(
                      text: 'Recharge',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8FC),
              Color(0xFFF5ECFF),
              Color(0xFFFFE8F4),
            ],
          ),
          border: Border.all(
            color: AppLightUi.pinkSoft.withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: AppLightUi.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -18,
              child: _glowOrb(AppLightUi.pink, 110),
            ),
            Positioned(
              bottom: -36,
              left: -22,
              child: _glowOrb(AppLightUi.violet, 120),
            ),
            Obx(() {
              final item = controller.selectedPreviewItem.value;
              if (item == null) {
                return const Center(
                  child: AppText(
                    text: 'Select an item below to preview',
                    color: AppLightUi.subtitle,
                  ),
                );
              }

              final tabId = controller.selectedTab.value;

              return Column(
                children: [
                  Expanded(
                    child: Center(child: _buildItemPreview(tabId, item)),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: BoxDecoration(
                      color: AppLightUi.card.withValues(alpha: 0.88),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      border: const Border(
                        top: BorderSide(color: AppLightUi.border),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SemiBoldText(
                          text: 'Preview: ${item['name']}',
                          fontSize: TextStyles.k12FontSize,
                          color: AppLightUi.title,
                          align: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacing.v2,
                        AppText(
                          text: item['description'] ?? '',
                          fontSize: TextStyles.k10FontSize,
                          color: AppLightUi.body,
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
      ),
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
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
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppLightUi.glossRingGradient,
              boxShadow: [
                BoxShadow(
                  color: AppLightUi.pink.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: const CircleAvatar(
              backgroundColor: kColorAvatarFallbackBg,
              child: Text(
                'User',
                style: TextStyle(
                  color: kColorWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
                border: Border.all(color: AppLightUi.gold, width: 3),
              ),
            ),
          if (item['isEquipped'] == true)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _equipped,
                  shape: BoxShape.circle,
                  border: Border.all(color: kColorWhite, width: 1.5),
                ),
                child: const Icon(Icons.check, color: kColorWhite, size: 12),
              ),
            ),
        ],
      );
    }

    if (tabId == 4) {
      final imageUrl = item['imageUrl']?.toString() ?? '';
      return Container(
        width: 150,
        height: 106,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppLightUi.borderStrong),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: imageUrl.isEmpty
              ? const LinearGradient(
                  colors: [Color(0xFFB14DFF), Color(0xFFFF5C9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: AppLightUi.cardShadow,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                kColorBlack.withValues(alpha: 0.05),
                kColorBlack.withValues(alpha: 0.35),
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
    }

    if (tabId == 2) {
      final isDragon = item['id'] == 'effect_dragon';
      final accent = isDragon ? const Color(0xFFE85D04) : AppLightUi.cyan;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDragon ? Icons.local_fire_department : Icons.stars,
              color: accent,
            ),
            Spacing.h8,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'SuperStar John Doe',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.title,
                ),
                AppText(
                  text: 'Entered the room with a burst of glory!',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.body,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Chat Bubbles Preview
    final isOcean = item['id'] == 'bubble_ocean';
    final accent = isOcean ? const Color(0xFF0EA5C6) : AppLightUi.pink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
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
                backgroundColor: accent,
                child: const Text(
                  'J',
                  style: TextStyle(fontSize: 6, color: kColorWhite),
                ),
              ),
              Spacing.h6,
              SemiBoldText(
                text: 'John Doe',
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.title,
              ),
            ],
          ),
          Spacing.v4,
          AppText(
            text: 'This is a premium chat bubble message preview!',
            fontSize: TextStyles.k10FontSize,
            color: AppLightUi.body,
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.tabs.map((tab) {
              final isSelected = controller.selectedTab.value == tab['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => controller.selectTab(tab['id'] as int),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppLightUi.familyCtaGradient : null,
                      color: isSelected ? null : AppLightUi.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppLightUi.borderStrong,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppLightUi.pink.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: AppText(
                      text: tab['name'] as String,
                      fontSize: TextStyles.k12FontSize,
                      color: isSelected ? kColorWhite : AppLightUi.body,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _storeGrid() {
    return Obx(() {
      final items = controller.storeItems[controller.selectedTab.value] ?? [];
      final activePreview = controller.selectedPreviewItem.value;
      final isFrameTab = controller.selectedTab.value == 1;
      final isBackgroundTab = controller.selectedTab.value == 4;

      if (controller.isLoading.value && (isFrameTab || isBackgroundTab)) {
        return const Center(
          child: CircularProgressIndicator(color: AppLightUi.pink),
        );
      }

      if (items.isEmpty) {
        return const Center(
          child: AppText(
            text: 'No items available',
            color: AppLightUi.subtitle,
            fontSize: TextStyles.k14FontSize,
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
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

          final categoryLabel = item['category']?.toString() ?? 'Premium';
          final categoryColor = isEquipped
              ? _equipped
              : isExpired
              ? _expired
              : AppLightUi.violet;

          return GestureDetector(
            onTap: isPlaceholder
                ? null
                : () => controller.selectedPreviewItem.value = item,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: AppLightUi.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppLightUi.pink
                      : AppLightUi.border,
                  width: isSelected ? 1.8 : 1.1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppLightUi.pink.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : AppLightUi.cardShadow,
              ),
              child: Column(
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
                  Spacing.v8,
                  SemiBoldText(
                    text: item['name'] as String,
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.title,
                    align: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (usesBackpackFlow) ...[
                    Spacing.v6,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: AppText(
                        text: categoryLabel,
                        fontSize: TextStyles.k10FontSize,
                        color: categoryColor,
                      ),
                    ),
                  ],
                  Spacing.v4,
                  AppText(
                    text: 'Validity: ${item['duration']}',
                    fontSize: TextStyles.k10FontSize,
                    color: isExpired ? _expired : AppLightUi.subtitle,
                  ),
                  Spacing.v8,
                  SizedBox(
                    height: 36,
                    width: double.infinity,
                    child: _actionButton(
                      label: buttonText,
                      enabled: !isPlaceholder,
                      emphasis: isEquipped || isSelected || !isOwned,
                      isEquipped: isEquipped,
                      onTap: isPlaceholder
                          ? null
                          : () => controller.buyItem(item),
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

  Widget _actionButton({
    required String label,
    required bool enabled,
    required bool emphasis,
    required bool isEquipped,
    VoidCallback? onTap,
  }) {
    final useGradient = enabled && (isEquipped || emphasis);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: useGradient && !isEquipped
                ? AppLightUi.familyCtaGradient
                : null,
            color: isEquipped
                ? _equipped
                : useGradient
                ? null
                : const Color(0xFFF3E8F4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: (isEquipped || useGradient)
                  ? kColorWhite
                  : AppLightUi.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
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

  static const _equipped = Color(0xFF1B8A5A);

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
                        ? _equipped
                        : AppLightUi.pink,
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
            color: item['isEquipped'] == true
                ? _equipped
                : AppLightUi.borderStrong,
            width: item['isEquipped'] == true ? 2 : 1.2,
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
      decoration: AppLightUi.iconTileDecoration(AppLightUi.violet, radius: 40),
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
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            color: AppLightUi.pink,
          ),
        ),
      ),
    );
  }
}
