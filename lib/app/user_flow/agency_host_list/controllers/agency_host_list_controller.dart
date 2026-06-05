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
  static const maxTreeHosts = 10;

  /// Minimum nodes drawn on the tree so 1–2 hosts still show the full network.
  static const minTreeVisualSlots = 8;

  final AgencyRepo _agencyRepo = AgencyRepo();

  final isLoading = true.obs;
  final loadError = ''.obs;
  final hostList = <AgencyHostModel>[].obs;
  final highlightHostId = RxnString();

  /// Top-ranked hosts rendered on the constellation tree (max 10).
  List<LiveMapHost> mapHosts = [];

  /// Hosts beyond [maxTreeHosts], shown in the bottom horizontal strip.
  List<AgencyHostModel> overflowHosts = [];

  AgencySessionController get _session => Get.find<AgencySessionController>();

  bool get hasHosts => hostList.isNotEmpty;

  bool get hasOverflowHosts => overflowHosts.isNotEmpty;

  String get agencyDisplayName {
    final name = _session.agencyName.value.trim();
    if (name.isNotEmpty) return name;
    return AgencyRevenueDemo.agencyName;
  }

  /// Tree slots ordered top → bottom. Index 0 = highest level (top center).
  static const _treeAlignmentsByRank = <Alignment>[
    Alignment(0, -0.72),
    Alignment(-0.42, -0.48),
    Alignment(0.42, -0.48),
    Alignment(-0.62, -0.18),
    Alignment(0.08, -0.22),
    Alignment(0.58, -0.12),
    Alignment(-0.32, 0.12),
    Alignment(0.34, 0.18),
    Alignment(-0.58, 0.42),
    Alignment(0.48, 0.48),
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
      _applyHosts(_hostsWithoutAgencyId());
      isLoading.value = false;
      return;
    }

    var loadedFromApi = false;
    try {
      final response = await _agencyRepo.getAgencyHostsList(
        agencyId: agencyId,
        isShowLoader: false,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is List) {
        loadedFromApi = true;
        _applyHosts(
          data
              .whereType<Map>()
              .map((e) => AgencyHostModel.fromApi(Map<String, dynamic>.from(e)))
              .toList(),
        );
        isLoading.value = false;
        return;
      }
      loadError.value = agencyApiMessage(response) ?? 'Could not load hosts.';
    } catch (_) {
      loadError.value = 'Network error.';
    }

    // Only fall back when the API call failed — not when it returned [].
    if (!loadedFromApi) {
      _applyHosts(_hostsWithoutAgencyId());
    }
    isLoading.value = false;
  }

  /// Session cache used when agency id is missing or host-list request fails.
  List<AgencyHostModel> _hostsWithoutAgencyId() {
    final cached = _session.cachedHosts;
    if (cached.isNotEmpty) {
      return cached.map(AgencyHostModel.fromDemo).toList();
    }
    return [];
  }

  void _applyHosts(List<AgencyHostModel> hosts) {
    hostList.assignAll(hosts);
    _buildMapHosts();
  }

  /// Builds tree + overflow lists from API data.
  ///
  /// - Sort by level (`coinsPerSecond`) descending — highest first.
  /// - Place up to [maxTreeHosts] on the tree; remainder in [overflowHosts].
  /// - Highest-level host uses tree slot 0 (top center).
  /// - Blank placeholder slots pad the tree when host count < [minTreeVisualSlots].
  void _buildMapHosts() {
    final sorted = List<AgencyHostModel>.from(hostList)
      ..sort((a, b) {
        final byLevel = b.coinsPerSecond.compareTo(a.coinsPerSecond);
        if (byLevel != 0) return byLevel;
        return a.name.compareTo(b.name);
      });

    final treeSources = sorted.take(maxTreeHosts).toList();
    overflowHosts = sorted.length > maxTreeHosts
        ? sorted.sublist(maxTreeHosts)
        : [];

    if (treeSources.isEmpty) {
      mapHosts = [];
      update();
      return;
    }

    final mapped = <LiveMapHost>[
      for (var i = 0; i < treeSources.length; i++)
        _toMapNode(treeSources[i], i),
    ];

    // Pad with empty nodes so dashed lines / rings always form a full tree.
    final visualSlots = treeSources.length >= minTreeVisualSlots
        ? treeSources.length
        : minTreeVisualSlots;
    for (var slot = treeSources.length; slot < visualSlots; slot++) {
      mapped.add(_placeholderNode(slot));
    }

    mapHosts = mapped;
    update();
  }

  LiveMapHost _toMapNode(AgencyHostModel host, int rankIndex) {
    return LiveMapHost(
      name: host.name,
      levelBadge: 'LV.${host.coinsPerSecond}',
      imageAsset: _suggestionPool[rankIndex % _suggestionPool.length],
      alignment: _treeAlignmentsByRank[
          rankIndex.clamp(0, _treeAlignmentsByRank.length - 1)],
      isAgencyHost: true,
      avatarUrl: host.avatarUrl.isNotEmpty ? host.avatarUrl : null,
      hostId: host.id,
      level: host.coinsPerSecond,
    );
  }

  LiveMapHost _placeholderNode(int slotIndex) {
    return LiveMapHost(
      name: '',
      levelBadge: '',
      imageAsset: _suggestionPool[slotIndex % _suggestionPool.length],
      alignment: _treeAlignmentsByRank[
          slotIndex.clamp(0, _treeAlignmentsByRank.length - 1)],
      isPlaceholder: true,
    );
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
