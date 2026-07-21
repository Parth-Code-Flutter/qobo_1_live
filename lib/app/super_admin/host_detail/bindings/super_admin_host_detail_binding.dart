import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/host_detail/controllers/super_admin_host_detail_controller.dart';

class SuperAdminHostDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminHostDetailController>(
      SuperAdminHostDetailController.new,
    );
  }
}
