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
import 'package:super_green_app/theme/sgl_theme.dart';
import 'package:super_green_app/theme/sgl_typography.dart';

/// Surface with a hairline border: the basic block of every redesigned
/// screen. `flat` uses the secondary surface (for the metrics strip).
class SglCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool flat;
  final VoidCallback? onTap;

  const SglCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.flat = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final BorderRadius radius = BorderRadius.circular(SglTheme.radiusLarge);
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = InkWell(onTap: onTap, borderRadius: radius, child: body);
    }
    return Material(
      color: flat ? c.surface2 : c.surface,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

/// Meaning of a [SglStatusChip], mapped to the semantic colors.
enum SglStatus { ok, warn, crit, info, off }

/// Small monospaced chip with a status dot: "live", "2 due", "offline"...
class SglStatusChip extends StatelessWidget {
  final String label;
  final SglStatus status;

  const SglStatusChip({Key? key, required this.label, this.status = SglStatus.ok}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final Color dot;
    final Color bg;
    final Color fg;
    switch (status) {
      case SglStatus.ok:
        dot = c.accent;
        bg = c.accentSoft;
        fg = c.accentDeep;
        break;
      case SglStatus.warn:
        dot = c.warn;
        bg = c.amberSoft;
        fg = c.amberInk;
        break;
      case SglStatus.crit:
        dot = c.crit;
        bg = c.critSoft;
        fg = c.crit;
        break;
      case SglStatus.info:
        dot = c.info;
        bg = c.infoSoft;
        fg = c.info;
        break;
      case SglStatus.off:
        dot = c.ink3;
        bg = c.bg2;
        fg = c.ink2;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: SglTextStyles.mono.copyWith(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Uppercase monospaced section label.
class SglEyebrow extends StatelessWidget {
  final String text;

  const SglEyebrow(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: SglTextStyles.eyebrow.copyWith(color: context.sgl.ink3));
  }
}

/// Card header: title on the left, optional trailing widget on the right.
class SglCardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SglCardHeader({Key? key, required this.title, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
