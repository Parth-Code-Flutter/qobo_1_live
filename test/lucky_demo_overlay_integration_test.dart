import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_demo_celebration.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_gift_trail.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_preview_sheet.dart';
import 'package:qobo_one_live/services/gifts/lucky_gift_session.dart';

void main() {
  testWidgets(
    'real modal taps show both overlays and confirmed dynamic reward',
    (tester) async {
      final session = LuckyGiftSession(
        repo: LuckyGiftRepo(),
        token: 'test',
        isOwner: () => true,
        onSuccess: (_, __, ___) {},
      );
      session.gifts = [
        LuckyGift.fromJson({'id': 'a', 'name': 'Heart', 'price': 10}),
      ];
      final sheetKey = GlobalKey();
      var sends = 0;
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Get.bottomSheet(
                  LuckyPreviewSheet(
                    key: sheetKey,
                    session: session,
                    onSelected: (gift, origin) {
                      final context = sheetKey.currentContext!;
                      LuckyDemoCelebration.show(context, reward: false);
                      LuckyGiftTrail.show(
                        context,
                        origin: origin,
                        target: const Offset(200, 140),
                        icon: '🎁',
                      );
                      sends++;
                    },
                  ),
                  isScrollControlled: true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Heart'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(LuckyDemoCelebration), findsOneWidget);
      }
      expect(find.text('You get 70 coins!'), findsNothing);
      // Simulate a confirmed server reward, not a local tap threshold.
      LuckyDemoCelebration.show(
        sheetKey.currentContext!,
        reward: true,
        total: 98,
        bonus: 28,
        combo: 7,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1700));
      expect(find.text('You get 98 coins!'), findsOneWidget);
      expect(find.byType(LuckyPreviewSheet), findsOneWidget);
      expect(sends, 5);
      LuckyDemoCelebration.dismiss();
      LuckyGiftTrail.dismiss();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      Get.reset();
    },
  );
}
