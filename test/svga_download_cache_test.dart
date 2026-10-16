import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qobo_one_live/utils/svga_network_loader.dart';

class _Path extends PathProviderPlatform {
  _Path(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'concurrent consumers download once, reuse disk, and cap concurrency',
    () async {
      final dir = await Directory.systemTemp.createTemp('svga_cache_test');
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _Path(dir.path);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final bytes = await File('test/fixtures/rose.svga').readAsBytes();
      var requests = 0;
      var active = 0;
      var peak = 0;
      var failNext = false;
      final subscription = server.listen((request) async {
        requests++;
        active++;
        if (active > peak) peak = active;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        if (failNext) {
          failNext = false;
          request.response.statusCode = 503;
        } else {
          request.response.add(bytes);
        }
        await request.response.close();
        active--;
      });
      try {
        final base = 'http://127.0.0.1:${server.port}';
        final results = await Future.wait(
          List.generate(
            8,
            (_) => SvgaNetworkLoader.downloadBytes('$base/rose.svga'),
          ),
        );
        expect(requests, 1);
        expect(results.every((value) => value?.length == bytes.length), isTrue);
        await SvgaNetworkLoader.downloadBytes('$base/rose.svga');
        expect(requests, 1, reason: 'repeat access must use disk');
        await Future.wait(
          List.generate(
            5,
            (i) => SvgaNetworkLoader.downloadBytes('$base/$i.svga'),
          ),
        );
        expect(requests, 6);
        expect(peak, lessThanOrEqualTo(2));
        // Corrupted local data must be discarded and recovered from the server.
        await File(
          '${dir.path}/svga_durable_cache/${stableDiskKey('$base/rose.svga')}.svga',
        ).writeAsString('invalid');
        await SvgaNetworkLoader.downloadBytes('$base/rose.svga');
        expect(requests, 7);
        // A failed request must leave no stuck in-flight future.
        failNext = true;
        expect(
          await SvgaNetworkLoader.downloadBytes('$base/retry.svga'),
          isNull,
        );
        expect(
          await SvgaNetworkLoader.downloadBytes('$base/retry.svga'),
          isNotNull,
        );
        expect(requests, 9);
      } finally {
        await subscription.cancel();
        await server.close(force: true);
        PathProviderPlatform.instance = original;
        await dir.delete(recursive: true);
      }
    },
  );
}
