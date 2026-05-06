import 'package:get/get.dart';

/// Controller for live room flow.
class LiveRoomController extends GetxController {
  int selectedCategoryIndex = 0;

  void onCategorySelected(int index) {
    if (selectedCategoryIndex == index) return;
    selectedCategoryIndex = index;
    update();
  }
}
