/// Country row from `GET /api/auth/countries`.
class CountryOption {
  const CountryOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    return CountryOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
      code: json['code']?.toString().trim().toUpperCase() ?? '',
    );
  }

  static List<CountryOption> listFromResponseData(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => CountryOption.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
        .toList();
  }
}

/// State row from `GET /api/auth/states?countryId=...`.
class StateOption {
  const StateOption({
    required this.id,
    required this.name,
    this.countryId = '',
  });

  final String id;
  final String name;
  final String countryId;

  factory StateOption.fromJson(Map<String, dynamic> json) {
    return StateOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
      countryId: json['countryId']?.toString() ?? '',
    );
  }

  static List<StateOption> listFromResponseData(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => StateOption.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.id.isNotEmpty && s.name.isNotEmpty)
        .toList();
  }
}

bool isGeoApiSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  final code = response['statusCode'];
  if (code == 1 || code == 200) return true;
  if (code is String) return code == '1' || code == '200';
  return false;
}
