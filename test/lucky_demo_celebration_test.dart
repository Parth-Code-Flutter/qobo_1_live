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
      for (var ms = 0; ms < 500; ms += 40) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull);
      }
      await tester.pump(const Duration(milliseconds: 1200));
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

  testWidgets('a finished coin reward releases the next gift animation', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    LuckyDemoCelebration.show(context, reward: true, total: 12, combo: 1);
    await tester.pump();
    expect(LuckyDemoCelebration.rewardVisible, isTrue);
    LuckyDemoCelebration.show(context, reward: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('You get 12 coins!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(LuckyDemoCelebration.rewardVisible, isFalse);

    LuckyDemoCelebration.show(context, reward: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('A little love, a lot of magic!'), findsOneWidget);
    LuckyDemoCelebration.dismiss();
    await tester.pump();
  });
}
