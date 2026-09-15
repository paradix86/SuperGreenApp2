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

  /// VPD in kPa, CO2 in ppm. Sensible ranges for a grow, but both alarms are
  /// off by default (see below).
  static const double defaultVpdMin = 0.8;
  static const double defaultVpdMax = 1.6;
  static const double defaultCo2Min = 400;
  static const double defaultCo2Max = 1500;

  final bool enabled;
  final double tempMin;
  final double tempMax;
  final double humiMin;
  final double humiMax;

  /// Opt-in: notify when the controller's restart counter goes up between polls
  /// (a reboot while you are away). Off by default so existing users are not
  /// surprised by a new alarm; only checked while [enabled] is also true.
  final bool rebootAlertEnabled;

  /// Opt-in VPD (kPa) and CO2 (ppm) range alarms. Off by default: VPD suits a
  /// range only some growers watch, and CO2 needs a sensor the box may not have
  /// (an absent CO2 sensor reads 0, which a min would fire on endlessly).
  final bool vpdAlertEnabled;
  final double vpdMin;
  final double vpdMax;
  final bool co2AlertEnabled;
  final double co2Min;
  final double co2Max;

  const LocalAlertSettings({
    this.enabled = false,
    this.tempMin = defaultTempMin,
    this.tempMax = defaultTempMax,
    this.humiMin = defaultHumiMin,
    this.humiMax = defaultHumiMax,
    this.rebootAlertEnabled = false,
    this.vpdAlertEnabled = false,
    this.vpdMin = defaultVpdMin,
    this.vpdMax = defaultVpdMax,
    this.co2AlertEnabled = false,
    this.co2Min = defaultCo2Min,
    this.co2Max = defaultCo2Max,
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
      vpdAlertEnabled: map['vpdAlertEnabled'] == true,
      vpdMin: _number(map['vpdMin'], defaultVpdMin),
      vpdMax: _number(map['vpdMax'], defaultVpdMax),
      co2AlertEnabled: map['co2AlertEnabled'] == true,
      co2Min: _number(map['co2Min'], defaultCo2Min),
      co2Max: _number(map['co2Max'], defaultCo2Max),
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
        'vpdAlertEnabled': vpdAlertEnabled,
        'vpdMin': vpdMin,
        'vpdMax': vpdMax,
        'co2AlertEnabled': co2AlertEnabled,
        'co2Min': co2Min,
        'co2Max': co2Max,
      };

  LocalAlertSettings copyWith({
    bool? enabled,
    double? tempMin,
    double? tempMax,
    double? humiMin,
    double? humiMax,
    bool? rebootAlertEnabled,
    bool? vpdAlertEnabled,
    double? vpdMin,
    double? vpdMax,
    bool? co2AlertEnabled,
    double? co2Min,
    double? co2Max,
  }) =>
      LocalAlertSettings(
        enabled: enabled ?? this.enabled,
        tempMin: tempMin ?? this.tempMin,
        tempMax: tempMax ?? this.tempMax,
        humiMin: humiMin ?? this.humiMin,
        humiMax: humiMax ?? this.humiMax,
        rebootAlertEnabled: rebootAlertEnabled ?? this.rebootAlertEnabled,
        vpdAlertEnabled: vpdAlertEnabled ?? this.vpdAlertEnabled,
        vpdMin: vpdMin ?? this.vpdMin,
        vpdMax: vpdMax ?? this.vpdMax,
        co2AlertEnabled: co2AlertEnabled ?? this.co2AlertEnabled,
        co2Min: co2Min ?? this.co2Min,
        co2Max: co2Max ?? this.co2Max,
      );

  @override
  List<Object?> get props => [
        enabled,
        tempMin,
        tempMax,
        humiMin,
        humiMax,
        rebootAlertEnabled,
        vpdAlertEnabled,
        vpdMin,
        vpdMax,
        co2AlertEnabled,
        co2Min,
        co2Max,
      ];
}
