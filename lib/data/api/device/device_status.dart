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

/// Snapshot of the controller diagnostics exposed by `GET http://<ip>/mqttdiag`.
///
/// Every field is nullable: older firmwares may omit some keys (or the whole endpoint),
/// so [DeviceStatus.fromJson] tolerates missing keys and int/string encoded numbers.
class DeviceStatus extends Equatable {
  static const int RESET_POWER_ON = 1;
  static const int RESET_SOFTWARE = 3;
  static const int RESET_PANIC = 4;
  static const int RESET_INT_WDT = 5;
  static const int RESET_TASK_WDT = 6;
  static const int RESET_OTHER_WDT = 7;
  static const int RESET_DEEPSLEEP = 8;
  static const int RESET_BROWNOUT = 9;
  static const int RESET_SDIO = 10;

  static const int OTA_IDLE = 0;
  static const int OTA_IN_PROGRESS = 1;
  static const int OTA_DISABLED = 2;
  static const int OTA_FAILED = 3;

  static const int WIFI_CONNECTED = 3;

  final int? mqttStage;
  final int? mqttDiscIdx;
  final int? state;
  final int? wifiStatus;
  final int? mqttConnected;
  final int? nRestarts;
  final int? otaStatus;
  final int? resetReason;
  final List<int> resetHistory;
  final int? heapFree;
  final int? heapMinFree;

  /// Uptime (s) at which [heapMinFree] was reached; null on firmwares without the heap watch.
  final int? heapMinFreeAt;

  /// Number of times free heap dipped below the firmware's 8 KB floor since boot.
  final int? heapLowEvents;
  final int? uptimeS;
  final int? nvsUsed;
  final int? nvsFree;
  final int? mqttStackHwm;
  final int? timeValid;
  final String? brokerUrl;
  final String? brokerClientId;

  const DeviceStatus({
    this.mqttStage,
    this.mqttDiscIdx,
    this.state,
    this.wifiStatus,
    this.mqttConnected,
    this.nRestarts,
    this.otaStatus,
    this.resetReason,
    this.resetHistory = const [],
    this.heapFree,
    this.heapMinFree,
    this.heapMinFreeAt,
    this.heapLowEvents,
    this.uptimeS,
    this.nvsUsed,
    this.nvsFree,
    this.mqttStackHwm,
    this.timeValid,
    this.brokerUrl,
    this.brokerClientId,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      mqttStage: parseInt(json['mqtt_stage']),
      mqttDiscIdx: parseInt(json['mqtt_disc_idx']),
      state: parseInt(json['state']),
      wifiStatus: parseInt(json['wifi_status']),
      mqttConnected: parseInt(json['mqtt_connected']),
      nRestarts: parseInt(json['n_restarts']),
      otaStatus: parseInt(json['ota_status']),
      resetReason: parseInt(json['reset_reason']),
      resetHistory: parseIntList(json['reset_history']),
      heapFree: parseInt(json['heap_free']),
      heapMinFree: parseInt(json['heap_min_free']),
      heapMinFreeAt: parseInt(json['heap_min_free_at']),
      heapLowEvents: parseInt(json['heap_low_events']),
      uptimeS: parseInt(json['uptime_s']),
      nvsUsed: parseInt(json['nvs_used']),
      nvsFree: parseInt(json['nvs_free']),
      mqttStackHwm: parseInt(json['mqtt_stack_hwm']),
      timeValid: parseInt(json['time_valid']),
      brokerUrl: parseString(json['broker_url']),
      brokerClientId: parseString(json['broker_clientid']),
    );
  }

  bool get isWifiConnected => wifiStatus == WIFI_CONNECTED;
  bool get isMqttConnected => mqttConnected == 1;
  bool get isTimeValid => timeValid != null && timeValid != 0;

  /// True for the reset reasons that indicate a crash (panic, watchdogs, brownout).
  static bool isAbnormalResetReason(int? reason) {
    return reason == RESET_PANIC ||
        reason == RESET_INT_WDT ||
        reason == RESET_TASK_WDT ||
        reason == RESET_OTHER_WDT ||
        reason == RESET_BROWNOUT;
  }

  static String resetReasonLabel(int? reason) {
    switch (reason) {
      case RESET_POWER_ON:
        return 'Power-on';
      case RESET_SOFTWARE:
        return 'Software';
      case RESET_PANIC:
        return 'Panic';
      case RESET_INT_WDT:
        return 'Interrupt watchdog';
      case RESET_TASK_WDT:
        return 'Task watchdog';
      case RESET_OTHER_WDT:
        return 'Other watchdog';
      case RESET_DEEPSLEEP:
        return 'Deep sleep';
      case RESET_BROWNOUT:
        return 'Brownout';
      case RESET_SDIO:
        return 'SDIO';
      default:
        return 'Unknown';
    }
  }

  static String otaStatusLabel(int? status) {
    switch (status) {
      case OTA_IDLE:
        return 'Idle';
      case OTA_IN_PROGRESS:
        return 'In progress';
      case OTA_DISABLED:
        return 'Disabled';
      case OTA_FAILED:
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  /// Accepts int, double, bool, numeric string or null.
  static int? parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    return int.tryParse(value.toString().trim());
  }

  static String? parseString(dynamic value) {
    if (value == null) {
      return null;
    }
    String str = value.toString();
    return str.isEmpty ? null : str;
  }

  /// Accepts a CSV string ("3,1,4"), a JSON list, or null. Non-numeric entries are dropped.
  static List<int> parseIntList(dynamic value) {
    if (value == null) {
      return const [];
    }
    Iterable<dynamic> parts;
    if (value is List) {
      parts = value;
    } else {
      parts = value.toString().split(',');
    }
    List<int> result = [];
    for (dynamic part in parts) {
      int? parsed = parseInt(part);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return List<int>.unmodifiable(result);
  }

  @override
  List<Object?> get props => [
        mqttStage,
        mqttDiscIdx,
        state,
        wifiStatus,
        mqttConnected,
        nRestarts,
        otaStatus,
        resetReason,
        resetHistory,
        heapFree,
        heapMinFree,
        heapMinFreeAt,
        heapLowEvents,
        uptimeS,
        nvsUsed,
        nvsFree,
        mqttStackHwm,
        timeValid,
        brokerUrl,
        brokerClientId,
      ];
}
