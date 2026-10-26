import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/repo/economy/mall_catalog.dart';

void main() {
  test('mall rows stay on their own tab even when the server mixes patti', () {
    expect(
      mallCatalogKind({
        'type': 'frame',
        'frameType': 'avatar',
        'itemType': 'AVATAR_FRAME',
      }),
      'avatar',
    );
    expect(
      mallCatalogKind({
        'type': 'frame',
        'frameType': 'entry',
        'itemTypes': 'VIP_FRAME',
      }),
      'entry',
    );
    expect(
      mallCatalogKind({
        'type': 'background',
        'itemType': 'PROFILE_BACKGROUND',
      }),
      'background',
    );
    expect(
      mallCatalogKind({
        'type': 'patti',
        'itemType': 'PATTI_STYLE',
        'frameType': null,
      }),
      'patti',
    );
  });
}
