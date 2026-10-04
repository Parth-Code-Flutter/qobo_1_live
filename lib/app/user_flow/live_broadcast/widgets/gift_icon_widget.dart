import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/services/gifts/gift_icon_preview_store.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';

/// Renders a gift icon from:
/// - network SVGA / animated clip URL (`icon` from gift-list API)
/// - network static image URL (legacy PNG/JPG fallback)
/// - emoji / plain text
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

    // Gift-list `icon` is treated as a network SVGA/animated clip.
    if (isNetworkGiftIcon(raw)) {
      return SizedBox(
        width: size,
        height: size,
        child: _NetworkGiftIcon(url: raw, size: size, emojiSize: emojiSize),
      );
    }

    return Text(raw, style: TextStyle(fontSize: emojiSize), maxLines: 1);
  }
}

/// Shows the small saved gift picture. The full animation plays only on send.
class _NetworkGiftIcon extends StatefulWidget {
  const _NetworkGiftIcon({
    required this.url,
    required this.size,
    required this.emojiSize,
  });

  final String url;
  final double size;
  final double emojiSize;

  @override
  State<_NetworkGiftIcon> createState() => _NetworkGiftIconState();
}

class _NetworkGiftIconState extends State<_NetworkGiftIcon> {
  String? _path;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _NetworkGiftIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _path = null;
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final path = await GiftIconPreviewStore.ensure(widget.url);
    if (!mounted) return;
    setState(() {
      _path = path;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _emoji(),
      );
    }
    if (_loading) {
      return Center(
        child: SizedBox(
          width: widget.size * 0.35,
          height: widget.size * 0.35,
          child: const CircularProgressIndicator(
            strokeWidth: 1.6,
            color: Colors.white54,
          ),
        ),
      );
    }
    if (_isStaticImage(widget.url)) {
      return SafeNetworkAvatar(
        url: widget.url,
        size: widget.size,
        fit: BoxFit.contain,
        fallback: _emoji(),
      );
    }
    return _emoji();
  }

  Widget _emoji() {
    return Text('🎁', style: TextStyle(fontSize: widget.emojiSize));
  }

  bool _isStaticImage(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}
