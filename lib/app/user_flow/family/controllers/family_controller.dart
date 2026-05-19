import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FamilyController extends GetxController {
  final hasFamily = false.obs;
  final searchQuery = ''.obs;

  // Mock list of popular families
  final RxList<Map<String, dynamic>> popularFamilies = <Map<String, dynamic>>[
    {'id': 'fam_1', 'name': 'The Royals', 'members': 450, 'maxMembers': 500, 'level': 5, 'leader': 'KingArthur', 'description': 'The most prestigious family in Qobo Live.'},
    {'id': 'fam_2', 'name': 'Star Gazers', 'members': 320, 'maxMembers': 400, 'level': 4, 'leader': 'Luna', 'description': 'Late night chats and chill acoustic music sessions.'},
    {'id': 'fam_3', 'name': 'Dragon Fire', 'members': 490, 'maxMembers': 500, 'level': 7, 'leader': 'Draco', 'description': 'Competitive PK battles and level grinders.'},
    {'id': 'fam_4', 'name': 'Elite Club', 'members': 120, 'maxMembers': 200, 'level': 3, 'leader': 'Alpha', 'description': 'An exclusive space for SVIP members.'},
    {'id': 'fam_5', 'name': 'Sound Waves', 'members': 285, 'maxMembers': 300, 'level': 4, 'leader': 'Vocalist', 'description': 'Singers, musicians and music lovers congregate here.'},
  ].obs;

  // Active family user details (populated when hasFamily is true)
  final RxMap<String, dynamic> myFamily = <String, dynamic>{}.obs;

  // Mock list of members for active family
  final RxList<Map<String, dynamic>> familyMembers = <Map<String, dynamic>>[
    {'name': 'KingArthur', 'role': 'Leader', 'contribution': 12500, 'avatar': 'K', 'isOnline': true, 'level': 45},
    {'name': 'SirLancelot', 'role': 'Co-Leader', 'contribution': 8400, 'avatar': 'S', 'isOnline': true, 'level': 38},
    {'name': 'Merlin', 'role': 'Elder', 'contribution': 5600, 'avatar': 'M', 'isOnline': false, 'level': 32},
    {'name': 'Gwen', 'role': 'Member', 'contribution': 2300, 'avatar': 'G', 'isOnline': true, 'level': 18},
    {'name': 'Percival', 'role': 'Member', 'contribution': 1100, 'avatar': 'P', 'isOnline': false, 'level': 15},
  ].obs;

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

  void joinFamily(String name) {
    // Simulate successfully joining a family
    Get.dialog(
      AlertDialog(
        title: const Text('Application Submitted'),
        content: Text('Your request to join "$name" has been sent to the leader. You will be notified once approved.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Simulating instant join for demo purposes
              hasFamily.value = true;
              myFamily.value = {
                'id': 'fam_1',
                'name': name,
                'members': 451,
                'maxMembers': 500,
                'level': 5,
                'leader': 'KingArthur',
                'description': 'The most prestigious family in Qobo Live.',
                'announcement': 'Welcome to the family! Join the group audio room at 8 PM for the weekly talk show. 🎙️🏆',
                'createdDate': '2026-01-10',
                'xp': 3200,
                'maxXp': 5000,
              };
              Get.snackbar(
                'Welcome!',
                'You have successfully joined $name!',
                backgroundColor: const Color(0xFF761B65).withOpacity(0.1),
                colorText: const Color(0xFF761B65),
              );
            },
            child: const Text('Instant Join (Demo)'),
          )
        ],
      ),
    );
  }

  void leaveFamily() {
    Get.dialog(
      AlertDialog(
        title: const Text('Leave Family?'),
        content: const Text('Are you sure you want to leave this family? You will lose access to family chats, tasks and bonuses.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              hasFamily.value = false;
              myFamily.clear();
              Get.snackbar(
                'Left Family',
                'You have left the family.',
                backgroundColor: Colors.red.withOpacity(0.1),
                colorText: Colors.red,
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF761B65),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              if (name.isEmpty) {
                Get.snackbar('Error', 'Family name cannot be empty');
                return;
              }
              Get.back();
              // Simulating creation success
              hasFamily.value = true;
              myFamily.value = {
                'id': 'fam_new',
                'name': name,
                'members': 1,
                'maxMembers': 100,
                'level': 1,
                'leader': 'MyNickname',
                'description': desc.isNotEmpty ? desc : 'A brand new Qobo Live family.',
                'announcement': 'Welcome to my new family! Let\'s build something great.',
                'createdDate': '2026-05-19',
                'xp': 0,
                'maxXp': 1000,
              };

              // Customize member list with leader being the user
              familyMembers.value = [
                {'name': 'You (Leader)', 'role': 'Leader', 'contribution': 0, 'avatar': 'Y', 'isOnline': true, 'level': 1},
              ];

              Get.snackbar(
                'Congratulations!',
                'Family "$name" created successfully!',
                backgroundColor: const Color(0xFF761B65).withOpacity(0.1),
                colorText: const Color(0xFF761B65),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
