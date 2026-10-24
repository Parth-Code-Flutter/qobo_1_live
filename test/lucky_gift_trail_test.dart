import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_gift_trail.dart';

void main() {
  testWidgets('staggered images shrink upward and finish once', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LuckyGiftTrail(
            origin: const Offset(100, 600),
            target: const Offset(200, 140),
            icon: '🎁',
            onComplete: () => completed++,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final first = tester.widget<Positioned>(
      find.byKey(const ValueKey('lucky-trail-0')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final later = tester.widget<Positioned>(
      find.byKey(const ValueKey('lucky-trail-0')),
    );
    expect(later.width, lessThan(first.width!));
    expect(later.top, lessThan(first.top!));
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('lucky-trail-$i')), findsOneWidget);
    }
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });
}
