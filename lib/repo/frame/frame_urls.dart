import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Equipped entry-frame URL for room and live arrival animations.
///
/// Reads `entryFrameUrl` and the documented aliases. Avatar borders are ignored.
String? readEntryFrameUrl(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final key in const [
    'entryFrameUrl',
    'entry_frame_url',
    'vipFrameUrl',
    'vip_frame_url',
  ]) {
    final text = _cleanUrl(raw[key]);
    if (text != null) return text;
  }
  for (final key in const [
    'entryFrame',
    'entry_frame',
    'vipFrame',
    'vip_frame',
  ]) {
    final text = _urlFromFrameValue(raw[key]);
    if (text != null) return text;
  }
  final viewer = raw['viewer'];
  if (viewer is Map) {
    return readEntryFrameUrl(Map<String, dynamic>.from(viewer));
  }
  return null;
}

/// Profile-circle border. Entry frames are never returned here.
String? readAvatarFrameUrl(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return null;
  final entry = readEntryFrameUrl(raw);
  final avatar = raw['avatarFrame'] ?? raw['avatar_frame'];
  if (avatar != null && !_isEntryFrame(avatar)) {
    final url = _urlFromFrameValue(avatar);
    if (url != null && url != entry) return url;
  }
  for (final key in const [
    'avatarFrameUrl',
    'avatar_frame_url',
    'profileFrameUrl',
    'profile_frame_url',
    'equippedFrameUrl',
    'equipped_frame_url',
    'frameUrl',
    'frame_url',
  ]) {
    final value = raw[key];
    if (_isEntryFrame(value)) continue;
    final text = _urlFromFrameValue(value);
    if (text != null && text != entry) return text;
  }
  return null;
}

bool _isEntryFrame(dynamic value) {
  if (value is! Map) return false;
  final frameType = '${value['frameType'] ?? ''}'.trim().toLowerCase();
  if (frameType == 'entry') return true;
  if (frameType == 'avatar') return false;
  final type = '${value['type'] ?? ''}'.trim().toLowerCase();
  if (type == 'entry' || type == 'vip') return true;
  if (type == 'avatar' || type == 'frames') return false;
  final item = '${value['itemType'] ?? value['itemTypes'] ?? ''}'
      .trim()
      .toUpperCase();
  if (item == 'VIP_FRAME') return true;
  if (item == 'AVATAR_FRAME') return false;
  return '${value['category'] ?? ''}'.trim().toLowerCase() == 'vip';
}

String? _urlFromFrameValue(dynamic value) {
  final direct = _cleanUrl(value);
  if (direct != null) return direct;
  if (value is! Map) return null;
  for (final key in const [
    'svgaUrl',
    'image',
    'imageUrl',
    'url',
    'frameUrl',
    'animationUrl',
  ]) {
    final text = _cleanUrl(value[key]);
    if (text != null) return text;
  }
  return null;
}

String? _cleanUrl(dynamic value) {
  if (value is! String) return null;
  return ApiImageUtils.normalize(value);
}
