import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:flutter/material.dart';

class HorizontalBlackLine extends StatelessWidget {
  const HorizontalBlackLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 94,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: kColorBlack,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
