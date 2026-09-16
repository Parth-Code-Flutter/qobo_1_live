import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared dating AppBar — purple→pink gradient, rounded bottom, white chrome.
///
/// Matches Family detail header; used by Settings, Visitors, Mall, etc.
class CommonAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBarWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.showVerifiedBadge = false,
    this.useMaterialAppBar = true,
    this.useGradientStyle = true,
    this.actions,
    this.rowAction,
    this.trailingIcon,
    this.onTrailingTap,
    this.onBackPressed,
    this.onTitleTap,
    this.backgroundColor = AppLightUi.bg,
    this.titleColor = AppLightUi.title,
    this.bottom,
    this.toolbarHeight = 64,
  });

  final String title;

  /// Optional second line under the title (e.g. ID / member count).
  final String? subtitle;

  final bool showBackButton;
  final bool showVerifiedBadge;

  /// Kept for call-site compatibility; gradient style is preferred.
  final bool useMaterialAppBar;

  /// When false, falls back to a flat light AppBar (legacy).
  final bool useGradientStyle;

  final List<Widget>? actions;
  final Widget? rowAction;

  /// Convenience gold circle action (Family-style `group_add` button).
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  final VoidCallback? onBackPressed;
  final VoidCallback? onTitleTap;
  final Color backgroundColor;
  final Color titleColor;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  static const gradient = AppLightUi.familyCtaGradient;

  /// Transparent margin under the rounded bar so tabs/lists aren't flush.
  static const double bottomGap = 12;

  @override
  Size get preferredSize {
    final extraBottom = bottom?.preferredSize.height ?? 0;
    final gap = useGradientStyle ? bottomGap : 0.0;
    return Size.fromHeight(toolbarHeight + gap + extraBottom);
  }

  @override
  Widget build(BuildContext context) {
    if (!useGradientStyle) {
      return useMaterialAppBar ? _buildFlatAppBar() : _buildFlatRowHeader();
    }
    return _buildGradientAppBar();
  }

  PreferredSizeWidget _buildGradientAppBar() {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final extraH = bottom?.preferredSize.height ?? 0;
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      // Gradient paints above [bottomGap]; gap itself stays transparent.
      flexibleSpace: Padding(
        padding: EdgeInsets.only(bottom: bottomGap + extraH),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A1744).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          ),
        ),
      ),
      leadingWidth: showBackButton ? 56 : 12,
      leading: showBackButton
          ? IconButton(
              onPressed: onBackPressed ?? () => Get.back(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: kColorWhite,
                size: 26,
              ),
            )
          : const SizedBox.shrink(),
      title: GestureDetector(
        onTap: onTitleTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.kSemiBoldPoppins(
                        fontSize: hasSubtitle
                            ? TextStyles.k18FontSize
                            : TextStyles.k20FontSize,
                        colors: kColorWhite,
                      ),
                    ),
                  ),
                  if (showVerifiedBadge) ...[
                    Spacing.h6,
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFFFFD45B),
                      size: 18,
                    ),
                  ],
                ],
              ),
              if (hasSubtitle) ...[
                const SizedBox(height: 2),
                AppText(
                  text: subtitle!,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.86),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        ...?actions,
        if (trailingIcon != null) ...[
          _GoldCircleAction(
            icon: trailingIcon!,
            onTap: onTrailingTap,
          ),
          const SizedBox(width: 10),
        ] else if (rowAction != null) ...[
          rowAction!,
          const SizedBox(width: 8),
        ],
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomGap + extraH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: bottomGap),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFlatAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: showBackButton
          ? IconButton(
              onPressed: onBackPressed ?? () => Get.back(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: titleColor,
                size: 24,
              ),
            )
          : const SizedBox.shrink(),
      title: Text(
        title,
        style: TextStyles.kBoldPoppins(
          fontSize: TextStyles.k20FontSize,
          colors: titleColor,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  Widget _buildFlatRowHeader() {
    final Widget leading = showBackButton
        ? IconButton(
            onPressed: onBackPressed ?? () => Get.back(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: titleColor,
              size: 24,
            ),
          )
        : const SizedBox(width: 48);

    final Widget trailing = rowAction ?? const SizedBox(width: 48);

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: kToolbarHeight,
            color: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                leading,
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.kBoldPoppins(
                        fontSize: TextStyles.k20FontSize,
                        colors: titleColor,
                      ),
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

class _GoldCircleAction extends StatelessWidget {
  const _GoldCircleAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC239), Color(0xFFFF9D1D)],
              ),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
            ),
            child: Icon(icon, color: kColorWhite, size: 22),
          ),
        ),
      ),
    );
  }
}
