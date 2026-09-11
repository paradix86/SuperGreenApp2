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

import 'package:drift/drift.dart' show Value;
import 'package:super_green_app/data/api/device/device_helper.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/overrides/box_override.dart';
import 'package:super_green_app/pages/feeds/home/common/settings/box_settings.dart';

/// A boost forces a control to full output: the light's `TIMER_MANUAL_OUTPUT`
/// is set to 100 and `TIMER_TYPE` switches to manual so it takes effect
/// immediately, and the blower gets its whole 0-100 duty range pinned to
/// 100 (`BLOWER_MIN` = `BLOWER_MAX` = 100).
enum BoxOverrideKind { light, blower }

/// Starts, stops and expires the light/blower boosts described in
/// [BoxOverrides]. Talks to the controller through [DeviceHelper] like any
/// other control, and keeps the box's own restore point in [BoxSettings] so
/// the override survives an app restart and a second reader (the daemon,
/// this page, the local-alerts service) can still end it correctly.
class BoxOverridesHelper {
  static const int _timerManual = 0; // enum timer { TIMER_MANUAL, ... } in timer.h
  static const int _fullOutput = 100;

  /// Reads the box's current values for [kind], saves them as the restore
  /// point, then pins the control to full for [minutes] (capped to
  /// [TemporaryOverride.maxMinutes]).
  ///
  /// For light, [_keysFor] orders TIMER_MANUAL_OUTPUT before TIMER_TYPE on
  /// purpose: TIMER_MANUAL_OUTPUT is inert until the box is actually in
  /// TIMER_MANUAL, so writing it first means the value is already 100 the
  /// instant TIMER_TYPE flips to manual (the firmware applies it as part of
  /// that same write), instead of a moment at 0 while manual mode's own
  /// no-schedule output catches up.
  static Future<void> start(Device device, Box box, BoxOverrideKind kind, int minutes) async {
    final int capped = minutes.clamp(1, TemporaryOverride.maxMinutes);
    final Map<String, int> restore = {};
    for (final String key in _keysFor(kind)) {
      final Param current = await DeviceHelper.loadBoxParam(device, box, key);
      // Every key here (TIMER_TYPE, TIMER_MANUAL_OUTPUT, BLOWER_MIN,
      // BLOWER_MAX) is always an int on the controller; null only means the
      // param hasn't been fetched into the local db yet, which loadBoxParam
      // already refreshes above, so 0 here would mean something else broke.
      restore[current.key] = current.ivalue ?? 0;
      final int fullValue = key == 'TIMER_TYPE' ? _timerManual : _fullOutput;
      await DeviceHelper.updateIntParam(device, current, fullValue);
    }
    final DateTime expiresAt = DateTime.now().toUtc().add(Duration(minutes: capped));
    final TemporaryOverride override = TemporaryOverride(
      active: true,
      expiresAt: expiresAt.millisecondsSinceEpoch ~/ 1000,
      restore: restore,
    );
    await _saveOverride(box, kind, override);
  }

  /// Writes the saved restore values back to the controller and clears the
  /// override, whether it expired or the user tapped "Stop now".
  ///
  /// Restores in the reverse of [start]'s write order: for light that means
  /// TIMER_TYPE goes back first (the box leaves manual immediately, its new
  /// mode's own task recomputes the real output right away), then
  /// TIMER_MANUAL_OUTPUT last, purely for hygiene since it no longer drives
  /// anything once TIMER_TYPE is off manual.
  static Future<void> stop(Device device, Box box, BoxOverrideKind kind) async {
    final BoxSettings settings = BoxSettings.fromJSON(box.settings);
    final TemporaryOverride override =
        kind == BoxOverrideKind.light ? settings.overrides.light : settings.overrides.blower;
    for (final MapEntry<String, int> entry in override.restore.entries.toList().reversed) {
      final Param param = await RelDB.get().devicesDAO.getParam(device.id, entry.key);
      await DeviceHelper.updateIntParam(device, param, entry.value);
    }
    await _saveOverride(box, kind, const TemporaryOverride());
  }

  /// Called on every daemon/service poll: ends any override of [box] whose
  /// time is up. Cheap when nothing is active (no param read, no write).
  static Future<void> checkExpired(Device device, Box box, {DateTime? now}) async {
    final DateTime at = now ?? DateTime.now();
    final BoxSettings settings = BoxSettings.fromJSON(box.settings);
    if (settings.overrides.light.isExpired(at)) {
      await stop(device, box, BoxOverrideKind.light);
    }
    if (settings.overrides.blower.isExpired(at)) {
      await stop(device, box, BoxOverrideKind.blower);
    }
  }

  static List<String> _keysFor(BoxOverrideKind kind) => kind == BoxOverrideKind.light
      ? const ['TIMER_MANUAL_OUTPUT', 'TIMER_TYPE']
      : const ['BLOWER_MIN', 'BLOWER_MAX'];

  static Future<void> _saveOverride(Box box, BoxOverrideKind kind, TemporaryOverride override) async {
    final BoxSettings settings = BoxSettings.fromJSON(box.settings);
    final BoxOverrides overrides = kind == BoxOverrideKind.light
        ? settings.overrides.copyWith(light: override)
        : settings.overrides.copyWith(blower: override);
    final String settingsJSON = settings.copyWith(overrides: overrides).toJSON();
    await RelDB.get().plantsDAO.updateBox(BoxesCompanion(id: Value(box.id), settings: Value(settingsJSON)));
  }
}
