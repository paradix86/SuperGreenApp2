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
import 'package:super_green_app/theme/sgl_theme.dart';

class FeedCard extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;

  const FeedCard({Key? key, required this.child, required this.animation}) : super(key: key);

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> with AutomaticKeepAliveClientMixin {
  double _opacity = 0;

  @override
  void initState() {
    if (widget.animation.status == AnimationStatus.completed) {
      _opacity = 1;
    } else {
      widget.animation.addStatusListener(_statusListener);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: _opacity,
        child: SizeTransition(
          axis: Axis.vertical,
          sizeFactor: widget.animation,
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: context.sgl.line, width: 1),
                  color: context.sgl.surface,
                  borderRadius: BorderRadius.circular(SglTheme.radiusLarge)),
              clipBehavior: Clip.antiAlias,
              child: widget.child),
        ),
      ),
    );
  }

  void _statusListener(status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _opacity = 1;
      });
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_statusListener);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
