import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

class UserLevelController extends GetxController {
  UserLevelController({UserRepo? userRepo})
    : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;
  final isLoading = false.obs;

  final currentLevel = 12.obs;
  final currentExp = 4500.obs;
  final nextLevelExp = 10000.obs;

  // Selected tab: 0 = Level Status, 1 = Icons History
  final selectedSubTab = 0.obs;

  double get progress {
    if (nextLevelExp.value <= 0) return 0;
    return (currentExp.value / nextLevelExp.value).clamp(0.0, 1.0);
  }

  final perks = <Map<String, String>>[
    {
      'title': 'Special Avatar Frame',
      'subtitle': 'Unlock the silver frame at level 15',
    },
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
    fetchLevel();
  }

  Future<void> fetchLevel() async {
    isLoading.value = true;
    try {
      final response = await _userRepo.getLevel(isShowLoader: false);
      final data = response?['data'];
      if (data is! Map) return;

      currentLevel.value = _toInt(data['currentLevel']);
      currentExp.value = _toInt(data['currentExp']);
      nextLevelExp.value = _toInt(data['nextLevelExp']);

      final apiPerks = data['perks'];
      if (apiPerks is List) {
        perks.assignAll(
          apiPerks
              .whereType<Map>()
              .map((perk) {
                return <String, String>{
                  'title': perk['title']?.toString() ?? '',
                  'subtitle': perk['subtitle']?.toString() ?? '',
                };
              })
              .where((perk) => perk['title']!.isNotEmpty),
        );
      }

      final apiMilestones = data['milestones'];
      if (apiMilestones is List) {
        levelMilestones.assignAll(
          apiMilestones
              .whereType<Map>()
              .map((mile) {
                return <String, dynamic>{
                  'level': _toInt(mile['level']),
                  'title': mile['title']?.toString() ?? '',
                  'icon': _iconFor(mile['icon']?.toString()),
                  'color': _parseColor(mile['color']),
                  'desc': mile['description']?.toString() ?? '',
                  'isUnlocked': mile['isUnlocked'] == true,
                };
              })
              .where((mile) => (mile['title'] as String).isNotEmpty),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _parseColor(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.startsWith('#')) {
      return int.tryParse('0xFF${text.substring(1)}') ?? 0xFF761B65;
    }
    return int.tryParse(text) ?? 0xFF761B65;
  }

  IconData _iconFor(String? icon) {
    switch ((icon ?? '').toLowerCase()) {
      case 'shield_rounded':
      case 'shield':
        return Icons.shield_rounded;
      case 'military_tech_rounded':
      case 'medal':
        return Icons.military_tech_rounded;
      case 'workspace_premium_rounded':
      case 'premium':
        return Icons.workspace_premium_rounded;
      case 'diamond_rounded':
      case 'diamond':
        return Icons.diamond_rounded;
      case 'explore':
        return Icons.explore_rounded;
      default:
        return Icons.shield_outlined;
    }
  }
}
