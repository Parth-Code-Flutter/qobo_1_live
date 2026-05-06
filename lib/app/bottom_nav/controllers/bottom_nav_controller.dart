import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for bottom-nav state.
class BottomNavController extends GetxController {
  final selectedIndex = 0.obs;

  /// Keep tabs centralized so view stays clean.
  final items = const <({String label, IconData icon})>[
    (label: 'Home', icon: Icons.home_outlined),
    (label: 'Search', icon: Icons.search),
    (label: 'Live', icon: Icons.videocam_outlined),
    (label: 'Chat', icon: Icons.chat_bubble_outline),
    (label: 'Profile', icon: Icons.person_outline),
  ];

  void onTabSelected(int index) {
    selectedIndex.value = index;
  }
}
