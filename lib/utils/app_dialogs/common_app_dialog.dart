import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.72),
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

/// Centered gift-combo picker — shows selected gift + 2×2 grid (1 → 3 → 5 → 10).
class _GiftComboDialog extends StatelessWidget {
  const _GiftComboDialog({
    required this.giftName,
    this.giftPrice,
    this.giftIcon,
  });

  final String giftName;
  final String? giftPrice;
  final Widget? giftIcon;

  static const _accent = Color(0xFFFF5CAB);
  static const _accentEnd = Color(0xFF9C6BFF);

  static const _options = <_ComboPick>[
    _ComboPick(
      count: 1,
      icon: Icons.card_giftcard_rounded,
      colors: [Color(0xFF26C6DA), Color(0xFF448AFF)],
    ),
    _ComboPick(
      count: 3,
      icon: Icons.local_fire_department_rounded,
      colors: [Color(0xFFFF5CAB), Color(0xFFAE4BFF)],
    ),
    _ComboPick(
      count: 5,
      icon: Icons.bolt_rounded,
      colors: [Color(0xFFFFAB40), Color(0xFFFF7043)],
    ),
    _ComboPick(
      count: 10,
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFFFFD54F), Color(0xFFFF5252)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                  color: _accent.withValues(alpha: 0.32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _selectedGiftCard(),
                  const SizedBox(height: 18),
                  const SemiBoldText(
                    text: 'Send as Combo?',
                    fontSize: TextStyles.k18FontSize,
                    color: kColorWhite,
                    align: TextAlign.center,
                  ),
                  Spacing.v8,
                  AppText(
                    text:
                        'Pick how many to send — 1, 3, 5 or 10 at once.',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.68),
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _grid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedGiftCard() {
    final price = giftPrice?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.14),
            _accentEnd.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
            ),
            child: giftIcon ??
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: kColorWhite,
                  size: 28,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: 'Selected gift',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 2),
                SemiBoldText(
                  text: giftName,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (price != null && price.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.diamond_outlined,
                        size: 12,
                        color: Colors.orange.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        text: price,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.75),
                      ),
                      AppText(
                        text: ' each',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.45),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) => _ComboPickTile(
        option: _options[i],
        delayMs: i * 50,
      ),
    );
  }
}

class _ComboPick {
  const _ComboPick({
    required this.count,
    required this.icon,
    required this.colors,
  });

  final int count;
  final IconData icon;
  final List<Color> colors;
}

class _ComboPickTile extends StatelessWidget {
  const _ComboPickTile({required this.option, this.delayMs = 0});

  final _ComboPick option;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final label = option.count == 1 ? '1' : '×${option.count}';
    final colors = option.colors;
    final accent = colors[0];
    final accentEnd = colors.length > 1 ? colors[1] : colors[0];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: Duration(milliseconds: 300 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(option.count),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  accentEnd.withValues(alpha: 0.08),
                  kColorWhite.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: accent.withValues(
                  alpha: option.count == 10 ? 0.65 : 0.42,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: option.count == 10 ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(option.icon, color: kColorWhite, size: 20),
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: colors),
                  ),
                  alignment: Alignment.center,
                  child: SemiBoldText(
                    text: label,
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
