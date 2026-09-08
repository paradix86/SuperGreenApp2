import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/api/device/dash_history.dart';
import 'package:super_green_app/data/api/device/device_dash.dart';

void main() {
  setUp(DashHistory.clear);

  DeviceDash dash(Map<String, int> values) => DeviceDash(intValues: values, stringValues: const {});

  test('records only box sensor readings, oldest first', () {
    final DateTime t0 = DateTime(2026, 9, 7, 14, 0);

    DashHistory.record(1, dash({'BOX_0_TEMP': 28, 'BOX_0_ON_HOUR': 10, 'LED_0_DIM': 100, 'BOX_0_BLOWER_DUTY': 40}), at: t0);
    DashHistory.record(1, dash({'BOX_0_TEMP': 29}), at: t0.add(const Duration(seconds: 15)));

    final List<DashSample> temp = DashHistory.samples(1, 'BOX_0_TEMP', now: t0.add(const Duration(minutes: 1)));
    expect(temp.map((s) => s.value), [28, 29]);
    expect(DashHistory.samples(1, 'BOX_0_BLOWER_DUTY', now: t0).map((s) => s.value), [40]);
    expect(DashHistory.samples(1, 'BOX_0_ON_HOUR', now: t0), isEmpty);
    expect(DashHistory.samples(1, 'LED_0_DIM', now: t0), isEmpty);
    expect(DashHistory.samples(2, 'BOX_0_TEMP', now: t0), isEmpty);
  });

  test('drops readings older than maxAge and honours the requested window', () {
    final DateTime t0 = DateTime(2026, 9, 7, 10, 0);

    DashHistory.record(1, dash({'BOX_0_HUMI': 50}), at: t0);
    DashHistory.record(1, dash({'BOX_0_HUMI': 55}), at: t0.add(const Duration(hours: 23)));
    DashHistory.record(1, dash({'BOX_0_HUMI': 60}), at: t0.add(const Duration(hours: 25)));

    final DateTime now = t0.add(const Duration(hours: 25));
    expect(DashHistory.samples(1, 'BOX_0_HUMI', now: now).map((s) => s.value), [55, 60]);
    expect(
      DashHistory.samples(1, 'BOX_0_HUMI', window: const Duration(hours: 1), now: now).map((s) => s.value),
      [60],
    );
  });
}
