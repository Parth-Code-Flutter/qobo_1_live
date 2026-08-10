import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_controller.dart';

class PkV1Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PkV1Controller>(PkV1Controller.new);
  }
}
