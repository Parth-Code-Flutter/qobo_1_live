import 'package:flutter_test/flutter_test.dart';

/// Mirrors PK opponent + score payload parsing rules used by PKBattleController.
Map<String, dynamic> normalizePkOpponent(Map<String, dynamic> map) {
  final host = map['host'] is Map
      ? Map<String, dynamic>.from(map['host'] as Map)
      : <String, dynamic>{};
  String read(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  final title = read(map, ['title', 'name']);
  final hostName = read(map, ['hostName', 'host_name']).isNotEmpty
      ? read(map, ['hostName', 'host_name'])
      : read(host, ['name', 'hostName']);
  final roomType = read(map, ['room_type', 'roomType']);
  final viewerCount = map['viewerCount'] ?? map['viewer_count'];
  return <String, dynamic>{
    'room_id': read(map, ['room_id', 'roomId', 'id']),
    'name': hostName.isNotEmpty
        ? hostName
        : (title.isNotEmpty ? title : 'PK Opponent'),
    'title': title.isNotEmpty ? title : hostName,
    'hostName': hostName,
    'avatar': read(map, ['avatar', 'displayPicture', 'coverImage']).isNotEmpty
        ? read(map, ['avatar', 'displayPicture', 'coverImage'])
        : read(host, ['displayPicture', 'avatar', 'profileImage']),
    'coverImage': read(map, ['coverImage', 'cover_image']),
    'room_type': roomType,
    'followers': viewerCount != null
        ? '$viewerCount watching'
        : (map['followers']?.toString() ?? 'Live now'),
    'isOnline': map['isLive'] == true || map['isOnline'] != false,
  };
}

int? remainingSecondsFrom(Map<String, dynamic> data) {
  final remaining = int.tryParse(
    data['remainingSeconds']?.toString() ??
        data['remaining_seconds']?.toString() ??
        '',
  );
  if (remaining != null && remaining >= 0) return remaining;
  return int.tryParse(data['duration']?.toString() ?? '');
}

void main() {
  group('PK search rooms payload', () {
    test('normalizes data.rooms fields from backend search', () {
      final rooms = [
        {
          'room_id': 'opp-1',
          'title': 'Night Live',
          'hostName': 'Host A',
          'avatar': 'https://cdn.example/a.png',
          'coverImage': 'https://cdn.example/c.png',
          'room_type': 'audio',
          'viewerCount': 12,
          'isLive': true,
        },
      ];

      final normalized = rooms.map(normalizePkOpponent).toList();
      expect(normalized.single['room_id'], 'opp-1');
      expect(normalized.single['name'], 'Host A');
      expect(normalized.single['title'], 'Night Live');
      expect(normalized.single['room_type'], 'audio');
      expect(normalized.single['followers'], '12 watching');
      expect(normalized.single['avatar'], 'https://cdn.example/a.png');
    });
  });

  group('PK remainingSeconds', () {
    test('prefers remainingSeconds over duration', () {
      expect(
        remainingSecondsFrom({
          'remainingSeconds': 142,
          'duration': 300,
        }),
        142,
      );
    });

    test('falls back to duration', () {
      expect(remainingSecondsFrom({'duration': 300}), 300);
    });
  });
}
