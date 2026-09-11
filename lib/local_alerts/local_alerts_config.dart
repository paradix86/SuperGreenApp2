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

import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:super_green_app/local_alerts/local_alert_settings.dart';

/// One lab the background service has to watch: which controller to poll,
/// which box of it, and the limits. The plant is what a notification opens.
class LocalAlertTarget extends Equatable {
  final int boxId;
  final String boxName;
  final int? plantId;
  final String? plantName;
  final String deviceIp;
  final String deviceName;
  final int boxIndex;
  final LocalAlertSettings alerts;

  const LocalAlertTarget({
    required this.boxId,
    required this.boxName,
    this.plantId,
    this.plantName,
    required this.deviceIp,
    required this.deviceName,
    required this.boxIndex,
    required this.alerts,
  });

  /// What the user sees in a notification title.
  String get label => plantName ?? boxName;

  factory LocalAlertTarget.fromMap(Map<String, dynamic> map) => LocalAlertTarget(
        boxId: map['boxId'] as int,
        boxName: map['boxName'] as String? ?? '',
        plantId: map['plantId'] as int?,
        plantName: map['plantName'] as String?,
        deviceIp: map['deviceIp'] as String,
        deviceName: map['deviceName'] as String? ?? '',
        boxIndex: map['boxIndex'] as int? ?? 0,
        alerts: LocalAlertSettings.fromMap(map['alerts'] as Map<String, dynamic>?),
      );

  Map<String, dynamic> toMap() => {
        'boxId': boxId,
        'boxName': boxName,
        'plantId': plantId,
        'plantName': plantName,
        'deviceIp': deviceIp,
        'deviceName': deviceName,
        'boxIndex': boxIndex,
        'alerts': alerts.toMap(),
      };

  @override
  List<Object?> get props => [boxId, boxName, plantId, plantName, deviceIp, deviceName, boxIndex, alerts];
}

/// Snapshot of everything the background service needs, written by the app
/// (which owns the database) and read by the service isolate (which does not
/// open the database: two isolates on one SQLite file is asking for trouble).
class LocalAlertsConfig extends Equatable {
  static const int currentVersion = 1;
  static const String fileName = 'local_alerts.json';

  final bool freedomUnits;
  final List<LocalAlertTarget> targets;

  const LocalAlertsConfig({this.freedomUnits = false, this.targets = const []});

  /// Targets whose alerts are switched on: the only ones worth polling.
  List<LocalAlertTarget> get enabledTargets => targets.where((t) => t.alerts.enabled).toList();

  bool get hasEnabledTargets => targets.any((t) => t.alerts.enabled);

  factory LocalAlertsConfig.fromJson(String source) {
    final dynamic decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('local alerts config is not an object');
    }
    final dynamic targets = decoded['targets'];
    return LocalAlertsConfig(
      freedomUnits: decoded['freedomUnits'] == true,
      targets: targets is List
          ? targets.whereType<Map<String, dynamic>>().map((m) => LocalAlertTarget.fromMap(m)).toList()
          : const [],
    );
  }

  String toJson() => json.encode({
        'version': currentVersion,
        'freedomUnits': freedomUnits,
        'targets': targets.map((t) => t.toMap()).toList(),
      });

  static File fileIn(Directory documents) => File('${documents.path}/$fileName');

  /// Missing or unreadable file means "nothing to watch".
  static Future<LocalAlertsConfig> read(Directory documents) async {
    final File file = fileIn(documents);
    if (!await file.exists()) {
      return const LocalAlertsConfig();
    }
    try {
      return LocalAlertsConfig.fromJson(await file.readAsString());
    } on FormatException {
      return const LocalAlertsConfig();
    }
  }

  Future<void> write(Directory documents) async {
    // Write-then-rename so the service never reads a half-written file.
    final File tmp = File('${documents.path}/$fileName.tmp');
    await tmp.writeAsString(toJson(), flush: true);
    await tmp.rename(fileIn(documents).path);
  }

  @override
  List<Object?> get props => [freedomUnits, targets];
}
