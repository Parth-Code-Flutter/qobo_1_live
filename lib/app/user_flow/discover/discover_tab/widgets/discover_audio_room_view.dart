import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
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
  });

  final List<Map<String, dynamic>> rooms;
  final bool isLoading;
  final VoidCallback? onCreateAudioRoom;
  final ValueChanged<Map<String, dynamic>>? onJoinRoom;

  static const String roomLabel = 'Audio Room';

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kColorWhite, strokeWidth: 2),
      );
    }

    if (rooms.isEmpty) return const _AudioRoomsEmptyState();

    final tiles = List<_AudioRoomTileData>.generate(
      rooms.length,
      (index) => _tileFromRoom(rooms[index], index),
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: tiles.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CreateAudioRoomPanel(
            liveCount: tiles.length,
            onTap: onCreateAudioRoom,
          );
        }
        final data = tiles[index - 1];
        return _AudioRoomCard(
          data: data,
          onJoin: onJoinRoom == null ? null : () => onJoinRoom!(data.room),
        );
      },
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

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

class _CreateAudioRoomPanel extends StatelessWidget {
  const _CreateAudioRoomPanel({required this.liveCount, this.onTap});

  final int liveCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kColorAudioMicBadgeBg.withValues(alpha: 0.96),
            kColorVideoPreviewGradientEnd.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
            ),
            child: const Icon(Icons.add_rounded, color: kColorWhite, size: 28),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Start an Audio Room',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v4,
                AppText(
                  text: '$liveCount rooms live now',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.72),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacing.h10,
          _CreateButton(onTap: onTap),
        ],
      ),
    );
  }
}

class _AudioRoomCard extends StatelessWidget {
  const _AudioRoomCard({required this.data, this.onJoin});

  final _AudioRoomTileData data;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kColorWhite.withValues(alpha: 0.10),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _AudioAvatarPreview(path: data.avatar),
              Spacing.h10,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: data.title,
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v4,
                      AppText(
                        text: data.category,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorVideoSecondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v6,
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              text: data.hostName,
                              fontSize: TextStyles.k12FontSize,
                              color: kColorWhite.withValues(alpha: 0.84),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacing.h8,
                          AppText(
                            text: '${data.speakerCount}/${data.maxSeats} seats',
                            fontSize: TextStyles.k10FontSize,
                            color: kColorWhite.withValues(alpha: 0.62),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _ListenerPill(count: data.listenerCount),
          ),
          Positioned(
            right: 0,
            bottom: 3,
            child: _JoinAudioButton(onTap: onJoin),
          ),
        ],
      ),
    );
  }
}

class _AudioAvatarPreview extends StatelessWidget {
  const _AudioAvatarPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kColorWhite.withValues(alpha: 0.14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipOval(child: _RoomImage(path: path)),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: kColorAudioSpeakingGreen,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF251235), width: 2),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: kColorWhite,
                size: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenerPill extends StatelessWidget {
  const _ListenerPill({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText(
        text: '$count listening',
        fontSize: TextStyles.k10FontSize,
        color: kColorWhite,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _JoinAudioButton extends StatelessWidget {
  const _JoinAudioButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 68,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorVideoJoinLivePurple, kColorVideoJoinLiveGradientEnd],
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const SemiBoldText(
          text: 'Join',
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const SemiBoldText(
            text: 'Create',
            fontSize: TextStyles.k12FontSize,
            color: kColorPrimary,
          ),
        ),
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
