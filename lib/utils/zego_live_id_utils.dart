import 'dart:math';

/// Helpers for Zego `liveID` / `userID` formatting.
abstract final class ZegoLiveIdUtils {
  /// Zego allows letters, digits, and underscore; max 128 bytes.
  static String sanitize(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (cleaned.isEmpty) {
      return generate();
    }
    return cleaned.length > 128 ? cleaned.substring(0, 128) : cleaned;
  }

  /// Host channel id (no special chars beyond underscore).
  static String generate() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = Random().nextInt(999999).toString().padLeft(6, '0');
    return sanitize('ls_${ts}_$suffix');
  }

  /// Zego `userID` max 32 chars, alphanumeric recommended.
  static String sanitizeUserId(String raw) {
    var id = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (id.isEmpty) {
      id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (id.length > 32) {
      id = id.substring(0, 32);
    }
    return id;
  }
}
