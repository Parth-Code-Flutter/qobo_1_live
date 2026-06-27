import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/gift_icon_widget.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../controllers/chat_voice_call_controller.dart';
import '../widgets/chat_call_control_buttons.dart';

/// Zego Call Kit screen — 1:1 voice or video (quick-start pattern).
class ChatVoiceCallView extends GetView<ChatVoiceCallController> {
  const ChatVoiceCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final callId = controller.callId.value;
      if (callId.isEmpty) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: kColorPrimary)),
        );
      }

      final isVideo = controller.isVideo.value;
      final config = _buildConfig(isVideo);

      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: ZegoUIKitPrebuiltCall(
                appID: ZegoConfig.callAppId,
                appSign: ZegoConfig.callAppSign,
                userID: controller.zegoUserId,
                userName: controller.zegoUserName,
                callID: callId,
                config: config,
                events: ZegoUIKitPrebuiltCallEvents(
                  onError: (error) {
                    controller.onZegoError(error);
                    if (!context.mounted) return;
                    AppToast.showError(
                      context,
                      error.message.isNotEmpty
                          ? error.message
                          : 'Call error (code ${error.code})',
                      title: 'Call failed',
                    );
                  },
                  room: ZegoCallRoomEvents(
                    onStateChanged: (state) {
                      LoggerUtils.logInfo(
                        'ChatVoiceCallView: room ${state.reason} '
                        'error=${state.errorCode}',
                      );
                    },
                  ),
                  user: ZegoCallUserEvents(
                    onEnter: (user) {
                      controller.onPeerJoined();
                      LoggerUtils.logInfo(
                        'ChatVoiceCallView: peer joined ${user.id}',
                      );
                    },
                  ),
                  onCallEnd: (event, defaultAction) async {
                    await controller.finishCall(refreshInbox: false);
                    defaultAction.call();
                    await controller.onCallScreenDisposed();
                    ChatVoiceCallController.refreshMessagesInbox();
                  },
                ),
              ),
            ),
            const _CallTopOverlay(),
            const _CallSideActions(),
          ],
        ),
      );
    });
  }

  ZegoUIKitPrebuiltCallConfig _buildConfig(bool isVideo) {
    final bottomBar = ZegoCallBottomMenuBarConfig(
      style: ZegoCallMenuBarStyle.light,
      hideAutomatically: false,
      buttons: isVideo
          ? const [
              ZegoCallMenuBarButtonName.toggleCameraButton,
              ZegoCallMenuBarButtonName.switchCameraButton,
              ZegoCallMenuBarButtonName.beautyEffectButton,
              ZegoCallMenuBarButtonName.hangUpButton,
            ]
          : const [ZegoCallMenuBarButtonName.hangUpButton],
      extendButtons: const [ChatCallMicButton(), ChatCallSpeakerButton()],
    );

    final device = ZegoCallDeviceConfig(enableSyncDeviceStatusBySEI: false);

    if (isVideo) {
      return ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..turnOnCameraWhenJoining = true
        ..turnOnMicrophoneWhenJoining = true
        ..useSpeakerWhenJoining = true
        ..enableAccidentalTouchPrevention = false
        ..duration.isVisible = false
        ..user.requiredUsers.enabled = false
        ..bottomMenuBar = bottomBar
        ..device = device;
    }

    return ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
      ..turnOnCameraWhenJoining = false
      ..turnOnMicrophoneWhenJoining = true
      ..useSpeakerWhenJoining = true
      ..enableAccidentalTouchPrevention = false
      ..duration.isVisible = false
      ..user.requiredUsers.enabled = false
      ..bottomMenuBar = bottomBar
      ..device = device;
  }
}

