import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(
    ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return ScreenUtilInit(
          child: ToastificationWrapper(
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Qobo One',
              home: const Scaffold(
                body: Center(
                  child: Text('Qobo One Live'),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
