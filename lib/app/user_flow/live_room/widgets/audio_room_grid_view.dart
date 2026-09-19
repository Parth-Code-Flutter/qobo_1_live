import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/rooms_empty_state.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
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
  String? frameUrl,
  Map<String, dynamic> room,
});

class AudioRoomGridView extends StatelessWidget {
  const AudioRoomGridView({
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
        child: CircularProgressIndicator(color: kColorPrimary, strokeWidth: 2),
      );
    }

    final tiles = List<_AudioRoomTileData>.generate(
      rooms.length,
      (index) => _tileFromRoom(rooms[index], index),
    );

    return RefreshIndicator(
      color: kColorPrimary,
      backgroundColor: AppLightUi.card,
      onRefresh: onRefresh ?? () async {},
      child: tiles.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(14, 48, 14, 120),
              children: [_AudioRoomsEmptyState(onCreate: onCreateAudioRoom)],
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
    final nested = room['room'];
    final nestedMap = nested is Map ? nested : const <String, dynamic>{};
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
              _text(hostMap['avatar']) ??
              _text(room['coverImage']),
        ) ??
        fallbackImages[index % fallbackImages.length];
    final frameUrl = ApiImageUtils.normalize(
      _readFrameUrl(room['avatarFrame']) ??
          _firstNonEmpty([
            room['avatarFrameUrl'],
            room['hostAvatarFrame'],
            room['hostAvatarFrameUrl'],
            room['profileFrameUrl'],
            room['frameUrl'],
          ]) ??
          _readFrameUrl(hostMap['avatarFrame']) ??
          _firstNonEmpty([
            hostMap['avatarFrameUrl'],
            hostMap['profileFrameUrl'],
            hostMap['frameUrl'],
          ]) ??
          _readFrameUrl(nestedMap['avatarFrame']) ??
          _firstNonEmpty([
            nestedMap['avatarFrameUrl'],
            nestedMap['hostAvatarFrameUrl'],
            nestedMap['profileFrameUrl'],
            nestedMap['frameUrl'],
          ]),
    );

    return (
      title: title,
      hostName: hostName,
      category: _text(room['category']) ?? 'Live audio chat',
      listenerCount: listenerCount,
      speakerCount: speakerCount,
      maxSeats: maxSeats,
      avatar: avatar,
      frameUrl: frameUrl,
      room: room,
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _text(value);
      if (text != null) return text;
    }
    return null;
  }

  String? _readFrameUrl(dynamic frame) {
    if (frame == null) return null;
    if (frame is String) return _text(frame);
    if (frame is Map) {
      return _firstNonEmpty([
        frame['image'],
        frame['imageUrl'],
        frame['url'],
        frame['frameUrl'],
        frame['svga'],
      ]);
    }
    return _text(frame);
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
    this.onTap,
  });

  final _AudioRoomTileData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final roomTitle = data.title.isNotEmpty ? data.title : 'Audio Room';
    final hostName = data.hostName.isNotEmpty ? data.hostName : 'Host';
    // FramedUserAvatar lays out at size * 1.34 (~88dp with size 66).
    const avatarSize = 66.0;

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
              FramedUserAvatar(
                name: hostName,
                imageUrl: data.avatar,
                frameUrl: data.frameUrl,
                frameSeed: hostName,
                size: avatarSize,
                fontSize: TextStyles.k14FontSize,
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppLightUi.violet, AppLightUi.pink],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppLightUi.card,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppLightUi.pink.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: kColorWhite,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          Spacing.v8,
          SemiBoldText(
            text: roomTitle,
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Spacing.v2,
          AppText(
            text: hostName,
            fontSize: TextStyles.k10FontSize,
            color: AppLightUi.subtitle,
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
              color: AppLightUi.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppLightUi.border),
              boxShadow: AppLightUi.cardShadow,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppLightUi.pink,
              size: 34,
            ),
          ),
          Spacing.v8,
          const SemiBoldText(
            text: 'Create',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.title,
            align: TextAlign.center,
          ),
          Spacing.v2,
          const AppText(
            text: 'Audio Room',
            fontSize: TextStyles.k10FontSize,
            color: AppLightUi.subtitle,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AudioRoomsEmptyState extends StatelessWidget {
  const _AudioRoomsEmptyState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return RoomsEmptyState(
      heroStyle: DatingEmptyHeroStyle.audio,
      title: 'No audio rooms live',
      subtitle:
          'Start a cozy room and invite someone special to hang out.',
      accentColors: const [Color(0xFFFF5C9A), Color(0xFFB14DFF)],
      ctaLabel: onCreate == null ? null : 'Create audio room',
      onCta: onCreate,
    );
  }
}
