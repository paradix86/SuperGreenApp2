import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/api/device/device_api.dart';
import 'package:super_green_app/data/logger/logger.dart';

/// Minimal stand-in for the controller's httpd: one handler per test.
class FakeController {
  late HttpServer server;
  final List<String> requestedPaths = [];
  void Function(HttpRequest req) handler = (HttpRequest req) {};

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) {
      requestedPaths.add(req.uri.toString());
      handler(req);
    });
  }

  String get ip => '127.0.0.1:${server.port}';

  Future<void> stop() => server.close(force: true);
}

void main() {
  late FakeController controller;

  setUpAll(() async {
    Logger.logFile = File('${Directory.systemTemp.path}/sgl_test_log.txt');
  });

  setUp(() async {
    controller = FakeController();
    await controller.start();
  });

  tearDown(() => controller.stop());

  group('backoffDelay', () {
    test('doubles from the base and caps at maxBackoffSeconds', () {
      expect(DeviceAPI.backoffDelay(1, 1), const Duration(seconds: 1));
      expect(DeviceAPI.backoffDelay(2, 1), const Duration(seconds: 2));
      expect(DeviceAPI.backoffDelay(3, 1), const Duration(seconds: 4));
      expect(DeviceAPI.backoffDelay(4, 1), const Duration(seconds: 8));
      expect(DeviceAPI.backoffDelay(5, 1), const Duration(seconds: 8));
      expect(DeviceAPI.backoffDelay(2, 3), const Duration(seconds: 6));
    });

    test('is zero before the first retry or when no wait is configured', () {
      expect(DeviceAPI.backoffDelay(0, 1), Duration.zero);
      expect(DeviceAPI.backoffDelay(1, 0), Duration.zero);
    });
  });

  group('fetchIntParam', () {
    test('parses the /i?k= body and upper-cases the key', () async {
      controller.handler = (HttpRequest req) {
        req.response.write('42\n');
        req.response.close();
      };

      final int value = await DeviceAPI.fetchIntParam(controller.ip, 'ota_status', nRetries: 1);

      expect(value, 42);
      expect(controller.requestedPaths, ['/i?k=OTA_STATUS']);
    });

    test('throws DeviceRequestException with the status code on a non-2xx reply', () async {
      controller.handler = (HttpRequest req) {
        req.response.statusCode = 500;
        req.response.close();
      };

      await expectLater(
        DeviceAPI.fetchIntParam(controller.ip, 'TIME', nRetries: 1),
        throwsA(isA<DeviceRequestException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('wraps an unparsable body instead of throwing a bare FormatException', () async {
      controller.handler = (HttpRequest req) {
        req.response.write('This URI does not exist');
        req.response.close();
      };

      await expectLater(
        DeviceAPI.fetchIntParam(controller.ip, 'WATERING_LEFT', nRetries: 1),
        throwsA(isA<DeviceRequestException>().having((e) => e.cause, 'cause', isA<FormatException>())),
      );
    });

    test('retries and eventually succeeds', () async {
      int calls = 0;
      controller.handler = (HttpRequest req) {
        ++calls;
        if (calls == 1) {
          req.response.statusCode = 503;
        } else {
          req.response.write('7');
        }
        req.response.close();
      };

      final int value = await DeviceAPI.fetchIntParam(controller.ip, 'STATE', nRetries: 2, wait: 0);

      expect(value, 7);
      expect(calls, 2);
    });

    test('times out when the controller accepts the connection but never answers', () async {
      controller.handler = (HttpRequest req) {
        // hold the socket open: the old implementation only bounded connect()
      };
      final Stopwatch sw = Stopwatch()..start();

      await expectLater(
        DeviceAPI.fetchIntParam(controller.ip, 'TIME', timeout: 1, nRetries: 1),
        throwsA(isA<TimeoutException>()),
      );

      expect(sw.elapsed, lessThan(const Duration(seconds: 4)));
    });
  });

  group('fetchString', () {
    test('joins a chunked body instead of returning the first chunk', () async {
      controller.handler = (HttpRequest req) async {
        req.response.write('{"mqtt_stage":6,');
        await req.response.flush();
        await Future.delayed(const Duration(milliseconds: 50));
        req.response.write('"heap_free":41836}');
        await req.response.close();
      };

      final String body = await DeviceAPI.fetchString('http://${controller.ip}/mqttdiag', nRetries: 1);

      expect(body, '{"mqtt_stage":6,"heap_free":41836}');
    });
  });
}
