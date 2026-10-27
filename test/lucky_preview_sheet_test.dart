import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/gifts/lucky_gift_session.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/lucky_preview_sheet.dart';

void main() {
  testWidgets('dynamic catalog stays visible and allows repeated paid taps', (
    tester,
  ) async {
    final s = LuckyGiftSession(
      repo: LuckyGiftRepo(),
      token: 'test',
      isOwner: () => true,
      onSuccess: (_, __, ___) {},
    );
    s.gifts = [
      LuckyGift.fromJson({
        'id': 'gift',
        'name': 'Heart',
        'price': 100,
        'luckyThreshold': 5,
        'luckyRewardRate': 40,
      }),
    ];
    var taps = 0;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LuckyPreviewSheet(
              session: s,
              onSelected: (_, origin) => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Heart'));
    await tester.pump();
    expect(taps, 0);
    expect(find.text('Send'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Send'));
      await tester.pump();
    }
    expect(
      tester.getSize(find.byKey(const ValueKey('lucky-sheet-panel'))).height,
      closeTo(640 * .40, .1),
    );
    s.showMessage(
      'Preview only • No coins charged. Select a recipient to send.',
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('lucky-sheet-panel'))).height,
      closeTo(640 * .40, .1),
    );
    expect(tester.takeException(), isNull);
    expect(taps, 3);
    expect(find.text('100 Coins'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('sends'), findsNothing);
    expect(find.byType(LuckyPreviewSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
}
