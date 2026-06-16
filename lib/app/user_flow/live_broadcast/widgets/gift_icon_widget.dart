import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';

/// Renders a gift icon from emoji text or a remote image URL.
class GiftIconWidget extends StatelessWidget {
  const GiftIconWidget({
    super.key,
    required this.icon,
    this.size = 36,
    this.emojiSize = 28,
  });

  final String? icon;
  final double size;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final raw = icon?.trim() ?? '';
    if (raw.isEmpty) {
      return Text('🎁', style: TextStyle(fontSize: emojiSize));
    }

    if (isNetworkGiftIcon(raw)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SafeNetworkAvatar(
          url: raw,
          size: size,
          fit: BoxFit.contain,
          fallback: Text('🎁', style: TextStyle(fontSize: emojiSize)),
        ),
      );
    }

    return Text(raw, style: TextStyle(fontSize: emojiSize), maxLines: 1);
  }
}
