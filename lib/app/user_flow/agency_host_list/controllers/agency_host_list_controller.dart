import 'package:get/get.dart';

class AgencyHostModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String status;
  final int totalEarnings;

  AgencyHostModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.status,
    required this.totalEarnings,
  });
}

class AgencyHostListController extends GetxController {
  final isLoading = true.obs;
  final hostList = <AgencyHostModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchHosts();
  }

  Future<void> _fetchHosts() async {
    isLoading.value = true;
    
    // Simulate API delay for GET /api/agency/host-list
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    
    // Mock Data
    hostList.addAll([
      AgencyHostModel(
        id: 'HST-1001',
        name: 'Sarah Khan',
        avatarUrl: 'https://i.pravatar.cc/150?u=1001',
        status: 'Active',
        totalEarnings: 45000,
      ),
      AgencyHostModel(
        id: 'HST-1002',
        name: 'Ali Raza',
        avatarUrl: 'https://i.pravatar.cc/150?u=1002',
        status: 'Pending',
        totalEarnings: 0,
      ),
      AgencyHostModel(
        id: 'HST-1003',
        name: 'Fatima Noor',
        avatarUrl: 'https://i.pravatar.cc/150?u=1003',
        status: 'Active',
        totalEarnings: 82000,
      ),
      AgencyHostModel(
        id: 'HST-1004',
        name: 'Osman Malik',
        avatarUrl: 'https://i.pravatar.cc/150?u=1004',
        status: 'Suspended',
        totalEarnings: 1500,
      ),
    ]);

    isLoading.value = false;
  }

  void refreshList() {
    hostList.clear();
    _fetchHosts();
  }
}
