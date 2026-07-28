// Shared JSON helpers for Coins Seller Portal models.

Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

/// Accepts both `success: true` and body `statusCode` envelopes (1 / 200 / 201).
bool isSellerPortalSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  if (response['success'] == true) return true;
  final code = response['statusCode'];
  if (code == 1 || code == 200 || code == 201) return true;
  if (code is String) {
    return code == '1' || code == '200' || code == '201';
  }
  return false;
}

bool isSellerPortalUnauthorized(Map<String, dynamic>? response) {
  if (response == null) return false;
  final code = response['statusCode'];
  return code == 401 || code?.toString() == '401';
}

String sellerPortalMessage(Map<String, dynamic>? response, String fallback) {
  final message = response?['message']?.toString().trim();
  return message == null || message.isEmpty ? fallback : message;
}
