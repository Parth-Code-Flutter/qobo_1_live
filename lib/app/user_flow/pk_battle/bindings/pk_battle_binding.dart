import 'package:get/get.dart';
import '../controllers/pk_battle_controller.dart';

class PKBattleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PKBattleController>(
      () => PKBattleController(),
    );
  }
}
