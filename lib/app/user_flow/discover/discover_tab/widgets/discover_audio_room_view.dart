import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

const double _kAudioAvatarSize = 82;
const double _kAudioMicBadgeSize = 30;
const int _kAudioGridCrossCount = 3;
const double _kAudioGridHPadding = 18;
const double _kAudioGridCrossSpacing = 12;

/// Minimum logical height for avatar + labels so [SliverGrid] never clips.
double _audioParticipantMinTileHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.4);
  const avatarBlock = _kAudioAvatarSize + 8;
  const nameLine = TextStyles.k14FontSize * 1.35;
  const roleLine = TextStyles.k12FontSize * 1.35;
  return avatarBlock + 8 * scale + nameLine * scale + 2 * scale + roleLine * scale + 8;
}

double _audioGridChildAspectRatio(double viewportWidth, BuildContext context) {
  final pad = _kAudioGridHPadding * 2;
  final gaps = _kAudioGridCrossSpacing * (_kAudioGridCrossCount - 1);
  final cellW = (viewportWidth - pad - gaps) / _kAudioGridCrossCount;
  final minH = _audioParticipantMinTileHeight(context);
  if (cellW <= 0 || minH <= 0) return 0.62;
  return (cellW / minH).clamp(0.48, 0.82);
}

/// Mic overlay on participant avatar (Figma).
enum _AudioMicVisual {
  /// [kIconMuteMike] on purple.
  muted,

  /// [kIconMike] on purple.
  unmuted,

  /// [kIconMike] on green — active speaker.
  speaking,
}

class _AudioParticipant {
  const _AudioParticipant({
    required this.name,
    required this.role,
    required this.imageAsset,
    required this.mic,
  });

  final String name;
  final String role;
  final String imageAsset;
  final _AudioMicVisual mic;
}

/// Audio Room discover content — participant grid + “Others in the room” (Figma).
class DiscoverAudioRoomView extends StatelessWidget {
  const DiscoverAudioRoomView({super.key});

  static const String roomLabel = 'Audio Room';

  static const ColorFilter _whiteIcon = ColorFilter.mode(
    kColorWhite,
    BlendMode.srcIn,
  );

  static const List<_AudioParticipant> _participants = [
    _AudioParticipant(
      name: 'Sarah',
      role: 'Host',
      imageAsset: kImgTemp2,
      mic: _AudioMicVisual.muted,
    ),
    _AudioParticipant(
      name: 'Merry',
      role: 'Speaking',
      imageAsset: kImgTemp3,
      mic: _AudioMicVisual.speaking,
    ),
    _AudioParticipant(
      name: 'Alex',
      role: 'Member Listener',
      imageAsset: kImgTemp4,
      mic: _AudioMicVisual.muted,
    ),
    _AudioParticipant(
      name: 'Jordan',
      role: 'Member Listener',
      imageAsset: kImgTemp5,
      mic: _AudioMicVisual.unmuted,
    ),
    _AudioParticipant(
      name: 'Sam',
      role: 'Member Listener',
      imageAsset: kImgTemp2,
      mic: _AudioMicVisual.muted,
    ),
    _AudioParticipant(
      name: 'Riya',
      role: 'Member Listener',
      imageAsset: kImgTemp3,
      mic: _AudioMicVisual.muted,
    ),
    _AudioParticipant(
      name: 'Chris',
      role: 'Anaynamouse',
      imageAsset: kImgTemp4,
      mic: _AudioMicVisual.unmuted,
    ),
    _AudioParticipant(
      name: 'Pat',
      role: 'Member Listener',
      imageAsset: kImgTemp5,
      mic: _AudioMicVisual.muted,
    ),
    _AudioParticipant(
      name: 'Jamie',
      role: 'Member Listener',
      imageAsset: kImgTemp2,
      mic: _AudioMicVisual.muted,
    ),
    _AudioParticipant(
      name: 'Taylor',
      role: 'Member Listener',
      imageAsset: kImgTemp3,
      mic: _AudioMicVisual.unmuted,
    ),
    _AudioParticipant(
      name: 'Casey',
      role: 'Member Listener',
      imageAsset: kImgTemp4,
      mic: _AudioMicVisual.muted,
    ),
  ];

  static const List<String> _othersAvatarAssets = [
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
    kImgTemp5,
    kImgTemp2,
  ];

