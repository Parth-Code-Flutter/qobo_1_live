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

  /// How much of the middle stage the video seat grid should occupy.
  ///
  /// 4-seat rooms stay near 70%; denser rooms use more so tiles stay readable.
  static double videoStageFillRatio(int seatCount) {
    if (seatCount <= 4) return 0.70;
    if (seatCount <= 6) return 0.78;
    if (seatCount <= 9) return 0.85;
    return 0.90;
  }

  /// Equal rounded rectangles for video rooms only (does not affect audio).
  ///
  /// - ≤4 seats → 2 columns (2×2)
  /// - ≤12 seats → 3 columns (keeps tiles wide enough for labels)
  /// - more → 4 columns
  ///
  /// When [maxHeight] is provided, tile height fills that budget so the
  /// grid can use ~70%+ of the middle stage instead of tiny width-squares.
  factory AudioRoomSeatLayoutMetrics.videoFromWidth(
    double maxWidth, {
    required bool compact,
    int seatCount = 0,
    double? maxHeight,
  }) {
    final count = seatCount > 0 ? seatCount : 4;
    final columns = _videoColumnsForSeatCount(count);
    final rows = (count / columns).ceil().clamp(1, 8);
    // Tighter gaps on dense grids so each tile keeps more usable space.
    final gap = columns >= 4
        ? (compact ? 4.0 : 5.0)
        : (compact ? 5.0 : 7.0);
    final usableWidth = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 360.0;
    final cellWidth = (usableWidth - gap * (columns - 1)) / columns;

    // Fill the stage budget exactly so 4-seat (~70%) and denser rooms
    // look large in the middle instead of tiny width-squares.
    double tileHeight;
    if (maxHeight != null && maxHeight.isFinite && maxHeight > 0) {
      final budget = (maxHeight - gap * (rows - 1)) / rows;
      // Floor to avoid sub-pixel GridView overflows (e.g. "1.3 pixels").
      tileHeight = budget.floorToDouble();
      if (tileHeight < 1) tileHeight = budget;
    } else {
      tileHeight = cellWidth.clamp(compact ? 118.0 : 128.0, 220.0);
    }

    final shortSide = tileHeight < cellWidth ? tileHeight : cellWidth;

    return AudioRoomSeatLayoutMetrics(
      frameSize: cellWidth,
      avatarSize: (shortSide * (columns >= 3 ? 0.26 : 0.30)).clamp(28.0, 64.0),
      topInset: 0,
      gapAfterFrame: 0,
      mainAxisExtent: tileHeight,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      badgeSize: compact || columns >= 3 ? 18.0 : 24.0,
      addButtonSize: compact || columns >= 3 ? 24.0 : 32.0,
      columns: columns,
    );
  }

  static int _videoColumnsForSeatCount(int seatCount) {
    if (seatCount <= 0) return 2;
    if (seatCount <= 4) return 2;
    // Prefer 3 columns through 12 seats so empty-seat labels stay readable.
    if (seatCount <= 12) return 3;
    return 4;
  }

  /// Estimated content height for a fully populated seat cell.
  double get estimatedContentHeight =>
      topInset + frameSize + gapAfterFrame + 20 + 20;
}
