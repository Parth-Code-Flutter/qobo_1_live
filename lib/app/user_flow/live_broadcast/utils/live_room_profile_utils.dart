import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';

/// Reads the first non-empty string from [data] for any of [keys].
String? readRoomField(Map<dynamic, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value != 'null') {
      return value;
    }
  }
  return null;
}

/// Pulls nested host map from room payloads (`host`, `owner`, `user`, etc.).
Map<String, dynamic>? readNestedHost(Map<dynamic, dynamic> roomData) {
  for (final key in ['host', 'owner', 'user', 'hostUser', 'host_user']) {
    final nested = roomData[key];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
  }
  return null;
}

String resolveHostName({
  required bool isHost,
  required String sessionName,
  required Map<String, dynamic> roomData,
}) {
  if (isHost && sessionName.isNotEmpty) return sessionName;

  final nested = readNestedHost(roomData);
  final fromNested = nested == null
      ? null
      : readRoomField(nested, [
          'name',
          'displayName',
          'username',
          'hostName',
          'fullName',
        ]);

  return fromNested ??
      readRoomField(roomData, [
        'hostName',
        'host_name',
        'ownerName',
        'owner_name',
        'streamerName',
        'userName',
        'user_name',
      ]) ??
      readRoomField(roomData, ['name', 'title']) ??
      'Live Host';
}

String? resolveHostAvatarUrl({
  required bool isHost,
  required String? sessionAvatarUrl,
  required Map<String, dynamic> roomData,
}) {
  if (isHost) {
    return resolveUserAvatarUrl(sessionAvatarUrl);
  }

  final nested = readNestedHost(roomData);
  final fromNested = nested == null
      ? null
      : readRoomField(nested, [
          'displayPicture',
          'display_picture',
          'avatar',
          'avatarUrl',
          'avatar_url',
          'profileImage',
          'profile_image',
          'photo',
        ]);

  final raw = fromNested ??
      readRoomField(roomData, [
        'hostAvatar',
        'host_avatar',
        'hostImage',
        'host_image',
        'displayPicture',
        'display_picture',
        'avatar',
        'avatarUrl',
      ]);

  return resolveUserAvatarUrl(ApiImageUtils.normalize(raw));
}

String? resolveHostId(Map<String, dynamic> roomData) {
  final nested = readNestedHost(roomData);
  if (nested != null) {
    final fromNested = readRoomField(nested, [
      'hostId',
      'host_id',
      'userId',
      'user_id',
      'ownerId',
      'owner_id',
      'id',
    ]);
    if (fromNested != null) return fromNested;
  }

  return readRoomField(roomData, [
    'hostId',
    'host_id',
    'userId',
    'user_id',
    'ownerId',
    'owner_id',
    'createdBy',
    'created_by',
    'receiverId',
    'receiver_id',
  ]);
}

int readEngagementCount(Map<String, dynamic> roomData) {
  final nested = readNestedHost(roomData);
  final raw = nested?['followerCount'] ??
      nested?['followers'] ??
      nested?['likes'] ??
      roomData['heatScore'] ??
      roomData['viewerCount'] ??
      roomData['onlineCount'] ??
      roomData['listenerCount'] ??
      roomData['audienceCount'] ??
      roomData['likes'] ??
      roomData['followerCount'] ??
      0;

  if (raw is num) return raw.round();
  return int.tryParse(raw?.toString().replaceAll(',', '') ?? '') ?? 0;
}

String formatCompactCount(int value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    return '${millions >= 10 ? millions.round() : millions.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final thousands = value / 1000;
    return '${thousands >= 10 ? thousands.round() : thousands.toStringAsFixed(1)}k';
  }
  return value.toString();
}

bool isNetworkGiftIcon(String? icon) {
  final raw = icon?.trim().toLowerCase() ?? '';
  return raw.startsWith('http://') || raw.startsWith('https://');
}

/// Marker appended to gift chat lines so peers can load `animationUrl`.
const giftAnimMarkerPrefix = '[[giftAnim:';
const giftAnimMarkerSuffix = ']]';

/// Removes the embedded animation marker so chat UI stays clean.
String stripGiftAnimMarker(String text) {
  return text
      .replaceAll(RegExp(r'\n?\[\[giftAnim:.*?\]\]'), '')
      .trim();
}

/// Parses `animationUrl` from a gift chat payload, if present.
String? parseGiftAnimUrl(String text) {
  final match = RegExp(
    r'\[\[giftAnim:(https?:\/\/[^\]]+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  final url = match?.group(1)?.trim();
  if (url == null || url.isEmpty) return null;
  return url;
}
