/// Shared models for Super Admin Dashboard / Agency / Host tabs.
library;

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

  bool get isPending => status.toLowerCase() == 'pending';

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
