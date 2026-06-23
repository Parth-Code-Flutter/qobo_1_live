import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';

/// Parsed Explore discover feed (`GET /api/discover`) per backend contract.
class ExploreDiscoverPage {
  const ExploreDiscoverPage({
    required this.users,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.hasMore = false,
  });

  final List<SocialUserCard> users;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  /// Parses envelope `data` from `GET /api/discover`.
  static ExploreDiscoverPage fromApiResponse(Map<String, dynamic>? response) {
    if (!isSocialApiSuccess(response)) {
      return const ExploreDiscoverPage(users: []);
    }
    return fromData(response?['data']);
  }

  static ExploreDiscoverPage fromData(dynamic data) {
    if (data is List) {
      return ExploreDiscoverPage(
        users: SocialUserCard.listFromResponseData(data),
      );
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return ExploreDiscoverPage(
        users: SocialUserCard.listFromResponseData(map),
        total: _toInt(map['total']),
        page: _toInt(map['page'], fallback: 1),
        limit: _toInt(map['limit'], fallback: 20),
        hasMore: map['hasMore'] == true,
      );
    }
    return const ExploreDiscoverPage(users: []);
  }

  static int _toInt(dynamic raw, {int fallback = 0}) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }
}

/// Favourite / unfavourite action result (`POST /api/user/favourite|unfavourite`).
class FavouriteActionResult {
  const FavouriteActionResult({
    required this.targetId,
    required this.isFavourite,
    this.message,
  });

  final String targetId;
  final bool isFavourite;
  final String? message;

  static FavouriteActionResult? fromApiResponse(
    Map<String, dynamic>? response,
  ) {
    if (!isSocialApiSuccess(response)) return null;
    final data = response?['data'];
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final targetId =
        map['targetId']?.toString() ?? map['target_id']?.toString() ?? '';
    if (targetId.isEmpty) return null;
    return FavouriteActionResult(
      targetId: targetId,
      isFavourite:
          map['isFavourite'] == true || map['isFavorite'] == true,
      message: response?['message']?.toString(),
    );
  }
}
