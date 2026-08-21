import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/zego_config.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/session_earnings_badge.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/live_heart_reaction_overlay.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_express_engine/zego_express_engine.dart' as express;
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart' as call;
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../controllers/live_broadcast_controller.dart';
import '../widgets/audio_room_stage_overlay.dart';
import '../widgets/live_room_pk_stage_slot.dart';
import '../widgets/room_options_sheet.dart';

class LiveBroadcastView extends GetView<LiveBroadcastController> {
  const LiveBroadcastView({super.key});

  static const Color _surface = Color(0xE6121720);
  static const Color _surfaceSoft = Color(0xB3121720);
  static const Color _accent = Color(0xFFFF3F7F);
  static const Color _accentPurple = Color(0xFF8E1B85);

  @override
  Widget build(BuildContext context) {
    _ensureZegoScreenUtil(context);
    if (controller.isAudioVideoRoom) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildGroupCallRoom(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final pkActive = controller.isInRoomPkActive;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Keep Zego live engine mounted; hide full-screen host feed during PK.
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: pkActive,
                    child: Opacity(
                      opacity: pkActive ? 0 : 1,
                      child: _buildMainVideoBackground(),
                    ),
                  ),
                ),
                if (pkActive)
                  const Positioned.fill(child: LiveRoomPkBattleBackdrop()),
              ],
            );
          }),
          Obx(() {
            if (controller.isVideoRoom || !controller.canOpenZego) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(child: _buildAudioRoomStage());
          }),
          Obx(() {
            if (controller.isInRoomPkActive) {
              return const SizedBox.shrink();
            }
            return const Positioned.fill(child: _LiveOverlayScrim());
          }),
          if (controller.isLiveStreamingSession)
            Positioned.fill(child: LiveHeartReactionLayer()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(),
                Expanded(
                  child: LiveRoomPkStageSlot(minHeight: 260, maxHeightCap: 520),
                ),
                _buildChatList(),
                _buildBottomControls(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _ensureZegoScreenUtil(BuildContext context) {
    if (MediaQuery.maybeOf(context) == null) return;
    try {
      final _ = ZegoScreenUtil().screenWidth;
    } catch (_) {
      try {
        ZegoScreenUtil.init(context);
      } catch (_) {}
    }
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

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _StableZegoGroupCall(
            userId: currentUserId,
            userName: currentUserName,
            isVideoRoom: controller.isVideoRoom,
            shouldReportExit: _shouldReportGroupCallExit,
            configBuilder: _buildGroupCallConfig,
          ),
        ),
        // Audio + video party rooms share the same seat grid overlay
        // (host on seat 1, empty seats, invite / request / floor strip).
        const Positioned.fill(child: AudioRoomStageOverlay()),
        Obx(() {
          final canOpenCall =
              controller.canOpenZego && controller.roomId.value.isNotEmpty;
          if (canOpenCall) return const SizedBox.shrink();
          if (controller.isVideoRoom) {
            return Positioned.fill(child: _buildConnectionIssueState());
          }
          return _buildAudioRoomConnectionBanner();
        }),
      ],
    );
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
      ..duration.isVisible = false
      ..user.requiredUsers.enabled = false
      // Hide Zego's default stacked gallery — we render seats ourselves.
      ..audioVideoView.containerBuilder = _buildHiddenPartyRoomVideoContainer
      ..audioVideoView.showUserNameOnView = false
      ..audioVideoView.showMicrophoneStateOnView = false
      ..audioVideoView.showCameraStateOnView = false
      ..topMenuBar = call.ZegoCallTopMenuBarConfig(
        title: roomTitle,
        style: call.ZegoCallMenuBarStyle.dark,
        hideAutomatically: true,
        isVisible: false,
        buttons: const [],
      )
      ..bottomMenuBar = call.ZegoCallBottomMenuBarConfig(
        style: call.ZegoCallMenuBarStyle.dark,
        hideAutomatically: true,
        isVisible: false,
        maxCount: 5,
        // Custom AudioRoomStageOverlay owns mic / cam / gift / leave.
        buttons: const [],
      );

    return config;
  }

  /// Keeps the Zego call engine running while our seat grid shows video tiles.
  Widget? _buildHiddenPartyRoomVideoContainer(
    BuildContext context,
    List<ZegoUIKitUser> allUsers,
    List<ZegoUIKitUser> audioVideoUsers,
    ZegoAudioVideoView Function(ZegoUIKitUser) audioVideoViewCreator,
  ) {
    return const SizedBox.shrink();
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
    final liveId = controller.liveZegoRoomId.trim();
    final zegoAppId = controller.liveZegoAppId;
    final zegoAppSign = controller.liveZegoAppSign;
    final zegoToken = controller.liveZegoToken;
    final publishStreamId = controller.livePublishStreamId;
    final playStreamId = controller.livePlayStreamId;
    final liveSessionKey = ValueKey(
      [
        'zego_live_engine',
        controller.isLiveStreamingSession ? 'live' : 'room',
        controller.isHost.value ? 'host' : 'audience',
        zegoAppId,
        currentUserId,
        liveId,
        controller.isHost.value ? publishStreamId : playStreamId,
      ].join('_'),
    );

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller.isLiveStreamingSession)
            _StableZegoExpressLiveStreaming(
              key: liveSessionKey,
              userId: currentUserId,
              userName: currentUserName,
              liveId: liveId,
              appId: zegoAppId,
              appSign: zegoAppSign,
              token: zegoToken,
              isHost: controller.isHost.value,
              publishStreamId: publishStreamId,
              playStreamId: playStreamId,
              hostName: controller.hostName.value,
              hostAvatarUrl: controller.hostAvatarUrl.value,
            )
          else
            _StableZegoLiveStreaming(
              key: liveSessionKey,
              userId: currentUserId,
              userName: currentUserName,
              liveId: liveId,
              appId: zegoAppId,
              appSign: zegoAppSign,
              isHost: controller.isHost.value,
              isAudioVideoRoom: controller.isAudioVideoRoom,
              isVideoRoom: controller.isVideoRoom,
              isLiveStreamingSession: controller.isLiveStreamingSession,
              hostName: controller.hostName.value,
              hostAvatarUrl: controller.hostAvatarUrl.value,
            ),
          // Live stream video is rendered inside Zego's containerBuilder.
          // Do not overlay LiveHostVideoFill — that hid the real stream (black).
          Obx(() {
            if (!controller.canOpenZego || liveId.isEmpty) {
              return Positioned.fill(child: _buildConnectionIssueState());
            }
            if (controller.isZegoConnected.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: _LiveConnectingCover(
                name: controller.hostName.value,
                avatarUrl: controller.hostAvatarUrl.value,
              ),
            );
          }),
        ],
      ),
    );
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
          final earningsMaxWidth = (constraints.maxWidth * 0.17).clamp(
            52.0,
            isCompact ? 64.0 : 72.0,
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _hostSummaryCard(compact: isCompact)),
              SizedBox(width: isCompact ? 6 : 10),
              _topActions(
                compact: isCompact,
                earningsMaxWidth: earningsMaxWidth,
              ),
            ],
          );
        },
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

  Widget _topActions({bool compact = false, double? earningsMaxWidth}) {
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
        Padding(
          padding: EdgeInsets.only(left: compact ? 5 : 8),
          child: Obx(
            () => SessionEarningsBadge(
              key: controller.sessionEarningsBadgeKey,
              tracker: controller.sessionEarnings,
              compact: compact,
              maxWidth: earningsMaxWidth,
              iconColor: const Color(0xFFFFA10A),
              onTap: controller.isHost.value
                  ? controller.openSessionEarningsDialog
                  : null,
            ),
          ),
        ),
        SizedBox(width: compact ? 5 : 8),
        // Host: end stream (power). Audience on live: close → listing.
        Obx(() {
          final isLiveAudience =
              controller.isLiveStreamingSession && !controller.isHost.value;
          if (isLiveAudience) {
            return _topIconButton(
              Icons.close_rounded,
              compact: compact,
              onTap: controller.leaveRoom,
            );
          }
          return _topIconButton(
            Icons.power_settings_new_rounded,
            compact: compact,
            iconColor: const Color(0xFFFF3B5C),
            onTap: controller.leaveRoom,
          );
        }),
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
    Color iconColor = kColorWhite,
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
        child: Icon(icon, color: iconColor, size: compact ? 19 : 22),
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
    final isLive = controller.isLiveStreamingSession;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            _buildChatInputField(),
            Spacing.v8,
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _liveStreamActionButtons(context, compact: true),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(child: _buildChatInputField()),
                Spacing.h10,
                ..._partyRoomActionButtons(context),
              ],
            ),
          Spacing.v10,
          Row(children: [const Spacer(), _bottomViewerStrip(context)]),
        ],
      ),
    );
  }

  Widget _buildChatInputField() {
    return AppTextField(
      controller: controller.chatTextController,
      hintText: 'Say something...',
      fillColor: _surface,
      inputBorderRadius: BorderRadius.circular(24),
      borderColor: kColorWhite.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      textStyle: TextStyles.kRegularPoppins(colors: kColorWhite, fontSize: 14),
      hintStyle: TextStyles.kRegularPoppins(
        colors: Colors.white54,
        fontSize: 14,
      ),
      suffix: _sendButton(),
    );
  }

  List<Widget> _liveStreamActionButtons(
    BuildContext context, {
    required bool compact,
  }) {
    return [
      Obx(
        () => _bottomActionIcon(
          controller.isMicMuted.value
              ? Icons.mic_off_rounded
              : Icons.mic_rounded,
          active: !controller.isMicMuted.value,
          compact: compact,
          onTap: controller.toggleMic,
        ),
      ),
      _bottomActionIcon(
        Icons.favorite_rounded,
        color: LiveHeartReactionLayer.whatsAppHeartGreen,
        compact: compact,
        onTap: controller.triggerHeartReaction,
      ),
      if (controller.isHost.value)
        Obx(
          () => _bottomActionIcon(
            controller.isCameraOff.value
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            active: !controller.isCameraOff.value,
            compact: compact,
            onTap: controller.toggleCamera,
          ),
        ),
      if (controller.isHost.value && !controller.isInRoomPkActive)
        _bottomActionIcon(
          Icons.flash_on_rounded,
          color: const Color(0xFFFFC857),
          compact: compact,
          onTap: controller.openPkV1Arena,
        ),
      if (!(controller.isInRoomPkActive && controller.isHost.value))
        _bottomActionIcon(
          kGiftIcon,
          color: _accent,
          compact: compact,
          onTap: controller.openGiftsSheet,
        ),
      _bottomActionIcon(
        Icons.more_horiz_rounded,
        compact: compact,
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
    ];
  }

  List<Widget> _partyRoomActionButtons(BuildContext context) {
    return [
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
      Obx(() {
        if (!controller.isHost.value || controller.isInRoomPkActive) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacing.h8,
            _bottomActionIcon(
              Icons.flash_on_rounded,
              color: const Color(0xFFFFC857),
              onTap: controller.openPkV1Arena,
            ),
          ],
        );
      }),
      Obx(() {
        if (controller.isInRoomPkActive && controller.isHost.value) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Spacing.h8,
            _bottomActionIcon(
              kGiftIcon,
              color: _accent,
              onTap: controller.openGiftsSheet,
            ),
          ],
        );
      }),
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
    ];
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
    bool compact = false,
    VoidCallback? onTap,
  }) {
    final size = compact ? 42.0 : 50.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? _surface : const Color(0xCC351D2B),
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: color ?? kColorWhite, size: compact ? 22 : 24),
      ),
    );
  }

  Widget _bottomViewerStrip(BuildContext context) {
    return Obx(() {
      final viewers = controller.liveViewers
          .where((viewer) => viewer['isHost'] != true)
          .toList();
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

/// Mounts PrebuiltCall once so Obx rebuilds (login, titles, banners) cannot
/// dispose the native engine and leave a black canvas.
class _StableZegoGroupCall extends StatefulWidget {
  const _StableZegoGroupCall({
    required this.userId,
    required this.userName,
    required this.isVideoRoom,
    required this.shouldReportExit,
    required this.configBuilder,
  });

  final String userId;
  final String userName;
  final bool isVideoRoom;
  final bool Function(call.ZegoCallEndReason reason) shouldReportExit;
  final call.ZegoUIKitPrebuiltCallConfig Function(bool isVideoRoom)
  configBuilder;

  @override
  State<_StableZegoGroupCall> createState() => _StableZegoGroupCallState();
}

class _StableZegoGroupCallState extends State<_StableZegoGroupCall> {
  Widget? _engine;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      final conferenceId = controller.roomId.value;
      final canOpen = controller.canOpenZego && conferenceId.isNotEmpty;
      if (_engine == null && canOpen) {
        _engine = call.ZegoUIKitPrebuiltCall(
          key: ValueKey('group_call_$conferenceId'),
          appID: ZegoConfig.roomAppId,
          appSign: ZegoConfig.roomAppSign,
          userID: widget.userId,
          userName: widget.userName,
          callID: conferenceId,
          config: widget.configBuilder(widget.isVideoRoom),
          events: call.ZegoUIKitPrebuiltCallEvents(
            onError: controller.handleGroupCallRoomError,
            room: call.ZegoCallRoomEvents(
              onStateChanged: (state) {
                if (state.reason == ZegoRoomStateChangedReason.Logined ||
                    state.reason == ZegoRoomStateChangedReason.Reconnected) {
                  controller.onGroupCallRoomConnected();
                } else if (state.reason ==
                    ZegoRoomStateChangedReason.LoginFailed) {
                  controller.handleGroupCallRoomLoginFailed(state.errorCode);
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
              if (!controller.canProcessGroupCallEnd) return;
              if (widget.shouldReportExit(event.reason)) {
                controller.reportRoomExit();
              }
              defaultAction.call();
            },
          ),
        );
      }
      return _engine ?? const ColoredBox(color: Colors.black);
    });
  }
}

/// Standalone live streaming renderer backed by Zego Express.
///
/// Live streams use backend-issued `zegoStreaming` payloads:
/// roomId + token + publish/play stream IDs. Keeping this separate from the
/// audio/video room prebuilt widgets prevents room APIs/roles from leaking into
/// the one-to-many live flow.
class _StableZegoExpressLiveStreaming extends StatefulWidget {
  const _StableZegoExpressLiveStreaming({
    super.key,
    required this.userId,
    required this.userName,
    required this.liveId,
    required this.appId,
    required this.appSign,
    required this.token,
    required this.isHost,
    required this.publishStreamId,
    required this.playStreamId,
    required this.hostName,
    this.hostAvatarUrl,
  });

  final String userId;
  final String userName;
  final String liveId;
  final int appId;
  final String appSign;
  final String token;
  final bool isHost;
  final String publishStreamId;
  final String playStreamId;
  final String hostName;
  final String? hostAvatarUrl;

  @override
  State<_StableZegoExpressLiveStreaming> createState() =>
      _StableZegoExpressLiveStreamingState();
}

class _StableZegoExpressLiveStreamingState
    extends State<_StableZegoExpressLiveStreaming> {
  Widget? _canvasView;
  int? _canvasViewId;
  var _starting = false;
  var _loggedIn = false;
  var _mediaStarted = false;
  String? _activePlayStreamId;
  String _status = 'Connecting live stream...';

  LiveBroadcastController get _controller =>
      Get.find<LiveBroadcastController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  @override
  void didUpdateWidget(covariant _StableZegoExpressLiveStreaming oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.liveId != widget.liveId ||
        oldWidget.appId != widget.appId ||
        oldWidget.appSign != widget.appSign ||
        oldWidget.token != widget.token ||
        oldWidget.userId != widget.userId ||
        oldWidget.isHost != widget.isHost ||
        oldWidget.publishStreamId != widget.publishStreamId ||
        oldWidget.playStreamId != widget.playStreamId;
    if (changed) {
      unawaited(_restart());
    }
  }

  @override
  void dispose() {
    unawaited(_stop());
    super.dispose();
  }

  Future<void> _restart() async {
    await _stop();
    if (mounted) {
      setState(() {
        _canvasView = null;
        _canvasViewId = null;
        _mediaStarted = false;
        _status = 'Connecting live stream...';
      });
    }
    await _start();
  }

  Future<void> _start() async {
    if (_starting || !mounted) return;
    _starting = true;

    final roomId = widget.liveId.trim();
    final publishStream = widget.publishStreamId.trim();
    final playStream = widget.playStreamId.trim();

    if (roomId.isEmpty) {
      _fail('Live room id is missing.');
      return;
    }
    if (widget.isHost && publishStream.isEmpty) {
      _fail('Live publish stream id is missing.');
      return;
    }
    if (!widget.isHost && playStream.isEmpty) {
      _fail('Live play stream id is missing.');
      return;
    }

    try {
      _controller.isZegoConnected.value = false;
      _bindExpressCallbacks();

      final profile = express.ZegoEngineProfile(
        widget.appId,
        express.ZegoScenario.Broadcast,
        appSign: widget.appSign.trim().isEmpty ? null : widget.appSign.trim(),
        enablePlatformView: false,
      );
      await express.ZegoExpressEngine.createEngineWithProfile(profile);

      final roomConfig = express.ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true;
      final token = widget.token.trim();
      if (token.isNotEmpty) {
        roomConfig.token = token;
      }

      final result = await express.ZegoExpressEngine.instance.loginRoom(
        roomId,
        express.ZegoUser(widget.userId, widget.userName),
        config: roomConfig,
      );
      if (result.errorCode != 0) {
        _fail('Zego room login failed (${result.errorCode}).');
        return;
      }

      _loggedIn = true;
      _controller.onExpressLiveRoomLogined();

      final view = await express.ZegoExpressEngine.instance.createCanvasView((
        viewId,
      ) {
        _canvasViewId = viewId;
        unawaited(_startMedia(viewId));
      });

      if (!mounted) return;
      setState(() {
        _canvasView = view;
        _status = widget.isHost
            ? 'Starting camera...'
            : 'Opening host video...';
      });
    } catch (error) {
      _fail('Unable to open live stream: $error');
    } finally {
      _starting = false;
    }
  }

  Future<void> _startMedia(int viewId) async {
    if (!mounted) return;
    try {
      final canvas = express.ZegoCanvas.view(viewId)
        ..viewMode = express.ZegoViewMode.AspectFill;

      if (widget.isHost) {
        await express.ZegoExpressEngine.instance.enableCamera(true);
        await express.ZegoExpressEngine.instance.muteMicrophone(false);
        await express.ZegoExpressEngine.instance.useFrontCamera(true);
        await express.ZegoExpressEngine.instance.startPreview(canvas: canvas);
        await express.ZegoExpressEngine.instance.startPublishingStream(
          widget.publishStreamId.trim(),
        );
      } else {
        final streamId = widget.playStreamId.trim();
        _activePlayStreamId = streamId;
        await express.ZegoExpressEngine.instance.startPlayingStream(
          streamId,
          canvas: canvas,
        );
      }
    } catch (error) {
      _fail('Unable to attach live video: $error');
    }
  }

  void _bindExpressCallbacks() {
    express.ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
          if (roomID != widget.liveId) return;
          if (errorCode != 0) {
            _controller.onExpressLiveRoomDisconnected(
              'Live room connection failed ($errorCode).',
            );
          } else if (_loggedIn) {
            _controller.onExpressLiveRoomLogined();
          }
        };

    express.ZegoExpressEngine.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
          if (streamID != widget.publishStreamId.trim()) return;
          if (!mounted) return;
          if (state == express.ZegoPublisherState.Publishing) {
            setState(() {
              _mediaStarted = true;
              _status = 'Live';
            });
            _controller.onExpressLiveRoomLogined();
          } else if (errorCode != 0) {
            _fail('Publishing failed ($errorCode).');
          } else {
            setState(() => _status = 'Starting broadcast...');
          }
        };

    express.ZegoExpressEngine.onPlayerStateUpdate =
        (streamID, state, errorCode, extendedData) {
          if (streamID != _activePlayStreamId) return;
          if (!mounted) return;
          if (state == express.ZegoPlayerState.Playing) {
            setState(() {
              _mediaStarted = true;
              _status = 'Live';
            });
            _controller.onExpressLiveRoomLogined();
          } else if (errorCode != 0) {
            _fail('Playback failed ($errorCode).');
          } else {
            setState(() => _status = 'Waiting for host video...');
          }
        };

    express.ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, streamList, extendedData) {
          if (widget.isHost || roomID != widget.liveId) return;
          if (updateType != express.ZegoUpdateType.Add) return;
          final viewId = _canvasViewId;
          if (viewId == null) return;

          final expected = widget.playStreamId.trim();
          final stream = streamList
              .map((item) => item.streamID.trim())
              .firstWhere(
                (id) => expected.isEmpty || id == expected,
                orElse: () => '',
              );
          if (stream.isEmpty) return;

          _activePlayStreamId = stream;
          final canvas = express.ZegoCanvas.view(viewId)
            ..viewMode = express.ZegoViewMode.AspectFill;
          unawaited(
            express.ZegoExpressEngine.instance.startPlayingStream(
              stream,
              canvas: canvas,
            ),
          );
        };

    express.ZegoExpressEngine.onIMRecvBroadcastMessage = (roomID, messageList) {
      if (roomID != widget.liveId) return;
      _controller.receiveExpressLiveMessages(messageList);
    };
  }

  Future<void> _stop() async {
    try {
      if (widget.isHost) {
        await express.ZegoExpressEngine.instance.stopPublishingStream();
        await express.ZegoExpressEngine.instance.stopPreview();
      } else {
        final streamId = _activePlayStreamId ?? widget.playStreamId.trim();
        if (streamId.isNotEmpty) {
          await express.ZegoExpressEngine.instance.stopPlayingStream(streamId);
        }
      }
    } catch (_) {}

    try {
      if (_loggedIn && widget.liveId.trim().isNotEmpty) {
        await express.ZegoExpressEngine.instance.logoutRoom(
          widget.liveId.trim(),
        );
      }
    } catch (_) {}

    final viewId = _canvasViewId;
    if (viewId != null) {
      try {
        await express.ZegoExpressEngine.instance.destroyCanvasView(viewId);
      } catch (_) {}
    }

    _loggedIn = false;
    _mediaStarted = false;
    _activePlayStreamId = null;
    express.ZegoExpressEngine.onRoomStateUpdate = null;
    express.ZegoExpressEngine.onPublisherStateUpdate = null;
    express.ZegoExpressEngine.onPlayerStateUpdate = null;
    express.ZegoExpressEngine.onRoomStreamUpdate = null;
    express.ZegoExpressEngine.onIMRecvBroadcastMessage = null;

    try {
      await express.ZegoExpressEngine.destroyEngine();
    } catch (_) {}
  }

  void _fail(String message) {
    _starting = false;
    _controller.onExpressLiveRoomDisconnected(message);
    if (!mounted) return;
    setState(() => _status = message);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: const Color(0xFF0B0714), child: _canvasView),
        if (!_mediaStarted)
          Positioned.fill(
            child: _LiveConnectingCover(
              name: widget.hostName,
              avatarUrl: widget.hostAvatarUrl,
            ),
          ),
        if (!_mediaStarted)
          Positioned(
            left: 20,
            right: 20,
            bottom: 150,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: kColorWhite.withValues(alpha: 0.08),
                    ),
                  ),
                  child: AppText(
                    text: _status,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.86),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mounts PrebuiltLiveStreaming once. Login/wallet Obx rebuilds used to recreate