  @override
  Widget build(BuildContext context) {
    // Transparent: uses parent Discover tab scaffold background (kImgBG).
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect = _audioGridChildAspectRatio(
          constraints.maxWidth,
          context,
        );
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _kAudioGridHPadding,
                4,
                _kAudioGridHPadding,
                8,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _kAudioGridCrossCount,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: _kAudioGridCrossSpacing,
                  childAspectRatio: aspect,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < _participants.length) {
                    return _ParticipantTile(participant: _participants[index]);
                  }
                  return const _AddParticipantTile();
                }, childCount: _participants.length + 1),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: _OthersInRoomSection(
                  avatarAssets: _othersAvatarAssets,
                  overflowCount: 52,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final _AudioParticipant participant;

  bool get _isSpeaking => participant.mic == _AudioMicVisual.speaking;

  @override
  Widget build(BuildContext context) {
    final nameColor = _isSpeaking ? kColorAudioSpeakingGreen : kColorWhite;
    final roleColor = _isSpeaking
        ? kColorAudioSpeakingGreen
        : kColorAudioRoleText;

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _kAudioAvatarSize + 4,
                  height: _kAudioAvatarSize + 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 0,
                        child: _AvatarRing(
                          speaking: _isSpeaking,
                          imageAsset: participant.imageAsset,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(child: _MicBadge(visual: participant.mic)),
                      ),
                    ],
                  ),
                ),
                Spacing.v8,
                SemiBoldText(
                  text: participant.name,
                  fontSize: TextStyles.k14FontSize,
                  color: nameColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
                Spacing.v2,
                AppText(
                  text: participant.role,
                  fontSize: TextStyles.k12FontSize,
                  color: roleColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.speaking, required this.imageAsset});

  final bool speaking;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final inner = ClipOval(
      child: Image.asset(
        imageAsset,
        width: _kAudioAvatarSize,
        height: _kAudioAvatarSize,
        fit: BoxFit.cover,
      ),
    );

    if (!speaking) return inner;

    return Container(
      width: _kAudioAvatarSize + 4,
      height: _kAudioAvatarSize + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kColorAudioSpeakingGreen, width: 2),
      ),
      child: Center(child: inner),
    );
  }
}

class _MicBadge extends StatelessWidget {
  const _MicBadge({required this.visual});

  final _AudioMicVisual visual;

  @override
  Widget build(BuildContext context) {
    final bg = visual == _AudioMicVisual.speaking
        ? kColorAudioSpeakingGreen
        : kColorAudioMicBadgeBg;

    final String asset = visual == _AudioMicVisual.muted
        ? kIconMuteMike
        : kIconMike;

    return Container(
      width: _kAudioMicBadgeSize,
      height: _kAudioMicBadgeSize,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: kColorAudioMicBadgeBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          asset,
          width: visual == _AudioMicVisual.muted ? 15 : 14,
          height: visual == _AudioMicVisual.muted ? 15 : 14,
          colorFilter: DiscoverAudioRoomView._whiteIcon,
        ),
      ),
    );
  }
}

class _AddParticipantTile extends StatelessWidget {
  const _AddParticipantTile();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _kAudioAvatarSize + 8,
                  child: Center(
                    child: Material(
                      color: kColorAudioAddTileBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {},
                        child: const SizedBox(
                          width: _kAudioAvatarSize,
                          height: _kAudioAvatarSize,
                          child: Icon(
                            Icons.add_rounded,
                            color: kColorWhite,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Spacing.v8,
                SizedBox(height: TextStyles.k14FontSize * 1.35),
                const SizedBox(height: 2),
                SizedBox(height: TextStyles.k12FontSize * 1.35),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OthersInRoomSection extends StatelessWidget {
  const _OthersInRoomSection({
    required this.avatarAssets,
    required this.overflowCount,
  });

  final List<String> avatarAssets;
  final int overflowCount;

  @override
  Widget build(BuildContext context) {
    const double overlap = 18;
    const double smallAvatar = 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: kColorWhite.withValues(alpha: 0.22),
        ),
        Spacing.v16,
        Row(
          children: [
            Icon(
              Icons.person_outline_rounded,
              color: kColorWhite.withValues(alpha: 0.9),
              size: 20,
            ),
            Spacing.h8,
            const Expanded(
              child: SemiBoldText(
                text: 'Others in the room',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
          ],
        ),
        Spacing.v12,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: smallAvatar + (avatarAssets.length - 1) * overlap,
              height: smallAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < avatarAssets.length; i++)
                    Positioned(
                      left: i * overlap,
                      child: Container(
                        width: smallAvatar,
                        height: smallAvatar,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kColorVideoRoomBgGradientBottom,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarAssets[i],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Spacing.h10,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kColorAudioOthersPillBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
              ),
              child: SemiBoldText(
                text: '+$overflowCount',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
