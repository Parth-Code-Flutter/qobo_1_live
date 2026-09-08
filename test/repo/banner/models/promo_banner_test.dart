import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/repo/banner/models/promo_banner.dart';

void main() {
  test('parses, filters, and sorts active banners for a placement', () {
    final banners = PromoBanner.listFromResponse(<String, dynamic>{
      'statusCode': 1,
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'second',
          'title': 'Second',
          'imageUrl': 'https://example.com/second.jpg',
          'targetUrl': 'qobo://vip',
          'type': 'live',
          'status': 'active',
          'sortOrder': 2,
        },
        <String, dynamic>{
          'id': 'inactive',
          'imageUrl': 'https://example.com/inactive.jpg',
          'type': 'live',
          'status': 'inactive',
          'sortOrder': 0,
        },
        <String, dynamic>{
          'id': 'other-placement',
          'imageUrl': 'https://example.com/home.jpg',
          'type': 'home',
          'status': 'active',
          'sortOrder': 0,
        },
        <String, dynamic>{
          'id': 'first',
          'title': 'First',
          'imageUrl': '/uploads/banners/first.jpg',
          'type': 'live',
          'status': 'active',
          'sortOrder': '1',
        },
      ],
    }, type: 'live');

    expect(banners.map((banner) => banner.id), <String>['first', 'second']);
    expect(
      banners.first.imageUrl,
      'https://dev-api.qobo1live.in/uploads/banners/first.jpg',
    );
    expect(banners.last.targetUrl, 'qobo://vip');
  });

  test('ignores banner entries without a usable image', () {
    final banners = PromoBanner.listFromResponse(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'missing-image',
          'imageUrl': '',
          'type': 'live',
          'status': 'active',
        },
      ],
    });

    expect(banners, isEmpty);
  });
}
