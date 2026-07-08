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
import 'package:zego_uikit/zego_uikit.dart';
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
            if (isVideo)
              const _VideoParticipantStrip()
            else ...[
              const _VoiceCallPortraitStage(),
              const _VoiceReceiverPreviewCard(),
            ],
            const _CallTopOverlay(),
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
        ..avatarBuilder = _buildZegoAvatar
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
      ..avatarBuilder = _buildZegoAvatar
      ..turnOnCameraWhenJoining = false
      ..turnOnMicrophoneWhenJoining = true
      ..useSpeakerWhenJoining = true
      ..enableAccidentalTouchPrevention = false
      ..background = const _VoiceCallGradientBackground()
      ..duration.isVisible = false
      ..user.requiredUsers.enabled = false
      ..audioVideoView.showAvatarInAudioMode = false
      ..audioVideoView.showSoundWavesInAudioMode = false
      ..audioVideoView.showUserNameOnView = false
      ..audioVideoView.showMicrophoneStateOnView = false
      ..audioVideoView.showWaitingCallAcceptAudioVideoView = false
      ..audioVideoView.containerBuilder = _buildHiddenVoiceAudioContainer
      ..bottomMenuBar = bottomBar
      ..device = device;
  }

  Widget? _buildHiddenVoiceAudioContainer(
    BuildContext context,
    List<ZegoUIKitUser> allUsers,
    List<ZegoUIKitUser> audioVideoUsers,
    ZegoAudioVideoView Function(ZegoUIKitUser) audioVideoViewCreator,
  ) {
    return const SizedBox.shrink();
  }

  Widget? _buildZegoAvatar(
    BuildContext context,
    Size size,
    ZegoUIKitUser? user,
    Map<String, dynamic> extraInfo,
  ) {
    if (user == null) return null;
    final isCurrentUser = user.id == controller.zegoUserId;
    return AppUserAvatar(
      name: isCurrentUser
          ? controller.currentUserName
          : controller.peerName.value,
      imageUrl: isCurrentUser
          ? controller.currentUserAvatar
          : controller.peerAvatar.value,
      size: size.shortestSide,
      fontSize: size.shortestSide * 0.28,
    );
  }
}

