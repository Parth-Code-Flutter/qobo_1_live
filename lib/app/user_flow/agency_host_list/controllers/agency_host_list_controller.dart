import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/app/user_flow/live_action/models/live_map_host.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
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

  List<LiveMapHost> mapHosts = [];
  List<String> suggestionAssets = [];

  AgencySessionController get _session => Get.find<AgencySessionController>();

  String get agencyDisplayName {
    final name = _session.agencyName.value.trim();
    if (name.isNotEmpty) return name;
    return AgencyRevenueDemo.agencyName;
  }

  static const _agencyAlignments = <Alignment>[
    Alignment(-0.35, -0.55),
    Alignment(0.42, -0.35),
    Alignment(-0.55, 0.05),
    Alignment(0.28, 0.22),
    Alignment(-0.12, -0.15),
    Alignment(0.62, 0.48),
    Alignment(-0.72, 0.42),
    Alignment(0.05, 0.72),
  ];

  static const _suggestionPool = <String>[
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
    kImgTemp5,
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
  ];

  static const _defaultDiscoverHosts = <LiveMapHost>[
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.10',
      imageAsset: kImgTemp2,
      alignment: Alignment(-0.68, -0.82),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.08',
      imageAsset: kImgTemp3,
      alignment: Alignment(0.54, -0.84),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.09',
      imageAsset: kImgTemp4,
      alignment: Alignment(-0.10, -0.42),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.12',
      imageAsset: kImgTemp5,
      alignment: Alignment(0.62, -0.30),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.07',
      imageAsset: kImgTemp3,
      alignment: Alignment(-0.78, 0.10),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.14',
      imageAsset: kImgTemp2,
      alignment: Alignment(0.10, 0.10),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.11',
      imageAsset: kImgTemp4,
      alignment: Alignment(0.56, 0.46),
    ),
    LiveMapHost(
      name: 'Afrin Sabila',
      levelBadge: 'LV.06',
      imageAsset: kImgTemp5,
      alignment: Alignment(0.08, 0.78),
    ),
  ];

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
      _buildMapHosts();
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
        _buildMapHosts();
        isLoading.value = false;
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
    _buildMapHosts();
    isLoading.value = false;
  }

  void _buildMapHosts() {
    final hosts = hostList;
    final mapped = <LiveMapHost>[];
    for (var i = 0; i < hosts.length; i++) {
      final host = hosts[i];
      mapped.add(
        LiveMapHost(
          name: host.name,
          levelBadge: 'LV.${host.coinsPerSecond}',
          imageAsset: _suggestionPool[i % _suggestionPool.length],
          alignment: _agencyAlignments[i % _agencyAlignments.length],
          isAgencyHost: true,
        ),
      );
    }
    for (var i = hosts.length; i < _agencyAlignments.length; i++) {
      final template = _defaultDiscoverHosts[i % _defaultDiscoverHosts.length];
      mapped.add(
        LiveMapHost(
          name: template.name,
          levelBadge: template.levelBadge,
          imageAsset: template.imageAsset,
          alignment: _agencyAlignments[i],
        ),
      );
    }
    mapHosts = mapped;
    suggestionAssets = mapped.take(7).map((h) => h.imageAsset).toList();
    update();
  }

  void refreshList() {
    _fetchHosts();
  }

  void onBackPressed() {
    Get.back<void>();
  }

  String formatCoins(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
