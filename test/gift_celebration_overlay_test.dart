import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_celebration_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('love_gif.gif asset exists and is a real GIF', () {
    final file = File('assets/gif/love_gif.gif');
    expect(file.existsSync(), isTrue, reason: 'assets/gif/love_gif.gif missing');

    final header = file.openSync().readSync(6);
    final signature = String.fromCharCodes(header);
    expect(
      signature == 'GIF89a' || signature == 'GIF87a',
      isTrue,
      reason: 'love_gif.gif must be a GIF file, got header: $signature',
    );
  });

  test('image constant points at love_gif.gif', () {
    expect(kGifLoveGift, 'assets/gif/love_gif.gif');
    expect(GiftCelebrationOverlay.loveGiftAsset, kGifLoveGift);
  });

  testWidgets(
    'GiftCelebrationOverlay shows celebration without success label',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    GiftCelebrationOverlay.show(
                      giftName: 'Fireworks',
                      gifAsset: GiftCelebrationOverlay.loveGiftAsset,
                    );
                  },
                  child: const Text('Send'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Success label removed — only the gift animation should show.
      expect(find.textContaining('sent successfully'), findsNothing);
      expect(find.byType(Image), findsWidgets);

      final image = tester.widgetList<Image>(find.byType(Image)).firstWhere(
        (img) =>
            img.image is AssetImage &&
            (img.image as AssetImage).assetName ==
                GiftCelebrationOverlay.loveGiftAsset,
      );
      expect(image.fit, BoxFit.contain);

      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
    },
  );
}
