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

import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/local_alerts/local_alert_settings.dart';
import 'package:super_green_app/local_alerts/local_alerts_config.dart';
import 'package:super_green_app/local_alerts/local_alerts_service.dart';
import 'package:super_green_app/main.dart';
import 'package:super_green_app/pages/feeds/home/common/settings/box_settings.dart';

/// Keeps the service's config file in step with the database: every change
/// to a box (limits, controller link) or a device (IP after mDNS
/// re-resolution) rebuilds the snapshot and starts or stops the service.
class LocalAlertsSync {
  static const Duration _debounce = Duration(seconds: 2);

  static StreamSubscription? _boxes;
  static StreamSubscription? _devices;
  static Timer? _pending;

  static void start() {
    _boxes?.cancel();
    _devices?.cancel();
    _boxes = RelDB.get().plantsDAO.watchBoxes().listen((_) => _schedule());
    _devices = RelDB.get().devicesDAO.watchDevices(isController: true).listen((_) => _schedule());
    _schedule();
  }

  static void _schedule() {
    _pending?.cancel();
    _pending = Timer(_debounce, () async {
      try {
        await rebuild();
      } catch (e, trace) {
        Logger.logError(e, trace);
      }
    });
  }

  static LocalAlertsConfig? _lastApplied;

  /// Reads boxes, plants and devices, writes the snapshot and tells the
  /// service to reload it (or to stop when no lab has alerts on). The device
  /// table changes at every daemon poll (reachability), so an unchanged
  /// snapshot is not rewritten.
  static Future<LocalAlertsConfig> rebuild() async {
    final LocalAlertsConfig config = await _buildConfig();
    if (config == _lastApplied) {
      return config;
    }
    final Directory documents = Directory(AppDB().documentPath);
    await config.write(documents);
    await LocalAlertsService.applyConfig(config);
    _lastApplied = config;
    return config;
  }

  static Future<LocalAlertsConfig> _buildConfig() async {
    final db = RelDB.get();
    final List<Box> boxes = await db.plantsDAO.getBoxes();
    final List<Device> devices = await db.devicesDAO.getDevices();
    final List<Plant> plants = await db.plantsDAO.getPlants();
    final List<LocalAlertTarget> targets = [];
    for (final Box box in boxes) {
      final LocalAlertSettings alerts = BoxSettings.fromJSON(box.settings).alerts;
      if (box.device == null || box.deviceBox == null) {
        continue;
      }
      Device? device;
      for (final Device d in devices) {
        if (d.id == box.device) {
          device = d;
          break;
        }
      }
      if (device == null || device.isRemote) {
        continue;
      }
      Plant? plant;
      for (final Plant p in plants) {
        if (p.box == box.id) {
          plant = p;
          break;
        }
      }
      targets.add(LocalAlertTarget(
        boxId: box.id,
        boxName: box.name,
        plantId: plant?.id,
        plantName: plant?.name,
        deviceIp: device.ip,
        deviceName: device.name,
        boxIndex: box.deviceBox!,
        alerts: alerts,
      ));
    }
    return LocalAlertsConfig(
      freedomUnits: AppDB().getUserSettings().freedomUnits == true,
      targets: targets,
    );
  }

  /// Android 13+ needs the notification permission before anything shows;
  /// without it the service would run for nothing. Returns true when granted.
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    final AndroidFlutterLocalNotificationsPlugin? android =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Battery optimisation (Samsung "sleeping apps" above all) kills a
  /// foreground service after a while; the exemption dialog is the only fix.
  static Future<bool> isBatteryUnrestricted() async {
    if (!Platform.isAndroid) {
      return true;
    }
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<bool> requestBatteryUnrestricted() async {
    if (!Platform.isAndroid) {
      return true;
    }
    return (await Permission.ignoreBatteryOptimizations.request()).isGranted;
  }
}
