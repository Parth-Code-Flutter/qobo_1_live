import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';

void main() {
  testWidgets('SVGA room frames bypass the raster image decoder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AvatarFrameMedia(
          source: 'https://example.invalid/equipped.svga?version=2',
          fallbackSource: 'assets/images/audio_room_frame_royal.svg',
          size: 112,
        ),
      ),
    );
    // A raster decoder silently dropped these frames in the room renderer.
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile frames preserve layout and do not recursively nest', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AppUserAvatar(name: 'Member', size: 48, fontSize: 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FramedUserAvatar), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(FramedUserAvatar)), const Size(48, 48));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a parent supplying its own frame can keep the inner photo plain',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppUserAvatar(
              name: 'Host',
              size: 48,
              fontSize: 12,
              showFrame: false,
            ),
          ),
        ),
      );
      expect(find.byType(FramedUserAvatar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
