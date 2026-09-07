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

/// Design tokens of the "greenhouse instrument" visual system.
///
/// Every color the UI needs comes from here (through `context.sgl`) so that
/// light and dark mode stay consistent and no screen hardcodes a hex value.
/// Semantic colors (amber = light/timer, crit, info) are separate from the
/// accent on purpose: the accent means "SuperGreenLab / action", not state.
@immutable
class SglColors extends ThemeExtension<SglColors> {
  final Color bg;
  final Color bg2;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color line2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color accentDeep;
  final Color amber;
  final Color amberSoft;
  final Color amberInk;
  final Color warn;
  final Color crit;
  final Color critSoft;
  final Color info;
  final Color infoSoft;

  const SglColors({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.line2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.accentDeep,
    required this.amber,
    required this.amberSoft,
    required this.amberInk,
    required this.warn,
    required this.crit,
    required this.critSoft,
    required this.info,
    required this.infoSoft,
  });

  static const SglColors light = SglColors(
    bg: Color(0xFFF3F5EF),
    bg2: Color(0xFFE9EDE3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F9F3),
    line: Color(0xFFD6DCCF),
    line2: Color(0xFFC3CBB9),
    ink: Color(0xFF16201A),
    ink2: Color(0xFF4A574E),
    ink3: Color(0xFF7B877E),
    accent: Color(0xFF2E9E0A),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE2F3D8),
    accentDeep: Color(0xFF1F6E08),
    amber: Color(0xFFE0A32B),
    amberSoft: Color(0xFFFBEFD2),
    amberInk: Color(0xFF6B4A05),
    warn: Color(0xFFC98A12),
    crit: Color(0xFFC4533F),
    critSoft: Color(0xFFF7E0DB),
    info: Color(0xFF2F6F9F),
    infoSoft: Color(0xFFDCE9F3),
  );

  static const SglColors dark = SglColors(
    bg: Color(0xFF0F1512),
    bg2: Color(0xFF141C17),
    surface: Color(0xFF182119),
    surface2: Color(0xFF1F2A22),
    line: Color(0xFF2A362D),
    line2: Color(0xFF37463B),
    ink: Color(0xFFEAF0E6),
    ink2: Color(0xFFAEBBAF),
    ink3: Color(0xFF77857A),
    accent: Color(0xFF5BD22A),
    accentInk: Color(0xFF0B1A05),
    accentSoft: Color(0xFF1E3316),
    accentDeep: Color(0xFF8FE86A),
    amber: Color(0xFFF0B848),
    amberSoft: Color(0xFF3A2C0F),
    amberInk: Color(0xFFF5D28A),
    warn: Color(0xFFE5AE3A),
    crit: Color(0xFFE2705C),
    critSoft: Color(0xFF3E1F1A),
    info: Color(0xFF6FAEDC),
    infoSoft: Color(0xFF173042),
  );

  static SglColors of(BuildContext context) => Theme.of(context).extension<SglColors>() ?? SglColors.light;

  @override
  SglColors copyWith({
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? line2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? accentDeep,
    Color? amber,
    Color? amberSoft,
    Color? amberInk,
    Color? warn,
    Color? crit,
    Color? critSoft,
    Color? info,
    Color? infoSoft,
  }) {
    return SglColors(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      accentDeep: accentDeep ?? this.accentDeep,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      amberInk: amberInk ?? this.amberInk,
      warn: warn ?? this.warn,
      crit: crit ?? this.crit,
      critSoft: critSoft ?? this.critSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
    );
  }

  @override
  SglColors lerp(ThemeExtension<SglColors>? other, double t) {
    if (other is! SglColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SglColors(
      bg: mix(bg, other.bg),
      bg2: mix(bg2, other.bg2),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      line: mix(line, other.line),
      line2: mix(line2, other.line2),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      accent: mix(accent, other.accent),
      accentInk: mix(accentInk, other.accentInk),
      accentSoft: mix(accentSoft, other.accentSoft),
      accentDeep: mix(accentDeep, other.accentDeep),
      amber: mix(amber, other.amber),
      amberSoft: mix(amberSoft, other.amberSoft),
      amberInk: mix(amberInk, other.amberInk),
      warn: mix(warn, other.warn),
      crit: mix(crit, other.crit),
      critSoft: mix(critSoft, other.critSoft),
      info: mix(info, other.info),
      infoSoft: mix(infoSoft, other.infoSoft),
    );
  }
}

extension SglColorsContext on BuildContext {
  /// Shortcut for the current theme's design tokens.
  SglColors get sgl => SglColors.of(this);
}
