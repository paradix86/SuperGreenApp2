/*
 * Copyright (C) 2026  SuperGreenLab <towelie@supergreenlab.com>
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

import 'dart:convert';
import 'dart:io';

import 'package:super_green_app/data/api/device/device_dash.dart';

/// One reading kept by [DashHistory].
class DashSample {
  final DateTime time;
  final int value;

  const DashSample(this.time, this.value);
}

/// Rolling history of the box readings received through `GET /dash`, used by
/// the Lab sparklines (last 3 h) and by the Graphs panel (last 24 h) so the
/// charts show what the controller in front of you is doing, not what the
/// cloud remembers.
///
/// The daemon polls the controller every 15 s while the app is open, so
/// [maxAge] of 24 h is at most 5760 samples per key. The history is written
/// to `dash_history.json` in the app documents directory (throttled to one
/// write per minute) and loaded again at startup, so closing the app does not
/// wipe the graph.
class DashHistory {
  static const Duration maxAge = Duration(hours: 24);
  static const Duration sparklineWindow = Duration(hours: 3);
  static const Duration _saveEvery = Duration(minutes: 1);

  /// Keys worth keeping: box sensors, blower/fan duty, LED dim and timer
  /// output (what the Graphs panel plots).
  static final RegExp _keptKey =
      RegExp(r'^BOX_\d+_(TEMP|HUMI|VPD|CO2|WEIGHT|BLOWER_DUTY|FAN_DUTY|LED_DIM|TIMER_OUTPUT)$');

  static final Map<int, Map<String, List<DashSample>>> _samples = {};
  static File? _file;
  static DateTime? _lastSave;
  static bool _dirty = false;

  /// Reads the persisted history from [dir]; call once at startup.
  static Future<void> load(Directory dir) async {
    _file = File('${dir.path}/dash_history.json');
    try {
      if (!await _file!.exists()) {
        return;
      }
      final dynamic json = jsonDecode(await _file!.readAsString());
      if (json is! Map) {
        return;
      }
      final DateTime now = DateTime.now();
      json.forEach((dynamic deviceID, dynamic perKey) {
        final int? id = int.tryParse('$deviceID');
        if (id == null || perKey is! Map) {
          return;
        }
        perKey.forEach((dynamic key, dynamic points) {
          if (points is! List) {
            return;
          }
          final List<DashSample> list = _samples.putIfAbsent(id, () => {}).putIfAbsent('$key', () => []);
          for (final dynamic p in points) {
            if (p is List && p.length == 2 && p[0] is num && p[1] is num) {
              list.add(DashSample(DateTime.fromMillisecondsSinceEpoch((p[0] as num).toInt()), (p[1] as num).toInt()));
            }
          }
          list.sort((a, b) => a.time.compareTo(b.time));
          _prune(list, now);
        });
      });
    } catch (e) {
      // A corrupt file only costs the history: start empty.
      _samples.clear();
    }
  }

  /// Appends every kept reading of [dash] for [deviceID] at [at] (now by
  /// default) and drops anything older than [maxAge].
  static void record(int deviceID, DeviceDash dash, {DateTime? at}) {
    final DateTime now = at ?? DateTime.now();
    final Map<String, List<DashSample>> perKey = _samples.putIfAbsent(deviceID, () => {});
    dash.intValues.forEach((String key, int value) {
      if (!_keptKey.hasMatch(key)) {
        return;
      }
      final List<DashSample> list = perKey.putIfAbsent(key, () => []);
      list.add(DashSample(now, value));
      _prune(list, now);
      _dirty = true;
    });
    _maybeSave(now);
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
  static void clear() {
    _samples.clear();
    _dirty = false;
  }

  static void _prune(List<DashSample> list, DateTime now) {
    final DateTime cutoff = now.subtract(maxAge);
    while (list.isNotEmpty && list.first.time.isBefore(cutoff)) {
      list.removeAt(0);
    }
  }

  static void _maybeSave(DateTime now) {
    if (_file == null || !_dirty) {
      return;
    }
    if (_lastSave != null && now.difference(_lastSave!) < _saveEvery) {
      return;
    }
    _lastSave = now;
    _dirty = false;
    final Map<String, Map<String, List<List<int>>>> out = {};
    _samples.forEach((int id, Map<String, List<DashSample>> perKey) {
      out['$id'] = perKey.map((String key, List<DashSample> list) =>
          MapEntry(key, list.map((s) => [s.time.millisecondsSinceEpoch, s.value]).toList()));
    });
    // Fire and forget: a failed write only costs the history.
    _file!.writeAsString(jsonEncode(out)).catchError((Object e) => _file!);
  }
}
