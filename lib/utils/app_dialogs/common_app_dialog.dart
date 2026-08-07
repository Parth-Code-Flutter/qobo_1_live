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