/// the widget (new config + signaling plugin) and tear down the camera.
class _StableZegoLiveStreaming extends StatefulWidget {
  const _StableZegoLiveStreaming({
    super.key,
    required this.userId,
    required this.userName,
    required this.liveId,
    required this.appId,
    required this.appSign,
    required this.isHost,
    required this.isAudioVideoRoom,
    required this.isVideoRoom,
    required this.isLiveStreamingSession,
    required this.hostName,
    this.hostAvatarUrl,
  });

  final String userId;
  final String userName;
  final String liveId;
  final int appId;
  final String appSign;
  final bool isHost;
  final bool isAudioVideoRoom;
  final bool isVideoRoom;
  final bool isLiveStreamingSession;
  final String hostName;
  final String? hostAvatarUrl;

  @override
  State<_StableZegoLiveStreaming> createState() =>
      _StableZegoLiveStreamingState();
}

class _StableZegoLiveStreamingState extends State<_StableZegoLiveStreaming> {
  Widget? _engine;

  @override
  void didUpdateWidget(covariant _StableZegoLiveStreaming oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mustRemount =
        oldWidget.liveId != widget.liveId ||
        oldWidget.appId != widget.appId ||
        oldWidget.appSign != widget.appSign ||
        oldWidget.userId != widget.userId ||
        oldWidget.isHost != widget.isHost ||
        oldWidget.isAudioVideoRoom != widget.isAudioVideoRoom ||
        oldWidget.isLiveStreamingSession != widget.isLiveStreamingSession;
    if (mustRemount) {
      // Zego's prebuilt widget owns engine state internally. If a user joins a
      // live from another path while this route is alive, remount the engine so
      // audience devices attach to the current liveID instead of a stale room.
      _engine = null;
    }
  }

