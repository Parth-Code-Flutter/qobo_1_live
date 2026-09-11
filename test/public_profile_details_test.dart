import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/public_profile/controllers/discover_public_profile_controller.dart';
import 'package:qobo_one_live/app/user_flow/discover/public_profile/views/discover_public_profile_view.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';

class _Controller extends DiscoverPublicProfileController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  tearDown(Get.reset);
  testWidgets(
    'profile details display API aliases once and exclude known fields',
    (tester) async {
      Get.testMode = true;
      final controller = Get.put<DiscoverPublicProfileController>(
        _Controller(),
      );
      controller.profile.value = const SocialUserCard(
        id: 'user-123',
        name: 'Test User',
      );
      controller.rawData.assignAll({
        'isLive': false,
        'is_live': false,
        'viewerCount': 0,
        'viewer_count': 0,
        'joinApprovalRequired': false,
        'join_approval_required': false,
        'user_id': 'user-123',
        'is_vip': false,
        'access_token': 'hidden-token',
      });
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) =>
              const GetMaterialApp(home: DiscoverPublicProfileView()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('Is Live'), findsOneWidget);
      expect(find.text('Viewer Count'), findsOneWidget);
      expect(find.text('Join Approval Required'), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);
      expect(find.text('hidden-token'), findsNothing);
      expect(find.text('Is Vip'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
