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
    );
  }

  /// Estimated content height for a fully populated seat cell.
  double get estimatedContentHeight =>
      topInset + frameSize + gapAfterFrame + 20 + 20;
}
