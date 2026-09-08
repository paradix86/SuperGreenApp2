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
import 'dart:math' as math;
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/feed_form/feed_form_param_layout.dart';

class SliderFormParam extends StatelessWidget {
  final double value;
  final void Function(String)? onTitleEdited;
  final void Function(double)? onChangeStart;  // Add this line
  final void Function(double) onChanged;
  final void Function(double) onChangeEnd;
  final String title;
  final bool boldTitle;
  final String icon;
  final Color color;
  final double min;
  final double max;
  final bool? loading;
  final bool? disable;

  const SliderFormParam({
    Key? key,
    required this.title,
    required this.icon,
    required this.value,
    this.onTitleEdited,
    this.onChangeStart,  // Add this line
    required this.onChanged,
    required this.onChangeEnd,
    required this.color,
    this.min = 0,
    this.max = 100,
    this.loading,
    this.disable,
    this.boldTitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FeedFormParamLayout(
      onTitleEdited: onTitleEdited,
      title: title,
      boldTitle: boldTitle,
      icon: icon,
      child: Column(
        children: <Widget>[
          Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                onPressed: disable == true
                    ? null
                    : () {
                        double newValue = math.max(min, value - 1);
                        if (onChangeStart != null) onChangeStart!(newValue);
                        onChanged(newValue);
                        onChangeEnd(newValue);
                      },
                child: Icon(Icons.remove, color: context.sgl.ink2),
              ),
              Text('${value.round()}%', style: SglTextStyles.reading.copyWith(fontSize: 28, color: context.sgl.ink)),
              TextButton(
                onPressed: disable == true
                    ? null
                    : () {
                        double newValue = math.min(max, value + 1);
                        if (onChangeStart != null) onChangeStart!(newValue);
                        onChanged(newValue);
                        onChangeEnd(newValue);
                      },
                child: Icon(Icons.add, color: context.sgl.ink2),
              ),
              loading == true
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(context.sgl.accent),
                      ),
                    )
                  : Container(),
            ],
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('0%', style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 12)),
                Expanded(
                  child: Slider(
                    min: min,
                    max: max,
                    onChangeStart: disable == true ? null : onChangeStart,  // Add this line
                    onChangeEnd: disable == true ? null : onChangeEnd,
                    value: value,
                    activeColor: color,
                    onChanged: disable == true ? null : onChanged,
                  ),
                ),
                Text('100%', style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
