import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// One action in [CommonAppDialog].
///
/// By default the dialog pops first, then [onPressed] runs.
/// Set [result] to pop with a typed value (e.g. `true` / `false`).
class CommonAppDialogAction {
  const CommonAppDialogAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.result,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  /// Optional value returned from [CommonAppDialog.show] / [showGet].
  final Object? result;
}

/// Premium glass confirm / info dialog — shared app-wide shell.
///
/// Matches coin-seller / dating-app polish: dark gradient, glow icon,
/// equal-height CTAs (no plain Material [AlertDialog]).
class CommonAppDialog extends StatelessWidget {
  const CommonAppDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconAccent = AdminAgencyUi.violet,
    this.content,
    required this.actions,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Color iconAccent;

  /// Optional custom body (forms, lists). Shown under [message].
  final Widget? content;
  final List<CommonAppDialogAction> actions;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    IconData? icon,
    Color iconAccent = AdminAgencyUi.violet,
    Widget? content,
    required List<CommonAppDialogAction> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => CommonAppDialog(
        title: title,
        message: message,
        icon: icon,
        iconAccent: iconAccent,
        content: content,
        actions: actions,
      ),
    );
  }

  /// Same shell via GetX (no [BuildContext] required).
  static Future<T?> showGet<T>({
    required String title,
    String? message,
    IconData? icon,
    Color iconAccent = AdminAgencyUi.violet,
    Widget? content,
    required List<CommonAppDialogAction> actions,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      CommonAppDialog(
        title: title,
        message: message,
        icon: icon,
        iconAccent: iconAccent,
        content: content,
        actions: actions,
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    );
  }

  /// Gift combo quantity: returns `1`, `3`, `5`, or `10`. Null if dismissed.
  static Future<int?> giftCombo({
    required String giftName,
    String? giftPrice,
    Widget? giftIcon,
  }) {
    return Get.dialog<int>(
      _GiftComboDialog(
        giftName: giftName,
        giftPrice: giftPrice,
        giftIcon: giftIcon,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  /// Two-button confirm helper.
  static Future<bool?> confirm({
    BuildContext? context,
    required String title,
    String? message,
    IconData icon = Icons.help_outline_rounded,
    Color iconAccent = AdminAgencyUi.violet,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    bool barrierDismissible = true,
  }) {
    final actions = <CommonAppDialogAction>[
      CommonAppDialogAction(
        label: cancelLabel,
        result: false,
      ),
      CommonAppDialogAction(
        label: confirmLabel,
        isPrimary: true,
        isDestructive: destructive,
        result: true,
      ),
    ];
    if (context != null) {
      return show<bool>(
        context,
        title: title,
        message: message,
        icon: icon,
        iconAccent: destructive ? AdminAgencyUi.rose : iconAccent,
        actions: actions,
        barrierDismissible: barrierDismissible,
      );
    }
    return showGet<bool>(
      title: title,
      message: message,
      icon: icon,
      iconAccent: destructive ? AdminAgencyUi.rose : iconAccent,
      actions: actions,
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = message?.trim() ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      // Dialog already insets for the keyboard; LayoutBuilder sees the leftover
      // height so we can scroll instead of overflowing (Create Family, etc.).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite &&
                  constraints.maxHeight > 0
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height * 0.85;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xF02A1638),
                          Color(0xF0140C22),
                          Color(0xF00C0814),
                        ],
                      ),
                      border: Border.all(
                        color: iconAccent.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: iconAccent.withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            AdminAgencyUi.glowIcon(
                              icon: icon!,
                              accent: iconAccent,
                              size: 56,
                              iconSize: 28,
                            ),
                            Spacing.v16,
                          ],
                          SemiBoldText(
                            text: title,
                            fontSize: TextStyles.k18FontSize,
                            color: kColorWhite,
                            align: TextAlign.center,
                          ),
                          if (body.isNotEmpty) ...[
                            Spacing.v10,
                            AppText(
                              text: body,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorWhite.withValues(alpha: 0.78),
                              align: TextAlign.center,
                            ),
                          ],
                          if (content != null) ...[
                            Spacing.v16,
                            content!,
                          ],
                          if (actions.isNotEmpty) ...[
                            Spacing.v20,
                            _actionRow(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionRow(BuildContext context) {
    if (actions.length == 1) {
      return _actionButton(context, actions.first, expanded: true);
    }

    // Prefer side-by-side equal-height when 2 actions.
    if (actions.length == 2) {
      return Row(
        children: [
          Expanded(child: _actionButton(context, actions[0])),
          Spacing.h10,
          Expanded(child: _actionButton(context, actions[1])),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) Spacing.v10,
          _actionButton(context, actions[i], expanded: true),
        ],
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    CommonAppDialogAction action, {
    bool expanded = false,
  }) {
    final onTap = () {
      final nav = Navigator.of(context);
      if (action.result != null) {
        nav.pop(action.result);
      } else {
        nav.pop<void>();
      }
      action.onPressed?.call();
    };

    if (action.isPrimary || action.isDestructive) {
      final colors = action.isDestructive
          ? const [Color(0xFFFF6B8A), Color(0xFFE53935)]
          : const [Color(0xFFFF5CAB), Color(0xFF9C6BFF)];
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 48,
            width: expanded ? double.infinity : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: SemiBoldText(
                text: action.label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          width: expanded ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: kColorWhite.withValues(alpha: 0.1),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.22)),
          ),
          child: Center(
            child: SemiBoldText(
              text: action.label,
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered gift-combo picker — light dating chrome + vivid combo tiles.
class _GiftComboDialog extends StatelessWidget {
  const _GiftComboDialog({
    required this.giftName,
    this.giftPrice,
    this.giftIcon,
  });

  final String giftName;
  final String? giftPrice;
  final Widget? giftIcon;

  static const _options = <_ComboPick>[
    _ComboPick(
      count: 1,
      caption: 'Solo',
      icon: Icons.card_giftcard_rounded,
      colors: [Color(0xFF5B8DEF), Color(0xFF7B5CFF)],
    ),
    _ComboPick(
      count: 3,
      caption: 'Triple',
      icon: Icons.local_fire_department_rounded,
      colors: [Color(0xFFFF4F98), Color(0xFFB14DFF)],
    ),
    _ComboPick(
      count: 5,
      caption: 'Burst',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFFFF8A3D), Color(0xFFFF4F98)],
    ),
    _ComboPick(
      count: 10,
      caption: 'Mega',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFFFFB020), Color(0xFFFF5C9A)],
    ),
  ];

  int? get _unitPrice {
    final raw = giftPrice?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: AppLightUi.glossRingGradient,
            boxShadow: [
              BoxShadow(
                color: AppLightUi.pink.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppLightUi.violet.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26.4),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFBFE),
                      Color(0xFFFFF6FA),
                      Color(0xFFF8F0FF),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _comboBadge(),
                      Spacing.v12,
                      _selectedGiftCard(),
                      Spacing.v16,
                      const SemiBoldText(
                        text: 'Send as Combo?',
                        fontSize: TextStyles.k20FontSize,
                        color: AppLightUi.title,
                        align: TextAlign.center,
                      ),
                      Spacing.v6,
                      const AppText(
                        text:
                            'Tap a pack to send — 1, 3, 5 or 10 gifts at once.',
                        fontSize: TextStyles.k12FontSize,
                        color: AppLightUi.subtitle,
                        align: TextAlign.center,
                      ),
                      Spacing.v16,
                      _grid(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _comboBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppLightUi.ctaGradient,
        boxShadow: [
          BoxShadow(
            color: AppLightUi.pink.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: kColorWhite),
          SizedBox(width: 6),
          SemiBoldText(
            text: 'COMBO SEND',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _selectedGiftCard() {
    final price = giftPrice?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AppLightUi.cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppLightUi.pink.withValues(alpha: 0.14),
                  AppLightUi.violet.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(
                color: AppLightUi.pink.withValues(alpha: 0.28),
              ),
            ),
            child: giftIcon ??
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppLightUi.pink,
                  size: 28,
                ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'Selected gift',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.muted,
                ),
                Spacing.v2,
                SemiBoldText(
                  text: giftName,
                  fontSize: TextStyles.k16FontSize,
                  color: AppLightUi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (price != null && price.isNotEmpty) ...[
                  Spacing.v4,
                  Row(
                    children: [
                      const AppCoinIcon(size: 14),
                      const SizedBox(width: 4),
                      SemiBoldText(
                        text: price,
                        fontSize: TextStyles.k12FontSize,
                        color: AppLightUi.gold,
                      ),
                      const AppText(
                        text: ' each',
                        fontSize: TextStyles.k10FontSize,
                        color: AppLightUi.subtitle,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    final unit = _unitPrice;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - 12) / 2;
        final ratio = cellW < 150 ? 0.80 : 0.86;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, i) => _ComboPickTile(
            option: _options[i],
            unitPrice: unit,
            delayMs: i * 55,
            featured: _options[i].count == 10,
          ),
        );
      },
    );
  }
}

class _ComboPick {
  const _ComboPick({
    required this.count,
    required this.caption,
    required this.icon,
    required this.colors,
  });

  final int count;
  final String caption;
  final IconData icon;
  final List<Color> colors;
}

class _ComboPickTile extends StatelessWidget {
  const _ComboPickTile({
    required this.option,
    this.unitPrice,
    this.delayMs = 0,
    this.featured = false,
  });

  final _ComboPick option;
  final int? unitPrice;
  final int delayMs;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final label = option.count == 1 ? '×1' : '×${option.count}';
    final colors = option.colors;
    final accent = colors[0];
    final accentEnd = colors.length > 1 ? colors[1] : colors[0];
    final total = unitPrice == null ? null : unitPrice! * option.count;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(option.count),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppLightUi.card,
              border: Border.all(
                color: accent.withValues(alpha: featured ? 0.55 : 0.32),
                width: featured ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: featured ? 0.28 : 0.16),
                  blurRadius: featured ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppLightUi.title.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.14),
                  AppLightUi.card,
                  accentEnd.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(option.icon, color: kColorWhite, size: 22),
                  ),
                  Spacing.v8,
                  SemiBoldText(
                    text: option.caption,
                    fontSize: TextStyles.k10FontSize,
                    color: AppLightUi.subtitle,
                  ),
                  Spacing.v4,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: colors),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SemiBoldText(
                      text: label,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                  ),
                  if (total != null) ...[
                    Spacing.v6,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppCoinIcon(size: 12),
                        const SizedBox(width: 3),
                        AppText(
                          text: '$total',
                          fontSize: TextStyles.k10FontSize,
                          color: AppLightUi.body,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
