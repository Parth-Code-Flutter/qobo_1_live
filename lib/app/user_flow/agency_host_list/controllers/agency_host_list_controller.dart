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
    hostList.clear();
    isLoading.value = false;
  }

  void refreshList() {
    hostList.clear();
    _fetchHosts();
  }
}
