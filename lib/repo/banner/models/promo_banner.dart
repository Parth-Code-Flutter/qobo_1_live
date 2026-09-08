import 'package:qobo_one_live/utils/api_image_utils.dart';

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.sortOrder,
    this.targetUrl,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String? targetUrl;
  final String type;
  final int sortOrder;

  static PromoBanner? tryFromJson(Map<String, dynamic> json) {
    final imageUrl = ApiImageUtils.normalize(json['imageUrl']?.toString());
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final rawTarget = json['targetUrl']?.toString().trim();
    return PromoBanner(
      id: json['id']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      imageUrl: imageUrl,
      targetUrl: rawTarget == null || rawTarget.isEmpty || rawTarget == 'null'
          ? null
          : rawTarget,
      type: json['type']?.toString().trim().toLowerCase() ?? '',
      sortOrder: _toInt(json['sortOrder']) ?? 999,
    );
  }

  static List<PromoBanner> listFromResponse(
    Map<String, dynamic>? response, {
    String? type,
  }) {
    final rawData = response?['data'];
    final rawList = rawData is List
        ? rawData
        : rawData is Map
        ? rawData['banners'] ?? rawData['items'] ?? rawData['data']
        : null;
    if (rawList is! List) return const <PromoBanner>[];

    final normalizedType = type?.trim().toLowerCase();
    final banners = <PromoBanner>[];
    for (final item in rawList.whereType<Map>()) {
      final json = Map<String, dynamic>.from(item);
      final status = json['status']?.toString().trim().toLowerCase();
      if (status != null && status.isNotEmpty && status != 'active') continue;

      final banner = tryFromJson(json);
      if (banner == null) continue;
      if (normalizedType != null &&
          normalizedType.isNotEmpty &&
          banner.type.isNotEmpty &&
          banner.type != normalizedType) {
        continue;
      }
      banners.add(banner);
    }
    banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return banners;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
