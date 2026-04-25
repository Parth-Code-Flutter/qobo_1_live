import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          kImgSplashScreen,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
