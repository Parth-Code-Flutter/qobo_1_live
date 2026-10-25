import 'package:get/get.dart';

import '../controllers/food_wheel_controller.dart';

class FoodWheelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FoodWheelController>(FoodWheelController.new);
  }
}
