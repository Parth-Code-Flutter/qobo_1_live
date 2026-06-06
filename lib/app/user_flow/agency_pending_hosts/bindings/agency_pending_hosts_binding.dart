import 'package:get/get.dart';

import '../controllers/agency_pending_hosts_controller.dart';

class AgencyPendingHostsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyPendingHostsController>(
      () => AgencyPendingHostsController(),
    );
  }
}