  ZegoUIKitPrebuiltLiveStreamingConfig _buildConfig() {
    final signalingPlugins = ZegoConfig.useSignalingPlugin
        ? [ZegoUIKitSignalingPlugin()]
        : null;
    final config = widget.isHost
        ? ZegoUIKitPrebuiltLiveStreamingConfig.host(plugins: signalingPlugins)
        : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
            plugins: signalingPlugins,
          );

    if (widget.isAudioVideoRoom) {
      config.layout = ZegoLayout.gallery(
        margin: const EdgeInsets.fromLTRB(8, 116, 8, 120),
        addBorderRadiusAndSpacingBetweenView: true,
      );
      if (!widget.isHost) {
        config.role = ZegoLiveStreamingRole.coHost;
      }
    }

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
    config.inRoomMessage = ZegoLiveStreamingInRoomMessageConfig(visible: false);
    config.preview.showPreviewForHost = false;
    config.showBackgroundTips = false;
    config.background = const ColoredBox(color: Colors.transparent);
    config.duration.isVisible = false;
    config.pip.enableWhenBackground = false;
    config.audioVideoView.showAvatarInAudioMode = true;
    config.audioVideoView.showSoundWavesInAudioMode = true;
    config.audioVideoView.useVideoViewAspectFill = true;
    config.audioVideoView.backgroundBuilder = (context, size, user, extraInfo) {
      return ColoredBox(
        color: const Color(0xFF12081C),
        child: Center(
          child: AppUserAvatar(
            name: widget.hostName,
            imageUrl: widget.hostAvatarUrl,
            size: size.shortestSide * 0.28,
          ),
        ),
      );
    };

