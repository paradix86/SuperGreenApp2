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

/// 24 h bar: the light "on" window in amber over a night-coloured track,
/// with a thin marker at the current time. Handles windows that cross
/// midnight (e.g. 20:00 -> 08:00).
class ScheduleTimeline extends StatelessWidget {
  final int onMinutes;
  final int offMinutes;
  final int nowMinutes;
  final double height;

  const ScheduleTimeline({
    Key? key,
    required this.onMinutes,
    required this.offMinutes,
    required this.nowMinutes,
    this.height = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelinePainter(
          onMinutes: onMinutes,
          offMinutes: offMinutes,
          nowMinutes: nowMinutes,
          track: c.bg2,
          day: c.amber,
          marker: c.ink,
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  static const int minutesPerDay = 24 * 60;

  final int onMinutes;
  final int offMinutes;
  final int nowMinutes;
  final Color track;
  final Color day;
  final Color marker;

  _TimelinePainter({
    required this.onMinutes,
    required this.offMinutes,
    required this.nowMinutes,
    required this.track,
    required this.day,
    required this.marker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect bar = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.save();
    canvas.clipRRect(bar);
    canvas.drawRect(Offset.zero & size, Paint()..color = track);

    final Paint on = Paint()..color = day;
    final int start = ((onMinutes % minutesPerDay) + minutesPerDay) % minutesPerDay;
    final int end = ((offMinutes % minutesPerDay) + minutesPerDay) % minutesPerDay;
    double x(int minutes) => size.width * minutes / minutesPerDay;
    if (start == end) {
      // 24 h on (or a degenerate schedule): light the whole bar.
      canvas.drawRect(Offset.zero & size, on);
    } else if (start < end) {
      canvas.drawRect(Rect.fromLTRB(x(start), 0, x(end), size.height), on);
    } else {
      canvas.drawRect(Rect.fromLTRB(x(start), 0, size.width, size.height), on);
      canvas.drawRect(Rect.fromLTRB(0, 0, x(end), size.height), on);
    }
    canvas.restore();

    final double nowX = x(((nowMinutes % minutesPerDay) + minutesPerDay) % minutesPerDay);
    canvas.drawRect(
      Rect.fromLTWH(nowX - 1, -1, 2, size.height + 2),
      Paint()..color = marker,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.onMinutes != onMinutes ||
      old.offMinutes != offMinutes ||
      old.nowMinutes != nowMinutes ||
      old.track != track ||
      old.day != day ||
      old.marker != marker;
}
