/// Filter selections for the Live Rooms listing (client-side + API query).
class LiveRoomFilterState {
  const LiveRoomFilterState({
    this.roomType = LiveRoomFilterState.allTypes,
    this.region = LiveRoomFilterState.allRegions,
  });

  static const String allTypes = 'ALL';
  static const String allRegions = 'ALL';

  final String roomType;
  final String region;

  bool get hasActiveFilters =>
      roomType != allTypes || region != allRegions;

  LiveRoomFilterState copyWith({
    String? roomType,
    String? region,
  }) {
    return LiveRoomFilterState(
      roomType: roomType ?? this.roomType,
      region: region ?? this.region,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LiveRoomFilterState &&
        other.roomType == roomType &&
        other.region == region;
  }

  @override
  int get hashCode => Object.hash(roomType, region);
}
