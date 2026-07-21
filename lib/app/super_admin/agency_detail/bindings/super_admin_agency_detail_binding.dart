import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/agency_detail/controllers/super_admin_agency_detail_controller.dart';

class SuperAdminAgencyDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminAgencyDetailController>(
      SuperAdminAgencyDetailController.new,
    );
  }
}
