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

/// Primary action button. Styling comes from the theme's FilledButton; the
/// legacy `color` parameter (an ARGB int) is still honoured when a call site
/// passes one explicitly.
class GreenButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final int? color;
  final double? fontSize;

  const GreenButton({Key? key, required this.title, this.onPressed, this.color, this.fontSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ButtonStyle? style;
    if (color != null || fontSize != null) {
      final TextStyle? base = Theme.of(context).filledButtonTheme.style?.textStyle?.resolve({});
      style = FilledButton.styleFrom(
        backgroundColor: color != null ? Color(color!) : null,
        foregroundColor: color != null ? Colors.white : null,
        textStyle: fontSize != null ? base?.copyWith(fontSize: fontSize) : null,
      );
    }
    return FilledButton(
      style: style,
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
