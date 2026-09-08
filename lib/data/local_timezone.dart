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

import 'package:flutter/services.dart';

/// The phone's time zone as the POSIX TZ string the controller's TIME_TZ
/// expects (newlib `tzset`), e.g. `CET-1CEST,M3.5.0,M10.5.0/3`.
class LocalTimezone {
  static const MethodChannel _channel = MethodChannel('supergreenlab/timezone');

  /// Suggested TIME_TZ and a short label of where it came from.
  static Future<TimezoneSuggestion> suggest() async {
    final String? iana = await ianaName();
    final String? known = iana == null ? null : posixFor(iana);
    if (known != null) {
      return TimezoneSuggestion(known, iana!, withDst: known.contains(','));
    }
    final DateTime now = DateTime.now();
    return TimezoneSuggestion(posixFromOffset(now.timeZoneOffset, now.timeZoneName), iana ?? now.timeZoneName,
        withDst: false);
  }

  /// IANA id from the platform (Android only); null elsewhere or on failure.
  static Future<String?> ianaName() async {
    try {
      return await _channel.invokeMethod<String>('id');
    } catch (e) {
      return null;
    }
  }

  /// Fixed-offset TZ: POSIX offsets are west-positive, so UTC+2 is `-2`.
  /// [abbr] must be 3-6 letters; anything else becomes the `<+02>-2` form.
  static String posixFromOffset(Duration offset, String abbr) {
    final int minutes = offset.inMinutes;
    final int h = minutes.abs() ~/ 60;
    final int m = minutes.abs() % 60;
    final String sign = minutes > 0 ? '-' : (minutes < 0 ? '+' : '');
    final String num = m == 0 ? '$h' : '$h:${m.toString().padLeft(2, '0')}';
    final bool alpha = RegExp(r'^[A-Za-z]{3,6}$').hasMatch(abbr);
    final String name = alpha
        ? abbr
        : '<${minutes >= 0 ? '+' : '-'}${h.toString().padLeft(2, '0')}${m == 0 ? '' : m.toString().padLeft(2, '0')}>';
    if (minutes == 0) {
      return '${name}0';
    }
    return '$name$sign$num';
  }

  static const String _cet = 'CET-1CEST,M3.5.0,M10.5.0/3';
  static const String _eet = 'EET-2EEST,M3.5.0/3,M10.5.0/4';
  static const String _wet = 'WET0WEST,M3.5.0/1,M10.5.0';

  static const Map<String, String> _exact = {
    'Europe/London': 'GMT0BST,M3.5.0/1,M10.5.0',
    'Europe/Dublin': 'IST-1GMT0,M10.5.0,M3.5.0/1',
    'Europe/Lisbon': _wet,
    'Atlantic/Canary': _wet,
    'Europe/Athens': _eet,
    'Europe/Helsinki': _eet,
    'Europe/Kiev': _eet,
    'Europe/Kyiv': _eet,
    'Europe/Bucharest': _eet,
    'Europe/Sofia': _eet,
    'Europe/Riga': _eet,
    'Europe/Tallinn': _eet,
    'Europe/Vilnius': _eet,
    'Europe/Chisinau': _eet,
    'Europe/Moscow': 'MSK-3',
    'Europe/Istanbul': '<+03>-3',
    'Europe/Minsk': '<+03>-3',
    'America/New_York': 'EST5EDT,M3.2.0,M11.1.0',
    'America/Toronto': 'EST5EDT,M3.2.0,M11.1.0',
    'America/Detroit': 'EST5EDT,M3.2.0,M11.1.0',
    'America/Chicago': 'CST6CDT,M3.2.0,M11.1.0',
    'America/Winnipeg': 'CST6CDT,M3.2.0,M11.1.0',
    'America/Denver': 'MST7MDT,M3.2.0,M11.1.0',
    'America/Edmonton': 'MST7MDT,M3.2.0,M11.1.0',
    'America/Phoenix': 'MST7',
    'America/Los_Angeles': 'PST8PDT,M3.2.0,M11.1.0',
    'America/Vancouver': 'PST8PDT,M3.2.0,M11.1.0',
    'America/Anchorage': 'AKST9AKDT,M3.2.0,M11.1.0',
    'Pacific/Honolulu': 'HST10',
    'America/Mexico_City': 'CST6',
    'America/Sao_Paulo': '<-03>3',
    'America/Argentina/Buenos_Aires': '<-03>3',
    'America/Bogota': '<-05>5',
    'America/Lima': '<-05>5',
    'America/Santiago': '<-04>4<-03>,M9.1.6/24,M4.1.6/24',
    'Africa/Johannesburg': 'SAST-2',
    'Africa/Cairo': 'EET-2EEST,M4.5.5/0,M10.5.4/24',
    'Africa/Lagos': 'WAT-1',
    'Africa/Nairobi': 'EAT-3',
    'Asia/Dubai': '<+04>-4',
    'Asia/Kolkata': 'IST-5:30',
    'Asia/Bangkok': '<+07>-7',
    'Asia/Jakarta': 'WIB-7',
    'Asia/Shanghai': 'CST-8',
    'Asia/Hong_Kong': 'HKT-8',
    'Asia/Singapore': '<+08>-8',
    'Asia/Manila': 'PST-8',
    'Asia/Tokyo': 'JST-9',
    'Asia/Seoul': 'KST-9',
    'Australia/Perth': 'AWST-8',
    'Australia/Brisbane': 'AEST-10',
    'Australia/Sydney': 'AEST-10AEDT,M10.1.0,M4.1.0/3',
    'Australia/Melbourne': 'AEST-10AEDT,M10.1.0,M4.1.0/3',
    'Australia/Adelaide': 'ACST-9:30ACDT,M10.1.0,M4.1.0/3',
    'Pacific/Auckland': 'NZST-12NZDT,M9.5.0,M4.1.0/3',
    'Etc/UTC': 'UTC0',
    'UTC': 'UTC0',
  };

  /// POSIX string for an IANA id, null when unknown.
  static String? posixFor(String iana) {
    final String? exact = _exact[iana];
    if (exact != null) {
      return exact;
    }
    // Every other Europe/* zone in the tz database is CET/CEST.
    if (iana.startsWith('Europe/')) {
      return _cet;
    }
    return null;
  }
}

class TimezoneSuggestion {
  final String posix;
  final String label;
  final bool withDst;

  const TimezoneSuggestion(this.posix, this.label, {required this.withDst});
}
