import 'package:get/get.dart';

import '../controllers/agency_access_controller.dart';

class AgencyAccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyAccessController>(AgencyAccessController.new);
  }
}
