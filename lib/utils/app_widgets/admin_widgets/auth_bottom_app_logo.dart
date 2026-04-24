import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:flutter/material.dart';

Widget authBottomAppLogo(){
  return  Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Image.asset(
      kIconApp,
      height: 32,
    ),
  );
}