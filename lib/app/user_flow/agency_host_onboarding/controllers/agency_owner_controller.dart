import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

class AgencyOwnerController extends GetxController {
  // Agency State
  final hasAgency = false.obs;
  final agencyName = ''.obs;
  final agencyCode = ''.obs;
  
  // Stats
  final totalHosts = 12.obs;
  final monthlyEarningsPkr = 85200.obs;
  final pendingCommissionPkr = 12780.obs;

  // Form Controllers
  final nameController = TextEditingController();
  final descController = TextEditingController();

  // Mock Hosts list
  final hosts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMockHosts();
  }

  void loadMockHosts() {
    hosts.assignAll([
      {
        'id': 'HST_9921',
        'name': 'Aria Sen',
        'avatar': 'assets/images/temp_img_2.png',
        'earningsPkr': 24000,
        'commissionPkr': 3600,
        'status': 'ACTIVE',
      },
      {
        'id': 'HST_3829',
        'name': 'Riya Sharma',
        'avatar': 'assets/images/temp_img_4.png',
        'earningsPkr': 41000,
        'commissionPkr': 6150,
        'status': 'ACTIVE',
      },
      {
        'id': 'HST_0821',
        'name': 'Neha Khan',
        'avatar': 'assets/images/temp_img_2.png',
        'earningsPkr': 20200,
        'commissionPkr': 3030,
        'status': 'ACTIVE',
      },
    ]);
  }

  void createAgency() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Agency Name',
        'Please enter a valid Agency Name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: kColorWhite,
      );
      return;
    }

    agencyName.value = name;
    agencyCode.value = 'QOBO_AG_${name.replaceAll(' ', '_').toUpperCase()}_${hashCode.toString().substring(0, 3)}';
    hasAgency.value = true;

    Get.snackbar(
      'Agency Created',
      'Congratulations! Your agency "$name" has been registered.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: kColorWhite,
    );
  }

  void copyInviteLink() {
    final link = 'https://qobo.live/agency/join?code=${agencyCode.value}';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Link Copied',
      'Agency invite link copied: $link',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: kColorWhite,
    );
  }

  void copyInviteCode() {
    Clipboard.setData(ClipboardData(text: agencyCode.value));
    Get.snackbar(
      'Code Copied',
      'Agency code copied: ${agencyCode.value}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: kColorWhite,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    super.onClose();
  }
}
