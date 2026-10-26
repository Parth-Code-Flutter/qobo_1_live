import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';

void main() {
  test('entry and avatar frames stay in separate slots', () {
    expect(
      frameCatalogIsEntry({
        'frameType': 'entry',
        'type': 'entry',
        'category': 'VIP',
      }),
      isTrue,
    );
    expect(
      frameCatalogIsEntry(
        {'itemType': 'VIP_FRAME'},
        details: {'frameType': 'entry', 'category': 'VIP'},
      ),
      isTrue,
    );
    expect(
      frameCatalogIsEntry({
        'frameType': 'avatar',
        'type': 'avatar',
        'category': 'Elite',
        'itemType': 'AVATAR_FRAME',
      }),
      isFalse,
    );
    expect(frameCatalogIsEntry({'category': 'Premium'}), isFalse);
    expect(
      frameCatalogIsEntry({
        'itemTypes': 'VIP_FRAME',
      }),
      isTrue,
    );
    expect(
      frameCatalogIsEntry(
        const <String, dynamic>{},
        details: {'itemTypes': 'AVATAR_FRAME', 'frameType': 'avatar'},
      ),
      isFalse,
    );
  });
}
