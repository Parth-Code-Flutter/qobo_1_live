import 'package:get/get.dart';

/// Tiny bridge so PK battle can flip the live-room overlay flag without a
/// circular import between [PkV1Controller] and [LiveBroadcastController].
class PkLiveRoomBridge {
  PkLiveRoomBridge._();

  /// Observable the live room listens to (`true` = show PK stage overlay).
  static final isActive = false.obs;

  static void setActive(bool active) {
    isActive.value = active;
  }
}
