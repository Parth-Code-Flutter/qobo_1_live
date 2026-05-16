import 'package:get/get.dart';
import '../controllers/agency_host_list_controller.dart';

class AgencyHostListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyHostListController>(
      () => AgencyHostListController(),
    );
  }
}