    if (widget.isLiveStreamingSession) {
      // Instagram-style: one host feed — no co-host / audience camera tiles.
      config.coHost.maxCoHostCount = 0;
      config.coHost.turnOnCameraWhenCohosted = () => false;
      config.audioVideoView.playCoHostVideo = (_, __, ___) => false;
      config.audioVideoView.playCoHostAudio = (_, __, ___) => false;
      config.audioVideoView.visible =
          (localUser, localRole, targetUser, targetUserRole) {
            return targetUserRole == ZegoLiveStreamingRole.host;
          };
      // Critical: never return SizedBox.shrink() here — that kills playback and
      // leaves a black canvas. Use Zego's view creator so the stream attaches.
      config.audioVideoView.containerBuilder =
          (context, allUsers, audioVideoUsers, audioVideoViewCreator) {
            return _LiveStreamHostFill(
              isHost: widget.isHost,
              localUserId: widget.userId,
              hostName: widget.hostName,
              hostAvatarUrl: widget.hostAvatarUrl,
              audioVideoUsers: audioVideoUsers,
              audioVideoViewCreator: audioVideoViewCreator,
            );
          };
    } else if (!widget.isAudioVideoRoom) {
      config.layout = ZegoLayout.gallery(
        margin: EdgeInsets.zero,
        addBorderRadiusAndSpacingBetweenView: false,
      );
    }

