import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/widgets/audio_room_grid_view.dart';
import 'package:qobo_one_live/app/user_flow/live_room/widgets/compact_live_room_tile.dart';
import 'package:qobo_one_live/app/user_flow/live_room/widgets/video_room_list_view.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/call_controller.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  static const _waGreen = Color(0xFF25D366);

  static const _hubTabs = <({IconData icon, String label})>[
    (icon: Icons.sensors_rounded, label: 'Live'),
    (icon: Icons.videocam_rounded, label: 'Video'),
    (icon: Icons.headphones_rounded, label: 'Audio'),
    (icon: Icons.call_rounded, label: 'Calls'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: _CallAppBar(controller: controller),
      body: Column(
        children: [
          Spacing.v10,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHubTabs(),
          ),
          Spacing.v8,
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
    );
  }

  Widget _buildHubTabs() {
    return Obx(() {
      final active = controller.hubTab.value;
      return Container(
        height: 64,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppLightUi.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppLightUi.border),
          boxShadow: AppLightUi.cardShadow,
        ),
        child: Row(
          children: List.generate(_hubTabs.length, (index) {
            final tab = _hubTabs[index];
            final isActive = active == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectHubTab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isActive ? AppLightUi.familyCtaGradient : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppLightUi.pink.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 18,
                        color: isActive ? kColorWhite : AppLightUi.muted,
                      ),
                      const SizedBox(height: 3),
                      SemiBoldText(
                        text: tab.label,
                        fontSize: TextStyles.k10FontSize,
                        color: isActive ? kColorWhite : AppLightUi.subtitle,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  // ─── Rooms tabs (Live / Video / Audio) ─────────────────────────────────

  Widget _buildRoomsTab() {
    return Obx(() {
      final rooms = controller.rooms.toList();
      final loading = controller.isRoomsLoading.value;
      final tab = controller.hubTab.value;

      // Live → same 3-col CompactLiveRoomTile grid as bottom-nav Live hub.
      if (tab == 0) {
        return _liveHubListing(rooms: rooms, loading: loading);
      }

      if (tab == 2) {
        return AudioRoomGridView(
          rooms: rooms,
          isLoading: loading && rooms.isEmpty,
          showCreatePanel: false,
          onRefresh: controller.fetchRooms,
          onJoinRoom: controller.joinRoom,
        );
      }

      // Video → Rooms → Video listing.
      return VideoRoomListView(
        rooms: rooms,
        isLoading: loading && rooms.isEmpty,
        showCreatePanel: false,
        onRefresh: controller.fetchRooms,
        onJoinLive: controller.joinRoom,
      );
    });
  }

  Widget _liveHubListing({
    required List<Map<String, dynamic>> rooms,
    required bool loading,
  }) {
    if (loading && rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppLightUi.pink),
      );
    }

    return RefreshIndicator(
      color: AppLightUi.pink,
      backgroundColor: AppLightUi.card,
      onRefresh: controller.fetchRooms,
      child: rooms.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              children: [
                DatingEmptyHero(
                  style: DatingEmptyHeroStyle.live,
                  size: 148,
                  accentColors: const [AppLightUi.pink, AppLightUi.violet],
                ),
                Spacing.v16,
                const SemiBoldText(
                  text: 'Nothing live yet',
                  fontSize: TextStyles.k16FontSize,
                  color: AppLightUi.title,
                  align: TextAlign.center,
                ),
                Spacing.v8,
                const AppText(
                  text: 'Pull to refresh — live rooms will appear here.',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                  align: TextAlign.center,
                ),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              clipBehavior: Clip.none,
              itemCount: rooms.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final name = _liveDisplayName(room);
                return CompactLiveRoomTile(
                  displayName: name,
                  imageUrl: _liveHostAvatarUrl(room),
                  frameUrl: _liveHostFrameUrl(room),
                  frameSeed: name,
                  viewerLabel: room['points']?.toString(),
                  onTap: () => controller.joinRoom(room),
                );
              },
            ),
    );
  }

  String _liveDisplayName(Map<String, dynamic> room) {
    final nameAge = room['nameAge']?.toString().trim() ?? '';
    if (nameAge.isNotEmpty) {
      // Hub tiles show host/title only (drop "· seats" suffix).
      final cut = nameAge.split('·').first.trim();
      if (cut.isNotEmpty) return cut;
    }
    return room['name']?.toString().trim().isNotEmpty == true
        ? room['name'].toString().trim()
        : 'Live';
  }

  String? _liveHostAvatarUrl(Map<String, dynamic> room) {
    final nested = room['roomData'] is Map
        ? Map<String, dynamic>.from(room['roomData'] as Map)
        : const <String, dynamic>{};
    final host = room['host'] is Map
        ? Map<String, dynamic>.from(room['host'] as Map)
        : (nested['host'] is Map
            ? Map<String, dynamic>.from(nested['host'] as Map)
            : const <String, dynamic>{});

    return ApiImageUtils.normalize(
      _firstNonEmpty([
        room['hostDisplayPicture'],
        room['hostAvatar'],
        host['displayPicture'],
        host['avatar'],
        host['avatarUrl'],
        nested['hostDisplayPicture'],
        nested['hostAvatar'],
        room['image'],
        room['coverImage'],
        nested['coverImage'],
      ]),
    );
  }

  String? _liveHostFrameUrl(Map<String, dynamic> room) {
    final nested = room['roomData'] is Map
        ? Map<String, dynamic>.from(room['roomData'] as Map)
        : const <String, dynamic>{};
    final host = room['host'] is Map
        ? Map<String, dynamic>.from(room['host'] as Map)
        : (nested['host'] is Map
            ? Map<String, dynamic>.from(nested['host'] as Map)
            : const <String, dynamic>{});

    return ApiImageUtils.normalize(
      _firstNonEmpty([
        room['avatarFrameUrl'],
        room['hostAvatarFrame'],
        room['hostAvatarFrameUrl'],
        room['profileFrameUrl'],
        room['frameUrl'],
        host['avatarFrameUrl'],
        host['profileFrameUrl'],
        host['frameUrl'],
        nested['avatarFrameUrl'],
        nested['hostAvatarFrameUrl'],
        nested['profileFrameUrl'],
        nested['frameUrl'],
      ]),
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
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
        color: AppLightUi.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: TextField(
        controller: controller.searchFieldController,
        onChanged: controller.onSearchChanged,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: AppLightUi.title,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search people to call',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k12FontSize,
            colors: AppLightUi.muted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppLightUi.pink.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _searchResultsList(BuildContext context) {
    return Obx(() {
      if (controller.isSearchLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppLightUi.pink));
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
                child: CircularProgressIndicator(color: AppLightUi.pink),
              );
            }
            if (controller.historyItems.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => controller.fetchHistory(refresh: true),
                color: AppLightUi.pink,
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
              color: AppLightUi.pink,
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
          color: isActive ? AppLightUi.cardSoft : kColorWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppLightUi.pink.withValues(alpha: 0.35)
                : kColorTextFieldBorder,
          ),
        ),
        child: AppText(
          text: label,
          style: TextStyles.kSemiBoldPoppins(
            fontSize: 12,
            colors: isActive ? AppLightUi.pink : AppLightUi.subtitle,
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
      directionColor = AppLightUi.pink;
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
                      color: AppLightUi.pinkSoft,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppLightUi.pink,
                        size: size * 0.45,
                      ),
                    ),
                    fit: BoxFit.cover,
                  )
                : ColoredBox(
                    color: AppLightUi.pinkSoft,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppLightUi.pink,
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

class _CallAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CallAppBar({required this.controller});

  final CallController controller;

  @override
  Size get preferredSize => const CommonAppBarWidget(title: '').preferredSize;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CommonAppBarWidget(
        title: 'Qobo Call',
        subtitle: 'Live, rooms & call history',
        trailingIcon: controller.hubTab.value == 3
            ? (controller.isCallsSearchOpen.value
                  ? Icons.close_rounded
                  : Icons.person_add_alt_1_rounded)
            : Icons.phone_in_talk_rounded,
        onTrailingTap: controller.hubTab.value == 3
            ? controller.toggleCallsSearch
            : null,
      ),
    );
  }
}
