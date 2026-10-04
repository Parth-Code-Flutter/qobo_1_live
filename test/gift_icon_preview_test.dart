import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:flutter_test/flutter_test.dart';
// Test-only stand-in for the app support folder. Already in the app via path_provider.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qobo_one_live/services/gifts/gift_icon_preview_store.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List readFixture(String name) {
    final file = File('test/fixtures/$name');
    expect(file.existsSync(), isTrue, reason: 'missing fixture $name');
    return file.readAsBytesSync();
  }

  Future<void> expectDecodableImage(String name) async {
    final bytes = readFixture(name);
    expect(bytes[0], 0x78, reason: '$name should be a zlib SVGA');

    final preview = extractSvgaPreviewBytes(bytes);
    expect(preview, isNotNull, reason: '$name produced no preview');
    expect(preview!.length, greaterThan(32));

    final looksLikeImage =
        (preview[0] == 0x89 && preview[1] == 0x50) ||
        (preview[0] == 0xFF && preview[1] == 0xD8) ||
        (preview[0] == 0x47 && preview[1] == 0x49);
    expect(looksLikeImage, isTrue, reason: '$name preview is not an image');

    final codec = await ui.instantiateImageCodec(preview);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, greaterThan(0));
    expect(frame.image.height, greaterThan(0));
    frame.image.dispose();
    codec.dispose();
  }

  test('EmptyState either has a picture or is vector-only', () {
    final bytes = readFixture('empty_state.svga');
    final inflated = ZLibCodec().decode(bytes);
    final movie = MovieEntity.fromBuffer(inflated);
    final preview = extractSvgaPreviewBytes(bytes);
    expect(
      movie.images.length,
      0,
      reason:
          'images=${movie.images.length} previewBytes=${preview?.length}',
    );
    expect(preview, isNull);
  });

  test('extracts a real picture from rose.svga', () async {
    await expectDecodableImage('rose.svga');
  });

  test('extracts rose inside the same isolate path the app uses', () async {
    final preview = await compute(
      extractSvgaPreviewBytes,
      readFixture('rose.svga'),
    );
    expect(preview, isNotNull);
    expect(preview!.length, greaterThan(32));
  });

  test('returns null for a broken file instead of throwing', () {
    expect(extractSvgaPreviewBytes(Uint8List.fromList([0x78, 0x9c, 1, 2, 3])), isNull);
  });

  test('long gift urls do not share one preview file', () {
    final prefix = 'https://cdn.qobo1live.com/gifts/icons/${'a' * 40}';
    final rose = '$prefix/rose.svga';
    final dragon = '$prefix/dragon.svga';

    String cutOff(String url) {
      final digest = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
      return digest.length <= 80 ? digest : digest.substring(0, 80);
    }

    expect(cutOff(rose), cutOff(dragon));
    expect(stableDiskKey(rose), isNot(stableDiskKey(dragon)));
  });

  test('a saved preview is reused and the animation is not downloaded', () async {
    final support = await Directory.systemTemp.createTemp('gift_preview_test');
    PathProviderPlatform.instance = _FakePath(support.path);
    GiftIconPreviewStore.debugReset();

    const url =
        'https://cdn.qobo1live.com/gifts/icons/rose-animation-file.svga';
    final preview = extractSvgaPreviewBytes(readFixture('rose.svga'));
    final file = File(
      '${support.path}/gift_icon_previews/${stableDiskKey(url)}.bin',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(preview!);

    final path = await GiftIconPreviewStore.ensure(url).timeout(
      const Duration(seconds: 5),
    );
    expect(path, file.path);

    final again = await GiftIconPreviewStore.ensure(url).timeout(
      const Duration(seconds: 5),
    );
    expect(again, file.path);

    GiftIconPreviewStore.debugReset();
    await support.delete(recursive: true);
  });
}

class _FakePath extends PathProviderPlatform {
  _FakePath(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}