    if (widget.isLiveStreamingSession) {
      config.turnOnCameraWhenJoining = widget.isHost;
      config.turnOnMicrophoneWhenJoining = widget.isHost;
      config.useFrontFacingCamera = true;
    } else if (widget.isVideoRoom) {
      config.turnOnCameraWhenJoining = widget.isHost || widget.isAudioVideoRoom;
      config.turnOnMicrophoneWhenJoining =
          widget.isHost || widget.isAudioVideoRoom;
      config.useFrontFacingCamera = true;
    } else {
      config.turnOnCameraWhenJoining = false;
      config.turnOnMicrophoneWhenJoining =
          widget.isHost || widget.isAudioVideoRoom;
    }

    return config;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveBroadcastController>();
    return Obx(() {
      final liveId = widget.liveId;
      final canOpen = controller.canOpenZego && liveId.isNotEmpty;
      if (_engine == null && canOpen) {
        _engine = ZegoUIKitPrebuiltLiveStreaming(
          key: ValueKey('zego_$liveId'),
          appID: widget.appId,
          appSign: widget.appSign,
          userID: widget.userId,
          userName: widget.userName,
          liveID: liveId,
          config: _buildConfig(),
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
        );
      }
      return _engine ?? const ColoredBox(color: Color(0xFF0B0714));
    });
  }
}

