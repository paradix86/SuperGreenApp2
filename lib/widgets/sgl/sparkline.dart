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

/// Tiny line chart without axes: a faint area fill, the line and an
/// emphasized last point. Draws a flat baseline when fewer than two values
/// are available so the tile keeps its height.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const Sparkline({Key? key, required this.values, required this.color, this.height = 22}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(values, color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (values.length < 2) {
      final double y = size.height * 0.6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line..color = color.withValues(alpha: 0.35));
      return;
    }

    double min = values.first;
    double max = values.first;
    for (final double v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    // Keep a flat series in the middle instead of glued to the top edge.
    final double span = (max - min) == 0 ? 1 : (max - min);
    final double top = 2;
    final double bottom = size.height - 2;

    Offset pointAt(int i) {
      final double x = size.width * i / (values.length - 1);
      final double y = bottom - (values[i] - min) / span * (bottom - top);
      return Offset(x, y);
    }

    final Path path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final Path area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.10));
    canvas.drawPath(path, line);
    canvas.drawCircle(pointAt(values.length - 1), 2.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}
