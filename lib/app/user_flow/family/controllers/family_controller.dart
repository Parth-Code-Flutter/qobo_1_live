import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/family/family_repo.dart';

class FamilyController extends GetxController {
  FamilyController({FamilyRepo? familyRepo})
    : _familyRepo = familyRepo ?? FamilyRepo();

  final FamilyRepo _familyRepo;
  final isLoading = false.obs;

  final hasFamily = false.obs;
  final searchQuery = ''.obs;

  // Mock list of popular families
  final RxList<Map<String, dynamic>> popularFamilies = <Map<String, dynamic>>[
    {
      'id': 'fam_1',
      'name': 'The Royals',
      'members': 450,
      'maxMembers': 500,
      'level': 5,
      'leader': 'KingArthur',
      'description': 'The most prestigious family in Qobo Live.',
    },
    {
      'id': 'fam_2',
      'name': 'Star Gazers',
      'members': 320,
      'maxMembers': 400,
      'level': 4,
      'leader': 'Luna',
      'description': 'Late night chats and chill acoustic music sessions.',
    },
    {
      'id': 'fam_3',
      'name': 'Dragon Fire',
      'members': 490,
      'maxMembers': 500,
      'level': 7,
      'leader': 'Draco',
      'description': 'Competitive PK battles and level grinders.',
    },
    {
      'id': 'fam_4',
      'name': 'Elite Club',
      'members': 120,
      'maxMembers': 200,
      'level': 3,
      'leader': 'Alpha',
      'description': 'An exclusive space for SVIP members.',
    },
    {
      'id': 'fam_5',
      'name': 'Sound Waves',
      'members': 285,
      'maxMembers': 300,
      'level': 4,
      'leader': 'Vocalist',
      'description': 'Singers, musicians and music lovers congregate here.',
    },
  ].obs;

  // Active family user details (populated when hasFamily is true)
  final RxMap<String, dynamic> myFamily = <String, dynamic>{}.obs;

  // Mock list of members for active family
  final RxList<Map<String, dynamic>> familyMembers = <Map<String, dynamic>>[
    {
      'name': 'KingArthur',
      'role': 'Leader',
      'contribution': 12500,
      'avatar': 'K',
      'isOnline': true,
      'level': 45,
    },
    {
      'name': 'SirLancelot',
      'role': 'Co-Leader',
      'contribution': 8400,
      'avatar': 'S',
      'isOnline': true,
      'level': 38,
    },
    {
      'name': 'Merlin',
      'role': 'Elder',
      'contribution': 5600,
      'avatar': 'M',
      'isOnline': false,
      'level': 32,
    },
    {
      'name': 'Gwen',
      'role': 'Member',
      'contribution': 2300,
      'avatar': 'G',
      'isOnline': true,
      'level': 18,
    },
    {
      'name': 'Percival',
      'role': 'Member',
      'contribution': 1100,
      'avatar': 'P',
      'isOnline': false,
      'level': 15,
    },
  ].obs;

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

    Get.dialog(
      AlertDialog(
        title: const Text('Application Submitted'),
        content: Text('Send your request to join "$name"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          TextButton(
            onPressed: () async {
              Get.back();
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
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void leaveFamily() {
    Get.dialog(
      AlertDialog(
        title: const Text('Leave Family?'),
        content: const Text(
          'Are you sure you want to leave this family? You will lose access to family chats, tasks and bonuses.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
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
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showCreateFamilyDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create a Family'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Creation cost: 1,000 Coins\nCreate your own community and climb the weekly ranks!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Family Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLength: 100,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Family Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF761B65),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              if (name.isEmpty) {
                Get.snackbar('Error', 'Family name cannot be empty');
                return;
              }
              Get.back();
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
            child: const Text('Create'),
          ),
        ],
      ),
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
