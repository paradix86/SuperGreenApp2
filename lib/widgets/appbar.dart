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

/// App bar of every secondary screen.
///
/// Colors always come from the theme (light or dark) so screens stay
/// coherent; the legacy `titleColor` / `iconColor` / `backgroundColor`
/// parameters are still accepted so old call sites compile, but ignored.
class SGLAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool hideBackButton;
  final double elevation;
  final double? fontSize;
  final Widget? leading;

  SGLAppBar(
    this.title, {
    Key? key,
    this.actions,
    this.hideBackButton = false,
    @Deprecated('Colors come from the theme now') Color? titleColor,
    @Deprecated('Colors come from the theme now') Color? iconColor,
    @Deprecated('Colors come from the theme now') Color? backgroundColor,
    this.elevation = 0,
    this.fontSize,
    this.leading,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final TextStyle? base = Theme.of(context).appBarTheme.titleTextStyle;
    return AppBar(
      automaticallyImplyLeading: !hideBackButton,
      title: Text(
        title,
        style: fontSize != null ? base?.copyWith(fontSize: fontSize) : base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
      elevation: elevation,
      leading: leading,
    );
  }
}
