import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/audio_room_models.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/frame/frame_urls.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

void main() {
  const entryUrl =
      'https://api.qobo1live.in/uploads/frames/image-1792756303542-267755178.svga';
  const avatarUrl = 'https://api.qobo1live.in/uploads/frames/neon_crown.png';

  test('entry and avatar frames stay in separate slots', () {
    final profile = {
      'id': 'idc1057300',
      'name': 'Niks',
      'avatarFrame': null,
      'entryFrame': {
        'name': 'Card',
        'image': entryUrl,
        'svgaUrl': entryUrl,
        'frameType': 'entry',
        'itemType': 'VIP_FRAME',
      },
      'entryFrameUrl': entryUrl,
      'vipFrameUrl': entryUrl,
    };

    expect(readEntryFrameUrl(profile), entryUrl);
    expect(readAvatarFrameUrl(profile), isNull);
    expect(
      readHostAvatarFrameUrl({
        'host': {
          'avatarFrame': {
            'image': avatarUrl,
            'svgaUrl': avatarUrl,
            'frameType': 'avatar',
            'itemType': 'AVATAR_FRAME',
          },
          'entryFrame': {
            'svgaUrl': entryUrl,
            'frameType': 'entry',
            'itemType': 'VIP_FRAME',
          },
        },
      }),
      avatarUrl,
    );
    expect(readHostAvatarFrameUrl(profile), isNull);

    final seat = AudioRoomSeatModel.fromMap({
      'seatNo': 2,
      'userId': 'idc1057300',
      'name': 'Niks',
      'avatarFrame': {
        'image': avatarUrl,
        'frameType': 'avatar',
        'itemType': 'AVATAR_FRAME',
      },
      'entryFrame': {
        'svgaUrl': entryUrl,
        'frameType': 'entry',
        'itemType': 'VIP_FRAME',
      },
    });
    expect(seat.avatarFrameUrl, avatarUrl);
    expect(seat.vipFrameUrl, entryUrl);

    final card = SocialUserCard.fromJson({
      'id': 'idc1057300',
      'name': 'Niks',
      'avatarFrame': {
        'image': avatarUrl,
        'frameType': 'avatar',
      },
      'entryFrameUrl': entryUrl,
    });
    expect(card.avatarFrameUrl, avatarUrl);
  });

  test('profile border ignores an entry frame when no avatar frame is equipped', () async {
    final session = UserSessionController();
    try {
      await session.saveProfile({
        'id': 'idc1057300',
        'name': 'Niks',
        'avatarFrame': null,
        'entryFrame': {
          'svgaUrl': entryUrl,
          'frameType': 'entry',
          'itemType': 'VIP_FRAME',
        },
        'entryFrameUrl': entryUrl,
        'frameUrl': entryUrl,
      });
    } catch (_) {}

    expect(session.entryFrameUrl, entryUrl);
    expect(session.profileFrameUrl, isEmpty);
  });

  test('an equipped avatar border stays when an entry frame is also equipped', () async {
    const border = 'https://api.qobo1live.in/uploads/frames/thirteen-frame.png';
    final session = UserSessionController();
    try {
      await session.saveProfile({
        'id': 'idc1057300',
        'name': 'Niks',
        'avatarFrame': {
          'name': 'thirteen frame',
          'frameType': 'avatar',
          'itemType': 'AVATAR_FRAME',
          'image': border,
          'imageUrl': border,
          'svgaUrl': null,
        },
        'entryFrameUrl': entryUrl,
        'frameUrl': entryUrl,
      });
    } catch (_) {}

    expect(session.profileFrameUrl, border);
    expect(session.entryFrameUrl, entryUrl);
  });

  test('viewer join payload resolves entryFrameUrl from the nested viewer', () {
    final url = readEntryFrameUrl({
      'event': 'live_stream.viewer_joined',
      'viewer': {
        'id': 'idc1057300',
        'name': 'Niks',
        'entryFrame': {
          'svgaUrl': entryUrl,
          'frameType': 'entry',
        },
        'entryFrameUrl': entryUrl,
        'avatarFrame': null,
      },
    });
    expect(url, entryUrl);
    expect(
      readAvatarFrameUrl({
        'viewer': {
          'entryFrameUrl': entryUrl,
          'avatarFrame': null,
        },
      }),
      isNull,
    );
  });

  test('equipped backpack entry row uses frameDetails svga', () {
    expect(
      readEntryFrameUrl({
        'itemType': 'VIP_FRAME',
        'frameType': 'entry',
        'isEquipped': true,
        'frameDetails': {
          'svgaUrl': entryUrl,
          'frameType': 'entry',
        },
      }),
      entryUrl,
    );
  });
}
