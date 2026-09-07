/*
 * Copyright (C) 2022  SuperGreenLab <towelie@supergreenlab.com>
 * Author: Constantin Clauzel <constantin.clauzel@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:equatable/equatable.dart';
import 'package:super_green_app/data/api/device/device_status.dart';

/// The live values served by `GET http://<ip>/dash` (firmwares from 2026-09-07):
/// every box, the LEDs, the firmware sensor health and the controller clock, in
/// one response instead of ~40 `GET /i`.
///
/// The payload is flattened into the same upper-case keys the local params
/// table uses (`BOX_0_TEMP`, `LED_2_DUTY`, `SENSOR_HEALTH_LAST_ALERT`, `TIME`),
/// so it can be applied to the database without knowing the config layout.
class DeviceDash extends Equatable {
  static const String TIME_KEY = 'TIME';

  /// Integer values keyed by the param's caps name.
  final Map<String, int> intValues;

  /// String values keyed by the param's caps name.
  final Map<String, String> stringValues;

  const DeviceDash({this.intValues = const {}, this.stringValues = const {}});

  /// Controller clock (unix seconds), null when the firmware did not send it.
  int? get time => intValues[TIME_KEY];

  factory DeviceDash.fromJson(Map<String, dynamic> json) {
    final Map<String, int> ints = {};
    final Map<String, String> strings = {};

    void put(String key, dynamic value) {
      if (value is String) {
        strings[key] = value;
        return;
      }
      final int? parsed = DeviceStatus.parseInt(value);
      if (parsed != null) {
        ints[key] = parsed;
      }
    }

    void putAll(String prefix, dynamic object) {
      if (object is! Map) {
        return;
      }
      object.forEach((dynamic field, dynamic value) {
        put('${prefix}_${'$field'.toUpperCase()}', value);
      });
    }

    final dynamic boxes = json['boxes'];
    if (boxes is List) {
      for (int position = 0; position < boxes.length; ++position) {
        final dynamic box = boxes[position];
        if (box is! Map) {
          continue;
        }
        final int index = DeviceStatus.parseInt(box['i']) ?? position;
        box.forEach((dynamic field, dynamic value) {
          if ('$field' == 'i') {
            return;
          }
          put('BOX_${index}_${'$field'.toUpperCase()}', value);
        });
      }
    }

    final dynamic leds = json['leds'];
    if (leds is List) {
      for (int index = 0; index < leds.length; ++index) {
        putAll('LED_$index', leds[index]);
      }
    }

    putAll('SENSOR_HEALTH', json['sensor_health']);
    put(TIME_KEY, json['time']);

    return DeviceDash(intValues: Map.unmodifiable(ints), stringValues: Map.unmodifiable(strings));
  }

  @override
  List<Object?> get props => [intValues, stringValues];
}
