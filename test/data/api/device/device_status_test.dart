import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/api/device/device_status.dart';

void main() {
  const String fullPayload =
      '{"mqtt_stage":6,"mqtt_disc_idx":23,"state":2,"wifi_status":3,"mqtt_connected":1,"n_restarts":145,'
      '"ota_status":0,"reset_reason":3,"reset_history":"3,1,4","heap_free":41836,"heap_min_free":33848,'
      '"heap_min_free_at":31,"heap_low_events":0,"uptime_s":46,"nvs_used":293,"nvs_free":211,"mqtt_stack_hwm":6852,"time_valid":1,'
      '"broker_url":"mqtt://sink2.supergreenlab.com:1883","broker_clientid":"304a4fd6eb4c"}';

  test('parses the full /mqttdiag payload of the current firmware', () {
    final DeviceStatus status = DeviceStatus.fromJson(json.decode(fullPayload));

    expect(status.nRestarts, 145);
    expect(status.resetReason, DeviceStatus.RESET_SOFTWARE);
    expect(status.resetHistory, [3, 1, 4]);
    expect(status.heapMinFree, 33848);
    expect(status.heapMinFreeAt, 31);
    expect(status.heapLowEvents, 0);
    expect(status.uptimeS, 46);
    expect(status.brokerClientId, '304a4fd6eb4c');
    expect(status.isWifiConnected, isTrue);
    expect(status.isMqttConnected, isTrue);
    expect(status.isTimeValid, isTrue);
    expect(DeviceStatus.otaStatusLabel(status.otaStatus), 'Idle');
  });

  test('tolerates the reduced payload of an older firmware', () {
    final DeviceStatus status = DeviceStatus.fromJson(json.decode('{"mqtt_stage":6,"n_restarts":"12","state":2}'));

    expect(status.nRestarts, 12);
    expect(status.resetReason, isNull);
    expect(status.resetHistory, isEmpty);
    expect(status.heapFree, isNull);
    expect(status.heapMinFreeAt, isNull);
    expect(status.heapLowEvents, isNull);
    expect(status.isTimeValid, isFalse);
    expect(DeviceStatus.resetReasonLabel(status.resetReason), 'Unknown');
  });

  test('flags crash-type reset reasons only', () {
    expect(DeviceStatus.isAbnormalResetReason(DeviceStatus.RESET_TASK_WDT), isTrue);
    expect(DeviceStatus.isAbnormalResetReason(DeviceStatus.RESET_BROWNOUT), isTrue);
    expect(DeviceStatus.isAbnormalResetReason(DeviceStatus.RESET_SOFTWARE), isFalse);
    expect(DeviceStatus.isAbnormalResetReason(DeviceStatus.RESET_POWER_ON), isFalse);
    expect(DeviceStatus.isAbnormalResetReason(null), isFalse);
  });

  test('reset_history accepts a JSON list and drops garbage entries', () {
    expect(DeviceStatus.parseIntList([6, '9', 'x', null]), [6, 9]);
    expect(DeviceStatus.parseIntList('7, 3,,1'), [7, 3, 1]);
  });
}
