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

class FeedFormButton extends StatelessWidget {
  final String title;
  final Icon? icon;
  final bool border;
  final TextStyle? textStyle;
  final void Function()? onPressed;

  const FeedFormButton({required this.title, this.border = false, this.onPressed, this.textStyle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.sgl.surface2,
        border: Border.all(color: border ? context.sgl.accent : context.sgl.line, width: border ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        style: ButtonStyle(
          overlayColor: MaterialStateColor.resolveWith((states) => context.sgl.accentSoft),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: this.icon != null ? 8.0 : 0.0),
              child: this.icon ?? Container(),
            ),
            Text(
              title,
              style: this.textStyle ?? TextStyle(color: context.sgl.ink, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