class _LiveConnectingCover extends StatefulWidget {
  const _LiveConnectingCover({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  State<_LiveConnectingCover> createState() => _LiveConnectingCoverState();
}

class _LiveConnectingCoverState extends State<_LiveConnectingCover> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) return const SizedBox.shrink();
    return IgnorePointer(
      child: ColoredBox(
        color: const Color(0xFF0B0714),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppUserAvatar(
                name: widget.name,
                imageUrl: widget.avatarUrl,
                size: 96,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                color: Color(0xFFFF3F7F),
                strokeWidth: 2.4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-bleed host camera using Zego's [audioVideoViewCreator] so the stream
/// actually attaches (unlike a blank [SizedBox.shrink] container).
class _LiveStreamHostFill extends StatelessWidget {
  const _LiveStreamHostFill({
    required this.isHost,
    required this.localUserId,
    required this.hostName,
    required this.audioVideoUsers,
    required this.audioVideoViewCreator,
    this.hostAvatarUrl,
  });

  final bool isHost;
  final String localUserId;
  final String hostName;
  final String? hostAvatarUrl;
  final List<ZegoUIKitUser> audioVideoUsers;
  final ZegoAudioVideoView Function(ZegoUIKitUser) audioVideoViewCreator;

  ZegoUIKitUser? _resolveFocusUser() {
    final local = ZegoLiveIdUtils.sanitizeUserId(localUserId);

    if (isHost) {
      for (final user in audioVideoUsers) {
        if (ZegoLiveIdUtils.sanitizeUserId(user.id) == local) return user;
      }
      try {
        final me = ZegoUIKit().getLocalUser();
        if (!me.isEmpty()) return me;
      } catch (_) {}
      return null;
    }

    for (final user in audioVideoUsers) {
      if (ZegoLiveIdUtils.sanitizeUserId(user.id) == local) continue;
      return user;
    }
    // Audience devices must wait for the host to appear in Zego's media list.
    // Rendering a user that is only in the member list can produce a black
    // texture before the host camera stream has actually attached.
    return null;
  }

  Widget _waiting() {
    return ColoredBox(
      color: const Color(0xFF12081C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppUserAvatar(name: hostName, imageUrl: hostAvatarUrl, size: 96),
            const SizedBox(height: 14),
            Text(
              isHost ? 'Starting camera…' : 'Waiting for host video…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focus = _resolveFocusUser();
    if (focus == null || focus.isEmpty()) {
      return _waiting();
    }
    return SizedBox.expand(child: audioVideoViewCreator(focus));
  }
}
