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

import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:super_green_app/misc/bloc.dart';
import 'package:super_green_app/theme/sgl_chart_palette.dart';
import 'package:flutter/painting.dart';
import 'package:super_green_app/data/api/backend/time_series/time_series_api.dart';
import 'package:super_green_app/data/api/device/dash_history.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/rel/rel_db.dart';

abstract class PlantFeedAppBarBlocEvent extends Equatable {}

class PlantFeedAppBarBlocEventLoadChart extends PlantFeedAppBarBlocEvent {
  @override
  List<Object> get props => [];
}

class PlantFeedAppBarBlocEventReloadChart extends PlantFeedAppBarBlocEvent {
  final int rand = Random().nextInt(1 << 32);

  @override
  List<Object> get props => [rand];
}

/// Switches between the readings polled from the controller (last 24 h,
/// [DashHistory]) and the SuperGreenLab cloud history (last 72 h).
class PlantFeedAppBarBlocEventSetSource extends PlantFeedAppBarBlocEvent {
  final bool cloud;

  PlantFeedAppBarBlocEventSetSource(this.cloud);

  @override
  List<Object> get props => [cloud];
}

enum GraphSource { local, cloud, demo }

abstract class PlantFeedAppBarBlocState extends Equatable {}

class PlantFeedAppBarBlocStateInit extends PlantFeedAppBarBlocState {
  @override
  List<Object> get props => [];
}

class PlantFeedAppBarBlocStateLoaded extends PlantFeedAppBarBlocState {
  final List<dynamic> version;
  final List<MetricSeries> graphData;
  final Plant? plant;
  final Box box;
  final GraphSource source;

  /// True when the box has a controller: the cloud history can be offered.
  final bool hasController;

  PlantFeedAppBarBlocStateLoaded(this.version, this.graphData, this.plant, this.box,
      {this.source = GraphSource.cloud, this.hasController = false});

  @override
  List<Object?> get props => [version, graphData, plant, box, source, hasController];
}

class BoxAppBarMetricsBloc extends LegacyBloc<PlantFeedAppBarBlocEvent, PlantFeedAppBarBlocState> {
  Timer? _timer;
  final Plant? plant;
  Box? box;

  List<dynamic> version = [];

  /// Newest local sample older than this: the local series is not offered.
  static const Duration localStaleAfter = Duration(minutes: 10);

  /// Set by [PlantFeedAppBarBlocEventSetSource]; null = local when available.
  bool? _preferCloud;
  GraphSource _source = GraphSource.demo;

