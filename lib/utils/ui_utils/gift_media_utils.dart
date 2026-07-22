import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_celebration_overlay.dart';

/// Shared helpers for gift-list mapping, send-gift media URLs, and celebration UI.
///
/// Used by live rooms and 1:1 voice/video calls so animation + sound stay consistent.
abstract final class GiftMediaUtils {
  GiftMediaUtils._();

  /// Maps a gift-list API row into the sheet/catalog shape used by send-gift.
  static Map<String, String> mapGiftFromApi(Map<String, dynamic> raw) {
    final name = raw['name']?.toString() ?? raw['title']?.toString() ?? 'Gift';
    final price = raw['price'] ?? raw['coins'] ?? raw['amount'] ?? 0;
    final icon =
        raw['icon']?.toString() ??
        raw['emoji']?.toString() ??
        raw['image']?.toString() ??
        raw['imageUrl']?.toString() ??
        '🎁';
    final category =
        raw['category']?.toString() ?? raw['type']?.toString() ?? 'Popular';
    // Backend SVGA clip + optional sound — played after send-gift success.
    final animationUrl =
        raw['animationUrl']?.toString() ??
        raw['animation_url']?.toString() ??
        raw['svgaUrl']?.toString() ??
        '';
    final soundUrl =
        raw['soundUrl']?.toString() ??
        raw['sound_url']?.toString() ??
        raw['audioUrl']?.toString() ??
        raw['audio_url']?.toString() ??
        '';
    return {
      'id': raw['id']?.toString() ?? raw['_id']?.toString() ?? '',
      'name': name,
      'price': price.toString(),
      'icon': icon,
      'category': category,
      'animationUrl':
          ApiImageUtils.normalize(animationUrl.trim()) ?? animationUrl.trim(),
      'soundUrl': ApiImageUtils.normalize(soundUrl.trim()) ?? soundUrl.trim(),
    };
  }

  /// Prefers send-gift response media, then falls back to the catalog gift.
  static String animationUrlFromResponse(
    Map<String, dynamic>? response,
    Map<String, String> gift,
  ) {
    final data = response?['data'];
    final responseGift = data is Map ? data['gift'] : null;
    final apiAnimationUrl = responseGift is Map
        ? (responseGift['animationUrl'] ??
                  responseGift['animation_url'] ??
                  responseGift['svgaUrl'])
              ?.toString()
              .trim()
        : null;
    if (apiAnimationUrl != null && apiAnimationUrl.isNotEmpty) {
      return ApiImageUtils.normalize(apiAnimationUrl) ?? apiAnimationUrl;
    }
    return ApiImageUtils.normalize(gift['animationUrl']?.trim()) ??
        gift['animationUrl']?.trim() ??
        '';
  }

  /// Prefers send-gift response sound, then falls back to the catalog gift.
  static String soundUrlFromResponse(
    Map<String, dynamic>? response,
    Map<String, String> gift,
  ) {
    final data = response?['data'];
    final responseGift = data is Map ? data['gift'] : null;
    final soundValue =
        (responseGift is Map
            ? responseGift['soundUrl'] ??
                  responseGift['sound_url'] ??
                  responseGift['audioUrl'] ??
                  responseGift['audio_url']
            : null) ??
        (data is Map
            ? data['soundUrl'] ??
                  data['sound_url'] ??
                  data['audioUrl'] ??
                  data['audio_url']
            : null);
    final apiSoundUrl = soundValue?.toString().trim();
    if (apiSoundUrl != null && apiSoundUrl.isNotEmpty) {
      return ApiImageUtils.normalize(apiSoundUrl) ?? apiSoundUrl;
    }
    return ApiImageUtils.normalize(gift['soundUrl']?.trim()) ??
        gift['soundUrl']?.trim() ??
        '';
  }

  /// Builds the Zego gift chat line with hidden `[[giftAnim:]]` / `[[giftSound:]]`.
  static String buildChatLabel({
    required String? giftName,
    required String? giftIcon,
    required String animationUrl,
    required String soundUrl,
  }) {
    final name = giftName?.trim().isNotEmpty == true
        ? giftName!.trim()
        : 'Gift';
    final iconPart = isNetworkGiftIcon(giftIcon) ? '' : (giftIcon ?? '');
    final base = '🎁 sent $name $iconPart'.trim();
    final markers = <String>[
      if (animationUrl.isNotEmpty) '[[giftAnim:$animationUrl]]',
      if (soundUrl.isNotEmpty) '[[giftSound:$soundUrl]]',
    ];
    // Hidden markers let peers play the exact gift animation and sound.
    return markers.isEmpty ? base : '$base\n${markers.join('\n')}';
  }

  /// Readable gift name from labels like "🎁 sent Red Rose 🌹".
  static String giftNameFromChatLabel(String text) {
    final visible = stripGiftAnimMarker(text).replaceFirst('🎁 ', '').trim();
    final withoutSent = visible.startsWith('sent ')
        ? visible.substring(5).trim()
        : visible;
    if (withoutSent.isEmpty) return 'Gift';
    final parts = withoutSent.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.last.runes.length <= 2) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
    return withoutSent;
  }

  /// True when the chat text is a gift celebration payload.
  static bool isGiftChatMessage(String text) =>
      text.trim().startsWith('🎁 ');

  /// Shows the shared full-screen SVGA / sound celebration overlay.
  static void showCelebration({
    String? giftName,
    String? animationUrl,
    String? soundUrl,
  }) {
    final anim = animationUrl?.trim() ?? '';
    final sound = soundUrl?.trim() ?? '';
    GiftCelebrationOverlay.show(
      giftName: giftName,
      svgaUrl: anim.isNotEmpty ? anim : null,
      soundUrl: sound.isNotEmpty ? sound : null,
    );
  }

  /// Audio-room timing for every surface: close gift sheet first so it never
  /// covers the celebration, then play SVGA/sound after a short settle delay.
  static Future<void> dismissSheetThenCelebrate({
    String? giftName,
    String? animationUrl,
    String? soundUrl,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    if (Get.isBottomSheetOpen == true) {
      Get.back<void>();
    }
    await Future<void>.delayed(delay);
    showCelebration(
      giftName: giftName,
      animationUrl: animationUrl,
      soundUrl: soundUrl,
    );
  }

  /// Peer path: parse embedded media markers from a Zego gift chat line.
  static void showCelebrationFromChatLabel(String message) {
    showCelebration(
      giftName: giftNameFromChatLabel(message),
      animationUrl: parseGiftAnimUrl(message),
      soundUrl: parseGiftSoundUrl(message),
    );
  }
}
