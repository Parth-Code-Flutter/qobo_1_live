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

  final raw =
      fromNested ??
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

String? resolveHostAvatarFrameUrl({
  required bool isHost,
  required String? sessionFrameUrl,
  required Map<String, dynamic> roomData,
}) {
  if (isHost && sessionFrameUrl?.trim().isNotEmpty == true) {
    return ApiImageUtils.normalize(sessionFrameUrl);
  }

  final nested = readNestedHost(roomData);
  final fromNested =
      _readFrameUrl(nested?['avatarFrame']) ??
      (nested == null
          ? null
          : readRoomField(nested, [
              'avatarFrameUrl',
              'avatar_frame_url',
              'profileFrameUrl',
              'profile_frame_url',
              'frameUrl',
              'frame_url',
            ]));

  final raw =
      fromNested ??
      _readFrameUrl(roomData['avatarFrame']) ??
      readRoomField(roomData, [
        'hostAvatarFrame',
        'host_avatar_frame',
        'avatarFrameUrl',
        'avatar_frame_url',
        'profileFrameUrl',
        'profile_frame_url',
        'frameUrl',
        'frame_url',
      ]);

  return ApiImageUtils.normalize(raw);
}

String? _readFrameUrl(dynamic frame) {
  if (frame is! Map) return null;
  return readRoomField(Map<String, dynamic>.from(frame), [
    'image',
    'imageUrl',
    'url',
    'frameUrl',
    'frame_url',
  ]);
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
  final raw =
      nested?['followerCount'] ??
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
const giftSoundMarkerPrefix = '[[giftSound:';
const giftSoundMarkerSuffix = ']]';

/// Removes embedded gift media / earnings markers so chat UI stays clean.
String stripGiftAnimMarker(String text) {
  return text
      .replaceAll(
        RegExp(
          r'\n?\[\[gift(?:Anim|Sound|To|From|Scope|Price|Credited|AmountEach):.*?\]\]',
          caseSensitive: false,
        ),
        '',
      )
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

/// Parses `soundUrl` from a gift chat payload, if present.
String? parseGiftSoundUrl(String text) {
  final match = RegExp(
    r'\[\[giftSound:(https?:\/\/[^\]]+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  final url = match?.group(1)?.trim();
  if (url == null || url.isEmpty) return null;
  return url;
}

/// Receiver id for user-scoped gifts (`[[giftTo:…]]`).
String? parseGiftReceiverId(String text) {
  final match = RegExp(
    r'\[\[giftTo:([^\]]+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  final id = match?.group(1)?.trim();
  if (id == null || id.isEmpty) return null;
  return id;
}

/// Sender id for gift earnings (`[[giftFrom:…]]`).
String? parseGiftSenderId(String text) {
  final match = RegExp(
    r'\[\[giftFrom:([^\]]+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  final id = match?.group(1)?.trim();
  if (id == null || id.isEmpty) return null;
  return id;
}

/// Gift scope from chat (`room` / `user`). Defaults to `user` when absent.
String parseGiftScope(String text) {
  final match = RegExp(
    r'\[\[giftScope:([^\]]+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  final scope = match?.group(1)?.trim().toLowerCase();
  if (scope == 'room' || scope == 'user') return scope!;
  return 'user';
}

/// Catalog / send price embedded for peer seat-diamond updates.
int? parseGiftPrice(String text) {
  final match = RegExp(
    r'\[\[giftPrice:(\d+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  return int.tryParse(match?.group(1) ?? '');
}

/// Backend `credited_user_ids` for room gifts (seated recipients only).
List<String> parseGiftCreditedUserIds(String text) {
  final match = RegExp(
    r'\[\[giftCredited:([^\]]+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  final raw = match?.group(1)?.trim() ?? '';
  if (raw.isEmpty) return const [];
  return raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Per-recipient credit for room gifts (`amount_each` from backend).
int? parseGiftAmountEach(String text) {
  final match = RegExp(
    r'\[\[giftAmountEach:(\d+)\]\]',
    caseSensitive: false,
  ).firstMatch(text);
  return int.tryParse(match?.group(1) ?? '');
}
