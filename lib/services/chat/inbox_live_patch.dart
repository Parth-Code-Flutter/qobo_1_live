/// Decides whether a Firestore message should replace an inbox row.
class InboxLiveUpdate {
  const InboxLiveUpdate({
    required this.preview,
    required this.messageType,
    required this.activityAt,
    required this.unreadCount,
  });

  final String preview;
  final String messageType;
  final DateTime activityAt;
  final int unreadCount;

  /// Returns null when this message is already what the row shows.
  static InboxLiveUpdate? resolve({
    required DateTime? currentActivityAt,
    required String currentPreview,
    required DateTime? messageAt,
    required String preview,
    required String messageType,
    required int shownUnread,
    required bool fromMe,
    required bool chatOpen,
    required bool alreadyCounted,
  }) {
    final text = preview.trim();
    if (messageAt == null || text.isEmpty) return null;

    if (currentActivityAt != null && messageAt.isBefore(currentActivityAt)) {
      return null;
    }

    // The list timestamp and the Firestore timestamp for one message often
    // differ by a few hundred milliseconds. Same text in that window is not
    // a new message.
    if (currentActivityAt != null && currentPreview.trim() == text) {
      final ahead = messageAt.difference(currentActivityAt);
      if (!ahead.isNegative && ahead.inSeconds < 2) return null;
    }

    final sameMoment =
        currentActivityAt != null &&
        messageAt.isAtSameMomentAs(currentActivityAt);

    return InboxLiveUpdate(
      preview: text,
      messageType: messageType,
      activityAt: messageAt,
      unreadCount: nextUnread(
        shownUnread: shownUnread,
        fromMe: fromMe,
        chatOpen: chatOpen,
        alreadyCounted: alreadyCounted || sameMoment,
      ),
    );
  }

  static int nextUnread({
    required int shownUnread,
    required bool fromMe,
    required bool chatOpen,
    required bool alreadyCounted,
  }) {
    if (chatOpen) return 0;
    if (fromMe || alreadyCounted) return shownUnread;
    return shownUnread + 1;
  }
}
