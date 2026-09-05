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

  /// Zego in-room text is ~1024 bytes. Keep combo payloads under that so
  /// peers still receive every hit (long Cloudinary URLs can overflow).
  static const int _maxInRoomGiftChars = 900;

  /// Builds the Zego in-room gift chat payload.
  ///
  /// Visible text stays human-readable. Hidden `[[gift…]]` markers carry
  /// animation / earnings metadata for peers (stripped before chat UI).
  ///
  /// Room gifts (`scope=room`, no single receiver) show
  /// **"🎁 sent {name} to the Room"** — never a raw user id.
  static String buildChatLabel({
    required String? giftName,
    required String? giftIcon,
    required String animationUrl,
    required String soundUrl,
    String scope = 'user',
    String? receiverId,
    String? senderId,
    String? giftId,
    int? giftPrice,
    List<String>? creditedUserIds,
    int? amountEach,
    int? comboIndex,
    int? comboTotal,
  }) {
    final name = giftName?.trim().isNotEmpty == true
        ? giftName!.trim()
        : 'Gift';
    final iconPart = isNetworkGiftIcon(giftIcon) ? '' : (giftIcon ?? '');
    final normalizedScope = scope.trim().toLowerCase() == 'room'
        ? 'room'
        : 'user';
    final toId = receiverId?.trim() ?? '';
    final isRoomGift = normalizedScope == 'room' || toId.isEmpty;
    final base =
        (isRoomGift
                ? '🎁 sent $name to the Room $iconPart'
                : '🎁 sent $name $iconPart')
            .trim();
    final fromId = senderId?.trim() ?? '';
    final credited = (creditedUserIds ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(',');
    final id = giftId?.trim() ?? '';
    final mediaMarkers = <String>[
      if (animationUrl.isNotEmpty) '[[giftAnim:$animationUrl]]',
      if (soundUrl.isNotEmpty) '[[giftSound:$soundUrl]]',
    ];
    final metaMarkers = <String>[
      if (id.isNotEmpty) '[[giftId:$id]]',
      '[[giftScope:${isRoomGift ? 'room' : normalizedScope}]]',
      if (fromId.isNotEmpty) '[[giftFrom:$fromId]]',
      if (!isRoomGift && toId.isNotEmpty) '[[giftTo:$toId]]',
      if (giftPrice != null && giftPrice > 0) '[[giftPrice:$giftPrice]]',
      if (amountEach != null && amountEach > 0)
        '[[giftAmountEach:$amountEach]]',
      // Hidden only — never shown in chat (stripped by stripGiftAnimMarker).
      if (credited.isNotEmpty) '[[giftCredited:$credited]]',
      // Unique per combo hit so Zego does not drop identical gift lines.
      if (comboIndex != null && comboTotal != null && comboTotal > 1)
        '[[giftCombo:$comboIndex/$comboTotal]]',
    ];
    final withMedia = [...mediaMarkers, ...metaMarkers];
    final full = withMedia.isEmpty ? base : '$base\n${withMedia.join('\n')}';
    if (full.length <= _maxInRoomGiftChars || mediaMarkers.isEmpty) {
      return full;
    }
    // URLs overflowed IM size — peers resolve SVGA from catalog via giftId.
    return '$base\n${metaMarkers.join('\n')}';
  }

  /// Readable gift name from labels like "🎁 sent Red Rose 🌹".
  static String giftNameFromChatLabel(String text) {
    var visible = stripGiftAnimMarker(text).replaceFirst('🎁 ', '').trim();
    if (visible.startsWith('sent ')) {
      visible = visible.substring(5).trim();
    }
    visible = visible.replaceFirst(RegExp(r'\s+to the [Rr]oom\s*$'), '').trim();
    if (visible.isEmpty) return 'Gift';
    final parts = visible.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.last.runes.length <= 2) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
    return visible;
  }

  /// True when the chat text is a gift celebration payload.
  static bool isGiftChatMessage(String text) => text.trim().startsWith('🎁 ');

  /// Shows the shared full-screen SVGA / sound celebration overlay.
  static void showCelebration({
    String? giftName,
    String? animationUrl,
    String? imageUrl,
    String? soundUrl,
    bool enqueueIfBusy = false,
  }) {
    final anim = animationUrl?.trim() ?? '';
    final image = imageUrl?.trim() ?? '';
    final sound = soundUrl?.trim() ?? '';
    GiftCelebrationOverlay.show(
      giftName: giftName,
      svgaUrl: anim.isNotEmpty ? anim : null,
      imageUrl: image.isNotEmpty ? image : null,
      soundUrl: sound.isNotEmpty ? sound : null,
      enqueueIfBusy: enqueueIfBusy,
    );
  }

  /// Audio-room timing for every surface: close gift sheet first so it never
  /// covers the celebration, then play SVGA/sound after a short settle delay.
  static Future<void> dismissSheetThenCelebrate({
    String? giftName,
    String? animationUrl,
    String? soundUrl,
    Duration delay = const Duration(milliseconds: 300),
    int times = 1,
  }) async {
    if (Get.isBottomSheetOpen == true) {
      Get.back<void>();
    }
    await Future<void>.delayed(delay);
    final count = times < 1 ? 1 : times;
    for (var i = 0; i < count; i++) {
      showCelebration(
        giftName: giftName,
        animationUrl: animationUrl,
        soundUrl: soundUrl,
        enqueueIfBusy: i > 0,
      );
    }
  }

  /// Peer path: parse embedded media markers from a Zego gift chat line.
  ///
  /// If the chat line lost `[[giftAnim:]]` (truncation / size cap), match the
  /// local gift catalog by id then name so receivers still play the SVGA.
  static void showCelebrationFromChatLabel(
    String message, {
    bool enqueueIfBusy = false,
    List<Map<String, String>> giftCatalog = const [],
  }) {
    var animationUrl = parseGiftAnimUrl(message)?.trim() ?? '';
    var soundUrl = parseGiftSoundUrl(message)?.trim() ?? '';
    if ((animationUrl.isEmpty || soundUrl.isEmpty) && giftCatalog.isNotEmpty) {
      final fromCatalog = catalogMediaForChat(message, giftCatalog);
      if (animationUrl.isEmpty) animationUrl = fromCatalog.$1;
      if (soundUrl.isEmpty) soundUrl = fromCatalog.$2;
    }
    showCelebration(
      giftName: giftNameFromChatLabel(message),
      animationUrl: animationUrl,
      soundUrl: soundUrl,
      enqueueIfBusy: enqueueIfBusy,
    );
  }

  /// `(animationUrl, soundUrl)` from the in-room catalog for a gift chat line.
  static (String, String) catalogMediaForChat(
    String message,
    List<Map<String, String>> giftCatalog,
  ) {
    if (giftCatalog.isEmpty) return ('', '');
    final giftId = parseGiftId(message)?.trim() ?? '';
    if (giftId.isNotEmpty) {
      for (final gift in giftCatalog) {
        if ((gift['id'] ?? '').trim() != giftId) continue;
        return (
          gift['animationUrl']?.trim() ?? '',
          gift['soundUrl']?.trim() ?? '',
        );
      }
    }
    final name = giftNameFromChatLabel(message).toLowerCase();
    if (name.isEmpty || name == 'gift') return ('', '');
    for (final gift in giftCatalog) {
      if ((gift['name'] ?? '').trim().toLowerCase() != name) continue;
      return (
        gift['animationUrl']?.trim() ?? '',
        gift['soundUrl']?.trim() ?? '',
      );
    }
    return ('', '');
  }
}
