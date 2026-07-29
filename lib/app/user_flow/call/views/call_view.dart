import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/widgets/common_live_room_widget.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/call_controller.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  static const _accent = Color(0xFF9B1F7A);
  static const _accentSoft = Color(0xFFF8E8F3);
  static const _waGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F8),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _glowBlob(const Color(0xFFFF6BB5), 220),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _glowBlob(const Color(0xFF7B61FF), 180),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                  child: _buildHubTabs(),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.hubTab.value == 3) {
                      return _buildCallsTab(context);
                    }
                    return _buildRoomsTab();
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          _glassIconButton(Icons.arrow_back_ios_new_rounded, Get.back),
          const Expanded(
            child: Center(
              child: BoldText(
                text: 'Qobo Call',
                fontSize: TextStyles.k22FontSize,
                color: kColorText,
              ),
            ),
          ),
          Obx(() {
            if (controller.hubTab.value != 3) {
              return const SizedBox(width: 46, height: 46);
            }
            return _glassIconButton(
              controller.isCallsSearchOpen.value
                  ? Icons.close_rounded
                  : Icons.person_add_alt_1_rounded,
              controller.toggleCallsSearch,
            );
          }),
        ],
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: kColorBlack.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: kColorText, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHubTabs() {
    return Obx(() {
      final active = controller.hubTab.value;
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.9)),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _hubTab(
                  icon: Icons.sensors_rounded,
                  label: 'Live',
                  isActive: active == 0,
                  onTap: () => controller.selectHubTab(0),
                ),
                _hubTab(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  isActive: active == 1,
                  onTap: () => controller.selectHubTab(1),
                ),
                _hubTab(
                  icon: Icons.headphones_rounded,
                  label: 'Audio',
                  isActive: active == 2,
                  onTap: () => controller.selectHubTab(2),
                ),
                _hubTab(
                  icon: Icons.call_rounded,
                  label: 'Calls',
                  isActive: active == 3,
                  onTap: () => controller.selectHubTab(3),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _hubTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 54,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B1F7A), Color(0xFF6B1560)],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? kColorWhite : kColorHint,
                size: 18,
              ),
              const SizedBox(height: 3),
              AppText(
                text: label,
                style: TextStyles.kSemiBoldPoppins(
                  fontSize: 11,
                  colors: isActive ? kColorWhite : kColorTextGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rooms tabs (Live / Video / Audio) ─────────────────────────────────

  Widget _buildRoomsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldText(
                  text: controller.currentRoomTitle,
                  fontSize: TextStyles.k20FontSize,
                  color: kColorText,
                ),
                Spacing.v4,
                AppText(
                  text: controller.currentRoomSubtitle,
                  style: TextStyles.kRegularPoppins(
                    fontSize: 13,
                    colors: kColorTextGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isRoomsLoading.value && controller.rooms.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _accent),
              );
            }
            if (controller.rooms.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.fetchRooms,
                color: _accent,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: Get.height * 0.16),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_off_outlined,
                          color: _accent,
                          size: 34,
                        ),
                      ),
                    ),
                    Spacing.v16,
                    const Center(
                      child: BoldText(
                        text: 'Nothing live here yet',
                        fontSize: 17,
                        color: kColorText,
                      ),
                    ),
                    Spacing.v6,
                    Center(
                      child: AppText(
                        text: 'Pull to refresh and check again.',
                        style: TextStyles.kRegularPoppins(
                          fontSize: 13,
                          colors: kColorTextGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchRooms,
              color: _accent,
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: controller.rooms.length,
                itemBuilder: (context, index) {
                  final room = controller.rooms[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1),
                    duration: Duration(milliseconds: 280 + (index % 4) * 40),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GestureDetector(
                      onTap: () => controller.joinRoom(room),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CommonLiveRoomWidget(
                            imageUrl: room['image']?.toString() ?? '',
                            userNameAge: room['nameAge']?.toString() ?? 'Room',
                            badgeText: room['badge']?.toString() ?? '',
                            locationText: room['location']?.toString() ?? '',
                            pointsText: room['points']?.toString() ?? '0',
                            isFavorite: room['favorite'] == true,
                          ),
                          Positioned(
                            left: 10,
                            bottom: 72,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF9B1F7A),
                                    Color(0xFFE6252F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: SemiBoldText(
                                text: room['typeLabel']?.toString() ?? '',
                                fontSize: TextStyles.k10FontSize,
                                color: kColorWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── Calls tab (WhatsApp-style history) ────────────────────────────────

  Widget _buildCallsTab(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          if (!controller.isCallsSearchOpen.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _searchBar(),
          );
        }),
        Obx(() {
          if (controller.isCallsSearchOpen.value &&
              controller.searchQuery.value.trim().isNotEmpty) {
            return Expanded(child: _searchResultsList(context));
          }
          return Expanded(child: _historyList(context));
        }),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchFieldController,
        onChanged: controller.onSearchChanged,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search people to call',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: 14,
            colors: kColorHint,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _accent),
        ),
      ),
    );
  }

  Widget _searchResultsList(BuildContext context) {
    return Obx(() {
      if (controller.isSearchLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _accent));
      }
      if (controller.searchResults.isEmpty) {
        return Center(
          child: AppText(
            text: 'No users found',
            style: TextStyles.kRegularPoppins(
              fontSize: 14,
              colors: kColorTextGrey,
            ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: controller.searchResults.length,
        separatorBuilder: (_, __) => Spacing.v8,
        itemBuilder: (context, index) {
          final user = controller.searchResults[index];
          return _newCallUserTile(context, user);
        },
      );
    });
  }

  Widget _newCallUserTile(BuildContext context, Map<String, dynamic> user) {
    final avatar = user['avatar']?.toString() ?? '';
    final voiceOk = user['acceptsVoiceCall'] != false && user['busy'] != true;
    final videoOk = user['acceptsVideoCall'] != false && user['busy'] != true;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(avatar, online: user['isOnline'] == true),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoldText(
                  text: user['name']?.toString() ?? 'User',
                  fontSize: 15,
                  color: kColorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v2,
                AppText(
                  text: user['username']?.toString().isNotEmpty == true
                      ? '@${user['username']}'
                      : (user['busy'] == true ? 'Busy' : 'Tap to call'),
                  style: TextStyles.kRegularPoppins(
                    fontSize: 12,
                    colors: kColorTextGrey,
                  ),
                ),
              ],
            ),
          ),
          _waCallButton(
            icon: Icons.call_rounded,
            enabled: voiceOk && !controller.isStartingCall.value,
            onTap: () => controller.startDirectCall(
              context,
              user: user,
              callType: ChatCallType.voice,
            ),
          ),
          _waCallButton(
            icon: Icons.videocam_rounded,
            enabled: videoOk && !controller.isStartingCall.value,
            onTap: () => controller.startDirectCall(
              context,
              user: user,
              callType: ChatCallType.video,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyList(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Obx(() {
            final filter = controller.historyFilter.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterPill('All', 'all', filter),
                  Spacing.h8,
                  _filterPill('Missed', 'missed', filter),
                  Spacing.h8,
                  _filterPill('Outgoing', 'outgoing', filter),
                  Spacing.h8,
                  _filterPill('Incoming', 'incoming', filter),
                ],
              ),
            );
          }),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isHistoryLoading.value &&
                controller.historyItems.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: _accent),
              );
            }
            if (controller.historyItems.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => controller.fetchHistory(refresh: true),
                color: _accent,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: Get.height * 0.14),
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          color: kColorWhite,
                          size: 34,
                        ),
                      ),
                    ),
                    Spacing.v16,
                    const Center(
                      child: BoldText(
                        text: 'No recent calls',
                        fontSize: 17,
                        color: kColorText,
                      ),
                    ),
                    Spacing.v6,
                    Center(
                      child: AppText(
                        text: 'Tap + to find someone and start calling.',
                        style: TextStyles.kRegularPoppins(
                          fontSize: 13,
                          colors: kColorTextGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchHistory(refresh: true),
              color: _accent,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: controller.historyItems.length,
                separatorBuilder: (_, __) => Spacing.v8,
                itemBuilder: (context, index) {
                  return _whatsAppHistoryTile(
                    context,
                    controller.historyItems[index],
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _filterPill(String label, String value, String active) {
    final isActive = active == value;
    return GestureDetector(
      onTap: () => controller.selectHistoryFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _accentSoft : kColorWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? _accent.withValues(alpha: 0.35)
                : kColorTextFieldBorder,
          ),
        ),
        child: AppText(
          text: label,
          style: TextStyles.kSemiBoldPoppins(
            fontSize: 12,
            colors: isActive ? _accent : kColorTextGrey,
          ),
        ),
      ),
    );
  }

  Widget _whatsAppHistoryTile(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final kind = item['kind']?.toString() ?? '';
    final peer = item['peer'] is Map
        ? Map<String, dynamic>.from(item['peer'] as Map)
        : <String, dynamic>{};
    final room = item['room'] is Map
        ? Map<String, dynamic>.from(item['room'] as Map)
        : <String, dynamic>{};
    final avatar = kind == 'room_join'
        ? (room['coverImage']?.toString() ?? '')
        : (peer['avatar']?.toString() ?? '');
    final isMissed = item['isMissed'] == true;
    final isVideo = item['isVideo'] == true;
    final isIncoming = item['direction']?.toString() == 'incoming';
    final isOutgoing = item['direction']?.toString() == 'outgoing';

    IconData directionIcon = Icons.call_made_rounded;
    Color directionColor = _waGreen;
    if (isMissed) {
      directionIcon = Icons.call_missed_outgoing_rounded;
      directionColor = Colors.redAccent;
    } else if (isIncoming) {
      directionIcon = Icons.call_received_rounded;
      directionColor = _waGreen;
    } else if (isOutgoing) {
      directionIcon = Icons.call_made_rounded;
      directionColor = _waGreen;
    }
    if (kind == 'room_join') {
      directionIcon = Icons.meeting_room_rounded;
      directionColor = _accent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => controller.callBackFromHistory(context, item),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _avatar(avatar, size: 54),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldText(
                      text: item['title']?.toString() ?? 'Unknown',
                      fontSize: 15,
                      color: isMissed ? Colors.redAccent : kColorText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v4,
                    Row(
                      children: [
                        Icon(directionIcon, size: 15, color: directionColor),
                        Spacing.h4,
                        Flexible(
                          child: AppText(
                            text: item['detailLine']?.toString() ?? '',
                            style: TextStyles.kRegularPoppins(
                              fontSize: 12,
                              colors: kColorTextGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppText(
                text: item['timeLabel']?.toString() ?? '',
                style: TextStyles.kRegularPoppins(
                  fontSize: 11,
                  colors: kColorHint,
                ),
              ),
              Spacing.h4,
              _waCallButton(
                icon: kind == 'room_join'
                    ? Icons.login_rounded
                    : (isVideo
                          ? Icons.videocam_rounded
                          : Icons.call_rounded),
                enabled: !controller.isStartingCall.value,
                onTap: () => controller.callBackFromHistory(context, item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String url, {double size = 52, bool online = false}) {
    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: url.startsWith('http')
                ? SafeNetworkAvatar(
                    url: url,
                    size: size,
                    fallback: ColoredBox(
                      color: _accentSoft,
                      child: Icon(
                        Icons.person_rounded,
                        color: _accent,
                        size: size * 0.45,
                      ),
                    ),
                    fit: BoxFit.cover,
                  )
                : ColoredBox(
                    color: _accentSoft,
                    child: Icon(
                      Icons.person_rounded,
                      color: _accent,
                      size: size * 0.45,
                    ),
                  ),
          ),
        ),
        if (online)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _waGreen,
                shape: BoxShape.circle,
                border: Border.all(color: kColorWhite, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _waCallButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? _waGreen.withValues(alpha: 0.12)
              : kColorHint.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? _waGreen : kColorHint,
          size: 20,
        ),
      ),
    );
  }
}
