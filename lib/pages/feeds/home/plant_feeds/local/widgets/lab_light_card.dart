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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/data/api/device/device_params.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/controls/box_controls_bloc.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';

/// "What the light is doing right now": on/off state, the schedule window,
/// average dimming and a progress bar through the current phase of the
/// cycle. Tapping opens the full box controls.
class LabLightCard extends StatelessWidget {
  final VoidCallback? onOpenControls;

  const LabLightCard({Key? key, this.onOpenControls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoxControlsBloc, BoxControlsBlocState>(
      builder: (BuildContext context, BoxControlsBlocState state) {
        if (state is! BoxControlsBlocStateLoaded) {
          return const SizedBox.shrink();
        }
        return _LightSchedule(state: state, onOpenControls: onOpenControls);
      },
    );
  }
}

class _LightSchedule extends StatelessWidget {
  final BoxControlsBlocStateLoaded state;
  final VoidCallback? onOpenControls;

  const _LightSchedule({required this.state, this.onOpenControls});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final BoxControlParamsController m = state.metrics;
    final int onMinutes = m.onHour.ivalue * 60 + m.onMin.ivalue;
    final int offMinutes = m.offHour.ivalue * 60 + m.offMin.ivalue;
    final DateTime now = DateTime.now();
    final int nowMinutes = now.hour * 60 + now.minute;
    final bool isOn = m.light.ivalue > 0;
    final int dim = _averageDim(m.lightsDimming);

    // Minutes since the phase started and its total length, both modulo a day
    // so schedules crossing midnight (e.g. 20:00 -> 08:00) work too.
    final int phaseStart = isOn ? onMinutes : offMinutes;
    final int phaseEnd = isOn ? offMinutes : onMinutes;
    final int length = ((phaseEnd - phaseStart) % 1440 + 1440) % 1440;
    final int elapsed = ((nowMinutes - phaseStart) % 1440 + 1440) % 1440;
    final double progress = length == 0 ? 0 : (elapsed / length).clamp(0.0, 1.0);

    final String headline = isOn ? 'Lights on · off at ${_hhmm(offMinutes)}' : 'Lights off · on at ${_hhmm(onMinutes)}';
    final String detail = '${_hhmm(onMinutes)} → ${_hhmm(offMinutes)}'
        '${m.lightsDimming.isEmpty ? '' : ' · LED $dim %'}'
        '${m.blower.available ? ' · blower ${m.blower.ivalue} %' : ''}';

    return SglCard(
      onTap: onOpenControls,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOn ? c.amberSoft : c.bg2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isOn ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                    color: isOn ? c.amber : c.ink3, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(detail, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.ink2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.ink3),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: isOn ? c.amber : c.ink3,
              backgroundColor: c.bg2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_hhmm(phaseStart), style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 11)),
              Text('now ${_hhmm(nowMinutes)}', style: SglTextStyles.mono.copyWith(color: c.ink2, fontSize: 11)),
              Text(_hhmm(phaseEnd), style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  static int _averageDim(List<ParamController> dims) {
    if (dims.isEmpty) {
      return 0;
    }
    return dims.fold<int>(0, (sum, d) => sum + d.ivalue) ~/ dims.length;
  }

  static String _hhmm(int minutes) {
    final int m = ((minutes % 1440) + 1440) % 1440;
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }
}
