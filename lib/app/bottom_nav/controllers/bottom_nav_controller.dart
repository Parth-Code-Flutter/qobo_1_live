import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Represents one tab in the custom bottom navigation bar.
class BottomNavItem {
  const BottomNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class BottomNavController extends GetxController {
  final selectedIndex = 2.obs;

  // Keep tab configuration centralized for cleaner view code.
  final items = const <BottomNavItem>[
    BottomNavItem(label: 'Discover', icon: Icons.explore_outlined),
    BottomNavItem(label: 'Live Rooms', icon: Icons.sensors_outlined),
    BottomNavItem(label: 'Heart', icon: Icons.favorite_border),
    BottomNavItem(label: 'Messages', icon: Icons.chat_bubble_outline),
    BottomNavItem(label: 'Profile', icon: Icons.person_outline),
  ];

  void onTabSelected(int index) {
    selectedIndex.value = index;
  }
}
