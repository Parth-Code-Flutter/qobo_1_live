import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

typedef _AudioRoomTileData = ({
  String title,
  String hostName,
  String category,
  String listenerCount,
  int speakerCount,
  int maxSeats,
  String avatar,
  Map<String, dynamic> room,
});

class DiscoverAudioRoomView extends StatelessWidget {
  const DiscoverAudioRoomView({
    super.key,
    this.rooms = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.onCreateAudioRoom,
    this.onJoinRoom,
    this.onRefresh,
    this.showCreatePanel = true,
  });

  final List<Map<String, dynamic>> rooms;
  final bool isLoading;
  final VoidCallback? onCreateAudioRoom;
  final ValueChanged<Map<String, dynamic>>? onJoinRoom;
  final Future<void> Function()? onRefresh;
  final bool showCreatePanel;

  static const String roomLabel = 'Audio Room';

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
      );
    }

    final tiles = List<_AudioRoomTileData>.generate(
      rooms.length,
      (index) => _tileFromRoom(rooms[index], index),
    );

    return RefreshIndicator(
      color: kColorPrimary,
      backgroundColor: LiveRoomUiColors.screenGradientBottom,
      onRefresh: onRefresh ?? () async {},
      child: tiles.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 64, 14, 120),
              children: const [_AudioRoomsEmptyState()],
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 104),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: tiles.length + (showCreatePanel ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 22,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                if (showCreatePanel && index == tiles.length) {
                  return _AudioRoomCreateTile(onTap: onCreateAudioRoom);
                }
                final data = tiles[index];
                return _AudioRoomGridTile(
                  data: data,
                  roleLabel: _roleLabelForIndex(index),
                  isSpeaking: index == 1,
                  onTap: onJoinRoom == null
                      ? null
                      : () => onJoinRoom!(data.room),
                );
              },
            ),
    );
  }

  _AudioRoomTileData _tileFromRoom(Map<String, dynamic> room, int index) {
    const fallbackImages = [kImgTemp2, kImgTemp3, kImgTemp4, kImgTemp5];
    final host = room['host'];
    final hostMap = host is Map ? host : const <String, dynamic>{};
    final title = _text(room['name']) ?? _text(room['title']) ?? 'Audio Room';
    final hostName =
        _text(room['hostName']) ?? _text(hostMap['name']) ?? 'Host';
    final listenerCount =
        _text(room['listenerCount']) ??
        _text(room['audienceCount']) ??
        _text(room['viewerCount']) ??
        '0';
    final speakerCount =
        int.tryParse(
          '${room['speakerCount'] ?? room['activeSpeakers'] ?? 0}',
        ) ??
        0;
    final maxSeats = int.tryParse('${room['maxSeats'] ?? 8}') ?? 8;
    final avatar =
        ApiImageUtils.normalize(
          _text(room['hostAvatar']) ??
              _text(room['hostDisplayPicture']) ??
              _text(hostMap['displayPicture']) ??
              _text(room['coverImage']),
        ) ??
        fallbackImages[index % fallbackImages.length];

    return (
      title: title,
      hostName: hostName,
      category: _text(room['category']) ?? 'Live audio chat',
      listenerCount: listenerCount,
      speakerCount: speakerCount,
      maxSeats: maxSeats,
      avatar: avatar,
      room: room,
    );
  }

  String _roleLabelForIndex(int index) {
    if (index == 0) return 'Host';
    if (index == 1) return 'Speaking';
    return 'Member Listen...';
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

class _AudioRoomGridTile extends StatelessWidget {
  const _AudioRoomGridTile({
    required this.data,
    required this.roleLabel,
    required this.isSpeaking,
    this.onTap,
  });

  final _AudioRoomTileData data;
  final String roleLabel;
  final bool isSpeaking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = data.hostName.isNotEmpty ? data.hostName : data.title;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                padding: EdgeInsets.all(isSpeaking ? 3 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeaking
                        ? const Color(0xFF12F287)
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isSpeaking)
                      BoxShadow(
                        color: const Color(0xFF12F287).withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipOval(child: _RoomImage(path: data.avatar)),
              ),
              Positioned(
                right: 2,
                bottom: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? const Color(0xFF14D96B)
                        : const Color(0xFF7B3B93),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF20104A),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSpeaking ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: kColorWhite,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          Spacing.v8,
          SemiBoldText(
            text: displayName,
            fontSize: TextStyles.k12FontSize,
            color: isSpeaking ? const Color(0xFF12F287) : kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v2,
          AppText(
            text: roleLabel,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.72),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AudioRoomCreateTile extends StatelessWidget {
  const _AudioRoomCreateTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
            ),
            child: const Icon(Icons.add_rounded, color: kColorWhite, size: 34),
          ),
          Spacing.v8,
          const SemiBoldText(
            text: 'Create',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v2,
          AppText(
            text: 'Audio Room',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.72),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kColorVideoPreviewGradientStart,
            kColorVideoPreviewGradientEnd,
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.graphic_eq_rounded, color: kColorWhite, size: 24),
      ),
    );
  }
}

class _AudioRoomsEmptyState extends StatelessWidget {
  const _AudioRoomsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: kColorWhite,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const SemiBoldText(
              text: 'No data found',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Audio rooms will appear here when available.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
