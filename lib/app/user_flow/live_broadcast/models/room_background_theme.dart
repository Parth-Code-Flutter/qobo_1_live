import 'package:qobo_one_live/utils/api_image_utils.dart';

/// One theme from `GET /api/room/backgrounds`.
class RoomBackgroundTheme {
  const RoomBackgroundTheme({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String imageUrl;
  final bool isDefault;
  final int sortOrder;

  factory RoomBackgroundTheme.fromJson(Map<String, dynamic> json) {
    final image =
        ApiImageUtils.normalize(
          (json['image'] ??
                  json['imageUrl'] ??
                  json['backgroundImage'] ??
                  json['background_image'] ??
                  json['url'])
              ?.toString(),
        ) ??
        '';
    return RoomBackgroundTheme(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Background',
      imageUrl: image,
      isDefault: json['isDefault'] == true || json['is_default'] == true,
      sortOrder: _toInt(json['sortOrder'] ?? json['sort_order']),
    );
  }

  static List<RoomBackgroundTheme> listFromResponse(dynamic data) {
    final list = data is List
        ? data
        : data is Map
        ? (data['items'] ?? data['backgrounds'] ?? data['list'] ?? data['data'])
        : null;
    if (list is! List) return const [];
    final themes = list
        .whereType<Map>()
        .map((e) => RoomBackgroundTheme.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.imageUrl.isNotEmpty)
        .toList();
    themes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return themes;
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
