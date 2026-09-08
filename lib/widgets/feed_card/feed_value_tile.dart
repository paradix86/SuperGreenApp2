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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_theme.dart';
import 'package:super_green_app/theme/sgl_typography.dart';

/// Horizontal strip of tiles inside a feed card. Sizes itself to the
/// tallest tile, so no fixed heights and no overflow when fonts change.
class FeedTileStrip extends StatelessWidget {
  final List<Widget> tiles;

  const FeedTileStrip({Key? key, required this.tiles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              tiles[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One tile: eyebrow label (with optional icon), a big reading and an
/// optional detail line. Used by the watering, nutrient and ventilation
/// cards.
class FeedValueTile extends StatelessWidget {
  final String label;
  final String? icon;
  final String value;
  final String? detail;
  final Color? valueColor;
  final double width;

  const FeedValueTile({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
    this.detail,
    this.valueColor,
    this.width = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(SglTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: icon!.endsWith('svg')
                      ? SvgPicture.asset(icon!, colorFilter: ColorFilter.mode(c.ink3, BlendMode.srcIn))
                      : Image.asset(icon!),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.replaceAll('\n', ' ').toUpperCase(),
                  style: SglTextStyles.eyebrow.copyWith(color: c.ink3, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: SglTextStyles.reading.copyWith(fontSize: 26, color: valueColor ?? c.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(detail!, style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 12), maxLines: 2),
          ],
        ],
      ),
    );
  }
}

/// "before → after" tile for the light and legacy ventilation cards.
class FeedChangeTile extends StatelessWidget {
  final String label;
  final String from;
  final String to;

  const FeedChangeTile({Key? key, required this.label, required this.from, required this.to}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return Container(
      width: 150,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(SglTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: SglTextStyles.eyebrow.copyWith(color: c.ink3, fontSize: 10)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(from, style: SglTextStyles.reading.copyWith(fontSize: 20, color: c.ink3)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 14, color: c.ink3),
              ),
              Text(to, style: SglTextStyles.reading.copyWith(fontSize: 26, color: c.accentDeep)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single big statement in a card ("Flipped to BLOOM", "Vegging started").
class FeedStatement extends StatelessWidget {
  final String text;

  const FeedStatement(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Text(
        text.replaceAll('\n', ' '),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: context.sgl.accentDeep),
      ),
    );
  }
}
