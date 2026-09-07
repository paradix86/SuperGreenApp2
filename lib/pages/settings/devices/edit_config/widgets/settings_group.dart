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
import 'package:super_green_app/widgets/sgl/sgl_card.dart';

/// Eyebrow title + one card holding a list of [SettingsRow], separated by
/// hairlines. The subtitle of each row states the current value, so the
/// screen reads as a status sheet and not as a menu.
class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const SettingsGroup({Key? key, required this.title, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Divider(height: 1, thickness: 1, indent: 56, color: c.line));
      }
      children.add(rows[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: SglEyebrow(title),
          ),
          SglCard(
            padding: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// One row: icon tile, title, one-line status subtitle, optional trailing
/// widget (defaults to a chevron when tappable).
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;
  final Color? subtitleColor;

  const SettingsRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.subtitleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(SglTheme.radiusSmall),
              ),
              child: Icon(icon, size: 19, color: iconColor ?? c.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleSmall?.copyWith(color: titleColor ?? c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: SglTextStyles.mono.copyWith(color: subtitleColor ?? c.ink3, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ?? (onTap == null ? const SizedBox() : Icon(Icons.chevron_right, color: c.ink3)),
          ],
        ),
      ),
    );
  }
}

/// Small monospaced verb on the right of a row: "copy", "edit", "check".
class SettingsRowAction extends StatelessWidget {
  final String label;

  const SettingsRowAction(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: SglTextStyles.mono.copyWith(color: context.sgl.accentDeep, fontSize: 12));
  }
}

/// On/off state chip for rows that toggle something on another screen.
class SettingsRowChip extends StatelessWidget {
  final String label;
  final bool on;

  const SettingsRowChip(this.label, {Key? key, required this.on}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SglStatusChip(label: label, status: on ? SglStatus.ok : SglStatus.off);
  }
}