class _CallTopOverlay extends GetView<ChatVoiceCallController> {
  const _CallTopOverlay();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Obx(
            () => GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.46),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AppUserAvatar(
                      name: controller.peerName.value,
                      imageUrl: controller.peerAvatar.value,
                      size: 46,
                      fontSize: TextStyles.k14FontSize,
                    ),
                    Spacing.h10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SemiBoldText(
                            text: controller.peerName.value,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacing.v2,
                          Row(
                            children: [
                              Icon(
                                controller.isVideo.value
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                color: kColorWhite.withValues(alpha: 0.68),
                                size: 13,
                              ),
                              Spacing.h4,
                              AppText(
                                text: controller.formattedDuration,
                                fontSize: 11,
                                color: kColorWhite.withValues(alpha: 0.78),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _CoinsPanel(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    Get.bottomSheet(
      _CallProfileSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _CoinsPanel extends StatelessWidget {
  const _CoinsPanel({required this.controller});

  final ChatVoiceCallController controller;

  @override
  Widget build(BuildContext context) {
    final earning = !controller.isCaller.value;
    return Container(
      constraints: const BoxConstraints(minWidth: 94),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: earning
              ? const [Color(0xFF0D8F68), Color(0xFF24C08A)]
              : const [Color(0xFF8E1B85), Color(0xFFE62572)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            text: controller.billingRoleLabel,
            fontSize: TextStyles.k8FontSize,
            color: kColorWhite.withValues(alpha: 0.76),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v2,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_rounded, color: Colors.amber, size: 14),
              Spacing.h2,
              SemiBoldText(
                text: controller.billingAmountLabel,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          AppText(
            text: 'Wallet ${controller.walletLabel}',
            fontSize: TextStyles.k8FontSize,
            color: kColorWhite.withValues(alpha: 0.74),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CallSideActions extends GetView<ChatVoiceCallController> {
  const _CallSideActions();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 70),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundActionButton(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  onTap: () => Get.bottomSheet(
                    _CallProfileSheet(controller: controller),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                if (controller.isVideo.value) ...[
                  Spacing.v12,
                  _RoundActionButton(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Gift',
                    onTap: () => Get.bottomSheet(
                      _CallGiftsBottomSheet(controller: controller),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.50),
              shape: BoxShape.circle,
              border: Border.all(color: kColorWhite.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: kColorWhite, size: 22),
          ),
          Spacing.v4,
          AppText(
            text: label,
            fontSize: 9,
            color: kColorWhite.withValues(alpha: 0.82),
          ),
        ],
      ),
    );
  }
}

class _CallProfileSheet extends StatelessWidget {
  const _CallProfileSheet({required this.controller});

  final ChatVoiceCallController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF171321),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Spacing.v16,
              AppUserAvatar(
                name: controller.peerName.value,
                imageUrl: controller.peerAvatar.value,
                size: 82,
                fontSize: TextStyles.k22FontSize,
              ),
              Spacing.v12,
              SemiBoldText(
                text: controller.peerName.value,
                fontSize: TextStyles.k20FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              if (controller.peerCountry.value.isNotEmpty) ...[
                Spacing.v6,
                AppText(
                  text: controller.peerCountry.value,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.70),
                  align: TextAlign.center,
                ),
              ],
              if (controller.peerBio.value.isNotEmpty) ...[
                Spacing.v12,
                AppText(
                  text: controller.peerBio.value,
                  fontSize: 13,
                  color: kColorWhite.withValues(alpha: 0.78),
                  align: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: _ProfileMetric(
                      label: 'Duration',
                      value: controller.formattedDuration,
                    ),
                  ),
                  Spacing.h10,
                  Expanded(
                    child: _ProfileMetric(
                      label: controller.isCaller.value ? 'Spent' : 'Earned',
                      value: controller.billingAmountLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v2,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
          ),
        ],
      ),
    );
  }
}

class _CallGiftsBottomSheet extends StatefulWidget {
  const _CallGiftsBottomSheet({required this.controller});

  final ChatVoiceCallController controller;

  @override
  State<_CallGiftsBottomSheet> createState() => _CallGiftsBottomSheetState();
}

class _CallGiftsBottomSheetState extends State<_CallGiftsBottomSheet> {
  var _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.loadGiftCatalog();
    widget.controller.loadWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.46,
      decoration: const BoxDecoration(
        color: Color(0xFF171321),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Spacing.v12,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v12,
            const SemiBoldText(
              text: 'Send Gift',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Expanded(
              child: Obx(() {
                if (widget.controller.isLoadingGifts.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                final gifts = widget.controller.giftCatalog;
                if (gifts.isEmpty) {
                  return Center(
                    child: AppText(
                      text: 'No gifts available right now.',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite.withValues(alpha: 0.65),
                      align: TextAlign.center,
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: gifts.length,
                  itemBuilder: (context, index) {
                    final gift = gifts[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: selected
                              ? kColorPrimary.withValues(alpha: 0.24)
                              : kColorWhite.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? kColorPrimary
                                : kColorWhite.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GiftIconWidget(icon: gift['icon'], size: 30),
                            Spacing.v4,
                            AppText(
                              text: gift['name'] ?? 'Gift',
                              fontSize: 9,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              align: TextAlign.center,
                            ),
                            Spacing.v2,
                            AppText(
                              text: gift['price'] ?? '0',
                              fontSize: 9,
                              color: Colors.amber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            Obx(
              () => Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  border: Border(
                    top: BorderSide(color: kColorWhite.withValues(alpha: 0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    Spacing.h6,
                    SemiBoldText(
                      text: formatLedgerAmount(
                        widget.controller.coinsBalance.value,
                      ),
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      width: 104,
                      child: TextButton(
                        onPressed:
                            _selectedIndex >= 0 &&
                                _selectedIndex <
                                    widget.controller.giftCatalog.length
                            ? () => widget.controller.sendGift(
                                widget.controller.giftCatalog[_selectedIndex],
                              )
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: kColorPrimary,
                          disabledBackgroundColor: kColorWhite.withValues(
                            alpha: 0.10,
                          ),
                          foregroundColor: kColorWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const SemiBoldText(
                          text: 'Send',
                          fontSize: 13,
                          color: kColorWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
