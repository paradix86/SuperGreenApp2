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
import 'package:super_green_app/data/api/device/device_api.dart';
import 'package:super_green_app/data/api/device/device_helper.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/rel/device/devices.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/overrides/box_override.dart';
import 'package:super_green_app/pages/feeds/home/common/settings/box_settings.dart';

/// A boost forces a control to full output for a while: the light gets a
/// countdown in `TIMER_BOOST_S` that the firmware itself runs down (it keeps
/// the box in its own timer type and just overrides the output while the
/// countdown lasts), and the blower gets its whole 0-100 duty range pinned to
/// 100 (`BLOWER_MIN` = `BLOWER_MAX` = 100).
enum BoxOverrideKind { light, blower }

/// Starts, stops and expires the light/blower boosts described in
/// [BoxOverrides]. Talks to the controller through [DeviceHelper] like any
/// other control, and keeps the box's own restore point in [BoxSettings] so
/// the override survives an app restart and a second reader (the daemon,
/// this page, the local-alerts service) can still end it correctly.
class BoxOverridesHelper {
  static const int _fullOutput = 100;

  /// Reads the box's current values for [kind], saves them as the restore
  /// point, then pins the control to full for [minutes] (capped to
  /// [TemporaryOverride.maxMinutes]).
  ///
  /// The light boost is a countdown rather than a value: the firmware runs
  /// TIMER_BOOST_S down on its own and goes back to the schedule when it hits
  /// zero, so the boost ends on time even with this phone off or off-network,
  /// and a reboot drops it instead of leaving the box stuck (TIMER_BOOST_S is
  /// deliberately not persisted on the controller).
  static Future<void> start(Device device, Box box, BoxOverrideKind kind, int minutes) async {
    final int capped = minutes.clamp(1, TemporaryOverride.maxMinutes);
    final Map<String, int> restore = {};
    for (final String key in _keysFor(kind)) {
      final Param current = await _loadBoxParamOrRefresh(device, box, key);
      // Every key here (TIMER_BOOST_S, BLOWER_MIN, BLOWER_MAX) is always an int
      // on the controller; null only means the param hasn't been fetched into
      // the local db yet, which loadBoxParam already refreshes above, so 0 here
      // would mean something else broke.
      restore[current.key] = current.ivalue ?? 0;
      final int fullValue = key == 'TIMER_BOOST_S' ? capped * 60 : _fullOutput;
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
  /// Restores in the reverse of [start]'s write order, which matters for the
  /// blower's MIN/MAX pair. For light this writes TIMER_BOOST_S back to 0,
  /// cancelling the countdown early; the firmware hands the box back to its
  /// schedule on the next tick, so there is nothing else to put back.
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
      ? const ['TIMER_BOOST_S']
      : const ['BLOWER_MIN', 'BLOWER_MAX'];

  /// A firmware update can introduce a KV key the local db has never seen
  /// (e.g. TIMER_BOOST_S, added after the app last set this device up) -
  /// DeviceHelper.loadBoxParam throws in that case (no local Params row to
  /// read). DeviceAPI.fetchAllParams can't help here either: it discovers
  /// keys from the controller's `/config`, which is served from SPIFFS and
  /// only updated by a separate, rarely-run web-UI upload - a firmware-only
  /// OTA (the common case) leaves it listing the old keys. Since the key name
  /// and type are already known at compile time, fetch and insert it directly
  /// instead, reusing this device's existing "timer" module row.
  static Future<Param> _loadBoxParamOrRefresh(Device device, Box box, String key) async {
    try {
      return await DeviceHelper.loadBoxParam(device, box, key);
    } catch (e) {
      final String fullKey = 'BOX_${box.deviceBox}_$key';
      final String? auth = AppDB().getDeviceAuth(device.identifier);
      final int value = await DeviceAPI.fetchIntParam(device.ip, fullKey, auth: auth);
      final Module module = await RelDB.get().devicesDAO.getModule(device.id, 'timer');
      await RelDB.get().devicesDAO.addParam(ParamsCompanion.insert(
          device: device.id, module: module.id, key: fullKey, type: INTEGER_TYPE, ivalue: Value(value)));
      return RelDB.get().devicesDAO.getParam(device.id, fullKey);
    }
  }

  static Future<void> _saveOverride(Box box, BoxOverrideKind kind, TemporaryOverride override) async {
    final BoxSettings settings = BoxSettings.fromJSON(box.settings);
    final BoxOverrides overrides = kind == BoxOverrideKind.light
        ? settings.overrides.copyWith(light: override)
        : settings.overrides.copyWith(blower: override);
    final String settingsJSON = settings.copyWith(overrides: overrides).toJSON();
    await RelDB.get().plantsDAO.updateBox(BoxesCompanion(id: Value(box.id), settings: Value(settingsJSON)));
  }
}
