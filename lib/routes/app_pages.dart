import 'package:flutter/material.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = '/';

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: INITIAL,
      page: () => const Scaffold(
        body: Center(
          child: Text('Qobo One Live'),
        ),
      ),
    ),
  ];
}
