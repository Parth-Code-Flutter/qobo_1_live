import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';

class AgencyHostModel {
  AgencyHostModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.status,
    required this.totalEarnings,
    required this.totalGifts,
    required this.totalCallingSpend,
    required this.callingMinutes,
    required this.coinsPerSecond,
    required this.lastViewer,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String status;
  final int totalEarnings;
  final int totalGifts;
  final int totalCallingSpend;
  final int callingMinutes;
  final int coinsPerSecond;
  final String lastViewer;

  factory AgencyHostModel.fromDemo(AgencyHostRevenueDemo demo) {
    return AgencyHostModel(
      id: demo.id,
      name: demo.name,
      avatarUrl: '',
      status: demo.status,
      totalEarnings: demo.totalEarnings,
      totalGifts: demo.totalGifts,
      totalCallingSpend: demo.totalCallingSpend,
      callingMinutes: demo.callingMinutes,
      coinsPerSecond: demo.coinsPerSecond,
      lastViewer: demo.lastViewer,
    );
  }
}

class AgencyHostListController extends GetxController {
  final isLoading = true.obs;
  final hostList = <AgencyHostModel>[].obs;
  final highlightHostId = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['highlightHostId'] != null) {
      highlightHostId.value = args['highlightHostId'].toString();
    }
    _fetchHosts();
  }

  Future<void> _fetchHosts() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    hostList.assignAll(
      AgencyRevenueDemo.hosts.map(AgencyHostModel.fromDemo),
    );
    isLoading.value = false;
  }

  void refreshList() {
    _fetchHosts();
  }

  String formatCoins(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
