/// Removes repeated room listings across API sources using backend room IDs
/// and streaming channel aliases. Display names never establish identity.
List<Map<String, dynamic>> uniqueLiveRoomListings(
  Iterable<Map<String, dynamic>> listings,
) {
  final result = <Map<String, dynamic>>[];
  final identities = <Set<String>>[];
  for (final listing in listings) {
    final raw = listing['roomData'] is Map
        ? Map<String, dynamic>.from(listing['roomData'] as Map)
        : listing;
    final keys = <String>{};
    for (final field in ['id', '_id', 'roomId', 'room_id']) {
      final value = raw[field]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') keys.add('room:$value');
    }
    for (final field in [
      'zegoLiveId',
      'zego_live_id',
      'liveStreamingId',
      'live_streaming_id',
      'channelName',
    ]) {
      final value = raw[field]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') keys.add('channel:$value');
    }
    final matches = <int>[
      for (var i = 0; i < identities.length; i++)
        if (identities[i].intersection(keys).isNotEmpty) i,
    ];
    if (matches.isEmpty) {
      result.add(listing);
      identities.add(keys);
    } else {
      final first = matches.first;
      identities[first].addAll(keys);
      for (final index in matches.skip(1).toList().reversed) {
        identities[first].addAll(identities[index]);
        identities.removeAt(index);
        result.removeAt(index);
      }
    }
  }
  return result;
}
