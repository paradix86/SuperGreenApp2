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

import 'package:flutter/material.dart';
import 'package:super_green_app/theme/sgl_colors.dart';

/// Destructive action button (delete, unpair...). Uses the theme's `crit`
/// color; the legacy `color` parameter is ignored.
class RedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final double? fontSize;

  const RedButton({
    Key? key,
    required this.title,
    this.onPressed,
    @Deprecated('Colors come from the theme now') int? color,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextStyle? base = Theme.of(context).filledButtonTheme.style?.textStyle?.resolve({});
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: c.crit,
        foregroundColor: Colors.white,
        textStyle: fontSize != null ? base?.copyWith(fontSize: fontSize) : null,
      ),
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
