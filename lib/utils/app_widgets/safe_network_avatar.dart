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

class _SafeNetworkAvatarState extends State<SafeNetworkAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _fetch();
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
    return Image.memory(
      bytes,
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }
}
