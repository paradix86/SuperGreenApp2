/*
 * Copyright (C) 2026  SuperGreenLab <towelie@supergreenlab.com>
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

import 'package:super_green_app/data/api/device/device_dash.dart';

/// One reading kept by [DashHistory].
class DashSample {
  final DateTime time;
  final int value;

  const DashSample(this.time, this.value);
}

/// In-memory rolling history of the box sensor readings received through
/// `GET /dash`, used to draw the sparklines of the Lab screen.
///
/// The daemon polls the controller every 15 s, so [maxAge] of 3 h is at
/// most 720 samples per key: cheap enough to keep in RAM and lost on app
/// restart on purpose (the sparkline says "last 3 hours", not "history").
class DashHistory {
  static const Duration maxAge = Duration(hours: 3);

  /// Keys worth keeping: `BOX_<n>_TEMP`, `BOX_<n>_HUMI`, `BOX_<n>_VPD`,
  /// `BOX_<n>_CO2`, `BOX_<n>_WEIGHT`.
  static final RegExp _sensorKey = RegExp(r'^BOX_\d+_(TEMP|HUMI|VPD|CO2|WEIGHT)$');

  static final Map<int, Map<String, List<DashSample>>> _samples = {};

  /// Appends every sensor reading of [dash] for [deviceID] at [at] (now by
  /// default) and drops anything older than [maxAge].
  static void record(int deviceID, DeviceDash dash, {DateTime? at}) {
    final DateTime now = at ?? DateTime.now();
    final Map<String, List<DashSample>> perKey = _samples.putIfAbsent(deviceID, () => {});
    dash.intValues.forEach((String key, int value) {
      if (!_sensorKey.hasMatch(key)) {
        return;
      }
      final List<DashSample> list = perKey.putIfAbsent(key, () => []);
      list.add(DashSample(now, value));
      _prune(list, now);
    });
  }

  /// Readings of [key] for [deviceID] within [window] before [now],
  /// oldest first. Empty when nothing was recorded.
  static List<DashSample> samples(int deviceID, String key, {Duration window = maxAge, DateTime? now}) {
    final List<DashSample>? list = _samples[deviceID]?[key];
    if (list == null) {
      return const [];
    }
    final DateTime cutoff = (now ?? DateTime.now()).subtract(window);
    return list.where((s) => !s.time.isBefore(cutoff)).toList(growable: false);
  }

  /// Forgets everything (tests, logout).
  static void clear() => _samples.clear();

  static void _prune(List<DashSample> list, DateTime now) {
    final DateTime cutoff = now.subtract(maxAge);
    while (list.isNotEmpty && list.first.time.isBefore(cutoff)) {
      list.removeAt(0);
    }
  }
}
