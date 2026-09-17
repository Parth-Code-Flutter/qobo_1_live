import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/network_svga_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/routes/app_pages.dart';

import '../controllers/backpack_controller.dart';

class BackpackView extends GetView<BackpackController> {
  const BackpackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: AppLightUi.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: AppLightUi.familyCtaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: kColorWhite,
                  size: 18,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SemiBoldText(
                      text: 'Active Customizations',
                      fontSize: TextStyles.k16FontSize,
                      color: AppLightUi.title,
                    ),
                    Spacing.v2,
                    const AppText(
                      text: 'What’s equipped on your profile right now',
                      fontSize: TextStyles.k10FontSize,
                      color: AppLightUi.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v16,
          // 2×2 grid so long names (e.g. “Royal Emerald”) aren’t clipped.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _equippedSlot(
                'Frame',
                controller.equippedFrame,
                displayNameObs: controller.equippedFrameName,
                accent: AppLightUi.gold,
              ),
              Spacing.h8,
              _equippedSlot(
                'Entrance',
                controller.equippedEffect,
                accent: AppLightUi.violet,
              ),
            ],
          ),
          Spacing.v8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _equippedSlot(
                'Chat Bubble',
                controller.equippedBubble,
                accent: AppLightUi.cyan,
              ),
              Spacing.h8,
              _equippedSlot(
                'Background',
                controller.equippedBackground,
                displayNameObs: controller.equippedBackgroundName,
                accent: AppLightUi.pink,
              ),
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
    Color accent = AppLightUi.violet,
  }) {
    return Expanded(
      child: Obx(() {
        final itemId = equippedObs.value;
        final isActive = itemId != null && itemId.trim().isNotEmpty;

        var displayName = displayNameObs?.value?.trim() ?? '';
        if (isActive) {
          if (displayName.isEmpty || displayName == 'None') {
            displayName = _friendlyEquippedName(itemId);
          }
        } else {
          displayName = 'None';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? accent.withValues(alpha: 0.08)
                : AppLightUi.cardSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? accent.withValues(alpha: 0.55)
                  : AppLightUi.border,
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                fontSize: 10,
                color: AppLightUi.subtitle,
              ),
              Spacing.v6,
              SemiBoldText(
                text: displayName,
                fontSize: TextStyles.k12FontSize,
                color: isActive ? accent : AppLightUi.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  String _friendlyEquippedName(String itemId) {
    final id = itemId.toLowerCase();
    if (id.contains('gold')) return 'Golden Crown';
    if (id.contains('neon')) return 'Neon Border';
    if (id.contains('vip')) return 'VVIP';
    if (id.contains('dragon')) return 'Dragon';
    if (id.contains('star')) return 'Star Shower';
    if (id.contains('ocean')) return 'Ocean';
    if (id.contains('love') || id.contains('rose')) return 'Love Heart';
    if (id.contains('royal')) return 'Royal Emerald';
    // Avoid showing raw UUIDs in the summary.
    if (_looksLikeUuid(itemId)) return 'Equipped';
    return itemId;
  }

  bool _looksLikeUuid(String value) {
    final v = value.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(v);
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.categories.map((cat) {
              final isSelected = controller.selectedCategory.value == cat['id'];
              final label = _shortCategoryLabel(cat['name']?.toString() ?? '');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.selectCategory(cat['id'] as int),
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: isSelected
                            ? AppLightUi.familyCtaGradient
                            : null,
                        color: isSelected ? null : AppLightUi.card,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppLightUi.borderStrong,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppLightUi.pink.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : AppLightUi.cardShadow,
                      ),
                      child: SemiBoldText(
                        text: label,
                        fontSize: TextStyles.k12FontSize,
                        color: isSelected ? kColorWhite : AppLightUi.subtitle,
                      ),
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

  String _shortCategoryLabel(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return 'Items';
    final lower = name.toLowerCase();
    if (lower.contains('entrance')) return 'Entrance';
    if (lower.contains('avatar') && lower.contains('frame')) return 'Frames';
    if (lower.contains('chat')) return 'Bubbles';
    if (lower.contains('background')) return 'Backgrounds';
    if (lower.contains('gift')) return 'Gifts';
    return name;
  }

  String _displayItemName(Map<String, dynamic> item) {
    final name = item['name']?.toString().trim() ?? '';
    final id = item['id']?.toString().trim() ?? '';
    if (name.isNotEmpty && !_looksLikeUuid(name)) return name;
    if (id.isNotEmpty && !_looksLikeUuid(id)) return id;
    final desc = item['description']?.toString().trim() ?? '';
    if (desc.isNotEmpty) {
      final first = desc.split('.').first.trim();
      if (first.isNotEmpty && first.length <= 28) return first;
    }
    return 'Gift';
  }

  String _displayItemDescription(Map<String, dynamic> item) {
    final desc = item['description']?.toString().trim() ?? '';
    if (desc.isNotEmpty && !_looksLikeUuid(desc)) return desc;
    final qty = item['quantity'];
    if (qty != null) return 'Qty $qty · Ready to send';
    return 'Owned item';
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
                  color: AppLightUi.title,
                ),
                Spacing.v8,
                const AppText(
                  text:
                      'You don\'t own any customizations in this category yet.',
                  color: AppLightUi.subtitle,
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

      if (categoryId == 5) {
        return _buildPurchasedBackgroundsGrid(items);
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
          if (categoryId == 5) {
            isEquipped = controller.equippedBackground.value == itemId;
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppLightUi.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isEquipped ? AppLightUi.gold : AppLightUi.border,
                width: isEquipped ? 1.6 : 1,
              ),
              boxShadow: AppLightUi.cardShadow,
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppLightUi.violet.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SemiBoldText(
                          text: 'x${item['quantity']}',
                          fontSize: 10,
                          color: AppLightUi.violet,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (isEquipped)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppLightUi.gold,
                        size: 18,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppLightUi.violet.withValues(alpha: 0.12),
                            AppLightUi.pink.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: AppLightUi.borderStrong,
                        ),
                      ),
                      child: SvgPicture.asset(
                        item['icon'] as String,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Spacing.v8,
                SemiBoldText(
                  text: _displayItemName(item),
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                  align: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: _displayItemDescription(item),
                  fontSize: 10,
                  color: AppLightUi.subtitle,
                  align: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v10,
                if (categoryId > 1)
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: appButton(
                      onPressed: () => controller.equipItem(categoryId, item),
                      buttonText: isEquipped ? 'Unequip' : 'Equip',
                      isGradient: !isEquipped,
                      buttonColor: isEquipped
                          ? AppLightUi.cardSoft
                          : null,
                      textColor: isEquipped ? AppLightUi.subtitle : kColorWhite,
                      borderRadius: 16,
                      textStyle: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k12FontSize,
                        colors: isEquipped ? AppLightUi.subtitle : kColorWhite,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: appButton(
                      onPressed: () {
                        Get.snackbar(
                          'Backpack',
                          'Gifts can be sent to streamers inside live rooms.',
                        );
                      },
                      buttonText: 'Send Gift',
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

  /// Profile backgrounds use a wider visual card so users can recognize the
  /// equipped profile skin before applying it.
  Widget _buildPurchasedBackgroundsGrid(
    List<Map<String, dynamic>> backgrounds,
  ) {
    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: controller.fetchBackpack,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: backgrounds.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final background = backgrounds[index];
          return _PurchasedBackgroundCard(
            background: background,
            onEquip: () => controller.equipItem(5, background),
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
    final isVip = frame['isVip'] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEquipped
              ? [const Color(0xFFFFF9E8), const Color(0xFFFFF1C1)]
              : [AppLightUi.card, AppLightUi.cardSoft],
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
                color: isVip
                    ? const Color(0xFFFFD700)
                    : isEquipped
                    ? Colors.green
                    : kColorPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                text: isVip
                    ? (isEquipped ? 'VIP ACTIVE' : 'VIP')
                    : isEquipped
                    ? 'ACTIVE'
                    : 'OWNED',
                fontSize: 9,
                color: isVip
                    ? kColorText
                    : isEquipped
                    ? kColorWhite
                    : kColorPrimary,
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
            color: AppLightUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v4,
          AppText(
            text: frame['description']?.toString() ?? 'Purchased frame',
            fontSize: 9,
            color: AppLightUi.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v10,
          SizedBox(
            width: double.infinity,
            height: 34,
            child: appButton(
              onPressed: isVip ? () {} : onEquip,
              buttonText: isVip
                  ? 'Auto VIP'
                  : isEquipped
                  ? 'Unequip'
                  : 'Equip Frame',
              buttonColor: isVip
                  ? const Color(0xFFFFF1C1)
                  : isEquipped
                  ? const Color(0xFFF1E6B8)
                  : kColorPrimary,
              textColor: isVip || isEquipped ? kColorText : kColorWhite,
              borderRadius: 17,
              textStyle: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: isVip || isEquipped ? kColorText : kColorWhite,
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
      loading: Center(
        child: SizedBox(
          width: size * 0.22,
          height: size * 0.22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: kColorPrimary.withValues(alpha: 0.85),
          ),
        ),
      ),
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
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: size * 0.22,
            height: size * 0.22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kColorPrimary.withValues(alpha: 0.85),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _PurchasedBackgroundCard extends StatelessWidget {
  const _PurchasedBackgroundCard({
    required this.background,
    required this.onEquip,
  });

  final Map<String, dynamic> background;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final isEquipped = background['isEquipped'] == true;
    final isExpired = background['isExpired'] == true;
    final imageUrl = background['imageUrl']?.toString().trim() ?? '';
    final previewImageUrl =
        background['previewImageUrl']?.toString().trim() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kColorWhite,
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
                color: isExpired
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : isEquipped
                    ? Colors.green
                    : kColorPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                text: isExpired
                    ? 'EXPIRED'
                    : isEquipped
                    ? 'ACTIVE'
                    : 'OWNED',
                fontSize: 9,
                color: isExpired
                    ? Colors.redAccent
                    : isEquipped
                    ? kColorWhite
                    : kColorPrimary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: imageUrl.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF8922C2), Color(0xFF151C68)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    ProfileBackgroundMedia(
                      url: imageUrl,
                      showLoadingIndicator: true,
                      previewImageUrl: previewImageUrl,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          kColorBlack.withValues(alpha: 0.04),
                          kColorBlack.withValues(alpha: 0.42),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: kColorAvatarFallbackBg,
                        child: SemiBoldText(
                          text: 'U',
                          fontSize: TextStyles.k16FontSize,
                          color: kColorWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SemiBoldText(
            text: background['name']?.toString() ?? 'Profile Background',
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v4,
          AppText(
            text: background['description']?.toString() ?? 'Purchased item',
            fontSize: 9,
            color: AppLightUi.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v10,
          SizedBox(
            width: double.infinity,
            height: 34,
            child: appButton(
              onPressed: isExpired ? () {} : onEquip,
              buttonText: isExpired
                  ? 'Expired'
                  : isEquipped
                  ? 'Unequip'
                  : 'Equip Background',
              buttonColor: isExpired
                  ? const Color(0xFFE8E8E8)
                  : isEquipped
                  ? const Color(0xFFF1E6B8)
                  : kColorPrimary,
              textColor: isExpired
                  ? kColorHint
                  : isEquipped
                  ? kColorText
                  : kColorWhite,
              borderRadius: 17,
              textStyle: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k12FontSize,
                colors: isExpired
                    ? kColorHint
                    : isEquipped
                    ? kColorText
                    : kColorWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
