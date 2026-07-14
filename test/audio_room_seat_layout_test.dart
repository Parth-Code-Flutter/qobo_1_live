import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/audio_room_seat_layout.dart';

void main() {
  group('AudioRoomSeatLayoutMetrics', () {
    const phoneWidths = <double>[
      320, // small (SE-like)
      360, // common Android
      375, // iPhone
      390, // compact boundary
      414, // Plus
      430, // large
    ];

    for (final width in phoneWidths) {
      test('cell height fits content at width $width (compact)', () {
        final metrics = AudioRoomSeatLayoutMetrics.fromWidth(
          width,
          compact: true,
        );

        expect(metrics.frameSize, greaterThan(0));
        expect(metrics.mainAxisExtent, greaterThan(metrics.estimatedContentHeight));
        expect(metrics.frameSize, lessThanOrEqualTo(108));
        expect(metrics.avatarSize, lessThan(metrics.frameSize));
      });

      test('cell height fits content at width $width (regular)', () {
        final metrics = AudioRoomSeatLayoutMetrics.fromWidth(
          width,
          compact: false,
        );

        expect(metrics.mainAxisExtent, greaterThan(metrics.estimatedContentHeight));
        expect(
          metrics.mainAxisExtent - metrics.estimatedContentHeight,
          greaterThanOrEqualTo(4),
          reason: 'need headroom against text-metric sub-pixel overflow',
        );
      });
    }

    test('narrow phones shrink frames instead of overflowing', () {
      final narrow = AudioRoomSeatLayoutMetrics.fromWidth(320, compact: true);
      final wide = AudioRoomSeatLayoutMetrics.fromWidth(430, compact: false);

      expect(narrow.frameSize, lessThan(wide.frameSize));
      expect(narrow.mainAxisExtent, lessThan(wide.mainAxisExtent));
    });
  });
}
