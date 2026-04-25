import 'package:flutter/material.dart';
import 'package:qobo_one_live/generated/locales.g.dart';

import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.splashTitle.tr),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          LocaleKeys.splashWorkingMessage.tr,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
