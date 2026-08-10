import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';
import 'package:qobo_one_live/services/pk/pk_v1_coordinator.dart';

class PkV1Binding extends Bindings {
  @override
  void dependencies() {
    // Prefer the shared permanent controller used by the live-room overlay.
    PkV1Coordinator.ensureController();
    if (!Get.isRegistered<PkV1Controller>()) {
      Get.lazyPut<PkV1Controller>(PkV1Controller.new);
    }
  }
}
