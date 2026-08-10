import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_history_controller.dart';

class PkV1HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PkV1HistoryController>(PkV1HistoryController.new);
  }
}
