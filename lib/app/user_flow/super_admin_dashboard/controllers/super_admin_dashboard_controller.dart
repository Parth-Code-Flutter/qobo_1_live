import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/utils/files_utils/file_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class SuperAdminStats {
  const SuperAdminStats({
    required this.totalAgencies,
    required this.activeHosts,
    required this.pendingAgencies,
    required this.pendingHosts,
    required this.totalCommissions,
  });

  final int totalAgencies;
  final int activeHosts;
  final int pendingAgencies;
  final int pendingHosts;
  final double totalCommissions;

  factory SuperAdminStats.fromJson(Map<String, dynamic> json) {
    return SuperAdminStats(
      totalAgencies: _asInt(json['totalAgencies']),
      activeHosts: _asInt(json['activeHosts']),
      pendingAgencies: _asInt(json['pendingAgencies']),
      pendingHosts: _asInt(json['pendingHosts']),
      totalCommissions: _asDouble(json['totalCommissions']),
    );
  }
}

class SuperAdminAgencyItem {
  const SuperAdminAgencyItem({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.ownerAvatar,
    required this.hostCount,
    required this.pendingHostsCount,
  });

  final String id;
  final String name;
  final String code;
  final String status;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String ownerAvatar;
  final int hostCount;
  final int pendingHostsCount;

  bool get isPending => isAgencyStatusPending(status);

  factory SuperAdminAgencyItem.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] is Map
        ? Map<String, dynamic>.from(json['owner'] as Map)
        : <String, dynamic>{};
    return SuperAdminAgencyItem(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Agency'),
      code: _asString(json['code']),
      status: _asString(json['status'], fallback: 'pending'),
      ownerName: _asString(owner['name'], fallback: 'Owner'),
      ownerPhone: _asString(owner['phone']),
      ownerEmail: _asString(owner['email']),
      ownerAvatar: _asString(owner['displayPicture']),
      hostCount: _asInt(json['hostCount']),
      pendingHostsCount: _asInt(json['pendingHostsCount']),
    );
  }
}

class SuperAdminTrackedHost {
  const SuperAdminTrackedHost({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.agencyCode,
    required this.status,
    required this.diamonds,
    required this.coins,
    required this.totalStreamSeconds,
    required this.totalCommissionEarned,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String agencyCode;
  final String status;
  final double diamonds;
  final double coins;
  final double totalStreamSeconds;
  final double totalCommissionEarned;

  factory SuperAdminTrackedHost.fromJson(Map<String, dynamic> json) {
    return SuperAdminTrackedHost(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Host'),
      avatarUrl: _asString(json['displayPicture']),
      agencyCode: _asString(json['agencyCode']),
      status: _asString(json['status'], fallback: 'active'),
      diamonds: _asDouble(json['diamonds']),
      coins: _asDouble(json['coins']),
      totalStreamSeconds: _asDouble(json['totalStreamSeconds']),
      totalCommissionEarned: _asDouble(json['totalCommissionEarned']),
    );
  }
}

class SuperAdminDashboardController extends GetxController {
  final SuperAdminRepo _repo = SuperAdminRepo();

  final isLoading = true.obs;
  final error = ''.obs;
  final stats = Rxn<SuperAdminStats>();
  final agencies = <SuperAdminAgencyItem>[].obs;
  final trackedHosts = <SuperAdminTrackedHost>[].obs;
  final processingAgencyId = ''.obs;
  final agencyStatusFilter = 'pending'.obs;
  final generatedAgencyLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard({bool showLoader = true}) async {
    isLoading.value = true;
    error.value = '';
    try {
      await Future.wait([
        _fetchStats(showLoader: showLoader),
        _fetchAgencies(showLoader: showLoader),
        _fetchTrackedHosts(showLoader: showLoader),
      ]);
    } catch (_) {
      error.value = 'Unable to load Super Admin dashboard.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeAgencyFilter(String status) async {
    agencyStatusFilter.value = status;
    await _fetchAgencies(showLoader: false);
  }

  Future<void> approveAgency(SuperAdminAgencyItem agency) async {
    await _processAgency(agency, 'approved');
  }

  Future<void> rejectAgency(
    SuperAdminAgencyItem agency,
    String feedback,
  ) async {
    await _processAgency(agency, 'rejected', feedback: feedback);
  }

  Future<void> generateAgencyLink() async {
    final response = await _repo.generateAgencyLink();
    final data = response?['data'];
    if (!isAgencyApiSuccess(response) || data is! Map) {
      AppToast.showError(
        Get.context!,
        agencyApiMessage(response) ?? 'Could not generate link.',
      );
      return;
    }

    final link = _asString(data['link']);
    final text = _asString(data['whatsappText'], fallback: link);
    generatedAgencyLink.value = link;
    await Clipboard.setData(ClipboardData(text: text));
    if (link.isNotEmpty) {
      await FileUtils.openFileOrLink(
        'https://wa.me/?text=${Uri.encodeComponent(text)}',
      );
    }
    AppToast.showSuccess(Get.context!, 'Agency invite copied.');
  }

  Future<void> _fetchStats({bool showLoader = true}) async {
    final response = await _repo.getDashboard(isShowLoader: showLoader);
    final data = response?['data'];
    if (isAgencyApiSuccess(response) && data is Map) {
      stats.value = SuperAdminStats.fromJson(Map<String, dynamic>.from(data));
    }
  }

  Future<void> _fetchAgencies({bool showLoader = true}) async {
    final response = await _repo.getAgencies(
      status: agencyStatusFilter.value,
      isShowLoader: showLoader,
    );
    final data = response?['data'];
    if (isAgencyApiSuccess(response) && data is List) {
      agencies.assignAll(
        data
            .whereType<Map>()
            .map(
              (e) =>
                  SuperAdminAgencyItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
    }
  }

  Future<void> _fetchTrackedHosts({bool showLoader = true}) async {
    final response = await _repo.getTrackedHosts(isShowLoader: showLoader);
    final data = response?['data'];
    if (isAgencyApiSuccess(response) && data is List) {
      trackedHosts.assignAll(
        data
            .whereType<Map>()
            .map(
              (e) =>
                  SuperAdminTrackedHost.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
      );
    }
  }

  Future<void> _processAgency(
    SuperAdminAgencyItem agency,
    String status, {
    String? feedback,
  }) async {
    if (agency.id.isEmpty) return;
    processingAgencyId.value = agency.id;
    try {
      final response = await _repo.processAgency(
        agencyId: agency.id,
        status: status,
        feedback: feedback,
      );
      if (isAgencyApiSuccess(response)) {
        AppToast.showSuccess(
          Get.context!,
          agencyApiMessage(response) ?? 'Agency $status.',
        );
        await _fetchAgencies(showLoader: false);
        await _fetchStats(showLoader: false);
        return;
      }
      AppToast.showError(
        Get.context!,
        agencyApiMessage(response) ?? 'Could not update agency.',
      );
    } finally {
      processingAgencyId.value = '';
    }
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
