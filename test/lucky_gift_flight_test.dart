import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/ui_utils/coin_fly_overlay.dart';

void main() {
  tearDown(() {
    CoinFlyOverlay.dismiss();
    Get.reset();
  });

  Future<GlobalKey> mount(WidgetTester tester, VoidCallback onTap) async {
    final target = GlobalKey();
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(key: target, width: 40, height: 40),
              TextButton(onPressed: onTap, child: const Text('Control')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return target;
  }

  Widget visual(double size) => SizedBox(
    key: ValueKey('gift-$size'),
    width: size,
    height: size,
    child: const ColoredBox(color: Colors.pink),
  );

  List<SizedBox> gifts(WidgetTester tester) => tester
      .widgetList<SizedBox>(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.key.toString().contains('gift-'),
        ),
      )
      .toList();

  testWidgets(
    'Lucky gift holds one full image then shrinks toward the seat with controls tappable',
    (tester) async {
      var taps = 0;
      final target = await mount(tester, () => taps++);
      final flight = CoinFlyOverlay.show(
        targetKey: target,
        delay: Duration.zero,
        coinCount: 8,
        startFrom: const Offset(200, 420),
        centerGiftFlight: true,
        flyVisual: visual,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      final early = gifts(tester);
      expect(early.first.width, 180);
      expect(early.length, 1);
      for (var i = 1; i < early.length; i++) {
        expect(early[i].width!, lessThan(early[i - 1].width!));
      }
      double leadScale() => tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.byKey(const ValueKey('gift-180.0')),
              matching: find.byType(Transform),
            ),
          )
          .map((w) => w.transform.storage[0])
          .reduce((a, b) => a < b ? a : b);
      final firstScale = leadScale();
      final firstPosition = tester.getCenter(
        find.byKey(const ValueKey('gift-180.0')),
      );
      expect(firstPosition, const Offset(200, 420));
      expect(firstScale, 1);
      await tester.pump(const Duration(milliseconds: 450));
      expect(leadScale(), lessThan(firstScale));
      expect(
        tester.getCenter(find.byKey(const ValueKey('gift-180.0'))).dy,
        lessThan(firstPosition.dy),
      );
      expect(gifts(tester), hasLength(1));
      await tester.tap(find.text('Control'));
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 2));
      await flight;
      expect(gifts(tester), isEmpty);
      expect(CoinFlyOverlay.isShowing, false);
    },
  );

  testWidgets('default coin flight keeps its original small sizes', (
    tester,
  ) async {
    final target = await mount(tester, () {});
    unawaited(
      CoinFlyOverlay.show(
        targetKey: target,
        delay: Duration.zero,
        flyVisual: visual,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 600));
    expect(gifts(tester), isNotEmpty);
    for (final gift in gifts(tester)) {
      expect(gift.width, inInclusiveRange(22, 36));
    }
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('queued Lucky flights retain the shrinking style and clean up', (
    tester,
  ) async {
    final target = await mount(tester, () {});
    for (var i = 0; i < 2; i++) {
      unawaited(
        CoinFlyOverlay.show(
          targetKey: target,
          delay: Duration.zero,
          coinCount: 8,
          centerGiftFlight: true,
          flyVisual: visual,
          enqueueIfBusy: true,
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(gifts(tester).first.width, 180);
    await tester.pump(const Duration(seconds: 2));
    expect(gifts(tester), isEmpty);
  });
}
