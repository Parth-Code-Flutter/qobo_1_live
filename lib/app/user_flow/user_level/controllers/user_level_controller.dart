import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserLevelController extends GetxController {
  final currentLevel = 12.obs;
  final currentExp = 4500.obs;
  final nextLevelExp = 10000.obs;

  // Selected tab: 0 = Level Status, 1 = Icons History
  final selectedSubTab = 0.obs;

  double get progress => currentExp.value / nextLevelExp.value;

  final perks = <Map<String, String>>[
    {'title': 'Special Avatar Frame', 'subtitle': 'Unlock the silver frame at level 15'},
    {'title': 'Broadcast Effects', 'subtitle': 'Custom entrance animation'},
    {'title': 'Exclusive Gifts', 'subtitle': 'Send VIP gifts in live rooms'},
  ].obs;

  // Level Badge History Ledger
  final levelMilestones = <Map<String, dynamic>>[
    {
      'level': 1,
      'title': 'Bronze Novice',
      'icon': Icons.shield_outlined,
      'color': 0xFFCD7F32, // Bronze
      'desc': 'Initiate your streaming journey with basic text capabilities.',
      'isUnlocked': true,
    },
    {
      'level': 10,
      'title': 'Silver Knight',
      'icon': Icons.shield_rounded,
      'color': 0xFFC0C0C0, // Silver
      'desc': 'Unlock silver chat speech bubbles & quick message options.',
      'isUnlocked': true,
    },
    {
      'level': 20,
      'title': 'Gold General',
      'icon': Icons.military_tech_rounded,
      'color': 0xFFFFD700, // Gold
      'desc': 'Exclusive gold profile nameplates and glowing entry splash.',
      'isUnlocked': false,
    },
    {
      'level': 40,
      'title': 'Platinum Warlord',
      'icon': Icons.workspace_premium_rounded,
      'color': 0xFFE5E4E2, // Platinum
      'desc': 'High-priority room entrance queue bypass and custom emojis.',
      'isUnlocked': false,
    },
    {
      'level': 60,
      'title': 'Diamond Sovereign',
      'icon': Icons.diamond_rounded,
      'color': 0xFFE0115F, // Diamond Pink/Ruby
      'desc': 'Premium red crown rank icon, fully animated entry banner Patti.',
      'isUnlocked': false,
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
  }
}