class _VoiceCallPortraitStage extends GetView<ChatVoiceCallController> {
  const _VoiceCallPortraitStage();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final haloSize = (constraints.maxWidth * 0.50)
                .clamp(154.0, 188.0)
                .toDouble();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 112, 20, 128),
              child: Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    _PortraitHalo(
                      name: controller.currentUserName,
                      imageUrl: controller.currentUserAvatar,
                      size: haloSize,
                      label: controller.currentUserName,
                      labelPrefix: controller.hasPeerJoined.value
                          ? 'You are connected'
                          : 'Waiting for answer',
                      prominent: true,
                    ),
                    const SizedBox(height: 80),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VideoParticipantStrip extends GetView<ChatVoiceCallController> {
  const _VideoParticipantStrip();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 118),
          child: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  child: _MiniParticipantPill(
                    name: controller.currentUserName,
                    imageUrl: controller.currentUserAvatar,
                    label: 'You',
                    dark: true,
                  ),
                ),
                const SizedBox(width: 6),
                IgnorePointer(
                  child: _MiniParticipantPill(
                    name: controller.peerName.value,
                    imageUrl: controller.peerAvatar.value,
                    label: controller.hasPeerJoined.value
                        ? controller.peerName.value
                        : 'Ringing',
                    dark: true,
                  ),
                ),
                const SizedBox(width: 6),
                _CompactCallActionButton(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Gift',
                  onTap: () => Get.bottomSheet(
                    _CallGiftsBottomSheet(controller: controller),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
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

class _CompactCallActionButton extends StatelessWidget {
  const _CompactCallActionButton({
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
      child: Container(
        width: 96,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: Icon(icon, color: kColorWhite, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SemiBoldText(
                text: label,
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceCallGradientBackground extends StatelessWidget {
  const _VoiceCallGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4B064A),
            Color(0xFF2D0B58),
            Color(0xFF06114B),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _VoiceReceiverPreviewCard extends StatefulWidget {
  const _VoiceReceiverPreviewCard();

  @override
  State<_VoiceReceiverPreviewCard> createState() =>
      _VoiceReceiverPreviewCardState();
}

class _VoiceReceiverPreviewCardState extends State<_VoiceReceiverPreviewCard> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatVoiceCallController>();
    const cardWidth = 140.0;
    const cardHeight = 154.0;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxX = constraints.maxWidth - cardWidth - 12;
          final maxY = constraints.maxHeight - cardHeight - 112;
          final initialPosition = Offset(
            constraints.maxWidth - cardWidth - 18,
            constraints.maxHeight - cardHeight - 132,
          );
          final position = _position ?? initialPosition;

          Offset clampPosition(Offset value) {
            return Offset(
              value.dx.clamp(12.0, maxX < 12 ? 12 : maxX),
              value.dy.clamp(96.0, maxY < 96 ? 96 : maxY),
            );
          }

          return Stack(
            children: [
              Positioned(
                left: clampPosition(position).dx,
                top: clampPosition(position).dy,
                width: cardWidth,
                height: cardHeight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _position = clampPosition(position + details.delta);
                    });
                  },
                  onTap: () => Get.bottomSheet(
                    _CallProfileSheet(controller: controller),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Obx(
                    () => _VoiceParticipantCard(
                      name: controller.peerName.value,
                      imageUrl: controller.peerAvatar.value,
                      label: controller.peerName.value,
                      status: controller.hasPeerJoined.value
                          ? 'Connected'
                          : 'Ringing',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VoiceParticipantCard extends StatelessWidget {
  const _VoiceParticipantCard({
    required this.name,
    required this.imageUrl,
    required this.label,
    required this.status,
  });

  final String name;
  final String? imageUrl;
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorProfileActionPinkStart.withValues(alpha: 0.72),
            const Color(0xFF2A1348).withValues(alpha: 0.88),
            const Color(0xFF111B3F).withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  kColorProfileActionPinkStart.withValues(alpha: 0.95),
                  kColorProfileChipPurpleEnd.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: AppUserAvatar(
              name: name,
              imageUrl: imageUrl,
              size: 62,
              fontSize: TextStyles.k16FontSize,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.80),
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
            align: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF24C08A),
                  shape: BoxShape.circle,
                ),
              ),
              Spacing.h6,
              Flexible(
                child: AppText(
                  text: status,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.82),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortraitHalo extends StatelessWidget {
  const _PortraitHalo({
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.label,
    required this.labelPrefix,
    this.prominent = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final String label;
  final String labelPrefix;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 22,
          height: size + 22,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: prominent ? 0.32 : 0.18),
                blurRadius: prominent ? 36 : 18,
                spreadRadius: prominent ? 5 : 1,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  kColorProfileActionPinkStart.withValues(alpha: 0.95),
                  kColorProfileChipPurpleEnd.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: AppUserAvatar(
              name: name,
              imageUrl: imageUrl,
              size: size,
              fontSize: TextStyles.k48FontSize,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.76),
                width: 3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AppText(
          text: labelPrefix,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite.withValues(alpha: 0.66),
          align: TextAlign.center,
        ),
        Spacing.v4,
        SemiBoldText(
          text: label,
          fontSize: TextStyles.k22FontSize,
          color: kColorWhite,
          align: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MiniParticipantPill extends StatelessWidget {
  const _MiniParticipantPill({
    required this.name,
    required this.imageUrl,
    required this.label,
    this.dark = false,
  });

  final String name;
  final String? imageUrl;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 44,
      padding: const EdgeInsets.fromLTRB(7, 6, 8, 6),
      decoration: BoxDecoration(
        color: (dark ? Colors.black : kColorWhite).withValues(
          alpha: dark ? 0.52 : 0.10,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppUserAvatar(
            name: name,
            imageUrl: imageUrl,
            size: 30,
            fontSize: TextStyles.k10FontSize,
            border: Border.all(color: kColorWhite.withValues(alpha: 0.72)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
                constraints: const BoxConstraints(minHeight: 74),
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(20),
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
                    GestureDetector(
                      onTap: () => _confirmBackEndsCall(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kColorWhite.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kColorWhite.withValues(alpha: 0.10),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: kColorWhite,
                          size: 20,
                        ),
                      ),
                    ),
                    Spacing.h8,
                    AppUserAvatar(
                      name: controller.isVideo.value
                          ? controller.peerName.value
                          : controller.currentUserName,
                      imageUrl: controller.isVideo.value
                          ? controller.peerAvatar.value
                          : controller.currentUserAvatar,
                      size: 40,
                      fontSize: TextStyles.k14FontSize,
                    ),
                    Spacing.h8,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SemiBoldText(
                            text: controller.isVideo.value
                                ? controller.peerName.value
                                : controller.currentUserName,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacing.v2,
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: controller.hasPeerJoined.value
                                      ? const Color(0xFF24C08A)
                                      : Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Spacing.h6,
                              AppText(
                                text: controller.formattedDuration,
                                fontSize: TextStyles.k10FontSize,
                                color: kColorWhite.withValues(alpha: 0.78),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: _CoinsPanel(controller: controller),
                    ),
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

  Future<void> _confirmBackEndsCall(BuildContext context) async {
    final shouldEnd = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF171321),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const SemiBoldText(
          text: 'End call?',
          fontSize: TextStyles.k18FontSize,
          color: kColorWhite,
        ),
        content: AppText(
          text: 'If you back call will be end',
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite.withValues(alpha: 0.78),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: AppText(
              text: 'Cancel',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.74),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const SemiBoldText(
              text: 'End Call',
              fontSize: TextStyles.k12FontSize,
              color: kColorPrimary,
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (shouldEnd != true || !context.mounted) return;
    await ZegoUIKitPrebuiltCallController().hangUp(
      context,
      reason: ZegoCallEndReason.localHangUp,
    );
  }
}

class _CoinsPanel extends StatelessWidget {
  const _CoinsPanel({required this.controller});

  final ChatVoiceCallController controller;

  @override
  Widget build(BuildContext context) {
    final earning = !controller.isCaller.value;
    final connected = controller.hasPeerJoined.value;
    return Container(
      constraints: const BoxConstraints(minWidth: 78, maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: connected
            ? LinearGradient(
                colors: earning
                    ? const [Color(0xFF0D8F68), Color(0xFF24C08A)]
                    : const [Color(0xFF8E1B85), Color(0xFFE62572)],
              )
            : null,
        color: connected ? null : kColorWhite.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
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
          connected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    Spacing.h2,
                    SemiBoldText(
                      text: controller.billingAmountLabel,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                    ),
                  ],
                )
              : const SemiBoldText(
                  text: 'No charge',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
          AppText(
            text: connected
                ? 'Wallet ${controller.walletLabel}'
                : 'until answer',
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
