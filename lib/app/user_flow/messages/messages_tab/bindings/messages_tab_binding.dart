import 'package:get/get.dart';

import '../controllers/messages_tab_controller.dart';

class MessagesTabBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessagesTabController>(() => MessagesTabController());
  }
}
