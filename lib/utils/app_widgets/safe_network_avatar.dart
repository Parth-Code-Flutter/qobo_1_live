import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Loads a profile image via HTTP first so a **404** never hits [Image.network]
/// (avoids noisy `NetworkImageLoadException` logs and broken decoders).
class SafeNetworkAvatar extends StatefulWidget {
  const SafeNetworkAvatar({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double size;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<SafeNetworkAvatar> createState() => _SafeNetworkAvatarState();
}

/// Keeps the last few avatar files so a card scrolled back into view
/// does not download the photo again. Display size stays the widget size.
const _maxCachedAvatars = 48;
final _cachedAvatarBytes = <String, Uint8List>{};
final _cachedAvatarOrder = <String>[];

void _rememberAvatar(String url, Uint8List bytes) {
  _cachedAvatarOrder.remove(url);
  _cachedAvatarOrder.add(url);
  _cachedAvatarBytes[url] = bytes;
  while (_cachedAvatarOrder.length > _maxCachedAvatars) {
    _cachedAvatarBytes.remove(_cachedAvatarOrder.removeAt(0));
  }
}

class _SafeNetworkAvatarState extends State<SafeNetworkAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    final url = widget.url?.trim();
    final cached = url == null ? null : _cachedAvatarBytes[url];
    if (cached != null) {
      _bytes = cached;
    } else {
      _fetch();
    }
  }

  @override
  void didUpdateWidget(covariant SafeNetworkAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      final url = widget.url?.trim();
      final cached = url == null ? null : _cachedAvatarBytes[url];
      if (cached != null) {
        setState(() => _bytes = cached);
      } else {
        _bytes = null;
        _fetch();
      }
    }
  }

  Future<void> _fetch() async {
    final u = widget.url?.trim();
    if (u == null || u.isEmpty) {
      if (mounted) setState(() => _bytes = null);
      return;
    }
    try {
      final res = await http
          .get(Uri.parse(u))
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _rememberAvatar(u, res.bodyBytes);
        setState(() => _bytes = res.bodyBytes);
      } else {
        setState(() => _bytes = null);
      }
    } catch (_) {
      if (mounted) setState(() => _bytes = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return widget.fallback;
    // Decode near the on-screen size. A full-resolution bitmap is wasted
    // on a 30px avatar and stalls the list while it scrolls.
    final cacheWidth = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(48, 512);
    return Image.memory(
      bytes,
      width: widget.size,
      height: widget.size,
      cacheWidth: cacheWidth,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}
