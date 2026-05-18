import 'package:get/get.dart';
import '../controllers/vip_store_controller.dart';

class VipStoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VipStoreController>(
      () => VipStoreController(),
    );
  }
}
