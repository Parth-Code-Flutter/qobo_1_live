import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/family/family_repo.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

class FamilyController extends GetxController {
  FamilyController({FamilyRepo? familyRepo})
    : _familyRepo = familyRepo ?? FamilyRepo();

  final FamilyRepo _familyRepo;
  final isLoading = true.obs;

  final hasFamily = false.obs;
  final searchQuery = ''.obs;

  /// 0 = This Week, 1 = Last Week, 2 = Rewards
  final rankingTab = 0.obs;

  final RxList<Map<String, dynamic>> popularFamilies =
      <Map<String, dynamic>>[].obs;

  // Active family user details (populated when hasFamily is true)
  final RxMap<String, dynamic> myFamily = <String, dynamic>{}.obs;

  final RxList<Map<String, dynamic>> familyMembers =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFamilyHub();
  }

  // Filtered popular families for search
  List<Map<String, dynamic>> get filteredFamilies {
    if (searchQuery.value.isEmpty) {
      return popularFamilies;
    }
    return popularFamilies.where((f) {
      final name = f['name'].toString().toLowerCase();
      final id = f['id'].toString().toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  /// Families sorted for ranking display (level + members).
  List<Map<String, dynamic>> get rankedFamilies {
    final list = List<Map<String, dynamic>>.from(filteredFamilies);
    list.sort((a, b) {
      final scoreA = _toInt(a['level']) * 1000 + _toInt(a['members']);
      final scoreB = _toInt(b['level']) * 1000 + _toInt(b['members']);
      return scoreB.compareTo(scoreA);
    });
    // Last-week tab: soft alternate order until a dedicated API exists.
    if (rankingTab.value == 1 && list.length > 1) {
      return list.reversed.toList();
    }
    return list;
  }

  Map<String, dynamic>? get topRankedFamily {
    final ranked = rankedFamilies;
    return ranked.isEmpty ? null : ranked.first;
  }

  /// Days / hours / mins / secs until next Monday 00:00 local.
  ({int days, int hours, int minutes, int seconds}) get weekCountdown {
    final now = DateTime.now();
    var daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    if (daysUntilMonday == 0) {
      daysUntilMonday = 7;
    }
    final end = DateTime(now.year, now.month, now.day)
        .add(Duration(days: daysUntilMonday));
    final diff = end.difference(now);
    return (
      days: diff.inDays,
      hours: diff.inHours % 24,
      minutes: diff.inMinutes % 60,
      seconds: diff.inSeconds % 60,
    );
  }

  void selectRankingTab(int index) {
    rankingTab.value = index.clamp(0, 2);
  }

  Future<void> loadFamilyHub() async {
    isLoading.value = true;
    try {
      final myResponse = await _familyRepo.getMyFamily(isShowLoader: false);
      final myData = myResponse?['data'];
      if (myData is Map && myData.isNotEmpty) {
        hasFamily.value = true;
        myFamily.assignAll(_mapFamily(myData));
        await _loadFamilyMembers(myFamily['id']?.toString() ?? '');
      } else {
        hasFamily.value = false;
        myFamily.clear();
      }

      final listResponse = await _familyRepo.getFamilies(isShowLoader: false);
      final listData = listResponse?['data'];
      final list = listData is Map ? listData['items'] : listData;
      if (list is List) {
        popularFamilies.assignAll(
          list
              .whereType<Map>()
              .map(_mapFamily)
              .where((family) => family['name'].toString().isNotEmpty),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinFamily(String name) async {
    Map<String, dynamic>? family;
    for (final item in popularFamilies) {
      if (item['name'] == name) {
        family = item;
        break;
      }
    }
    final familyId = family?['id']?.toString() ?? '';
    if (familyId.isEmpty) return;

    CommonAppDialog.showGet(
      title: 'Join Family',
      message: 'Send your request to join "$name"?',
      icon: Icons.groups_rounded,
      iconAccent: AdminAgencyUi.pink,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Join',
          isPrimary: true,
          onPressed: () async {
            final response = await _familyRepo.joinFamily(
              familyId: familyId,
              isShowLoader: true,
            );
            if (response == null || response['statusCode'] == 0) {
              Get.snackbar('Family', 'Could not join this family.');
              return;
            }
            await loadFamilyHub();
            Get.snackbar(
              'Welcome!',
              response['message']?.toString() ??
                  'Your family request was submitted.',
              backgroundColor: const Color(0xFF761B65).withValues(alpha: 0.1),
              colorText: const Color(0xFF761B65),
            );
          },
        ),
      ],
    );
  }

  void leaveFamily() {
    CommonAppDialog.showGet(
      title: 'Leave Family?',
      message:
          'Are you sure you want to leave this family? You will lose access to family chats, tasks and bonuses.',
      icon: Icons.logout_rounded,
      iconAccent: AdminAgencyUi.rose,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Leave',
          isPrimary: true,
          isDestructive: true,
          onPressed: () async {
            final response = await _familyRepo.leaveFamily(
              isShowLoader: true,
            );
            if (response == null || response['statusCode'] == 0) {
              Get.snackbar('Family', 'Could not leave this family.');
              return;
            }
            await loadFamilyHub();
            Get.snackbar(
              'Left Family',
              response['message']?.toString() ?? 'You have left the family.',
            );
          },
        ),
      ],
    );
  }

  void showCreateFamilyDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    CommonAppDialog.showGet(
      title: 'Create a Family',
      message:
          'Creation cost: 1,000 Coins. Build your community and climb the weekly ranks!',
      icon: Icons.diversity_3_rounded,
      iconAccent: AdminAgencyUi.goldDeep,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            maxLength: 20,
            style: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorWhite,
            ),
            decoration: InputDecoration(
              labelText: 'Family Name',
              labelStyle: TextStyle(color: kColorWhite.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.group, color: AdminAgencyUi.gold),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: kColorWhite.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminAgencyUi.gold),
              ),
            ),
          ),
          Spacing.v12,
          TextField(
            controller: descController,
            maxLength: 100,
            maxLines: 2,
            style: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorWhite,
            ),
            decoration: InputDecoration(
              labelText: 'Family Description',
              labelStyle: TextStyle(color: kColorWhite.withValues(alpha: 0.7)),
              prefixIcon: const Icon(
                Icons.description,
                color: AdminAgencyUi.violet,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: kColorWhite.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminAgencyUi.violet),
              ),
            ),
          ),
        ],
      ),
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Create',
          isPrimary: true,
          onPressed: () async {
            final name = nameController.text.trim();
            final desc = descController.text.trim();
            if (name.isEmpty) {
              Get.snackbar('Error', 'Family name cannot be empty');
              return;
            }
            final response = await _familyRepo.createFamily(
              name: name,
              description: desc.isNotEmpty
                  ? desc
                  : 'A brand new Qobo Live family.',
              isShowLoader: true,
            );
            if (response == null || response['statusCode'] == 0) {
              Get.snackbar('Family', 'Could not create family.');
              return;
            }
            await loadFamilyHub();
            Get.snackbar(
              'Congratulations!',
              response['message']?.toString() ??
                  'Family "$name" created successfully!',
              backgroundColor: const Color(0xFF761B65).withValues(alpha: 0.1),
              colorText: const Color(0xFF761B65),
            );
          },
        ),
      ],
    );
  }

  Future<void> _loadFamilyMembers(String familyId) async {
    if (familyId.isEmpty) return;
    final detailResponse = await _familyRepo.getFamilyDetail(
      familyId: familyId,
      isShowLoader: false,
    );
    final data = detailResponse?['data'];
    if (data is! Map) return;
    final members = data['members'];
    if (members is List) {
      familyMembers.assignAll(
        members.whereType<Map>().map((member) {
          final user = member['user'];
          final userMap = user is Map ? user : const {};
          final name =
              userMap['name']?.toString() ??
              member['name']?.toString() ??
              'Member';
          return <String, dynamic>{
            'name': name,
            'role': member['role']?.toString() ?? 'member',
            'contribution': _toInt(member['contribution']),
            'avatar': name.isNotEmpty
                ? name.substring(0, 1).toUpperCase()
                : 'M',
            'isOnline': member['isOnline'] == true,
            'level': _toInt(userMap['level']),
          };
        }),
      );
    }
  }

  Map<String, dynamic> _mapFamily(Map raw) {
    return <String, dynamic>{
      'id': raw['id']?.toString() ?? '',
      'name': raw['name']?.toString() ?? '',
      'members': _toInt(raw['members'] ?? raw['memberCount']),
      'maxMembers': _toInt(raw['maxMembers']) == 0
          ? 500
          : _toInt(raw['maxMembers']),
      'level': _toInt(raw['level']) == 0 ? 1 : _toInt(raw['level']),
      'leader':
          raw['leader']?.toString() ??
          raw['creatorName']?.toString() ??
          raw['creatorId']?.toString() ??
          '',
      'description': raw['description']?.toString() ?? '',
      'announcement': raw['announcement']?.toString() ?? '',
      'createdDate': raw['createdAt']?.toString() ?? '',
      'xp': _toInt(raw['xp']),
      'maxXp': _toInt(raw['maxXp']) == 0 ? 1000 : _toInt(raw['maxXp']),
      'role': raw['role']?.toString() ?? '',
    };
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
