import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:qobo_one_live/constants/icon_constants.dart';

/// Looping gift mark for room, live, and PK docks.
///
/// The clip is muted so the button does not play gift audio.
class DockGiftIcon extends StatefulWidget {
  const DockGiftIcon({super.key, required this.size});

  final double size;

  static const asset = 'assets/icons/growth_task_gift_default.svga';

  @override
  State<DockGiftIcon> createState() => _DockGiftIconState();
}

class _DockGiftIconState extends State<DockGiftIcon>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _controller;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void> _load() async {
    final controller = SVGAAnimationController(vsync: this);
    _controller = controller;
    try {
      final video = await SVGAParser.shared.decodeFromAssets(DockGiftIcon.asset);
      if (!mounted || _controller != controller) {
        video.dispose();
        return;
      }
      controller.videoItem = video;
      controller
        ..muted = true
        ..volume = 0
        ..repeat();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted && _controller == controller) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller?.videoItem == null) {
      return Icon(
        kGiftIcon,
        color: Colors.white,
        size: widget.size * 0.62,
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: SVGAImage(
        controller!,
        fit: BoxFit.contain,
        preferredSize: Size(widget.size, widget.size),
        clearsAfterStop: false,
      ),
    );
  }
}
