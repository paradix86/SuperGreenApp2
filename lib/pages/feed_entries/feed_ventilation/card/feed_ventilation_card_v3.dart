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
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/assets/feed_entry.dart';
import 'package:super_green_app/pages/feed_entries/feed_ventilation/card/feed_ventilation_card_page.dart';
import 'package:super_green_app/pages/feed_entries/feed_ventilation/form/feed_ventilation_form_bloc.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/feed_card/feed_value_tile.dart';

class FeedVentilationCardV3Values {

  final String type;
  final int refSource;
  final int refMin;
  final int refMax;
  final int min;
  final int max;

  FeedVentilationCardV3Values(this.type, this.refSource, this.refMin, this.refMax, this.min, this.max);

}

class FeedVentilationCardV3 extends StatelessWidget {

  final FeedVentilationCardV3Values values;

  FeedVentilationCardV3({Key? key, required this.values}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isTempSource(values.refSource)) {
      return _renderTemperatureMode(context);
    }
    if (isHumiSource(values.refSource)) {
      return _renderHumidityMode(context);
    } else if (isTimerSource(values.refSource)) {
      return _renderTimerMode(context);
    } else if (values.refSource == 0) {
      return _renderManualMode(context);
    }
    return Fullscreen(
      child: Icon(Icons.upgrade),
      title: FeedVentilationCardPage.feedVentilationCardPageUpgrade,
    );
  }

  Widget _renderTemperatureMode(BuildContext context) {
    String unit = AppDB().getUserSettings().freedomUnits == true ? '°F' : '°C';
    List<Widget> cards = [
      renderCard(FeedVentilationCardPage.feedVentilationCardPageLowTempSettings, '${values.min}%', detail: 'at ${_tempUnit(values.refMin.toDouble())}$unit'),
      renderCard(FeedVentilationCardPage.feedVentilationCardPageHighTempSettings, '${values.max}%', detail: 'at ${_tempUnit(values.refMax.toDouble())}$unit'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Text(FeedVentilationCardPage.feedVentilationCardPageTemperatureMode,
            style: Theme.of(context).textTheme.titleSmall),
      ),
      FeedTileStrip(tiles: cards),
    ]);
  }

  Widget _renderHumidityMode(BuildContext context) {
    String unit = '%';

    List<Widget> cards = [
      renderCard(FeedVentilationCardPage.feedVentilationCardPageLowHumiSettings, '${values.min}%', detail: 'at ${values.refMin.toDouble()}$unit'),
      renderCard(FeedVentilationCardPage.feedVentilationCardPageHighHumiSettings, '${values.max}%', detail: 'at ${values.refMax.toDouble()}$unit'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Text(FeedVentilationCardPage.feedVentilationCardPageHumidityMode,
            style: Theme.of(context).textTheme.titleSmall),
      ),
      FeedTileStrip(tiles: cards),
    ]);
  }

  Widget _renderTimerMode(BuildContext context) {
    List<Widget> cards = [
      renderCard(FeedVentilationCardPage.feedVentilationCardPageNightSettings, '${values.min}%'),
      renderCard(FeedVentilationCardPage.feedVentilationCardPageDaySettings, '${values.max}%'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Text(FeedVentilationCardPage.feedVentilationCardPageTimerMode,
            style: Theme.of(context).textTheme.titleSmall),
      ),
      FeedTileStrip(tiles: cards),
    ]);
  }

  Widget _renderManualMode(BuildContext context) {
    List<Widget> cards = [
      renderCard(FeedVentilationCardPage.feedVentilationCardPagePower, '${values.min}%'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Text(FeedVentilationCardPage.feedVentilationCardPageManualMode,
            style: Theme.of(context).textTheme.titleSmall),
      ),
      FeedTileStrip(tiles: cards),
    ]);
  }



  Widget renderCard(String title, String value, {String? detail}) {
    return FeedValueTile(icon: FeedEntryIcons[FE_VENTILATION]!, label: title, value: value, detail: detail);
  }

  double _tempUnit(double temp) {
    if (AppDB().getUserSettings().freedomUnits == true) {
      return temp * 9 / 5 + 32;
    }
    return temp;
  }
}