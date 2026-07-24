import 'package:get/get.dart';

import '../controllers/coin_seller_controller.dart';

class CoinSellerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoinSellerController>(CoinSellerController.new);
  }
}
