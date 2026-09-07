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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';

class FeedCardTitle extends StatelessWidget {
  final String icon;
  final String title;
  final String? title2;
  final bool synced;
  final Function()? onEdit;
  final Function()? onDelete;
  final Function()? onShare;
  final bool showSyncStatus;
  final bool showControls;
  final List<Widget>? actions;

  const FeedCardTitle(this.icon, this.title, this.synced,
      {this.onEdit,
      this.title2,
      this.onDelete,
      this.onShare,
      this.showSyncStatus = true,
      this.showControls = true,
      this.actions});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme text = Theme.of(context).textTheme;
    List<Widget> content = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
          child: icon.endsWith('svg') ? SvgPicture.asset(icon) : Image.asset(icon),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              title2 != null
                  ? AutoSizeText(title2!, maxLines: 1, style: text.bodySmall!.copyWith(color: c.accentDeep, fontWeight: FontWeight.w600))
                  : Container(),
              showSyncStatus && !synced
                  ? Text('Not synced', style: SglTextStyles.mono.copyWith(color: c.warn, fontSize: 11))
                  : Container(),
            ],
          ),
        ),
      ),
    ];
    if (onShare != null && showControls) {
      content.add(IconButton(icon: Icon(Icons.share_outlined, size: 20), onPressed: onShare));
    }
    if (onEdit != null && showControls) {
      content.add(IconButton(icon: Icon(Icons.edit_outlined, size: 20), onPressed: onEdit));
    }
    if (onDelete != null && showControls) {
      content.add(IconButton(
        icon: Icon(Icons.delete_outline, size: 20),
        onPressed: () {
          _deleteFeedEntry(context);
        },
      ));
    }
    content.addAll(actions ?? []);
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 4, top: 3.0, bottom: 3.0),
      child: Row(
        children: content,
      ),
    );
  }

  Future _deleteFeedEntry(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete this card?'),
            content: Text('This can\'t be reverted. Continue?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text('NO'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text('YES'),
              ),
            ],
          );
        });
    if (confirm ?? false) {
      onDelete!();
    }
  }
}
