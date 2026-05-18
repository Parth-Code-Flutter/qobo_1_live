import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/broadcast_watched_controller.dart';

class BroadcastWatchedView extends GetView<BroadcastWatchedController> {
  const BroadcastWatchedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Broadcast History',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
            ),
          );
        }

        if (controller.broadcasts.isEmpty) {
          return _buildEmptyState();
        }

        return _buildWatchedHistoryList();
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kColorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              color: kColorPrimary,
              size: 64,
            ),
          ),
          Spacing.v24,
          const SemiBoldText(
            text: 'No Broadcast History',
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
          Spacing.v8,
          const AppText(
            text: 'Hosts you watch will appear here.',
            fontSize: TextStyles.k14FontSize,
            color: kColorHint,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWatchedHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: controller.broadcasts.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final broadcast = controller.broadcasts[index];
        final bool isLive = broadcast['isLive'] ?? false;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with live indicator
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLive ? kColorPrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        kImgTemp2, // Using default fallback
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF007A), Color(0xFFFF4E00)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: kColorWhite,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Spacing.h4,
                            const AppText(
                              text: 'LIVE',
                              fontSize: 8,
                              color: kColorWhite,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Spacing.h12,
              // Broadcaster Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: SemiBoldText(
                            text: broadcast['name'] ?? 'Unknown Host',
                            fontSize: TextStyles.k16FontSize,
                            color: kColorText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLive) ...[
                          Spacing.h6,
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, color: kColorPrimary, size: 12),
                              Spacing.h2,
                              AppText(
                                text: broadcast['viewers'] ?? '',
                                fontSize: 10,
                                color: kColorPrimary,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: broadcast['category'] ?? 'Category',
                      fontSize: 11,
                      color: kColorPrimary.withOpacity(0.8),
                    ),
                    Spacing.v6,
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.grey.shade400, size: 12),
                        Spacing.h4,
                        Expanded(
                          child: AppText(
                            text: '${broadcast['watchDuration'] ?? ''}  •  ${broadcast['lastWatched'] ?? ''}',
                            fontSize: 11,
                            color: kColorHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Action Button (Watch / Profile)
              SizedBox(
                height: 32,
                width: 76,
                child: appButton(
                  onPressed: isLive
                      ? () => controller.joinLiveRoom(broadcast['name'])
                      : () => controller.visitProfile(broadcast['name']),
                  buttonText: isLive ? 'Watch' : 'Profile',
                  buttonColor: isLive ? kColorPrimary : kColorBackground,
                  buttonBorderColor: isLive ? Colors.transparent : kColorPrimary,
                  borderRadius: 16,
                  buttonWidth: 76,
                  textStyle: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: isLive ? kColorWhite : kColorPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
