import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen Video Player Widget
/// Displays videos in fullscreen with playback controls
/// Reusable widget for playing videos throughout the app
class FullscreenVideoPlayer extends StatefulWidget {
  /// Video URL to play
  final String videoUrl;
  
  /// Video title/name to display
  final String? videoTitle;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoUrl,
    this.videoTitle,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();

  /// Show fullscreen video player
  /// Utility method to easily display videos in fullscreen
  static void show({
    required BuildContext context,
    required String videoUrl,
    String? videoTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoUrl: videoUrl,
          videoTitle: videoTitle,
        ),
      ),
    );
  }
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  /// Initialize video player
  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController!.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: errorMessage,
                    fontSize: 16,
                    color: Colors.white,
                    style: TextStyles.kRegularPoppins(fontSize: 16, colors: Colors.white),
                    align: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.videoTitle != null
            ? AppText(
                text: widget.videoTitle!,
                fontSize: 16,
                color: Colors.white,
                style: TextStyles.kSemiBoldPoppins(fontSize: 16, colors: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
      body: _hasError
          ? _buildErrorWidget()
          : _isInitialized && _chewieController != null
              ? Center(
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                )
              : _buildLoadingWidget(),
    );
  }

  /// Build loading widget
  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        color: kColorPrimary,
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            AppText(
              text: _errorMessage ?? 'Failed to load video',
              fontSize: 16,
              color: Colors.white,
              style: TextStyles.kRegularPoppins(fontSize: 16, colors: Colors.white),
              align: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializeVideo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kColorPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

