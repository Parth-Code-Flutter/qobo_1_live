import 'package:get/get.dart';

/// Controller for discover tab local UI state.
class DiscoverTabController extends GetxController {
  final isVideoModeSelected = true.obs;

  void selectVideoMode() {
    if (isVideoModeSelected.value) return;
    isVideoModeSelected.value = true;
  }

  void selectAudioMode() {
    if (!isVideoModeSelected.value) return;
    isVideoModeSelected.value = false;
  }
}

