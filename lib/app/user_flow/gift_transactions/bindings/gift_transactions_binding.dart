import 'package:get/get.dart';

import '../controllers/gift_transactions_controller.dart';

class GiftTransactionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<GiftTransactionsController>(
      GiftTransactionsController(),
    );
  }
}
