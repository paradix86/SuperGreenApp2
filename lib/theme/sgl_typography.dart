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

import 'package:flutter/material.dart';

/// Font families bundled in `assets/fonts` (see pubspec.yaml).
///
/// - display: Bricolage Grotesque, for titles and big readings
/// - body: Instrument Sans, for everything you read
/// - mono: IBM Plex Mono, for sensor values, keys, chips and timestamps
class SglFonts {
  static const String display = 'BricolageGrotesque';
  static const String body = 'InstrumentSans';
  static const String mono = 'IBMPlexMono';
}

/// Text styles that are not part of Material's TextTheme but that the app
/// uses everywhere: monospaced readings and uppercase eyebrows.
class SglTextStyles {
  /// Big sensor reading (temperature, humidity, VPD...).
  static const TextStyle reading = TextStyle(
    fontFamily: SglFonts.display,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.7,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Small monospaced value: chips, timestamps, parameter keys.
  static const TextStyle mono = TextStyle(
    fontFamily: SglFonts.mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Uppercase section eyebrow, always paired with `ink3`.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: SglFonts.mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.4,
  );

  /// Material text theme built on the three families. Colors are applied by
  /// ThemeData through `ColorScheme.onSurface`, not here.
  static TextTheme textTheme() {
    const display = SglFonts.display;
    const body = SglFonts.body;
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: display, fontSize: 48, fontWeight: FontWeight.w700, height: 1.05, letterSpacing: -1),
      displayMedium: TextStyle(fontFamily: display, fontSize: 40, fontWeight: FontWeight.w700, height: 1.05, letterSpacing: -0.8),
      displaySmall: TextStyle(fontFamily: display, fontSize: 32, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.5),
      headlineLarge: TextStyle(fontFamily: display, fontSize: 28, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.4),
      headlineMedium: TextStyle(fontFamily: display, fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontFamily: display, fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.2),
      titleLarge: TextStyle(fontFamily: display, fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.2),
      titleMedium: TextStyle(fontFamily: body, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(fontFamily: body, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
      bodyLarge: TextStyle(fontFamily: body, fontSize: 16, fontWeight: FontWeight.w400, height: 1.45),
      bodyMedium: TextStyle(fontFamily: body, fontSize: 15, fontWeight: FontWeight.w400, height: 1.45),
      bodySmall: TextStyle(fontFamily: body, fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: TextStyle(fontFamily: body, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
      labelMedium: TextStyle(fontFamily: body, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
      labelSmall: TextStyle(fontFamily: body, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.3),
    );
  }
}
