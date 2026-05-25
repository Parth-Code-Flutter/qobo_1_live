import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';

class LiveRoomCreateController extends GetxController {
  final roomNameController = TextEditingController();
  final roomType = 'AUDIO'.obs; // AUDIO or VIDEO
  final seatCount = '8'.obs;

  final RoomRepo _roomRepo = RoomRepo();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('type')) {
        roomType.value = args['type'];
      }
    }
  }

  void selectRoomType(String type) {
    roomType.value = type;
  }

  void selectSeats(String count) {
    seatCount.value = count;
  }

  void createRoom(BuildContext context) async {
    if (roomNameController.text.trim().isEmpty) {
      AppToast.showError(context, 'Please enter a room name');
      return;
    }

    final maxSeats = int.tryParse(seatCount.value) ?? 8;

    final response = await _roomRepo.createRoom(
      name: roomNameController.text.trim(),
      type: roomType.value,
      country: 'IN',
      maxSeats: maxSeats,
    );

    if (!context.mounted) return;

    if (response != null &&
        (response['statusCode'] == 1 ||
            response['statusCode'] == 200 ||
            response['statusCode'] == 201)) {
      AppToast.showSuccess(
        context,
        response['message'] ?? 'Room created successfully!',
      );
      Get.offNamed(
        '/live-broadcast',
        arguments: {
          'isHost': true,
          'roomType': roomType.value,
          'roomData': response['data'],
        },
      );
    } else {
      AppToast.showError(
        context,
        response?['message'] ?? 'Failed to create room',
      );
    }
  }

  @override
  void onClose() {
    roomNameController.dispose();
    super.onClose();
  }
}
