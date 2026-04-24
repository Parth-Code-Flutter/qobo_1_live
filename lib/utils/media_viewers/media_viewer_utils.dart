import 'package:flutter/material.dart';
import 'package:aligned_rewards/utils/media_viewers/fullscreen_image_viewer.dart';
import 'package:aligned_rewards/utils/media_viewers/fullscreen_video_player.dart';

/// Media Viewer Utils
/// Utility class providing convenient methods to show images and videos
/// Reusable throughout the app for consistent media viewing experience
class MediaViewerUtils {
  /// Show fullscreen image viewer
  /// 
  /// [context] - BuildContext for navigation
  /// [imageUrl] - URL of the image to display
  /// [imageTitle] - Optional title to display in the app bar
  /// [imageUrls] - Optional list of image URLs for gallery mode (swipe between images)
  /// [initialIndex] - Initial image index when using gallery mode (default: 0)
  /// 
  /// Example usage:
  /// ```dart
  /// MediaViewerUtils.showImage(
  ///   context: context,
  ///   imageUrl: 'https://example.com/image.jpg',
  ///   imageTitle: 'My Image',
  /// );
  /// ```
  static void showImage({
    required BuildContext context,
    required String imageUrl,
    String? imageTitle,
    List<String>? imageUrls,
    int initialIndex = 0,
  }) {
    FullscreenImageViewer.show(
      context: context,
      imageUrl: imageUrl,
      imageTitle: imageTitle,
      imageUrls: imageUrls,
      initialIndex: initialIndex,
    );
  }

  /// Show fullscreen video player
  /// 
  /// [context] - BuildContext for navigation
  /// [videoUrl] - URL of the video to play
  /// [videoTitle] - Optional title to display in the app bar
  /// 
  /// Example usage:
  /// ```dart
  /// MediaViewerUtils.showVideo(
  ///   context: context,
  ///   videoUrl: 'https://example.com/video.mp4',
  ///   videoTitle: 'My Video',
  /// );
  /// ```
  static void showVideo({
    required BuildContext context,
    required String videoUrl,
    String? videoTitle,
  }) {
    FullscreenVideoPlayer.show(
      context: context,
      videoUrl: videoUrl,
      videoTitle: videoTitle,
    );
  }

  /// Check if a URL is an image file
  /// 
  /// [url] - URL to check
  /// Returns true if the URL appears to be an image file
  static bool isImageFile(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.bmp') ||
        lowerUrl.endsWith('.svg');
  }

  /// Check if a URL is a video file
  /// 
  /// [url] - URL to check
  /// Returns true if the URL appears to be a video file
  static bool isVideoFile(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.flv') ||
        lowerUrl.endsWith('.wmv');
  }
}

