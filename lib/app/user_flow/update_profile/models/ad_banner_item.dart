import 'package:qobo_one_live/utils/api_image_utils.dart';

/// One row from `GET /api/admin/ads-config`.
///
/// Manage body fields from doc: `{ title, imageUrl, link, isActive }`.
class AdBannerItem {
  const AdBannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.link = '',
    this.isActive = true,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String link;
  final bool isActive;

  factory AdBannerItem.fromJson(Map<String, dynamic> json) {
    final image =
        ApiImageUtils.normalize(
          (json['imageUrl'] ??
                  json['image_url'] ??
                  json['image'] ??
                  json['bannerUrl'] ??
                  json['banner'])
              ?.toString(),
        ) ??
        '';
    return AdBannerItem(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['adId']?.toString() ??
          '',
      title: (json['title'] ?? json['name'] ?? 'Banner').toString().trim(),
      imageUrl: image,
      link: (json['link'] ?? json['url'] ?? json['targetUrl'] ?? '')
          .toString()
          .trim(),
      isActive: json['isActive'] == true ||
          json['is_active'] == true ||
          json['status']?.toString().toLowerCase() == 'active' ||
          (json['isActive'] == null &&
              json['is_active'] == null &&
              json['status'] == null),
    );
  }

  static List<AdBannerItem> listFromResponse(dynamic data) {
    final list = data is List
        ? data
        : data is Map
        ? (data['items'] ??
              data['ads'] ??
              data['banners'] ??
              data['list'] ??
              data['data'])
        : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => AdBannerItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.imageUrl.isNotEmpty && e.isActive)
        .toList();
  }
}
