/// Normalizes JSON persisted under [kStorageUserData].
///
/// Some auth responses nest fields under `user`, while GET profile returns a flat
/// row; gender/dob may arrive as strings, ints, or alternate keys.
Map<String, dynamic> coalesceStoredProfileMap(Map<String, dynamic> data) {
  final merged = <String, dynamic>{};
  final nested = data['user'];
  if (nested is Map<String, dynamic>) {
    merged.addAll(nested);
  } else if (nested is Map) {
    merged.addAll(Map<String, dynamic>.from(nested));
  }
  for (final e in data.entries) {
    if (e.key == 'user') continue;
    final v = e.value;
    if (v == null) continue;
    if (v is String && v.trim().isEmpty) continue;
    merged[e.key] = v;
  }
  return merged;
}

dynamic firstPresent(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    final v = data[k];
    if (v == null) continue;
    final asString = v.toString().trim();
    if (asString.isEmpty) continue;
    return v;
  }
  return null;
}

/// Maps backend gender values to UI chips `'Male'` / `'Female'`.
String genderLabelFromStored(dynamic raw) {
  if (raw == null) return '';
  if (raw is int) {
    switch (raw) {
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      default:
        return '';
    }
  }
  final s = raw.toString().trim().toLowerCase();
  if (s.isEmpty) return '';
  if (s == 'female' || s == 'f' || s == '2' || s == 'woman') {
    return 'Female';
  }
  if (s == 'male' || s == 'm' || s == '1' || s == 'man') {
    return 'Male';
  }
  return '';
}

DateTime? parseStoredDob(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) {
    if (raw <= 0) return null;
    if (raw > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
  }
  if (raw is double) {
    return parseStoredDob(raw.round());
  }
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;

  final slash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(s);
  if (slash != null) {
    final dayOrMonth1 = int.tryParse(slash.group(1)!);
    final dayOrMonth2 = int.tryParse(slash.group(2)!);
    final year = int.tryParse(slash.group(3)!);
    if (dayOrMonth1 != null && dayOrMonth2 != null && year != null) {
      try {
        return DateTime(year, dayOrMonth2, dayOrMonth1);
      } catch (_) {
        try {
          return DateTime(year, dayOrMonth1, dayOrMonth2);
        } catch (_) {
          return null;
        }
      }
    }
  }
  return null;
}
