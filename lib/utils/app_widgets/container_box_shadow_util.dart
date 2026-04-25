import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:flutter/material.dart';

List<BoxShadow> containerBoxShadowUtils() {
  return [
    BoxShadow(
      color: kColorGreyDD,
      spreadRadius: 0.2,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
