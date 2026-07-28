import 'seller_admin.dart';
import 'seller_portal_parsers.dart';

/// Parsed `data` from `POST /api/admin/login`.
class SellerLoginData {
  const SellerLoginData({
    required this.token,
    required this.admin,
  });

  final String token;
  final SellerAdmin admin;

  factory SellerLoginData.fromJson(Map<String, dynamic> json) {
    return SellerLoginData(
      token: json['token']?.toString().trim() ?? '',
      admin: SellerAdmin.fromJson(asJsonMap(json['admin'])),
    );
  }

  /// Parses a full API envelope (`success` / `statusCode` + `data`).
  static SellerLoginData? tryParseEnvelope(Map<String, dynamic>? response) {
    if (!isSellerPortalSuccess(response)) return null;
    final data = asJsonMap(response!['data']);
    if (data.isEmpty) return null;
    final parsed = SellerLoginData.fromJson(data);
    if (parsed.token.isEmpty) return null;
    return parsed;
  }
}
