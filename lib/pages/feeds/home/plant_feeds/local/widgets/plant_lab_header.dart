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
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/common/metrics/app_bar_metrics_bloc.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/controls/box_controls_bloc.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/app_bar/checklist/appbar_checklist_bloc.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/widgets/lab_checklist_card.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/widgets/lab_light_card.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/widgets/lab_metrics_card.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/widgets/lab_panels_row.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';

/// Everything above the diary in the Lab: readings, light, checklist and
/// the buttons to the secondary panels. Replaces the 5-page dotted carousel.
class PlantLabHeader extends StatelessWidget {
  final Plant plant;
  final Box box;
  final List<LabPanel> panels;

  /// Panel to open when the light card is tapped (the box controls).
  final LabPanel? controlsPanel;

  const PlantLabHeader({
    Key? key,
    required this.plant,
    required this.box,
    required this.panels,
    this.controlsPanel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBarMetricsBloc>(create: (context) => AppBarMetricsBloc(box)),
        BlocProvider<BoxControlsBloc>(create: (context) => BoxControlsBloc(plant, box)),
        BlocProvider<AppbarChecklistBloc>(create: (context) => AppbarChecklistBloc(plant, box)),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LabMetricsCard(),
            const SizedBox(height: 10),
            Builder(
              builder: (context) => LabLightCard(
                onOpenControls: controlsPanel == null ? null : () => LabPanelsRow.open(context, controlsPanel!),
              ),
            ),
            const SizedBox(height: 10),
            const LabChecklistCard(),
            const SizedBox(height: 10),
            LabPanelsRow(panels: panels),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: SglEyebrow('Diary'),
            ),
          ],
        ),
      ),
    );
  }
}
