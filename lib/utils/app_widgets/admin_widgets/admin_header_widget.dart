import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/utils/app_widgets/common_action_icons_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminHeaderWidget extends StatelessWidget {
  const AdminHeaderWidget(
      {super.key,
      required this.title,
      required this.onTap,
      this.subWidget,
      this.actionWidget,
      this.padding,
      this.isShowBack = true,
      this.isShowDrawerIcon = false});

  final String title;
  final bool? isShowBack;
  final bool? isShowDrawerIcon;
  final Widget? subWidget;
  final Widget? actionWidget;
  final EdgeInsets? padding;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, top: 12, right: 20, left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Visibility(
            visible: isShowBack ?? true,
            child: InkWell(
              onTap: onTap,
              child: SvgPicture.asset(
                isShowDrawerIcon == true ? kIconSideDrawer : kIconArrowBack,
                // height: isShowDrawerIcon == true ? 24 : 24,
                height: 24,
                width: 10,
              ),
            ),
          ),
          Expanded(
            child: Image.asset(
              kIconApp,
              height: 32,
            ),
          ),
          actionWidget ??
              const CommonActionIconsRowWidget(
                notificationIconSize: 22,
              ),
        ],
      ),
    );
  }

// @override
// Widget build(BuildContext context) {
//   return Padding(
//     padding:
//         padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Spacing.v20,
//         Spacing.h16,
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Visibility(
//                       visible: isShowBack ?? true,
//                       child: InkWell(
//                         onTap: onTap,
//                         child: SvgPicture.asset(
//                           kIconArrowBack,
//                           height: 18,
//                           width: 10,
//                         ),
//                       ),
//                     ),
//                     Spacing.h12,
//                     BoldText(
//                       text: title,
//                       fontSize: 24,
//                     ),
//                   ],
//                 ),
//                 if (subWidget != null)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 24),
//                     child: subWidget ?? SizedBox.shrink(),
//                   ),
//               ],
//             ),
//             if (actionWidget != null) actionWidget ?? SizedBox.shrink(),
//           ],
//         ),
//       ],
//     ),
//   );
// }
}
