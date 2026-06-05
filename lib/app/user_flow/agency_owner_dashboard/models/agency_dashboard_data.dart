import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_status/models/agency_owner_application_state.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';

/// Parsed `GET /api/agency/dashboard` response `data` object.
class AgencyDashboardData {
  AgencyDashboardData({
    required this.agencyId,
    required this.agencyName,
    required this.agencyCode,
    required this.agencyStatus,
    required this.commissionRate,
    required this.ownerName,
    required this.ownerCoinsPerSecond,
    required this.month,
    required this.totalAgencyEarnings,
    required this.availableForPayout,
    required this.activeHosts,
    required this.totalTalkMinutes,
    required this.totalCallingGross,
    required this.companyShare,
    required this.hostCallShare,
    required this.ownerCommissionCoins,
    required this.totalGiftsVolume,
    required this.pendingCommissionCount,
    required this.payoutStatus,
    required this.recruitLink,
    required this.hosts,
    this.latestCall,
    this.applicationState = AgencyOwnerApplicationState.none,
  });

  final String agencyId;
  final String agencyName;
  final String agencyCode;
  final String agencyStatus;
  final double commissionRate;
  final String ownerName;
  final int ownerCoinsPerSecond;
  final String month;
  final int totalAgencyEarnings;
  final int availableForPayout;
  final int activeHosts;
  final int totalTalkMinutes;
  final int totalCallingGross;
  final int companyShare;
  final int hostCallShare;
  final int ownerCommissionCoins;
  final int totalGiftsVolume;
  final int pendingCommissionCount;
  final String payoutStatus;
  final String recruitLink;
  final List<AgencyHostRevenueDemo> hosts;
  final AgencyCallSample? latestCall;

  bool get isApproved => isAgencyStatusApproved(agencyStatus);

  bool get isPending =>
      isAgencyStatusPending(agencyStatus) ||
      applicationState == AgencyOwnerApplicationState.pending;

  final AgencyOwnerApplicationState applicationState;

  factory AgencyDashboardData.fromJson(Map<String, dynamic> json) {
    final agency = _asMap(json['agency']);
    final owner = _asMap(json['owner']);
    final summary = _asMap(json['summary']);
    final latestRaw = json['latestCall'];
    final agencyStatus = agency['status']?.toString() ??
        json['applicationStatus']?.toString() ??
        json['status']?.toString() ??
        'active';

    return AgencyDashboardData(
      agencyId: agency['id']?.toString() ?? '',
      agencyName: agency['name']?.toString() ?? '',
      agencyCode: agency['code']?.toString() ?? '',
      agencyStatus: agencyStatus,
      applicationState: AgencyOwnerApplicationState.fromApi(agencyStatus),
      commissionRate: _toDouble(agency['commissionRate']),
      ownerName: owner['name']?.toString() ?? '',
      ownerCoinsPerSecond: _toInt(owner['coinsPerSecond']),
      month: json['month']?.toString() ?? '',
      totalAgencyEarnings: _toInt(summary['totalAgencyEarnings']),
      availableForPayout: _toInt(summary['availableForPayout']),
      activeHosts: _toInt(summary['activeHosts']),
      totalTalkMinutes: _toInt(summary['totalTalkMinutes']),
      totalCallingGross: _toInt(summary['totalCallingGross']),
      companyShare: _toInt(summary['companyShare']),
      hostCallShare: _toInt(summary['hostCallShare']),
      ownerCommissionCoins: _toInt(summary['ownerCommissionCoins']),
      totalGiftsVolume: _toInt(summary['totalGiftsVolume']),
      pendingCommissionCount: _toInt(summary['pendingCommissionCount']),
      payoutStatus: summary['payoutStatus']?.toString() ?? '',
      recruitLink: json['recruitLink']?.toString() ?? '',
      hosts: _parseHosts(json['hosts']),
      latestCall: latestRaw is Map
          ? _parseLatestCall(Map<String, dynamic>.from(latestRaw))
          : null,
    );
  }

  static List<AgencyHostRevenueDemo> _parseHosts(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => parseHostFromApi(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

AgencyCallSample _parseLatestCall(Map<String, dynamic> json) {
  return AgencyCallSample(
    hostName: json['hostName']?.toString() ?? '',
    viewerName: json['viewerName']?.toString() ?? '',
    durationSeconds: _toInt(json['durationSeconds']),
    coinsPerSecond: _toInt(json['coinsPerSecond']),
    grossCoins: _toInt(json['grossCoins']),
    companyCoins: _toInt(json['companyCoins']),
    hostCoins: _toInt(json['hostCoins']),
    giftsDuringCall: _toInt(json['giftsDuringCall']),
  );
}

AgencyHostRevenueDemo parseHostFromApi(Map<String, dynamic> json) {
  return AgencyHostRevenueDemo(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    status: json['status']?.toString() ?? 'active',
    coinsPerSecond: _toInt(json['coinsPerSecond']),
    totalEarnings: _toInt(json['totalEarnings']),
    totalGifts: _toInt(json['totalGifts']),
    totalCallingSpend: _toInt(json['totalCallingSpend']),
    callingMinutes: _toInt(json['callingMinutes']),
    lastViewer: json['lastViewer']?.toString() ?? '',
    photoUrl: json['photo']?.toString(),
  );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
