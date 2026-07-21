import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/bottom_nav/controllers/super_admin_bottom_nav_controller.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

class SuperAdminBottomNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserSessionController>(
      () => UserSessionController(),
      fenix: true,
    );
    Get.lazyPut<SuperAdminHomeController>(SuperAdminHomeController.new);
    Get.lazyPut<SuperAdminBottomNavController>(
      SuperAdminBottomNavController.new,
    );
  }
}
