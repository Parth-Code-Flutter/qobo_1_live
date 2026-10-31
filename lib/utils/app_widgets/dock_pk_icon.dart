import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';

/// Looping PK mark for room and live docks.
///
/// The clip is muted so the button does not play its own audio.
class DockPkIcon extends StatefulWidget {
  const DockPkIcon({super.key, required this.size});

  final double size;

  static const asset = 'assets/icons/pk_matching.svga';

  @override
  State<DockPkIcon> createState() => _DockPkIconState();
}

class _DockPkIconState extends State<DockPkIcon>
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
      final video = await SVGAParser.shared.decodeFromAssets(DockPkIcon.asset);
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
        Icons.flash_on_rounded,
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
