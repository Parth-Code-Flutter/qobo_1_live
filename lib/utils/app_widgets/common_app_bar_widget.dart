import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
    this.backgroundColor = kColorWhite,
  });

  final String title;
  final bool showBackButton;
  final bool useMaterialAppBar;
  final List<Widget>? actions;
  final Widget? rowAction;
  final VoidCallback? onBackPressed;
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return useMaterialAppBar ? _buildAppBar() : _buildRowHeader();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
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
          colors: kColorText,
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildRowHeader() {
    final Widget leading = showBackButton
        ? IconButton(
            onPressed: onBackPressed ?? () => Get.back(),
            icon: SvgPicture.asset(kIconArrowBack, width: 22, height: 22),
          )
        : const SizedBox(width: 48);

    final Widget trailing = rowAction ?? const SizedBox(width: 48);

    return SafeArea(
      bottom: false,
      child: Container(
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
                    fontSize: TextStyles.k24FontSize,
                    colors: kColorText,
                  ),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
