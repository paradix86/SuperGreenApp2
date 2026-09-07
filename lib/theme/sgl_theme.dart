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
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';

/// Material 3 theme of the app, derived entirely from [SglColors] and
/// [SglTextStyles]. Use `SglTheme.light()` / `SglTheme.dark()` in
/// MaterialApp and let `themeMode: ThemeMode.system` pick one.
class SglTheme {
  static const double radiusSmall = 8;
  static const double radius = 12;
  static const double radiusLarge = 16;

  static ThemeData light() => _build(SglColors.light, Brightness.light);

  static ThemeData dark() => _build(SglColors.dark, Brightness.dark);

  static ThemeData _build(SglColors c, Brightness brightness) {
    final ColorScheme scheme = _colorScheme(c, brightness);
    final TextTheme text = SglTextStyles.textTheme().apply(bodyColor: c.ink, displayColor: c.ink);
    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
      side: BorderSide(color: c.line),
    );
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.line2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      fontFamily: SglFonts.body,
      textTheme: text,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.ink),
        actionsIconTheme: IconThemeData(color: c.ink2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accentSoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? c.accentDeep : c.ink3, size: 24),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(color: states.contains(WidgetState.selected) ? c.ink : c.ink3),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentInk,
          disabledBackgroundColor: c.bg2,
          disabledForegroundColor: c.ink3,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentInk,
          disabledBackgroundColor: c.bg2,
          disabledForegroundColor: c.ink3,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line2),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentDeep,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.ink2),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.accentInk,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: text.bodyMedium!.copyWith(color: c.ink3),
        labelStyle: text.bodyMedium!.copyWith(color: c.ink2),
        errorStyle: text.bodySmall!.copyWith(color: c.crit),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.line)),
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.crit)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.crit, width: 1.5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accentInk : c.ink3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.bg2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : c.line2,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.bg2,
        thumbColor: c.accent,
        overlayColor: c.accent.withValues(alpha: 0.12),
        valueIndicatorColor: c.ink,
        valueIndicatorTextStyle: SglTextStyles.mono.copyWith(color: c.bg),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(c.accentInk),
        side: BorderSide(color: c.line2, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.line2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface2,
        selectedColor: c.accentSoft,
        disabledColor: c.bg2,
        side: BorderSide(color: c.line),
        labelStyle: SglTextStyles.mono.copyWith(color: c.ink2),
        secondaryLabelStyle: SglTextStyles.mono.copyWith(color: c.accentDeep),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink2,
        textColor: c.ink,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall!.copyWith(color: c.ink2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.ink2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.line2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge + 4)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.bg),
        actionTextColor: brightness == Brightness.light ? c.amber : c.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.ink,
        unselectedLabelColor: c.ink3,
        indicatorColor: c.accent,
        dividerColor: c.line,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.bg2,
        circularTrackColor: c.bg2,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: c.line)),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(radiusSmall)),
        textStyle: text.bodySmall!.copyWith(color: c.bg),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ColorScheme _colorScheme(SglColors c, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.accentInk,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accentDeep,
      secondary: c.amber,
      onSecondary: c.amberInk,
      secondaryContainer: c.amberSoft,
      onSecondaryContainer: c.amberInk,
      tertiary: c.info,
      onTertiary: c.surface,
      tertiaryContainer: c.infoSoft,
      onTertiaryContainer: c.info,
      error: c.crit,
      onError: c.surface,
      errorContainer: c.critSoft,
      onErrorContainer: c.crit,
      surface: c.bg,
      onSurface: c.ink,
      onSurfaceVariant: c.ink2,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface2,
      surfaceContainerHigh: c.bg2,
      surfaceContainerHighest: c.bg2,
      outline: c.line2,
      outlineVariant: c.line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.ink,
      onInverseSurface: c.bg,
      inversePrimary: c.accentDeep,
    );
  }
}
