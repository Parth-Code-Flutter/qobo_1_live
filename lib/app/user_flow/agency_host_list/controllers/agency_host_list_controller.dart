import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_action/models/live_map_host.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../../agency_owner_dashboard/models/agency_dashboard_data.dart';
import '../../agency_owner_dashboard/models/agency_revenue_demo.dart';

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
    this.applicationId = '',
    this.phone = '',
    this.gmail = '',
    this.category = '',
    this.reason,
    this.createdAt = '',
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
  final String applicationId;
  final String phone;
  final String gmail;
  final String category;
  final String? reason;
  final String createdAt;

  bool get isPending => isHostStatusPending(status);
  bool get isActive => isHostStatusActive(status);
  bool get isRejected => isHostStatusRejected(status);

  String get reviewApplicationId =>
      applicationId.isNotEmpty ? applicationId : id;

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
      applicationId: demo.applicationId,
      phone: demo.phone,
      gmail: demo.gmail,
      category: demo.category,
      reason: demo.reason,
      createdAt: demo.createdAt,
    );
  }

  factory AgencyHostModel.fromApi(Map<String, dynamic> json) {
    final host = parseHostFromApi(json);
    return AgencyHostModel.fromDemo(host);
  }

  /// Maps `GET /api/agency/host-applications` item shape.
  factory AgencyHostModel.fromApplicationJson(Map<String, dynamic> json) {
    final demo = parseHostFromApi({
      ...json,
      'id': json['hostId']?.toString() ?? json['applicationId']?.toString(),
      'name': json['hostName']?.toString() ?? json['name']?.toString(),
      'applicationId': json['applicationId']?.toString(),
    });
    return AgencyHostModel.fromDemo(demo);
  }
}

class AgencyHostListController extends GetxController {
  AgencyHostListController({this.embeddedInBottomNav = false});

  final bool embeddedInBottomNav;

  static const maxTreeHosts = 10;

  /// Minimum nodes drawn on the tree so 1–2 hosts still show the full network.
  static const minTreeVisualSlots = 8;

  /// Host-list API filter — guide statuses: pending | approved | rejected.
  /// Tree UI still renders active/approved hosts only.
  static const String hostListStatus = 'all';

  final AgencyRepo _agencyRepo = AgencyRepo();

  final isLoading = true.obs;
  final loadError = ''.obs;
  final hostList = <AgencyHostModel>[].obs;
  final highlightHostId = RxnString();
  final processingReviewId = ''.obs;

  bool _fetchedWithAgencyContext = false;
  int _fetchSeq = 0;

  /// Whether the last host-list fetch ran after agency id was known.
  bool get fetchedWithAgencyContext => _fetchedWithAgencyContext;

  /// Top-ranked hosts rendered on the constellation tree (max 10).
  List<LiveMapHost> mapHosts = [];

  /// Hosts beyond [maxTreeHosts], shown in the bottom horizontal strip.
  List<AgencyHostModel> overflowHosts = [];

  AgencySessionController? get _session =>
      Get.isRegistered<AgencySessionController>()
      ? Get.find<AgencySessionController>()
      : null;

  bool get hasHosts => hostList.isNotEmpty;

  bool get hasOverflowHosts => overflowHosts.isNotEmpty;

