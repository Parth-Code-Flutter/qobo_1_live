import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/block_list_controller.dart';

class BlockListView extends GetView<BlockListController> {
  const BlockListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBarWidget(
        title: 'Block List',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        if (controller.blockedUsers.isEmpty) {
          return Center(
            child: AppText(
              text: 'Your block list is empty.',
              color: kColorHint,
              fontSize: TextStyles.k14FontSize,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.blockedUsers.length,
          separatorBuilder: (_, __) => const Divider(color: kColorBackground, height: 24),
          itemBuilder: (context, index) {
            final user = controller.blockedUsers[index];
            return Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: AssetImage(user['image']),
                ),
                Spacing.h16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: user['name'],
                        fontSize: TextStyles.k14FontSize,
                        color: kColorText,
                      ),
                      Spacing.v4,
                      AppText(
                        text: 'ID: ${user['id']}',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorHint,
                      ),
                    ],
                  ),
                ),
                Spacing.h8,
                SizedBox(
                  width: 90,
                  height: 32,
                  child: appButton(
                    onPressed: () => controller.unblockUser(index),
                    buttonText: 'Unblock',
                    buttonColor: Colors.transparent,
                    textColor: kColorPrimary,
                    buttonBorderColor: kColorPrimary,
                    borderRadius: 16,
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
