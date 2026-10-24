import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_demo_celebration.dart';

void main() {
  test(
    'five consecutive same-gift taps trigger, switching resets, repeats work',
    () {
      final streak = LuckyDemoStreak();
      for (var i = 0; i < 4; i++) {
        expect(streak.tap('a'), isFalse);
      }
      expect(streak.tap('b'), isFalse);
      for (var i = 0; i < 3; i++) {
        expect(streak.tap('b'), isFalse);
      }
      expect(streak.tap('b'), isTrue);
      for (var i = 0; i < 4; i++) {
        expect(streak.tap('b'), isFalse);
      }
      expect(streak.tap('b'), isTrue);
    },
  );
  for (final reward in [false, true]) {
    testWidgets('celebration renders and completes reward=$reward', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LuckyDemoCelebration(
              reward: reward,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1700));
      expect(
        find.text(
          reward ? 'You get 70 coins!' : 'A little love, a lot of magic!',
        ),
        findsOneWidget,
      );
      if (reward) {
        expect(find.text('Demo reward • Wallet unchanged'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
