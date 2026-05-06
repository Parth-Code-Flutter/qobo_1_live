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
        // GIF is rendered as an animated image directly from assets.
        child: Image.asset(
          kGifSplashScreen,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
