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

import 'package:equatable/equatable.dart';

/// Temperature / humidity limits of one lab, checked on the phone against the
/// controller's `/dash` readings (no SuperGreenLab cloud involved).
///
/// Temperatures are always stored in °C, humidity in %; the UI converts for
/// imperial units. Stored inside [BoxSettings] under the `alerts` key.
class LocalAlertSettings extends Equatable {
  static const double defaultTempMin = 18;
  static const double defaultTempMax = 28;
  static const double defaultHumiMin = 40;
  static const double defaultHumiMax = 75;

  final bool enabled;
  final double tempMin;
  final double tempMax;
  final double humiMin;
  final double humiMax;

  /// Opt-in: notify when the controller's restart counter goes up between polls
  /// (a reboot while you are away). Off by default so existing users are not
  /// surprised by a new alarm; only checked while [enabled] is also true.
  final bool rebootAlertEnabled;

  const LocalAlertSettings({
    this.enabled = false,
    this.tempMin = defaultTempMin,
    this.tempMax = defaultTempMax,
    this.humiMin = defaultHumiMin,
    this.humiMax = defaultHumiMax,
    this.rebootAlertEnabled = false,
  });

  factory LocalAlertSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const LocalAlertSettings();
    }
    return LocalAlertSettings(
      enabled: map['enabled'] == true,
      tempMin: _number(map['tempMin'], defaultTempMin),
      tempMax: _number(map['tempMax'], defaultTempMax),
      humiMin: _number(map['humiMin'], defaultHumiMin),
      humiMax: _number(map['humiMax'], defaultHumiMax),
      rebootAlertEnabled: map['rebootAlertEnabled'] == true,
    );
  }

  static double _number(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'humiMin': humiMin,
        'humiMax': humiMax,
        'rebootAlertEnabled': rebootAlertEnabled,
      };

  LocalAlertSettings copyWith({
    bool? enabled,
    double? tempMin,
    double? tempMax,
    double? humiMin,
    double? humiMax,
    bool? rebootAlertEnabled,
  }) =>
      LocalAlertSettings(
        enabled: enabled ?? this.enabled,
        tempMin: tempMin ?? this.tempMin,
        tempMax: tempMax ?? this.tempMax,
        humiMin: humiMin ?? this.humiMin,
        humiMax: humiMax ?? this.humiMax,
        rebootAlertEnabled: rebootAlertEnabled ?? this.rebootAlertEnabled,
      );

  @override
  List<Object?> get props => [enabled, tempMin, tempMax, humiMin, humiMax, rebootAlertEnabled];
}
