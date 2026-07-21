/// Shared models for Super Admin Dashboard / Agency / Host flows.
/// Spec: `super_admin_mobile_api_handover_v1.md`
library;

class SuperAdminStats {
  const SuperAdminStats({
    required this.totalAgencies,
    required this.activeAgencies,
    required this.suspendedAgencies,
    required this.activeHosts,
    required this.pendingAgencies,
    required this.pendingHosts,
    required this.liveHostsNow,
    required this.totalCommissions,
    required this.commissionsThisMonth,
    required this.topAgencies,
    required this.recentPendingAgencies,
  });

  final int totalAgencies;
  final int activeAgencies;
  final int suspendedAgencies;
  final int activeHosts;
  final int pendingAgencies;
  final int pendingHosts;
  final int liveHostsNow;
  final double totalCommissions;
  final double commissionsThisMonth;
  final List<SuperAdminTopAgency> topAgencies;
  final List<SuperAdminAgencyItem> recentPendingAgencies;

  factory SuperAdminStats.fromJson(Map<String, dynamic> json) {
    final top = json['topAgencies'];
    final recent = json['recentPendingAgencies'];
    return SuperAdminStats(
      totalAgencies: _asInt(json['totalAgencies']),
      activeAgencies: _asInt(json['activeAgencies']),
      suspendedAgencies: _asInt(json['suspendedAgencies']),
      activeHosts: _asInt(json['activeHosts']),
      pendingAgencies: _asInt(json['pendingAgencies']),
      pendingHosts: _asInt(json['pendingHosts']),
      liveHostsNow: _asInt(json['liveHostsNow']),
      totalCommissions: _asDouble(json['totalCommissions']),
      commissionsThisMonth: _asDouble(json['commissionsThisMonth']),
      topAgencies: top is List
          ? top
                .whereType<Map>()
                .map(
                  (e) => SuperAdminTopAgency.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      recentPendingAgencies: recent is List
          ? recent
                .whereType<Map>()
                .map(
                  (e) => SuperAdminAgencyItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class SuperAdminTopAgency {
  const SuperAdminTopAgency({
    required this.id,
    required this.name,
    required this.code,
    required this.totalCommissionEarned,
  });

  final String id;
  final String name;
  final String code;
  final double totalCommissionEarned;

  factory SuperAdminTopAgency.fromJson(Map<String, dynamic> json) {
    return SuperAdminTopAgency(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Agency'),
      code: _asString(json['code']),
      totalCommissionEarned: _asDouble(json['totalCommissionEarned']),
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
    this.commissionRate = 0,
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
  final double commissionRate;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved {
    final s = status.toLowerCase();
    return s == 'approved' || s == 'active';
  }

  bool get isSuspended => status.toLowerCase() == 'suspended';

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
      commissionRate: _asDouble(json['commissionRate']),
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
    this.phone = '',
    this.email = '',
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
  final String phone;
  final String email;

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
      phone: _asString(json['phone']),
      email: _asString(json['email']),
    );
  }
}

/// Full agency detail — `GET /api/super-admin/agencies/:agencyId`.
class SuperAdminAgencyDetail {
  const SuperAdminAgencyDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.logo,
    required this.commissionRate,
    required this.status,
    required this.feedback,
    required this.createdAt,
    required this.updatedAt,
    required this.address,
    required this.owner,
    required this.documents,
    required this.stats,
    required this.invitedBy,
  });

  final String id;
  final String name;
  final String code;
  final String logo;
  final double commissionRate;
  final String status;
  final String feedback;
  final String createdAt;
  final String updatedAt;
  final SuperAdminAddress address;
  final SuperAdminPerson owner;
  final SuperAdminDocuments documents;
  final SuperAdminAgencyStats stats;
  final SuperAdminPerson invitedBy;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved {
    final s = status.toLowerCase();
    return s == 'approved' || s == 'active';
  }

  bool get isSuspended => status.toLowerCase() == 'suspended';

  factory SuperAdminAgencyDetail.fromJson(Map<String, dynamic> json) {
    return SuperAdminAgencyDetail(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Agency'),
      code: _asString(json['code']),
      logo: _asString(json['logo']),
      commissionRate: _asDouble(json['commissionRate']),
      status: _asString(json['status'], fallback: 'pending'),
      feedback: _asString(json['feedback']),
      createdAt: _asString(json['createdAt']),
      updatedAt: _asString(json['updatedAt']),
      address: SuperAdminAddress.fromJson(
        json['address'] is Map
            ? Map<String, dynamic>.from(json['address'] as Map)
            : const {},
      ),
      owner: SuperAdminPerson.fromJson(
        json['owner'] is Map
            ? Map<String, dynamic>.from(json['owner'] as Map)
            : const {},
      ),
      documents: SuperAdminDocuments.fromJson(
        json['documents'] is Map
            ? Map<String, dynamic>.from(json['documents'] as Map)
            : const {},
      ),
      stats: SuperAdminAgencyStats.fromJson(
        json['stats'] is Map
            ? Map<String, dynamic>.from(json['stats'] as Map)
            : const {},
      ),
      invitedBy: SuperAdminPerson.fromJson(
        json['invitedBy'] is Map
            ? Map<String, dynamic>.from(json['invitedBy'] as Map)
            : const {},
      ),
    );
  }
}

class SuperAdminAddress {
  const SuperAdminAddress({
    required this.country,
    required this.state,
    required this.city,
    required this.fullAddress,
  });

  final String country;
  final String state;
  final String city;
  final String fullAddress;

  String get line {
    final parts = [
      fullAddress,
      city,
      state,
      country,
    ].where((e) => e.trim().isNotEmpty);
    return parts.join(', ');
  }

  factory SuperAdminAddress.fromJson(Map<String, dynamic> json) {
    return SuperAdminAddress(
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      fullAddress: _asString(json['fullAddress']),
    );
  }
}

class SuperAdminPerson {
  const SuperAdminPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.displayPicture,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String countryCode;
  final String displayPicture;
  final String role;

  factory SuperAdminPerson.fromJson(Map<String, dynamic> json) {
    return SuperAdminPerson(
      id: _asString(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      countryCode: _asString(json['countryCode']),
      displayPicture: _asString(json['displayPicture']),
      role: _asString(json['role']),
    );
  }
}

class SuperAdminDocuments {
  const SuperAdminDocuments({
    required this.docPhotoFront,
    required this.docPhotoBack,
    this.idNo = '',
    this.photo = '',
  });

  final String docPhotoFront;
  final String docPhotoBack;
  final String idNo;
  final String photo;

  factory SuperAdminDocuments.fromJson(Map<String, dynamic> json) {
    return SuperAdminDocuments(
      docPhotoFront: _asString(json['docPhotoFront']),
      docPhotoBack: _asString(json['docPhotoBack']),
      idNo: _asString(json['idNo']),
      photo: _asString(json['photo']),
    );
  }
}

class SuperAdminAgencyStats {
  const SuperAdminAgencyStats({
    required this.hostCount,
    required this.pendingHostsCount,
    required this.activeHostsCount,
    required this.totalCommissionEarned,
    required this.totalDiamonds,
    required this.totalCoins,
  });

  final int hostCount;
  final int pendingHostsCount;
  final int activeHostsCount;
  final double totalCommissionEarned;
  final double totalDiamonds;
  final double totalCoins;

  factory SuperAdminAgencyStats.fromJson(Map<String, dynamic> json) {
    return SuperAdminAgencyStats(
      hostCount: _asInt(json['hostCount']),
      pendingHostsCount: _asInt(json['pendingHostsCount']),
      activeHostsCount: _asInt(json['activeHostsCount']),
      totalCommissionEarned: _asDouble(json['totalCommissionEarned']),
      totalDiamonds: _asDouble(json['totalDiamonds']),
      totalCoins: _asDouble(json['totalCoins']),
    );
  }
}

/// Full host detail — `GET /api/super-admin/hosts/:hostId`.
class SuperAdminHostDetail {
  const SuperAdminHostDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.displayPicture,
    required this.role,
    required this.status,
    required this.category,
    required this.dob,
    required this.gender,
    required this.country,
    required this.state,
    required this.city,
    required this.address,
    required this.joinedAt,
    required this.agency,
    required this.earnings,
    required this.documents,
    required this.recentActivity,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String countryCode;
  final String displayPicture;
  final String role;
  final String status;
  final String category;
  final String dob;
  final String gender;
  final String country;
  final String state;
  final String city;
  final String address;
  final String joinedAt;
  final SuperAdminHostAgency agency;
  final SuperAdminHostEarnings earnings;
  final SuperAdminDocuments documents;
  final SuperAdminHostActivity recentActivity;

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'active' || s == 'approved';
  }

  bool get isSuspended => status.toLowerCase() == 'suspended';

  factory SuperAdminHostDetail.fromJson(Map<String, dynamic> json) {
    return SuperAdminHostDetail(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Host'),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      countryCode: _asString(json['countryCode']),
      displayPicture: _asString(json['displayPicture']),
      role: _asString(json['role']),
      status: _asString(json['status'], fallback: 'active'),
      category: _asString(json['category']),
      dob: _asString(json['dob']),
      gender: _asString(json['gender']),
      country: _asString(json['country']),
      state: _asString(json['state']),
      city: _asString(json['city']),
      address: _asString(json['address']),
      joinedAt: _asString(json['joinedAt']),
      agency: SuperAdminHostAgency.fromJson(
        json['agency'] is Map
            ? Map<String, dynamic>.from(json['agency'] as Map)
            : const {},
      ),
      earnings: SuperAdminHostEarnings.fromJson(
        json['earnings'] is Map
            ? Map<String, dynamic>.from(json['earnings'] as Map)
            : const {},
      ),
      documents: SuperAdminDocuments.fromJson(
        json['documents'] is Map
            ? Map<String, dynamic>.from(json['documents'] as Map)
            : const {},
      ),
      recentActivity: SuperAdminHostActivity.fromJson(
        json['recentActivity'] is Map
            ? Map<String, dynamic>.from(json['recentActivity'] as Map)
            : const {},
      ),
    );
  }
}

class SuperAdminHostAgency {
  const SuperAdminHostAgency({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  final String id;
  final String name;
  final String code;
  final String status;

  factory SuperAdminHostAgency.fromJson(Map<String, dynamic> json) {
    return SuperAdminHostAgency(
      id: _asString(json['id']),
      name: _asString(json['name']),
      code: _asString(json['code']),
      status: _asString(json['status']),
    );
  }
}

class SuperAdminHostEarnings {
  const SuperAdminHostEarnings({
    required this.diamonds,
    required this.coins,
    required this.totalStreamSeconds,
    required this.totalCommissionEarned,
    required this.coinsPerSecond,
  });

  final double diamonds;
  final double coins;
  final double totalStreamSeconds;
  final double totalCommissionEarned;
  final double coinsPerSecond;

  factory SuperAdminHostEarnings.fromJson(Map<String, dynamic> json) {
    return SuperAdminHostEarnings(
      diamonds: _asDouble(json['diamonds']),
      coins: _asDouble(json['coins']),
      totalStreamSeconds: _asDouble(json['totalStreamSeconds']),
      totalCommissionEarned: _asDouble(json['totalCommissionEarned']),
      coinsPerSecond: _asDouble(json['coinsPerSecond']),
    );
  }
}

class SuperAdminHostActivity {
  const SuperAdminHostActivity({
    required this.lastLiveAt,
    required this.isLiveNow,
    required this.totalSessions,
  });

  final String lastLiveAt;
  final bool isLiveNow;
  final int totalSessions;

  factory SuperAdminHostActivity.fromJson(Map<String, dynamic> json) {
    return SuperAdminHostActivity(
      lastLiveAt: _asString(json['lastLiveAt']),
      isLiveNow: json['isLiveNow'] == true,
      totalSessions: _asInt(json['totalSessions']),
    );
  }
}

/// Extracts agency/host list arrays from either legacy `data: []`
/// or paginated `data: { agencies|hosts: [] }` responses.
List<Map<String, dynamic>> extractSuperAdminListMaps(
  dynamic data, {
  required String nestedKey,
}) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (data is Map) {
    final nested = data[nestedKey];
    if (nested is List) {
      return nested
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  return const [];
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
