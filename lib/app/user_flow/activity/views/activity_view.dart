import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/activity_controller.dart';

class ActivityView extends GetView<ActivityController> {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(kImgBG),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CommonAppBarWidget(
          title: 'Hot Activities',
          useMaterialAppBar: true,
          backgroundColor: Colors.transparent,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.activities.length,
            separatorBuilder: (_, __) => Spacing.v16,
            itemBuilder: (context, index) {
              final act = controller.activities[index];
              final gradients = act['gradient'] as List<int>;
              final isSoon = act['status'] == 'Starting Soon';

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradients.map((hex) => Color(hex).withOpacity(0.9)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(gradients[0]).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15), // overlay for extra text readability
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Status Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSoon ? Colors.orange : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppText(
                                text: act['status'],
                                fontSize: 10,
                                color: kColorWhite,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Time Left
                            Row(
                              children: [
                                const Icon(Icons.timer_rounded, color: kColorWhite, size: 14),
                                Spacing.h4,
                                AppText(
                                  text: act['timeLeft'],
                                  fontSize: TextStyles.k12FontSize,
                                  color: kColorWhite.withOpacity(0.9),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Spacing.v16,
                        BoldText(
                          text: act['title'],
                          fontSize: TextStyles.k20FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v8,
                        AppText(
                          text: act['desc'],
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite.withOpacity(0.9),
                        ),
                        Spacing.v20,
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 36,
                            width: 130,
                            child: appButton(
                              onPressed: () => controller.openActivityDetails(act['title']),
                              buttonText: isSoon ? 'Notify Me' : 'Join Now',
                              buttonColor: kColorWhite,
                              textColor: Color(gradients[0]),
                              borderRadius: 18,
                              textStyle: TextStyles.kSemiBoldPoppins(
                                fontSize: TextStyles.k12FontSize,
                                colors: Color(gradients[0]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
