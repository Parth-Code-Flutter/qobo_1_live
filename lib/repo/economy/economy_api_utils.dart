/// Shared helpers for economy / wallet API responses.
bool isEconomyApiSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  if (response['success'] == true) return true;
  final code = response['statusCode'];
  if (code is int) return code == 1 || code == 200 || code == 201;
  return code?.toString() == '1' ||
      code?.toString() == '200' ||
      code?.toString() == '201';
}

int parseWalletAmount(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
}

String formatLedgerAmount(num value) {
  final abs = value.abs().round();
  final formatted = abs.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return formatted;
}
