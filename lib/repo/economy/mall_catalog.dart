/// Classifies one row from `GET /api/economy/mall`.
///
/// The server `type` filter currently mixes patti into other buckets, so the
/// item's own type fields decide the tab. Patti is checked first.
String mallCatalogKind(Map<String, dynamic> item) {
  final itemType = _text(item['itemType'] ?? item['itemTypes']).toUpperCase();
  final frameType = _text(item['frameType']).toLowerCase();
  final type = _text(item['type']).toLowerCase();

  if (itemType.contains('PATTI') || type == 'patti') return 'patti';
  if (itemType.contains('BACKGROUND') || type == 'background') {
    return 'background';
  }
  if (itemType.contains('BUBBLE') || type.contains('bubble')) return 'bubble';
  if (itemType == 'VIP_FRAME' ||
      frameType == 'entry' ||
      type == 'entry' ||
      type == 'vip') {
    return 'entry';
  }
  if (itemType == 'AVATAR_FRAME' ||
      frameType == 'avatar' ||
      type == 'frame' ||
      type == 'avatar' ||
      type == 'frames') {
    return 'avatar';
  }
  return 'other';
}

String _text(dynamic value) {
  if (value is List) return value.map((part) => part.toString()).join(' ');
  return value?.toString() ?? '';
}
