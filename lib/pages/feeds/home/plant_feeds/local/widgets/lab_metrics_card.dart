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
import 'package:super_green_app/data/api/device/dash_history.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/common/metrics/app_bar_metrics_bloc.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/widgets/sgl/sgl_info.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';
import 'package:super_green_app/widgets/sgl/sparkline.dart';

/// The three readings at the top of the Lab: temperature, humidity and VPD
/// (plus CO2 and weight when the controller has those sensors). Each tile
/// shows the current value, the 3 h min–max and a sparkline fed by
/// [DashHistory].
class LabMetricsCard extends StatelessWidget {
  const LabMetricsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBarMetricsBloc, AppBarMetricsBlocState>(
      builder: (BuildContext context, AppBarMetricsBlocState state) {
        if (state is AppBarMetricsBlocStateNoDevice) {
          return _NoController();
        }
        if (state is AppBarMetricsBlocStateLoaded) {
          return SglCard(flat: true, padding: const EdgeInsets.all(12), child: _tiles(context, state));
        }
        return SglCard(flat: true, padding: const EdgeInsets.all(12), child: _placeholderTiles(context));
      },
    );
  }

  Widget _placeholderTiles(BuildContext context) {
    final SglColors c = context.sgl;
    return Row(
      children: [
        _MetricTile(label: 'temp', value: '–', unit: '', color: c.ink3, samples: const []),
        _MetricTile(label: 'rh', value: '–', unit: '', color: c.ink3, samples: const []),
        _MetricTile(label: 'vpd', value: '–', unit: '', color: c.ink3, samples: const []),
      ],
    );
  }

  Widget _tiles(BuildContext context, AppBarMetricsBlocStateLoaded state) {
    final SglColors c = context.sgl;
    final AppBarMetricsParamsController m = state.metrics;
    final Box box = state.box;
    final int deviceID = box.device!;
    final String prefix = 'BOX_${box.deviceBox}_';
    final bool freedomUnits = AppDB().getUserSettings().freedomUnits ?? false;
    final int version = m.version.ivalue;
    final double vpdScale = version != 0 && version <= 1700000000 ? 10 : 100;

    double toTemp(num v) => freedomUnits ? v * 9 / 5 + 32 : v.toDouble();
    String fmt(double v, {int decimals = 0}) => v.toStringAsFixed(decimals);

    final List<DashSample> temps = DashHistory.samples(deviceID, '${prefix}TEMP', window: DashHistory.sparklineWindow);
    final List<DashSample> humis = DashHistory.samples(deviceID, '${prefix}HUMI', window: DashHistory.sparklineWindow);
    final List<DashSample> vpds = DashHistory.samples(deviceID, '${prefix}VPD', window: DashHistory.sparklineWindow);
    final double vpd = m.vpd.ivalue / vpdScale;

    final List<Widget> tiles = [
      _MetricTile(
        label: 'temp',
        value: fmt(toTemp(m.temp.ivalue)),
        unit: freedomUnits ? '°F' : '°C',
        color: c.accent,
        samples: temps.map((s) => toTemp(s.value)).toList(),
      ),
      _MetricTile(
        label: 'rh',
        value: '${m.humidity.ivalue}',
        unit: '%',
        color: c.info,
        samples: humis.map((s) => s.value.toDouble()).toList(),
      ),
      _MetricTile(
        label: 'vpd',
        value: m.vpd.ivalue == 0 ? 'n/a' : fmt(vpd, decimals: 2),
        unit: m.vpd.ivalue == 0 ? '' : 'kPa',
        color: c.amber,
        samples: vpds.map((s) => s.value / vpdScale).toList(),
        decimals: 2,
      ),
    ];
    if (m.co2.available && m.co2.ivalue != 0) {
      tiles.add(_MetricTile(
        label: 'co2',
        value: '${m.co2.ivalue}',
        unit: 'ppm',
        color: c.ink2,
        samples: DashHistory.samples(deviceID, '${prefix}CO2', window: DashHistory.sparklineWindow).map((s) => s.value.toDouble()).toList(),
      ));
    }
    if (m.weight.available && m.weight.ivalue != 0) {
      final double kg = m.weight.ivalue / 1000.0;
      tiles.add(_MetricTile(
        label: 'weight',
        value: fmt(freedomUnits ? kg * 2.20462 : kg, decimals: 2),
        unit: freedomUnits ? 'lb' : 'kg',
        color: c.ink2,
        samples: DashHistory.samples(deviceID, '${prefix}WEIGHT', window: DashHistory.sparklineWindow).map((s) => s.value / 1000.0).toList(),
        decimals: 2,
      ));
    }
    if (tiles.length <= 3) {
      return Row(children: tiles);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: tiles.map((t) => SizedBox(width: 120, child: t)).toList()),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final List<double> samples;
  final int decimals;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.samples,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    String range = '3h –';
    if (samples.length >= 2) {
      final double min = samples.reduce((a, b) => a < b ? a : b);
      final double max = samples.reduce((a, b) => a > b ? a : b);
      range = '${min.toStringAsFixed(decimals)}–${max.toStringAsFixed(decimals)}';
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              maxLines: 1,
              overflow: TextOverflow.clip,
              text: TextSpan(
                text: value,
                style: SglTextStyles.reading.copyWith(color: c.ink, fontSize: 30),
                children: [
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [SglEyebrow(label), SglInfoButton(label, size: 13)]),
                InkWell(
                  onTap: () => SglInfoButton.show(context, 'range3h'),
                  child: Text(range, style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 10.5)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Sparkline(values: samples, color: color),
          ],
        ),
      ),
    );
  }
}

class _NoController extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return SglCard(
      flat: true,
      child: Row(
        children: [
          Icon(Icons.sensors_off_outlined, color: c.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No controller paired with this box: readings and light control appear once one is added.',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
