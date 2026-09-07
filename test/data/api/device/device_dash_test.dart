import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/api/device/device_dash.dart';

void main() {
  late Map<String, dynamic> fixture;

  setUpAll(() {
    // Captured from a real controller on 2026-09-07 (firmware 1788767754).
    fixture = json.decode(File('test/data/api/device/dash_fixture.json').readAsStringSync());
  });

  test('flattens the boxes into the BOX_<i>_<FIELD> params of the local db', () {
    final DeviceDash dash = DeviceDash.fromJson(fixture);

    expect(dash.intValues['BOX_0_ENABLED'], 1);
    expect(dash.intValues['BOX_0_TEMP'], fixture['boxes'][0]['temp']);
    expect(dash.intValues['BOX_0_VPD'], fixture['boxes'][0]['vpd']);
    expect(dash.intValues['BOX_0_FAN_REF_SOURCE'], 8);
    expect(dash.intValues['BOX_2_ENABLED'], 0);
    expect(dash.intValues.containsKey('BOX_0_I'), isFalse);
  });

  test('flattens the LEDs, the sensor health and the clock', () {
    final DeviceDash dash = DeviceDash.fromJson(fixture);

    expect(dash.intValues['LED_0_BOX'], 0);
    expect(dash.intValues['LED_5_DIM'], fixture['leds'][5]['dim']);
    expect(dash.intValues['SENSOR_HEALTH_STATUS'], 3);
    expect(dash.intValues['SENSOR_HEALTH_STUCK_SAMPLES'], 15);
    expect(dash.stringValues['SENSOR_HEALTH_LAST_ALERT'], 'box_0_temp_stuck');
    expect(dash.time, fixture['time']);
  });

  test('tolerates a partial payload and uses the list position when "i" is missing', () {
    final DeviceDash dash = DeviceDash.fromJson(json.decode('{"boxes":[{"temp":21},{"i":2,"temp":null}],"time":null}'));

    expect(dash.intValues['BOX_0_TEMP'], 21);
    expect(dash.intValues.containsKey('BOX_2_TEMP'), isFalse);
    expect(dash.time, isNull);
    expect(dash.stringValues, isEmpty);
  });
}
