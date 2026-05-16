import 'package:get/get.dart';
import '../controllers/agency_owner_register_controller.dart';

class AgencyOwnerRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyOwnerRegisterController>(
      () => AgencyOwnerRegisterController(),
    );
  }
}
