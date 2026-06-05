import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

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
      avatarUrl: demo.photoUrl ?? '',
      status: demo.status,
      totalEarnings: demo.totalEarnings,
      totalGifts: demo.totalGifts,
      totalCallingSpend: demo.totalCallingSpend,
      callingMinutes: demo.callingMinutes,
      coinsPerSecond: demo.coinsPerSecond,
      lastViewer: demo.lastViewer,
    );
  }

  factory AgencyHostModel.fromApi(Map<String, dynamic> json) {
    final host = parseHostFromApi(json);
    return AgencyHostModel.fromDemo(host);
  }
}

class AgencyHostListController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final isLoading = true.obs;
  final loadError = ''.obs;
  final hostList = <AgencyHostModel>[].obs;
  final highlightHostId = RxnString();

  AgencySessionController get _session => Get.find<AgencySessionController>();

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
    loadError.value = '';

    final agencyId = _session.agencyId.value;
    if (agencyId.isEmpty) {
      hostList.assignAll(AgencyRevenueDemo.hosts.map(AgencyHostModel.fromDemo));
      isLoading.value = false;
      return;
    }

    try {
      final response = await _agencyRepo.getAgencyHostsList(
        agencyId: agencyId,
        isShowLoader: false,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is List) {
        hostList.assignAll(
          data
              .whereType<Map>()
              .map((e) => AgencyHostModel.fromApi(Map<String, dynamic>.from(e)))
              .toList(),
        );
        return;
      }
      loadError.value = agencyApiMessage(response) ?? 'Could not load hosts.';
    } catch (_) {
      loadError.value = 'Network error.';
    }

    if (hostList.isEmpty) {
      final cached = _session.cachedHosts;
      if (cached.isNotEmpty) {
        hostList.assignAll(cached.map(AgencyHostModel.fromDemo));
      } else {
        hostList.assignAll(AgencyRevenueDemo.hosts.map(AgencyHostModel.fromDemo));
      }
    }
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
