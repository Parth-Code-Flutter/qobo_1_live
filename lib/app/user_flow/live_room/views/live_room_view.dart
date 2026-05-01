import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

import '../controllers/live_room_controller.dart';

class LiveRoomView extends GetView<LiveRoomController> {
  const LiveRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Live Rooms Page',
          style: TextStyle(
            color: kColorWhite,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
