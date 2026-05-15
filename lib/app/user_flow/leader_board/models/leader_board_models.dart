/// Top-three podium row (Figma).
class LeaderBoardPodiumUser {
  const LeaderBoardPodiumUser({
    required this.rank,
    required this.name,
    required this.imageAsset,
  });

  final int rank;
  final String name;
  final String imageAsset;
}

/// “Running up” list row.
class LeaderBoardListEntry {
  const LeaderBoardListEntry({
    required this.displayRank,
    required this.name,
    required this.subtitle,
    required this.points,
    required this.imageAsset,
    this.highlighted = false,
  });

  final int displayRank;
  final String name;
  final String subtitle;
  final String points;
  final String imageAsset;
  final bool highlighted;
}
