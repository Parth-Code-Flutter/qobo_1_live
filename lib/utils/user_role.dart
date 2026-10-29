import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

/// Account role used on profile, Discover, room cards, and people lists.
///
/// Privileged roles win over a plain `user`. A missing role stays `user`.
String normalizeUserRole(String? raw) {
  final normalized = (raw ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');
  if (normalized == 'super_admin' || normalized == 'superadmin') {
    return 'super_admin';
  }
  if (normalized == 'agency' ||
      normalized == 'agency_owner' ||
      normalized == 'agencyowner') {
    return 'agency';
  }
  if (normalized == 'host') return 'host';
  if (normalized == 'coin_seller' ||
      normalized == 'coins_seller' ||
      normalized == 'seller' ||
      normalized == 'seller_admin') {
    return 'coins_seller';
  }
  return 'user';
}

/// Reads a role from a user, host, or room row.
String readUserRole(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return 'user';

  for (final key in const [
    'role',
    'userRole',
    'user_role',
    'accountRole',
    'account_role',
  ]) {
    final text = raw[key]?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') continue;
    final role = normalizeUserRole(text);
    if (role != 'user') return role;
  }

  if (_flag(raw, const [
    'isSuperAdmin',
    'is_super_admin',
    'superAdmin',
  ])) {
    return 'super_admin';
  }
  if (_flag(raw, const ['isAgency', 'is_agency', 'agencyOwner'])) {
    return 'agency';
  }
  if (_flag(raw, const [
    'isCoinsSeller',
    'isCoinSeller',
    'is_coins_seller',
    'is_coin_seller',
    'coinsSeller',
  ])) {
    return 'coins_seller';
  }
  if (_flag(raw, const ['isHost', 'is_host'])) return 'host';

  final flags = raw['roleFlags'] ?? raw['role_flags'];
  if (flags is Map) {
    final role = readUserRole(Map<String, dynamic>.from(flags));
    if (role != 'user') return role;
  }

  for (final key in const ['user', 'host', 'owner']) {
    final nested = raw[key];
    if (nested is Map && !identical(nested, raw)) {
      final role = readUserRole(Map<String, dynamic>.from(nested));
      if (role != 'user') return role;
    }
  }

  final direct = raw['role'] ?? raw['userRole'] ?? raw['user_role'];
  final text = direct?.toString().trim() ?? '';
  if (text.isNotEmpty && text != 'null') return normalizeUserRole(text);
  return 'user';
}

/// True when two ids are the same account, including a Zego-safe form.
bool sameAccountId(String left, String right) {
  final a = left.trim();
  final b = right.trim();
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  return ZegoLiveIdUtils.sanitizeUserId(a) ==
      ZegoLiveIdUtils.sanitizeUserId(b);
}

/// Tag for someone on a seat or in a room.
///
/// The signed-in account role wins over a seat label such as Host.
String roleShownForPerson({
  required String fallbackRole,
  String personId = '',
  String sessionUserId = '',
  String sessionRole = '',
  bool forceSessionRole = false,
}) {
  final mine = sessionRole.trim();
  if (mine.isNotEmpty &&
      (forceSessionRole || sameAccountId(personId, sessionUserId))) {
    return normalizeUserRole(mine);
  }
  return normalizeUserRole(fallbackRole);
}

/// Readable label for a stored role key.
String userRoleLabel(String? role) {
  return switch (normalizeUserRole(role)) {
    'super_admin' => 'Super Admin',
    'coins_seller' => 'Coin Seller',
    'agency' => 'Agency',
    'host' => 'Host',
    _ => 'User',
  };
}

/// Role shown on a room card. A plain user who opened the room is a Host.
String listingHostRole(Map<String, dynamic> room) {
  final host = room['host'] ?? room['owner'] ?? room['user'];
  final hostMap = host is Map
      ? Map<String, dynamic>.from(host)
      : const <String, dynamic>{};
  final role = readUserRole(hostMap.isEmpty ? room : hostMap);
  return role == 'user' ? 'host' : role;
}

bool _flag(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value == true || value == 1) return true;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') return true;
  }
  return false;
}