  BoxAppBarMetricsBloc({this.plant, this.box}) : super(PlantFeedAppBarBlocStateInit()) {
    add(PlantFeedAppBarBlocEventLoadChart());
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      this.add(PlantFeedAppBarBlocEventReloadChart());
    });
  }

  @override
  Stream<PlantFeedAppBarBlocState> mapEventToState(PlantFeedAppBarBlocEvent event) async* {
    if (event is PlantFeedAppBarBlocEventLoadChart) {
      try {
        if (box == null) {
          final db = RelDB.get();
          box = await db.plantsDAO.getBox(plant!.box);
        }
        List<MetricSeries> graphData = await updateChart();
        yield _loaded(graphData);
      } catch (e) {
        print(e);
      }
    } else if (event is PlantFeedAppBarBlocEventReloadChart) {
      try {
        List<MetricSeries> graphData = await updateChart();
        yield _loaded(graphData);
      } catch (e) {
        print(e);
      }
    } else if (event is PlantFeedAppBarBlocEventSetSource) {
      _preferCloud = event.cloud;
      try {
        List<MetricSeries> graphData = await updateChart();
        yield _loaded(graphData);
      } catch (e) {
        print(e);
      }
    }
  }

  PlantFeedAppBarBlocStateLoaded _loaded(List<MetricSeries> graphData) {
    return PlantFeedAppBarBlocStateLoaded(version, graphData, plant, box!,
        source: _source, hasController: box?.device != null);
  }

  /// Series built from the readings the app polled from the controller
  /// itself ([DashHistory]), same scaling as the cloud series so the chart
  /// and the metric strip read the same. Null when nothing was recorded yet.
  List<MetricSeries>? _localChart(int deviceID, int deviceBox) {
    final String prefix = 'BOX_${deviceBox}_';
    final List<DashSample> temps = DashHistory.samples(deviceID, '${prefix}TEMP');
    if (temps.length < 2) {
      return null;
    }
    // "From the controller" must mean live: with the app closed or the
    // controller offline the history stops, so past [localStaleAfter] the
    // cloud series (which shows the gap) is the honest choice.
    if (DateTime.now().difference(temps.last.time) > localStaleAfter) {
      return null;
    }
    version = [];
    MetricSeries series(String key, String id, Color color, double Function(int) scale) {
      final List<DashSample> samples = DashHistory.samples(deviceID, '$prefix$key');
      final bool keepZero = key == 'BLOWER_DUTY' || key == 'LED_DIM';
      final List<Metric> data =
          samples.where((s) => keepZero || s.value != 0).map((s) => Metric(s.time, scale(s.value))).toList();
      return MetricSeries(id: id, color: color, data: data);
    }

    return [
      series('TEMP', 'Temperature', SglChartPalette.temperature, (v) => _tempUnit(v.toDouble(), 0)),
      series('HUMI', 'Humidity', SglChartPalette.humidity, (v) => v.toDouble()),
      series('VPD', 'VPD', SglChartPalette.vpd, (v) => min(140, max(v * 0.4, 0))),
      series('LED_DIM', 'Light', SglChartPalette.light, (v) => v.toDouble()),
      series('BLOWER_DUTY', 'Ventilation', SglChartPalette.ventilation, (v) => v.toDouble()),
      series('CO2', 'CO2', SglChartPalette.co2, (v) => _co2(v.toDouble(), 0)),
      series('WEIGHT', 'Weight', SglChartPalette.weight, (v) => _weight(v.toDouble(), 0)),
    ];
  }

  Future<List<MetricSeries>> updateChart() async {
    if (box?.device == null) {
      _source = GraphSource.demo;
      return _createDummyData();
    } else {
      late Device device;
      try {
        device = await RelDB.get().devicesDAO.getDevice(box!.device!);
      } catch (e) {
        _timer?.cancel();
        _timer = null;
        _source = GraphSource.demo;
        return _createDummyData();
      }
      String identifier = device.identifier;
      int deviceBox = box!.deviceBox!;
      if (_preferCloud != true) {
        final List<MetricSeries>? local = _localChart(device.id, deviceBox);
        if (local != null) {
          _source = GraphSource.local;
          return local;
        }
      }
      _source = GraphSource.cloud;
      version = await TimeSeriesAPI.fetchMetric(box!, identifier, 'OTA_TIMESTAMP', 0, 10000000000);
      MetricSeries temp = await TimeSeriesAPI.fetchTimeSeries(
          box!, identifier, 'Temperature', 'BOX_${deviceBox}_TEMP', SglChartPalette.temperature, 0, 50,
          transform: _tempUnit);
      MetricSeries humi = await TimeSeriesAPI.fetchTimeSeries(
          box!, identifier, 'Humidity', 'BOX_${deviceBox}_HUMI', SglChartPalette.humidity, 0, 100);
      MetricSeries vpd = await TimeSeriesAPI.fetchTimeSeries(
          box!, identifier, 'VPD', 'BOX_${deviceBox}_VPD', SglChartPalette.vpd, 0, 254,
          transform: _vpd);

      MetricSeries ventilation = await TimeSeriesAPI.fetchTimeSeries(
          box!, identifier, 'Ventilation', 'BOX_${deviceBox}_BLOWER_DUTY', SglChartPalette.ventilation, 0, 100);

      late MetricSeries light;
      try {
        List<dynamic> timerOutput = await TimeSeriesAPI.fetchMetric(box!, identifier, 'BOX_${deviceBox}_TIMER_OUTPUT', 0, 100);
        List<List<dynamic>> dims = [];
        Module lightModule = await RelDB.get().devicesDAO.getModule(device.id, "led");
        for (int i = 0; i < lightModule.arrayLen; ++i) {
          Param boxParam = await RelDB.get().devicesDAO.getParam(device.id, "LED_${i}_BOX");
          if (boxParam.ivalue != box!.deviceBox!) {
            continue;
          }
          List<dynamic> dim = await TimeSeriesAPI.fetchMetric(box!, identifier, 'LED_${i}_DIM', 0, 100);
          dims.add(dim);
        }
        List<int> avgDims = TimeSeriesAPI.avgMetrics(dims);
        light = TimeSeriesAPI.toTimeSeries(
            TimeSeriesAPI.multiplyMetric(timerOutput, avgDims), 'Light', SglChartPalette.light);
      } catch (e) {
        light = TimeSeriesAPI.toTimeSeries([], 'Light', SglChartPalette.light);
      }

      MetricSeries co2 = await TimeSeriesAPI.fetchTimeSeries(
          box!, identifier, 'CO2', 'BOX_${deviceBox}_CO2', SglChartPalette.co2, 0, 100000,
          transform: _co2);
      MetricSeries weight = await TimeSeriesAPI.fetchTimeSeries(
          box!, identifier, 'Weight', 'BOX_${deviceBox}_WEIGHT', SglChartPalette.weight, 0, 100000,
          transform: _weight);
      return [temp, humi, vpd, light, ventilation, co2, weight];
    }
  }

  List<MetricSeries> _createDummyData() {
    final tempData = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            _tempUnit((cos(index / 100) * 20) + Random().nextInt(7) + 20, index).toDouble()));
    final humiData = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            ((sin(index / 100) * 5).toInt() + Random().nextInt(3) + 20).toDouble()));
    final vpdData = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            ((sin(index / 100) * 5).toInt() + Random().nextInt(3) + 20).toDouble()));
    final lightData = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            ((cos(index / 100) * 10).toInt() + Random().nextInt(5) + 20).toDouble()));
    final ventilationData = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            ((cos(index / 100) * 10).toInt() + Random().nextInt(5) + 20).toDouble()));
    final co2Data = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            ((cos(index / 100) * 10).toInt() + Random().nextInt(5) + 20).toDouble()));
    final weightData = List.generate(
        50,
        (index) => Metric(DateTime.now().subtract(Duration(hours: 72)).add(Duration(hours: index * 72 ~/ 50)),
            ((cos(index / 100) * 10).toInt() + Random().nextInt(5) + 20).toDouble()));

    return [
      MetricSeries(id: 'Temperature', color: SglChartPalette.temperature, data: tempData),
      MetricSeries(id: 'Humidity', color: SglChartPalette.humidity, data: humiData),
      MetricSeries(id: 'VPD', color: SglChartPalette.vpd, data: vpdData),
      MetricSeries(id: 'Light', color: SglChartPalette.light, data: lightData),
      MetricSeries(id: 'Ventilation', color: SglChartPalette.ventilation, data: ventilationData),
      MetricSeries(id: 'CO2', color: SglChartPalette.ventilation, data: co2Data),
      MetricSeries(id: 'Weight', color: SglChartPalette.ventilation, data: weightData),
    ];
  }

  double _tempUnit(double temp, int i) {
    if (AppDB().getUserSettings().freedomUnits == true) {
      return temp * 9 / 5 + 32;
    }
    return temp;
  }

  double _vpd(double vpd, int i) {
    return min(140, max(version[i][1] != 0 && version[i][1] < 1700000000 ? vpd * 4 :  vpd * 0.4, 0));
  }

  double _weight(double weight, int i) {
    if (AppDB().getUserSettings().freedomUnits == true) {
      return weight / 1000 * 2.20462;
    }
    return weight / 1000;
  }

  double _co2(double co2, int i) {
    return co2 / 20;
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    return super.close();
  }
}
