import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Reusable app bar that can render either a Material AppBar
/// or a custom row-based header.
class CommonAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const CommonAppBarWidget({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.useMaterialAppBar = true,
    this.actions,
    this.rowAction,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
    this.bottom,
  });

  final String title;
  final bool showBackButton;
  final bool useMaterialAppBar;
  final List<Widget>? actions;
  final Widget? rowAction;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return useMaterialAppBar
        ? _buildAppBar(context)
        : _buildRowHeader(context);
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final titleClr = titleColor ?? Theme.of(context).colorScheme.onSurface;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      leading: showBackButton
          ? Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
                onPressed: onBackPressed ?? () => Get.back(),
                icon: SvgPicture.asset(kIconArrowBack),
              ),
          )
          : const SizedBox.shrink(),
      title: Text(
        title,
        style: TextStyles.kBoldPoppins(
          fontSize: TextStyles.k24FontSize,
          colors: titleClr,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  Widget _buildRowHeader(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final titleClr = titleColor ?? Theme.of(context).colorScheme.onSurface;

    final Widget leading = showBackButton
        ? IconButton(
            onPressed: onBackPressed ?? () => Get.back(),
            icon: SvgPicture.asset(kIconArrowBack, width: 22, height: 22),
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
            color: bg,
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
                        fontSize: TextStyles.k24FontSize,
                        colors: titleClr,
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
