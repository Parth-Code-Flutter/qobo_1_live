import 'package:qobo_one_live/app/user_flow/messages/messages_tab/widgets/message_inbox_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/widgets/messages_common_widgets.dart';

void main() {
  testWidgets('conversation card fits a narrow phone and opens the chat', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(home: Scaffold(body: Padding(
        padding: const EdgeInsets.all(16),
        child: MessageInboxTileWidget(
          item: const MessageListItemModel(targetId: 'u1', name: 'A very long display name', message: 'Hello there!', time: '14/9/2026', unreadCount: 12),
          onTap: () => tapped = true,
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('9+'), findsOneWidget);
    await tester.tap(find.byType(MessageInboxTileWidget));
    expect(tapped, isTrue);
  });

  testWidgets('match card fits its row and preserves profile tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 148,
                child: MessageMatchAvatarItem(
                  user: const SocialUserCard(
                    id: 'u1',
                    name: 'A long display name',
                  ),
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Say hello'));
    expect(tapped, isTrue);
  });
}
