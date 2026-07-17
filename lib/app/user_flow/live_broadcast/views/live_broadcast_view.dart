import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart' as call;
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

import '../controllers/live_broadcast_controller.dart';
import '../widgets/audio_room_stage_overlay.dart';
import '../widgets/room_options_sheet.dart';

class LiveBroadcastView extends GetView<LiveBroadcastController> {
  const LiveBroadcastView({super.key});

  static const Color _surface = Color(0xE6121720);
  static const Color _surfaceSoft = Color(0xB3121720);
  static const Color _accent = Color(0xFFFF3F7F);
  static const Color _accentPurple = Color(0xFF8E1B85);

  @override
  Widget build(BuildContext context) {
    if (controller.isAudioVideoRoom) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildGroupCallRoom(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainVideoBackground(),
          Obx(() {
            if (controller.isVideoRoom || !controller.canOpenZego) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(child: _buildAudioRoomStage());
          }),
          const Positioned.fill(child: _LiveOverlayScrim()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(),
                const Spacer(),
                // ZEGOCLOUD Prebuilt UIKit automatically handles the interactive audio seats/grids
                // in the viewport background. Hence, we do not double-render our simulated seat layout.
                _buildChatList(),
                _buildBottomControls(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCallRoom() {
    final userSession = Get.find<UserSessionController>();
    final rawUserId = userSession.userId.isNotEmpty
        ? userSession.userId
        : 'user_${userSession.hashCode}';
    final currentUserId = ZegoLiveIdUtils.sanitizeUserId(rawUserId);
    final currentUserName = userSession.displayName.isNotEmpty
        ? userSession.displayName
        : 'User';

    return Obx(() {
      final isVideoRoom = controller.isVideoRoom;
      final conferenceId = controller.roomId.value;
      final canOpenCall = controller.canOpenZego && conferenceId.isNotEmpty;

      if (isVideoRoom && !canOpenCall) {
        return _buildConnectionIssueState();
      }

      final config = _buildGroupCallConfig(isVideoRoom);

      return Stack(
        children: [
          if (canOpenCall)
            call.ZegoUIKitPrebuiltCall(
              key: ValueKey('group_call_$conferenceId'),
              appID: ZegoConfig.roomAppId,
              appSign: ZegoConfig.roomAppSign,
              userID: currentUserId,
              userName: currentUserName,
              callID: conferenceId,
              config: config,
              events: call.ZegoUIKitPrebuiltCallEvents(
                onError: controller.handleGroupCallRoomError,
                room: call.ZegoCallRoomEvents(
                  onStateChanged: (state) {
                    if (state.reason == ZegoRoomStateChangedReason.Logined ||
                        state.reason ==
                            ZegoRoomStateChangedReason.Reconnected) {
                      controller.onGroupCallRoomConnected();
                    } else if (state.reason ==
                        ZegoRoomStateChangedReason.LoginFailed) {
                      controller.handleGroupCallRoomLoginFailed(
                        state.errorCode,
                      );
                    }
                  },
                ),
                onHangUpConfirmation: (event, defaultAction) async {
                  final confirmed = await defaultAction.call();
                  if (!confirmed || !controller.isHost.value) {
                    return confirmed;
                  }
                  return controller.endRoomAfterConfirmedHangUp();
                },
                onCallEnd: (event, defaultAction) {
                  // Do not let participant/reconnect lifecycle events navigate
                  // the host away from an active room.
                  if (!controller.canProcessGroupCallEnd) return;
                  if (_shouldReportGroupCallExit(event.reason)) {
                    controller.reportRoomExit();
                  }
                  defaultAction.call();
                },
              ),
            )
          else
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
          if (!isVideoRoom) ...[
            const Positioned.fill(child: AudioRoomStageOverlay()),
            if (!canOpenCall) _buildAudioRoomConnectionBanner(),
          ],
          _buildGroupCallGiftDock(),
        ],
      );
    });
  }

  bool _shouldReportGroupCallExit(call.ZegoCallEndReason reason) {
    // Host rooms are ended only after the explicit hang-up confirmation.
    // Zego may emit lifecycle end events during reconnects or internal rebuilds.
    if (controller.isHost.value) return false;

    // Zego can emit `abandoned` when a call auto-closes during connection
    // checks. Do not end backend rooms for that case; it makes new rooms
    // disappear from lists even though the host did not intentionally end them.
    if (reason == call.ZegoCallEndReason.abandoned) return false;

    if (reason == call.ZegoCallEndReason.localHangUp ||
        reason == call.ZegoCallEndReason.kickOut) {
      return true;
    }

    // Viewers should still report leave when the host/room ends remotely.
    return reason == call.ZegoCallEndReason.remoteHangUp;
  }

  Widget _buildGroupCallGiftDock() {
    return Obx(() {
      if (controller.isAudioVideoRoom && !controller.isVideoRoom) {
        return const SizedBox.shrink();
      }
      if (!controller.canSendGifts) {
        return const SizedBox.shrink();
      }

      // Keep gifts outside Zego's menu bars so call controls stay unchanged.
      return Positioned(
        right: 14,
        bottom: 108,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.openGiftsSheet,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      color: kColorWalletAmount,
                      size: 18,
                    ),
                    Spacing.h6,
                    SemiBoldText(
                      text: formatLedgerAmount(controller.coinsBalance.value),
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.h10,
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: kColorWhite,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAudioRoomConnectionBanner() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 108,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_tethering_rounded,
                color: _accent,
                size: 18,
              ),
              Spacing.h8,
              Expanded(
                child: AppText(
                  text: controller.connectionIssue.value.isEmpty
                      ? 'Connecting audio...'
                      : controller.connectionIssue.value,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.78),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Spacing.h8,
              TextButton(
                onPressed: controller.leaveRoom,
                style: TextButton.styleFrom(
                  minimumSize: const Size(56, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: _accentPurple,
                  foregroundColor: kColorWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const SemiBoldText(
                  text: 'Back',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  call.ZegoUIKitPrebuiltCallConfig _buildGroupCallConfig(bool isVideoRoom) {
    // Rooms are backed by the ZEGOCLOUD Voice & Video Call product in group
    // mode. Audio rooms join without camera; video rooms join with camera.
    final config = isVideoRoom
        ? call.ZegoUIKitPrebuiltCallConfig.groupVideoCall()
        : call.ZegoUIKitPrebuiltCallConfig.groupVoiceCall();

    final fallbackTitle = isVideoRoom ? 'Video Room' : 'Audio Room';
    final roomTitle = controller.streamTitle.value.isNotEmpty
        ? controller.streamTitle.value
        : fallbackTitle;

    config
      ..turnOnCameraWhenJoining = isVideoRoom
      ..turnOnMicrophoneWhenJoining = true
      ..useSpeakerWhenJoining = true
      ..enableAccidentalTouchPrevention = false
      ..duration.isVisible = true
      ..user.requiredUsers.enabled = false
      ..topMenuBar = call.ZegoCallTopMenuBarConfig(
        title: roomTitle,
        style: call.ZegoCallMenuBarStyle.dark,
        hideAutomatically: false,
        buttons: const [call.ZegoCallMenuBarButtonName.showMemberListButton],
      )
      ..bottomMenuBar = call.ZegoCallBottomMenuBarConfig(
        style: call.ZegoCallMenuBarStyle.dark,
        hideAutomatically: false,
        maxCount: 5,
        buttons: isVideoRoom
            ? const [
                call.ZegoCallMenuBarButtonName.toggleCameraButton,
                call.ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                call.ZegoCallMenuBarButtonName.switchCameraButton,
                call.ZegoCallMenuBarButtonName.switchAudioOutputButton,
                call.ZegoCallMenuBarButtonName.hangUpButton,
              ]
            : const [
                // Audio rooms use the custom concert-style control dock.
              ],
      );

    return config;
  }

  Widget _buildMainVideoBackground() {
    final userSession = Get.find<UserSessionController>();
    final rawUserId = userSession.userId.isNotEmpty
        ? userSession.userId
        : 'user_${userSession.hashCode}';
    final currentUserId = ZegoLiveIdUtils.sanitizeUserId(rawUserId);
    final currentUserName = userSession.displayName.isNotEmpty
        ? userSession.displayName
        : 'Host';

    final signalingPlugins = ZegoConfig.useSignalingPlugin
        ? [ZegoUIKitSignalingPlugin()]
        : null;

    return Obx(() {
      if (!controller.canOpenZego) {
        return Positioned.fill(child: _buildConnectionIssueState());
      }

      final liveId = controller.roomId.value;
      if (liveId.isEmpty) {
        return Positioned.fill(child: _buildConnectionIssueState());
      }

      final config = controller.isHost.value
          ? ZegoUIKitPrebuiltLiveStreamingConfig.host(plugins: signalingPlugins)
          : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
              plugins: signalingPlugins,
            );
      final isAudioVideoRoom = controller.isAudioVideoRoom;
      final isVideoRoom = controller.isVideoRoom;

      if (isAudioVideoRoom) {
        config.layout = ZegoLayout.gallery(
          margin: const EdgeInsets.fromLTRB(8, 116, 8, 120),
          addBorderRadiusAndSpacingBetweenView: true,
        );
        if (!controller.isHost.value) {
          config.role = ZegoLiveStreamingRole.coHost;
        }
      }

      // Custom overlay replaces Zego chrome — hide built-in bars.
      config.bottomMenuBar = ZegoLiveStreamingBottomMenuBarConfig(
        hostButtons: [],
        audienceButtons: [],
      );
      config.topMenuBar = ZegoLiveStreamingTopMenuBarConfig(
        showCloseButton: false,
        height: 0,
        hostAvatarBuilder: (_) => const SizedBox.shrink(),
      );
      config.memberButton = ZegoLiveStreamingMemberButtonConfig(
        builder: (_) => const SizedBox.shrink(),
      );
      config.inRoomMessage = ZegoLiveStreamingInRoomMessageConfig(
        visible: false,
      );

      // Preview page has its own "Start Live" button — our overlay covers it.
      config.preview.showPreviewForHost = false;

      if (isVideoRoom) {
        config.turnOnCameraWhenJoining =
            controller.isHost.value || isAudioVideoRoom;
        config.turnOnMicrophoneWhenJoining =
            controller.isHost.value || isAudioVideoRoom;
        config.useFrontFacingCamera = true;
      } else {
        config.turnOnCameraWhenJoining = false;
        config.turnOnMicrophoneWhenJoining =
            controller.isHost.value || isAudioVideoRoom;
        config.audioVideoView.showAvatarInAudioMode = true;
        config.audioVideoView.showSoundWavesInAudioMode = true;
      }

      return Positioned.fill(
        key: ValueKey('zego_$liveId'),
        child: ZegoUIKitPrebuiltLiveStreaming(
          appID: ZegoConfig.liveAppId,
          appSign: ZegoConfig.liveAppSign,
          userID: currentUserId,
          userName: currentUserName,
          liveID: liveId,
          config: config,
          events: ZegoUIKitPrebuiltLiveStreamingEvents(
            room: ZegoLiveStreamingRoomEvents(
              onStateChanged: (state) {
                if (state.reason == ZegoRoomStateChangedReason.Logined &&
                    state.errorCode == 0) {
                  controller.clearConnectionIssue();
                  controller.onZegoRoomLogined();
                }
              },
              onLoginFailed: (event, defaultAction) {
                // Avoid defaultAction dialog — it crashes if Obx rebuilds first.
                controller.handleZegoLoginFailed(event.errorCode);
              },
            ),
            onEnded: (event, defaultAction) {
              if (controller.isAudioVideoRoom &&
                  event.reason == ZegoLiveStreamingEndReason.hostEnd) {
                return;
              }
              controller.leaveRoom();
              defaultAction.call();
            },
          ),
        ),
      );
    });
  }

  Widget _buildAudioRoomStage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A0D64), Color(0xFF101E69), Color(0xFF0B143F)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 118, 18, 150),
          child: Obx(() {
            final participants = _audioParticipants();
            return GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: participants.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 22,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                if (index == participants.length) {
                  return _AudioRoomPlusTile(onTap: controller.openViewersSheet);
                }
                final participant = participants[index];
                return _AudioRoomParticipantTile(
                  name: participant['name']?.toString() ?? 'Member',
                  avatarUrl: participant['avatarUrl']?.toString(),
                  avatarFrameUrl: participant['avatarFrameUrl']?.toString(),
                  isHost: participant['isHost'] == true,
                  isSpeaking:
                      index == 1 || participant['isCurrentUser'] == true,
                  isMuted: participant['isHost'] != true && index != 1,
                );
              },
            );
          }),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _audioParticipants() {
    final participants = <Map<String, dynamic>>[];
    participants.add({
      'name': controller.hostName.value,
      'avatarUrl': controller.hostAvatarUrl.value,
      'avatarFrameUrl': controller.hostAvatarFrameUrl.value,
      'isHost': true,
    });

    for (final viewer in controller.liveViewers) {
      final name = viewer['name']?.toString() ?? '';
      final isHost = viewer['isHost'] == true;
      if (isHost || name.trim().isEmpty) continue;
      participants.add(Map<String, dynamic>.from(viewer));
    }

    return participants.take(11).toList();
  }

  Widget _buildConnectionIssueState() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_tethering_error_rounded,
                color: _accent,
                size: 42,
              ),
              Spacing.v12,
              const SemiBoldText(
                text: 'Unable to join live',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v8,
              Obx(
                () => AppText(
                  text: controller.connectionIssue.value,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.72),
                  align: TextAlign.center,
                ),
              ),
              Spacing.v16,
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: controller.leaveRoom,
                  style: TextButton.styleFrom(
                    backgroundColor: _accentPurple,
                    foregroundColor: kColorWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const SemiBoldText(
                    text: 'Back',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 390;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _hostSummaryCard(compact: isCompact)),
                  SizedBox(width: isCompact ? 6 : 10),
                  _topActions(compact: isCompact),
                ],
              ),
              Obx(() {
                if (!controller.isHost.value) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _hostEarningsCard(compact: isCompact),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _hostEarningsCard({bool compact = false}) {
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C1744).withValues(alpha: 0.92),
              const Color(0xFF181B45).withValues(alpha: 0.88),
            ],
          ),
          border: Border.all(color: kColorWalletAmount.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 38 : 42,
              height: compact ? 38 : 42,
              decoration: BoxDecoration(
                color: kColorWalletAmount.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kColorWalletAmount.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: kColorWalletAmount,
                size: 22,
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: 'Host earnings',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.66),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v2,
                  Row(
                    children: [
                      Flexible(
                        child: SemiBoldText(
                          text: formatLedgerAmount(
                            controller.diamondsBalance.value,
                          ),
                          fontSize: compact
                              ? TextStyles.k16FontSize
                              : TextStyles.k18FontSize,
                          color: kColorWalletAmount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacing.h4,
                      AppText(
                        text: 'diamonds',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite.withValues(alpha: 0.70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacing.h8,
            TextButton(
              onPressed: controller.openWithdrawalWallet,
              style: TextButton.styleFrom(
                minimumSize: Size(compact ? 86 : 96, compact ? 36 : 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: kColorWalletAmount,
                foregroundColor: kColorBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const SemiBoldText(
                text: 'Withdraw',
                fontSize: TextStyles.k12FontSize,
                color: kColorBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostSummaryCard({bool compact = false}) {
    return Obx(() {
      final subtitle = compact
          ? controller.likesLabel.value
          : '${controller.likesLabel.value}  •  ${controller.roomType.value}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        child: Container(
          constraints: BoxConstraints(maxWidth: compact ? 170 : 238),
          padding: EdgeInsets.all(compact ? 6 : 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FramedUserAvatar(
                    name: controller.hostName.value,
                    imageUrl: controller.hostAvatarUrl.value,
                    frameUrl: controller.hostAvatarFrameUrl.value,
                    frameSeed: controller.receiverId.value.isNotEmpty
                        ? controller.receiverId.value
                        : controller.hostName.value,
                    size: compact ? 30 : 38,
                    fontSize: compact
                        ? TextStyles.k10FontSize
                        : TextStyles.k12FontSize,
                  ),
                  Positioned(
                    right: compact ? -1 : -2,
                    bottom: compact ? -1 : 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF35F27A),
                        shape: BoxShape.circle,
                        border: Border.all(color: _surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: compact ? 7 : 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: controller.hostName.value,
                      fontSize: compact
                          ? TextStyles.k14FontSize
                          : TextStyles.k16FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v2,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: _accent, size: 14),
                        Spacing.h4,
                        Flexible(
                          child: AppText(
                            text: subtitle,
                            fontSize: compact ? 9 : TextStyles.k10FontSize,
                            color: kColorWhite.withValues(alpha: 0.72),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact && !controller.isHost.value) ...[
                Spacing.h8,
                _followButton(),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _followButton() {
    return Obx(() {
      final following = controller.isFollowingHost.value;
      return GestureDetector(
        onTap: controller.toggleFollowHost,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: following
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE12BC5), _accentPurple],
                  ),
            color: following ? Colors.white12 : null,
            border: following
                ? Border.all(color: kColorWhite.withValues(alpha: 0.2))
                : null,
          ),
          child: Icon(
            following ? Icons.check_rounded : Icons.add_rounded,
            color: kColorWhite,
            size: 22,
          ),
        ),
      );
    });
  }

  Widget _topActions({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _viewerCountPill(compact: compact),
        SizedBox(width: compact ? 5 : 8),
        _topIconButton(
          Icons.ios_share_rounded,
          compact: compact,
          onTap: controller.shareRoom,
        ),
        SizedBox(width: compact ? 5 : 8),
        _topIconButton(
          Icons.close_rounded,
          compact: compact,
          onTap: controller.leaveRoom,
        ),
      ],
    );
  }

  Widget _viewerCountPill({bool compact = false}) {
    return Obx(
      () => GestureDetector(
        onTap: controller.openViewersSheet,
        child: Container(
          height: compact ? 36 : 42,
          padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12),
          decoration: BoxDecoration(
            color: const Color(0xCC1A2233),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_rounded,
                color: kColorWhite,
                size: compact ? 17 : 20,
              ),
              SizedBox(width: compact ? 3 : 5),
              SemiBoldText(
                text: controller.viewerCount.value.toString(),
                fontSize: compact
                    ? TextStyles.k12FontSize
                    : TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topIconButton(
    IconData icon, {
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? 36 : 42,
        height: compact ? 36 : 42,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: kColorWhite, size: compact ? 19 : 22),
      ),
    );
  }

  Widget _buildChatList() {
    return SizedBox(
      height: 170,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Obx(
          () => controller.chatMessages.isEmpty
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AppText(
                      text: controller.isZegoConnected.value
                          ? 'Say hi to everyone...'
                          : 'Connecting to live room...',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.72),
                    ),
                  ),
                )
              : ListView.separated(
                  reverse: true, // Auto-scroll to bottom behavior
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: controller.chatMessages.length,
                  separatorBuilder: (_, __) => Spacing.v6,
                  itemBuilder: (_, index) {
                    // Because list is reversed, we access elements from end
                    final actualIndex =
                        controller.chatMessages.length - 1 - index;
                    final msg = controller.chatMessages[actualIndex];
                    final sender = msg['sender'] ?? '';
                    final text = msg['message'] ?? '';
                    final isSystem = msg['isSystem'] ?? false;
                    final isTranslated = msg['isTranslated'] ?? false;
                    final translation = msg['translation'] ?? '';

                    final displayMessage =
                        isTranslated && translation.isNotEmpty
                        ? translation
                        : text;

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          if (!isSystem) {
                            controller.translateMessage(actualIndex);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSystem
                                ? const Color(0xCC4E2E90)
                                : _surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: isSystem
                                ? Border.all(
                                    color: const Color(0xFF7D5BFF),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: isSystem ? '' : '$sender: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: sender == 'You'
                                              ? const Color(0xFFFF8AC0)
                                              : const Color(0xFFFF79B4),
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextSpan(
                                        text: displayMessage,
                                        style: TextStyle(
                                          color: isSystem
                                              ? Colors.amberAccent
                                              : kColorWhite,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isSystem && translation.isNotEmpty) ...[
                                Spacing.h6,
                                Icon(
                                  Icons.translate_rounded,
                                  size: 12,
                                  color: isTranslated
                                      ? kColorPrimary
                                      : Colors.white38,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller.chatTextController,
                  hintText: 'Say something...',
                  fillColor: _surface,
                  inputBorderRadius: BorderRadius.circular(24),
                  borderColor: kColorWhite.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  textStyle: TextStyles.kRegularPoppins(
                    colors: kColorWhite,
                    fontSize: 14,
                  ),
                  hintStyle: TextStyles.kRegularPoppins(
                    colors: Colors.white54,
                    fontSize: 14,
                  ),
                  suffix: _sendButton(),
                ),
              ),
              Spacing.h10,
              Obx(
                () => _bottomActionIcon(
                  controller.isMicMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  active: !controller.isMicMuted.value,
                  onTap: controller.toggleMic,
                ),
              ),
              if (controller.isHost.value && controller.isVideoRoom) ...[
                Spacing.h8,
                Obx(
                  () => _bottomActionIcon(
                    controller.isCameraOff.value
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    active: !controller.isCameraOff.value,
                    onTap: controller.toggleCamera,
                  ),
                ),
              ],
              if (controller.canSendGifts) ...[
                Spacing.h8,
                _bottomActionIcon(
                  Icons.card_giftcard_rounded,
                  color: _accent,
                  onTap: controller.openGiftsSheet,
                ),
              ],
              Spacing.h8,
              _bottomActionIcon(
                Icons.more_horiz_rounded,
                onTap: () {
                  Get.bottomSheet(
                    RoomOptionsSheet(
                      isHost: controller.isHost.value,
                      isVideoRoom: controller.isVideoRoom,
                    ),
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ],
          ),
          Spacing.v10,
          Row(children: [const Spacer(), _bottomViewerStrip(context)]),
        ],
      ),
    );
  }

  Widget _sendButton() {
    return IconButton(
      icon: const Icon(Icons.send_rounded, color: kColorWhite, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: controller.sendMessage,
    );
  }

  Widget _bottomActionIcon(
    IconData icon, {
    Color? color,
    bool active = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: active ? _surface : const Color(0xCC351D2B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: color ?? kColorWhite, size: 24),
      ),
    );
  }

  Widget _bottomViewerStrip(BuildContext context) {
    return Obx(() {
      final viewers = controller.liveViewers.toList();
      final chatViewers = viewers
          .where((viewer) => viewer['isCurrentUser'] != true)
          .take(4)
          .toList();
      final visibleViewers = chatViewers.isNotEmpty
          ? chatViewers
          : viewers.take(3).toList();

      if (visibleViewers.isEmpty) {
        return GestureDetector(
          onTap: controller.openViewersSheet,
          child: _ViewerOvalShell(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  color: kColorWhite.withValues(alpha: 0.86),
                  size: 18,
                ),
                Spacing.h6,
                const SemiBoldText(
                  text: 'Viewers',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                ),
              ],
            ),
          ),
        );
      }

      return _ViewerOvalShell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < visibleViewers.length; index++) ...[
              _ViewerAvatarButton(
                viewer: visibleViewers[index],
                onTap: () {
                  final viewer = visibleViewers[index];
                  if (viewer['isCurrentUser'] == true) {
                    controller.openViewersSheet();
                    return;
                  }
                  controller.openChatWithViewer(context, viewer);
                },
              ),
              if (index != visibleViewers.length - 1) Spacing.h6,
            ],
            if (controller.liveViewers.length > visibleViewers.length) ...[
              Spacing.h8,
              GestureDetector(
                onTap: controller.openViewersSheet,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kColorWhite.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SemiBoldText(
                    text:
                        '+${controller.liveViewers.length - visibleViewers.length}',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ViewerOvalShell extends StatelessWidget {
  const _ViewerOvalShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD9141B29),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ViewerAvatarButton extends StatelessWidget {
  const _ViewerAvatarButton({required this.viewer, required this.onTap});

  final Map<String, dynamic> viewer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = viewer['name']?.toString().trim().isNotEmpty == true
        ? viewer['name'].toString()
        : 'Viewer';
    final avatarUrl = viewer['avatarUrl']?.toString();

    return GestureDetector(
      onTap: onTap,
      child: AppUserAvatar(
        name: name,
        imageUrl: avatarUrl,
        size: 32,
        fontSize: TextStyles.k10FontSize,
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.70),
          width: 1.5,
        ),
      ),
    );
  }
}

class _LiveOverlayScrim extends StatelessWidget {
  const _LiveOverlayScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.42),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.58),
            ],
            stops: const [0, 0.22, 0.56, 1],
          ),
        ),
      ),
    );
  }
}

class _AudioRoomParticipantTile extends StatelessWidget {
  const _AudioRoomParticipantTile({
    required this.name,
    required this.avatarUrl,
    this.avatarFrameUrl,
    required this.isHost,
    required this.isSpeaking,
    required this.isMuted,
  });

  final String name;
  final String? avatarUrl;
  final String? avatarFrameUrl;
  final bool isHost;
  final bool isSpeaking;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isSpeaking
        ? const Color(0xFF14D96B)
        : const Color(0xFF8E1B85);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: FramedUserAvatar(
                name: name,
                imageUrl: avatarUrl,
                frameUrl: avatarFrameUrl,
                frameSeed: name,
                size: 52,
              ),
            ),
            Positioned(
              right: 2,
              bottom: -2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF20104A), width: 2),
                ),
                child: Icon(
                  isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: kColorWhite,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        Spacing.v8,
        SemiBoldText(
          text: name,
          fontSize: TextStyles.k12FontSize,
          color: isSpeaking ? const Color(0xFF12F287) : kColorWhite,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
        Spacing.v2,
        AppText(
          text: isHost
              ? 'Host'
              : isSpeaking
              ? 'Speaking'
              : 'Member Listen...',
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.68),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
      ],
    );
  }
}

class _AudioRoomPlusTile extends StatelessWidget {
  const _AudioRoomPlusTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
            ),
            child: const Icon(Icons.add_rounded, color: kColorWhite, size: 34),
          ),
          Spacing.v8,
          const SemiBoldText(
            text: 'Invite',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v2,
          AppText(
            text: 'Add member',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.68),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
