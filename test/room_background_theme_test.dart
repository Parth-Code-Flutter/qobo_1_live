import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/room_background_theme.dart';

void main() {
  group('RoomBackgroundTheme.listFromResponse', () {
    test('parses catalog list and sorts by sortOrder', () {
      final themes = RoomBackgroundTheme.listFromResponse([
        {
          'id': 'bg-2',
          'name': 'Neon Cosmic Stage',
          'image': 'https://cdn.example/neon.jpg',
          'isDefault': false,
          'sortOrder': 2,
        },
        {
          'id': 'bg-1',
          'name': 'Royal Purple Lounge',
          'image': 'https://cdn.example/purple.jpg',
          'isDefault': true,
          'sortOrder': 1,
        },
      ]);

      expect(themes, hasLength(2));
      expect(themes.first.id, 'bg-1');
      expect(themes.first.isDefault, isTrue);
      expect(themes.last.name, 'Neon Cosmic Stage');
    });

    test('reads nested list from map payloads', () {
      final themes = RoomBackgroundTheme.listFromResponse({
        'backgrounds': [
          {
            'id': 'bg-3',
            'name': 'Golden Luxury Villa',
            'backgroundImage': 'https://cdn.example/gold.jpg',
            'sort_order': 3,
          },
        ],
      });

      expect(themes, hasLength(1));
      expect(themes.single.imageUrl, 'https://cdn.example/gold.jpg');
    });

    test('skips entries missing id or image', () {
      final themes = RoomBackgroundTheme.listFromResponse([
        {'id': 'bg-ok', 'image': 'https://cdn.example/ok.jpg'},
        {'id': 'missing-image'},
        {'image': 'https://cdn.example/missing-id.jpg'},
      ]);

      expect(themes, hasLength(1));
      expect(themes.single.id, 'bg-ok');
    });
  });
}
