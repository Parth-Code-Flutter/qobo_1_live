import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_demo_celebration.dart';

void main() {
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
              total: 42,
              bonus: 12,
              combo: 3,
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1700));
      expect(
        find.text(
          reward ? 'You get 42 coins!' : 'A little love, a lot of magic!',
        ),
        findsOneWidget,
      );
      if (reward) {
        expect(find.text('Reward confirmed'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
