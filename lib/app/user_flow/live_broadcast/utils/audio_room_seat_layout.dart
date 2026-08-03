/// Responsive audio-room seat cell sizing.
///
/// Keeps the 3-column grid from overflowing on small phones while still
/// looking proportional on larger devices.
class AudioRoomSeatLayoutMetrics {
  const AudioRoomSeatLayoutMetrics({
    required this.frameSize,
    required this.avatarSize,
    required this.topInset,
    required this.gapAfterFrame,
    required this.mainAxisExtent,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.badgeSize,
    required this.addButtonSize,
    this.columns = crossAxisCount,
  });

  final double frameSize;
  final double avatarSize;
  final double topInset;
  final double gapAfterFrame;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double badgeSize;
  final double addButtonSize;

  /// Column count for this metrics instance (audio defaults to [crossAxisCount]).
  final int columns;

  /// Audio rooms always use a fixed 3-column circular seat grid.
  static const crossAxisCount = 3;

  factory AudioRoomSeatLayoutMetrics.fromWidth(
    double maxWidth, {
    required bool compact,
  }) {
    final crossAxisSpacing = compact ? 4.0 : 8.0;
    final mainAxisSpacing = compact ? 6.0 : 8.0;
    final usableWidth = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 360.0;
    final cellWidth =
        (usableWidth - crossAxisSpacing * (crossAxisCount - 1)) /
        crossAxisCount;

    // Keep frames proportional to cell width; cap so large phones stay neat.
    final frameSize = (cellWidth * 0.82).clamp(compact ? 76.0 : 84.0, 108.0);
    final avatarSize = frameSize * (64 / 112);
    final topInset = (frameSize * 0.12).clamp(8.0, 12.0);
    final gapAfterFrame = compact ? 4.0 : 6.0;
    // Name/Invite line + diamond row + text-metric safety padding.
    final labelBlock = compact ? 18.0 : 20.0;
    final diamondBlock = compact ? 18.0 : 20.0;
    const safety = 6.0;
    final mainAxisExtent =
        topInset +
        frameSize +
        gapAfterFrame +
        labelBlock +
        diamondBlock +
        safety;

    return AudioRoomSeatLayoutMetrics(
      frameSize: frameSize,
      avatarSize: avatarSize,
      topInset: topInset,
      gapAfterFrame: gapAfterFrame,
      mainAxisExtent: mainAxisExtent,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      badgeSize: compact ? 20.0 : 24.0,
      addButtonSize: compact ? 26.0 : 30.0,
      columns: crossAxisCount,
    );
  }

  /// Equal rounded rectangles for video rooms only (does not affect audio).
  ///
  /// - ≤4 seats → 2 columns (2×2)
  /// - ≤9 seats → 3 columns
  /// - more → 4 columns
  factory AudioRoomSeatLayoutMetrics.videoFromWidth(
    double maxWidth, {
    required bool compact,
    int seatCount = 0,
  }) {
    final columns = _videoColumnsForSeatCount(seatCount > 0 ? seatCount : 4);
    final gap = compact ? 6.0 : 8.0;
    final usableWidth = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 360.0;
    final tileSize = ((usableWidth - gap * (columns - 1)) / columns).clamp(
      120.0,
      220.0,
    );

    return AudioRoomSeatLayoutMetrics(
      frameSize: tileSize,
      avatarSize: tileSize * 0.32,
      topInset: 0,
      gapAfterFrame: 0,
      mainAxisExtent: tileSize,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      badgeSize: compact ? 22.0 : 24.0,
      addButtonSize: compact ? 28.0 : 32.0,
      columns: columns,
    );
  }

  static int _videoColumnsForSeatCount(int seatCount) {
    if (seatCount <= 0) return 2;
    if (seatCount <= 4) return 2;
    if (seatCount <= 9) return 3;
    return 4;
  }

  /// Estimated content height for a fully populated seat cell.
  double get estimatedContentHeight =>
      topInset + frameSize + gapAfterFrame + 20 + 20;
}
