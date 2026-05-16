import 'package:get/get.dart';
import '../controllers/block_list_controller.dart';

class BlockListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlockListController>(
      () => BlockListController(),
    );
  }
}
