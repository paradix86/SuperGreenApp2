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

/// One control (light or blower) forced to full for a limited time, with the
/// param values to restore when it ends. Stored inside [BoxSettings] so the
/// countdown survives the app being closed; the daemon or the local-alerts
/// service ends it, in the local db and on the controller.
class TemporaryOverride extends Equatable {
  /// Longest boost the UI offers; also enforced when starting one, so a
  /// corrupt or hand-edited value can't leave a box stuck on full forever.
  static const int maxMinutes = 60;

  final bool active;

  /// Unix seconds; null when not active.
  final int? expiresAt;

  /// Param key -> value to write back when the override ends.
  final Map<String, int> restore;

  const TemporaryOverride({this.active = false, this.expiresAt, this.restore = const {}});

  bool isExpired(DateTime now) {
    final int? at = expiresAt;
    return active && at != null && now.toUtc().millisecondsSinceEpoch ~/ 1000 >= at;
  }

  Duration? remaining(DateTime now) {
    final int? at = expiresAt;
    if (!active || at == null) {
      return null;
    }
    final int secondsLeft = at - now.toUtc().millisecondsSinceEpoch ~/ 1000;
    return Duration(seconds: secondsLeft > 0 ? secondsLeft : 0);
  }

  factory TemporaryOverride.fromMap(Map<String, dynamic>? map) {
    if (map == null || map['active'] != true) {
      return const TemporaryOverride();
    }
    final dynamic restore = map['restore'];
    return TemporaryOverride(
      active: true,
      expiresAt: map['expiresAt'] is int ? map['expiresAt'] : null,
      restore: restore is Map
          ? restore.map((key, value) => MapEntry('$key', value is int ? value : int.tryParse('$value') ?? 0))
          : const {},
    );
  }

  Map<String, dynamic> toMap() => {
        'active': active,
        'expiresAt': expiresAt,
        'restore': restore,
      };

  @override
  List<Object?> get props => [active, expiresAt, restore];
}

/// The two overridable controls of a box. Kept as two typed fields (rather
/// than one map keyed by name) so callers get compile-time-checked access
/// instead of a string key to typo.
class BoxOverrides extends Equatable {
  final TemporaryOverride light;
  final TemporaryOverride blower;

  const BoxOverrides({this.light = const TemporaryOverride(), this.blower = const TemporaryOverride()});

  factory BoxOverrides.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const BoxOverrides();
    }
    return BoxOverrides(
      light: TemporaryOverride.fromMap(map['light'] as Map<String, dynamic>?),
      blower: TemporaryOverride.fromMap(map['blower'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() => {
        'light': light.toMap(),
        'blower': blower.toMap(),
      };

  BoxOverrides copyWith({TemporaryOverride? light, TemporaryOverride? blower}) =>
      BoxOverrides(light: light ?? this.light, blower: blower ?? this.blower);

  @override
  List<Object?> get props => [light, blower];
}
