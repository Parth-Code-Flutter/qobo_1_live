import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/auth/role_home_route.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test('super_admin role resolves to Super Admin bottom nav', () async {
    Get.put(UserSessionController(), permanent: true);
    final route = await RoleHomeRoute.resolveAfterLogin(<String, dynamic>{
      'id': 'u1',
      'name': 'Admin',
      'role': 'super_admin',
    });
    expect(route, Routes.SUPER_ADMIN_BOTTOM_NAV);
    expect(Get.find<UserSessionController>().isSuperAdmin, isTrue);
  });

  test('user role resolves to standard bottom nav', () async {
    Get.put(UserSessionController(), permanent: true);
    final route = await RoleHomeRoute.resolveAfterLogin(<String, dynamic>{
      'id': 'u2',
      'name': 'User',
      'role': 'user',
    });
    expect(route, Routes.BOTTOM_NAV);
    expect(Get.find<UserSessionController>().isSuperAdmin, isFalse);
  });

  test('agency role resolves to agency owner shell', () async {
    Get.put(UserSessionController(), permanent: true);
    final route = await RoleHomeRoute.resolveAfterLogin(<String, dynamic>{
      'id': 'u3',
      'name': 'Agency Owner',
      'role': 'agency',
    });
    expect(route, Routes.AGENCY_OWNER);
    expect(Get.find<UserSessionController>().isAgency, isTrue);
  });
}
