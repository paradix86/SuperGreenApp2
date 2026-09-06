import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/api/device/request_limiter.dart';

void main() {
  test('never runs more than maxInFlight actions at once and keeps FIFO order', () async {
    final RequestLimiter limiter = RequestLimiter(2);
    int running = 0;
    int peak = 0;
    final List<int> order = [];
    final Completer<void> gate = Completer<void>();

    Future<int> action(int id) => limiter.run(() async {
          ++running;
          peak = running > peak ? running : peak;
          order.add(id);
          await gate.future;
          --running;
          return id;
        });

    final Future<List<int>> all = Future.wait([action(1), action(2), action(3), action(4)]);
    await Future<void>.delayed(Duration.zero);

    expect(limiter.inFlight, 2);
    expect(limiter.waiting, 2);
    expect(order, [1, 2]);

    gate.complete();
    expect(await all, [1, 2, 3, 4]);
    expect(peak, 2);
    expect(order, [1, 2, 3, 4]);
    expect(limiter.inFlight, 0);
    expect(limiter.waiting, 0);
  });

  test('releases the slot when the action throws', () async {
    final RequestLimiter limiter = RequestLimiter(1);

    await expectLater(limiter.run(() async => throw StateError('boom')), throwsStateError);

    expect(limiter.inFlight, 0);
    expect(await limiter.run(() async => 7), 7);
  });
}
