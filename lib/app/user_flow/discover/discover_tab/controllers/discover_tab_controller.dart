import 'package:get/get.dart';

import '../models/discover_room_selection.dart';

/// Controller for discover tab local UI state.
class DiscoverTabController extends GetxController {
  final roomSelection = DiscoverRoomSelection.none.obs;

  void selectVideoRoom() {
    roomSelection.value = DiscoverRoomSelection.video;
  }

  void selectAudioRoom() {
    roomSelection.value = DiscoverRoomSelection.audio;
  }

  /// Default feed (no room chip selected). Called when user switches to Discover tab.
  void clearRoomMode() {
    roomSelection.value = DiscoverRoomSelection.none;
  }
}
