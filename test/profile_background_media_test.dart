import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';

void main() {
  group('ApiImageUtils.normalize', () {
    test('upgrades http API host uploads to https', () {
      final input =
          'http://my-backend-api-960q.onrender.com/uploads/backgrounds/dragon.svga';
      final expected =
          'https://my-backend-api-960q.onrender.com/uploads/backgrounds/dragon.svga';
      expect(ApiImageUtils.normalize(input), expected);
      expect(Uri.parse(ApiConstants.baseUrl).host, 'my-backend-api-960q.onrender.com');
    });

    test('keeps https Unsplash images unchanged', () {
      const input =
          'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=600';
      expect(ApiImageUtils.normalize(input), input);
    });
  });

  group('ProfileBackgroundMedia media detection', () {
    test('detects svga from backgroundDetails.image field', () {
      expect(
        ProfileBackgroundMedia.isSvgaUrl(
          'http://my-backend-api-960q.onrender.com/uploads/backgrounds/image-1.svga',
        ),
        isTrue,
      );
      expect(
        ProfileBackgroundMedia.isKnownStaticMedia(
          'https://images.unsplash.com/photo-x.jpg',
        ),
        isTrue,
      );
    });
  });
}
