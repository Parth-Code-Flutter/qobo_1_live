import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Fullscreen Image Viewer Widget
/// Displays images in fullscreen with zoom, pan, and swipe capabilities
/// Reusable widget for viewing images throughout the app
class FullscreenImageViewer extends StatelessWidget {
  /// List of image URLs (for gallery mode)
  final List<String> imageUrls;
  
  /// Initial image index (default: 0)
  final int initialIndex;
  
  /// Image title/name to display
  final String? imageTitle;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.imageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: imageTitle != null
            ? AppText(
                text: imageTitle!,
                fontSize: 16,
                color: Colors.white,
                style: TextStyles.kSemiBoldLato(fontSize: 16, colors: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
      body: imageUrls.length == 1
          ? _buildSingleImageView(imageUrls[0])
          : _buildGalleryView(),
    );
  }

  /// Build single image view (non-gallery mode)
  Widget _buildSingleImageView(String imageUrl) {
    return PhotoView(
      imageProvider: NetworkImage(imageUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              AppText(
                text: 'Failed to load image',
                fontSize: 16,
                color: Colors.white,
                style: TextStyles.kRegularLato(fontSize: 16, colors: Colors.white),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, event) {
        return Center(
          child: CircularProgressIndicator(
            value: event == null
                ? null
                : event.expectedTotalBytes != null
                    ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
            color: kColorPrimary,
          ),
        );
      },
    );
  }

  /// Build gallery view (multiple images with swipe)
  Widget _buildGalleryView() {
    return PhotoViewGallery.builder(
      itemCount: imageUrls.length,
      pageController: PageController(initialPage: initialIndex),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(imageUrls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: 'Failed to load image',
                    fontSize: 16,
                    color: Colors.white,
                    style: TextStyles.kRegularLato(fontSize: 16, colors: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
      scrollPhysics: const BouncingScrollPhysics(),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  /// Show fullscreen image viewer
  /// Utility method to easily display images in fullscreen
  static void show({
    required BuildContext context,
    required String imageUrl,
    String? imageTitle,
    List<String>? imageUrls,
    int initialIndex = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageUrls: imageUrls ?? [imageUrl],
          initialIndex: initialIndex,
          imageTitle: imageTitle,
        ),
      ),
    );
  }
}