  String get agencyDisplayName {
    final name = _session?.agencyName.value.trim() ?? '';
    if (name.isNotEmpty) return name;
    final applied = _session?.appliedAgencyName.value.trim() ?? '';
    if (applied.isNotEmpty) return applied;
    return 'Agency';
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

  Future<void> _fetchHosts({bool showLoading = true}) async {
    final seq = ++_fetchSeq;
    if (showLoading) {
      isLoading.value = true;
    }
    loadError.value = '';

    await _session?.ensureHydratedFromDashboard();
    if (seq != _fetchSeq) return;

    final agencyId = _session?.agencyId.value.trim() ?? '';
    _fetchedWithAgencyContext = agencyId.isNotEmpty;

    var loadedFromApi = false;
    try {
      final response = await _agencyRepo.getAgencyHostsList(
        agencyId: agencyId.isNotEmpty ? agencyId : null,
        status: hostListStatus,
        isShowLoader: false,
      );
      final hosts = _hostsFromResponse(response);
      if (isAgencyApiSuccess(response) && hosts != null) {
        loadedFromApi = true;
        _applyHosts(hosts);
        if (seq == _fetchSeq) {
          isLoading.value = false;
        }
        return;
      }
      loadError.value = agencyApiMessage(response) ?? 'Could not load hosts.';
    } catch (_) {
      loadError.value = 'Network error.';
    }

    if (seq != _fetchSeq) return;

    // Only fall back when the API call failed — not when it returned [].
    if (!loadedFromApi) {
      _applyHosts(_hostsWithoutAgencyId());
    }
    isLoading.value = false;
  }

  /// Session cache used when agency id is missing or host-list request fails.
  List<AgencyHostModel> _hostsWithoutAgencyId() {
    final cached = _session?.cachedHosts;
    if (cached != null && cached.isNotEmpty) {
      return cached
          .map(AgencyHostModel.fromDemo)
          .where((h) => h.isActive)
          .toList();
    }
    return [];
  }

  /// Accepts both `data: []` and wrapped `{ hosts|items|list: [] }` envelopes.
  List<AgencyHostModel>? _hostsFromResponse(Map<String, dynamic>? response) {
    final data = response?['data'];
    final list = data is List
        ? data
        : data is Map
        ? (data['hosts'] ?? data['items'] ?? data['list'] ?? data['data'])
        : null;
    if (list is! List) return null;
    return list
        .whereType<Map>()
        .map((e) => AgencyHostModel.fromApi(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _applyHosts(List<AgencyHostModel> hosts) {
    // Keep the full registry (pending/approved/rejected). Tree uses actives.
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
    final sorted = List<AgencyHostModel>.from(hostList.where((h) => h.isActive))
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
      alignment:
          _treeAlignmentsByRank[rankIndex.clamp(
            0,
            _treeAlignmentsByRank.length - 1,
          )],
      isAgencyHost: true,
      avatarUrl: host.avatarUrl.isNotEmpty ? host.avatarUrl : null,
      hostId: host.id.isNotEmpty ? host.id : host.reviewApplicationId,
      level: host.coinsPerSecond,
      isPending: host.isPending,
    );
  }

  LiveMapHost _placeholderNode(int slotIndex) {
    return LiveMapHost(
      name: '',
      levelBadge: '',
      imageAsset: _suggestionPool[slotIndex % _suggestionPool.length],
      alignment:
          _treeAlignmentsByRank[slotIndex.clamp(
            0,
            _treeAlignmentsByRank.length - 1,
          )],
      isPlaceholder: true,
    );
  }

  void refreshList({bool showLoading = true}) {
    _fetchHosts(showLoading: showLoading);
  }

  Future<void> openAddHost() async {
    await _session?.ensureHydratedFromDashboard();
    if (isClosed) return;

    final agencyCode = _session?.agencyCode.value.trim() ?? '';
    // GetPage routes are registered as dynamic; a typed result here makes
    // Navigator cast GetPageRoute<dynamic> to Route<bool?> and crashes.
    final added = await Get.toNamed(
      Routes.AGENCY_HOST_ONBOARDING,
      arguments: {
        'fromAgencyOwner': true,
        if (agencyCode.isNotEmpty) 'agencyCode': agencyCode,
        if (agencyCode.isNotEmpty) 'lockAgencyCode': true,
      },
    );
    if (added == true && !isClosed) {
      await _fetchHosts();
    }
  }

  void onBackPressed() {
    if (embeddedInBottomNav) {
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().onNavBarTabSelected(0);
      }
      return;
    }
    Get.back<void>();
  }

  /// Resolves a tree/overflow node back to full API host data.
  AgencyHostModel? hostById(String? hostId) {
    if (hostId == null || hostId.isEmpty) return null;
    for (final host in hostList) {
      if (host.id == hostId ||
          host.reviewApplicationId == hostId ||
          host.applicationId == hostId) {
        return host;
      }
    }
    return null;
  }

  Future<bool> approveHostApplication(AgencyHostModel host) async {
    final id = host.reviewApplicationId;
    if (id.isEmpty) return false;

    processingReviewId.value = id;
    try {
      final response = await _agencyRepo.approveHostApplication(
        applicationId: id,
        coinsPerSecond: host.coinsPerSecond > 0 ? host.coinsPerSecond : 5,
        note: 'Approved by Agency Owner',
      );
      if (isAgencyApiSuccess(response)) {
        hostList.removeWhere((h) => h.reviewApplicationId == id);
        _buildMapHosts();
        Get.snackbar(
          'Approved',
          agencyApiMessage(response) ?? '${host.name} is now active.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.85),
          colorText: Colors.white,
        );
        return true;
      }
      Get.snackbar(
        'Failed',
        agencyApiMessage(response) ?? 'Could not approve host.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error while approving.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processingReviewId.value = '';
    }
    return false;
  }

  Future<bool> rejectHostApplication(
    AgencyHostModel host,
    String reason,
  ) async {
    final id = host.reviewApplicationId;
    if (id.isEmpty) return false;

    processingReviewId.value = id;
    try {
      final response = await _agencyRepo.rejectHostApplication(
        applicationId: id,
        reason: reason,
      );
      if (isAgencyApiSuccess(response)) {
        hostList.removeWhere((h) => h.reviewApplicationId == id);
        _buildMapHosts();
        Get.snackbar(
          'Rejected',
          agencyApiMessage(response) ?? '${host.name} was rejected.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }
      Get.snackbar(
        'Failed',
        agencyApiMessage(response) ?? 'Could not reject host.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error while rejecting.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processingReviewId.value = '';
    }
    return false;
  }

  String formatCoins(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
