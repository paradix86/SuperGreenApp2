
import 'package:flutter/material.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/widgets/sgl/sgl_info.dart';
import 'package:super_green_app/theme/sgl_chart_palette.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:intl/intl.dart';
import 'package:super_green_app/data/api/backend/time_series/time_series_api.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/environment/graphs/box_app_bar_metrics_bloc.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

const minCharPoints = 10;

class BoxAppBarMetricsPage extends StatefulWidget {
  @override
  _BoxAppBarMetricsPageState createState() => _BoxAppBarMetricsPageState();
}

class _BoxAppBarMetricsPageState extends State<BoxAppBarMetricsPage> {
  int? selectedGraphIndex;

  final ScrollController _scrollController = ScrollController();

  final Map<int, bool> disabledGraphs = {};

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoxAppBarMetricsBloc, PlantFeedAppBarBlocState>(
      listener: (BuildContext context, PlantFeedAppBarBlocState state) {},
      child: BlocBuilder<BoxAppBarMetricsBloc, PlantFeedAppBarBlocState>(
        builder: (BuildContext context, PlantFeedAppBarBlocState state) {
          Widget body = FullscreenLoading(
            title: 'Loading..',
          );
          if (state is PlantFeedAppBarBlocStateInit) {
            body = FullscreenLoading(
              title: 'Loading..',
              textColor: context.sgl.ink,
            );
          } else if (state is PlantFeedAppBarBlocStateLoaded) {
            if (state.graphData.where((g) => g.data.length != 0).length == 0) { // TODO replace with firstWhere when they fix it to return null
              body = Fullscreen(
                title: 'Not enough data to display metrics yet',
                subtitle: 'try again in a few minutes',
                fontSize: 20,
                fontWeight: FontWeight.normal,
                child: Container(),
                childFirst: false,
              );
            } else {
              body = _renderGraphs(context, state);
            }
          }
          return AnimatedSwitcher(duration: Duration(milliseconds: 200), child: body);
        },
      ),
    );
  }

  Widget _renderGraphs(BuildContext context, PlantFeedAppBarBlocStateLoaded state) {
    String tempUnit = AppDB().getUserSettings().freedomUnits! ? '°F' : '°C';

    charts.Series<Metric, DateTime> dateGraphData = state.graphData.firstWhere((g) => g.data.length != 0);
    DateTime metricDate = dateGraphData.data[selectedGraphIndex ?? dateGraphData.data.length - 1].time;
    
    String weightUnit = AppDB().getUserSettings().freedomUnits! ? 'lb' : 'kg';
    String format = AppDB().getUserSettings().freedomUnits! ? 'MM/dd/yyyy HH:mm' : 'dd/MM/yyyy HH:mm';
    Widget dateText = Text('${DateFormat(format).format(metricDate)}',
        style: SglTextStyles.mono.copyWith(color: context.sgl.ink2, fontSize: 12));
    List<charts.LineAnnotationSegment<Object>>? annotations;
    if (selectedGraphIndex != null) {
      annotations = [
        charts.LineAnnotationSegment(metricDate, charts.RangeAnnotationAxisType.domain,
            labelStyleSpec: charts.TextStyleSpec(color: _chartColor(context.sgl.ink)),
            color: _chartColor(context.sgl.ink3))
      ];
      dateText = Row(
        children: <Widget>[
          dateText,
          Expanded(
            child: Text(
              'tap to reset',
              style: TextStyle(color: context.sgl.ink, decoration: TextDecoration.underline),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }
    Widget graphs = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.sgl.surface,
        border: Border.all(color: context.sgl.line, width: 1),
      ),
      child: /*Stack(
        children: [*/
          Padding(
        padding: const EdgeInsets.all(8.0),
        child: charts.TimeSeriesChart(
          state.graphData.where((gd) => !(disabledGraphs[state.graphData.indexOf(gd)] ?? false)).toList(),
          animate: false,
          domainAxis: charts.DateTimeAxisSpec(
            renderSpec: charts.SmallTickRendererSpec(
              labelStyle: charts.TextStyleSpec(fontSize: 10, color: _chartColor(context.sgl.ink3)),
              lineStyle: charts.LineStyleSpec(color: _chartColor(context.sgl.line)),
            ),
          ),
          primaryMeasureAxis: charts.NumericAxisSpec(
            renderSpec: charts.GridlineRendererSpec(
              labelStyle: charts.TextStyleSpec(fontSize: 10, color: _chartColor(context.sgl.ink3)),
              lineStyle: charts.LineStyleSpec(color: _chartColor(context.sgl.line)),
            ),
          ),
          behaviors: selectedGraphIndex != null
              ? [
                  charts.RangeAnnotation(annotations!),
                ]
              : null,
          customSeriesRenderers: [charts.PointRendererConfig(customRendererId: 'customPoint')],
          selectionModels: [
            new charts.SelectionModelConfig(
                type: charts.SelectionModelType.info,
                changedListener: (charts.SelectionModel model) {
                  if (!model.hasAnySelection) {
                    return;
                  }
                  setState(() {
                    selectedGraphIndex = model.selectedDatum[0].index;
                  });
                }),
          ],
        ),
      ),
    );
    if (state.graphData.where((g) => g.data.length > minCharPoints).length == 0) {
      graphs = Stack(children: [
        graphs,
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: context.sgl.surface,
            border: Border.all(color: context.sgl.line, width: 1),
          ),
          child: Fullscreen(
            title: 'Still not enough data\nto show a graph',
            subtitle: 'try again in a few minutes',
            fontSize: 20,
            fontWeight: FontWeight.normal,
            child: Container(),
            childFirst: false,
          ),
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 0, right: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () {
              setState(() {
                selectedGraphIndex = null;
              });
            },
            child: Padding(padding: const EdgeInsets.all(6.0), child: dateText),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Container(
              height: 60,
              child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: <Widget>[
                    Container(width: 4),
                    state.graphData[0].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.temperature,
                        'Temp',
                        '${state.graphData[0].data[selectedGraphIndex ?? state.graphData[0].data.length - 1].metric.toInt()}$tempUnit',
                        '${TimeSeriesAPI.min(state.graphData[0].data).metric.toInt()}$tempUnit',
                        '${TimeSeriesAPI.max(state.graphData[0].data).metric.toInt()}$tempUnit', () {
                      setState(() {
                        disabledGraphs[0] = !(disabledGraphs[0] ?? false);
                      });
                    }, disabledGraphs[0] ?? false),
                    state.graphData[1].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.humidity,
                        'Humi',
                        '${state.graphData[1].data[selectedGraphIndex ?? state.graphData[1].data.length - 1].metric.toInt()}%',
                        '${TimeSeriesAPI.min(state.graphData[1].data).metric.toInt()}%',
                        '${TimeSeriesAPI.max(state.graphData[1].data).metric.toInt()}%', () {
                      setState(() {
                        disabledGraphs[1] = !(disabledGraphs[1] ?? false);
                      });
                    }, disabledGraphs[1] ?? false),
                    state.graphData[2].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.vpd,
                        'VPD',
                        '${(state.graphData[2].data[selectedGraphIndex ?? state.graphData[2].data.length - 1].metric / 40).toStringAsFixed(2)}',
                        '${(TimeSeriesAPI.min(state.graphData[2].data).metric / 40).toStringAsFixed(2)}',
                        '${(TimeSeriesAPI.max(state.graphData[2].data).metric / 40).toStringAsFixed(2)}', () {
                      setState(() {
                        disabledGraphs[2] = !(disabledGraphs[2] ?? false);
                      });
                    }, disabledGraphs[2] ?? false),
                    state.graphData[4].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.ventilation,
                        'Ventilation',
                        '${state.graphData[4].data[selectedGraphIndex ?? state.graphData[4].data.length - 1].metric.toInt()}%',
                        '${TimeSeriesAPI.min(state.graphData[4].data).metric.toInt()}%',
                        '${TimeSeriesAPI.max(state.graphData[4].data).metric.toInt()}%', () {
                      setState(() {
                        disabledGraphs[4] = !(disabledGraphs[4] ?? false);
                      });
                    }, disabledGraphs[4] ?? false),
                    state.graphData[3].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.light,
                        'Light',
                        '${state.graphData[3].data[selectedGraphIndex ?? state.graphData[3].data.length - 1].metric.toInt()}%',
                        '${TimeSeriesAPI.min(state.graphData[3].data).metric.toInt()}%',
                        '${TimeSeriesAPI.max(state.graphData[3].data).metric.toInt()}%', () {
                      setState(() {
                        disabledGraphs[3] = !(disabledGraphs[3] ?? false);
                      });
                    }, disabledGraphs[3] ?? false),
                    state.graphData[5].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.co2,
                        'CO2',
                        '${(state.graphData[5].data[selectedGraphIndex ?? state.graphData[5].data.length - 1].metric * 20).toInt()}',
                        '${(TimeSeriesAPI.min(state.graphData[5].data).metric * 20).toInt()}',
                        '${(TimeSeriesAPI.max(state.graphData[5].data).metric * 20).toInt()}', () {
                      setState(() {
                        disabledGraphs[5] = !(disabledGraphs[5] ?? false);
                      });
                    }, disabledGraphs[5] ?? false),
                    state.graphData[6].data.length == 0 ? Container() : _renderMetric(
                        SglChartPalette.weight,
                        'Weight ($weightUnit)',
                        '${state.graphData[6].data[selectedGraphIndex ?? state.graphData[6].data.length - 1].metric.toStringAsFixed(3)}',
                        '${TimeSeriesAPI.min(state.graphData[6].data).metric.toStringAsFixed(3)}',
                        '${TimeSeriesAPI.max(state.graphData[6].data).metric.toStringAsFixed(3)}', () {
                      setState(() {
                        disabledGraphs[6] = !(disabledGraphs[6] ?? false);
                      });
                    }, disabledGraphs[6] ?? false),
                    Container(width: 4),
                  ],
              ),
            ),
          ),
          Expanded(
            child: graphs,
          ),
          // Text("*VPD chart is experimental, please report any inconsistencies",
          //     style: TextStyle(fontSize: 9, color: context.sgl.ink)),
        ],
      ),
    );
  }

  Widget _renderMetric(
      Color color, String name, String value, String min, String max, void Function() onTap, bool disabled) {
    const Map<String, String> infoKeys = {
      'Temp': 'temp',
      'Humi': 'rh',
      'VPD': 'vpd',
      'Ventilation': 'ventilation',
      'Light': 'light',
      'CO2': 'co2',
      'Weight': 'weight',
    };
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name.toUpperCase(), style: SglTextStyles.eyebrow.copyWith(color: context.sgl.ink3, fontSize: 10)),
                  SglInfoButton(infoKeys[name] ?? name.toLowerCase(), size: 12),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(value == "0" ? "N/A" : value,
                      style: SglTextStyles.reading.copyWith(color: color, fontSize: value == "0" ? 18 : 24)),
                  const SizedBox(width: 4),
                  value != "0"
                      ? Column(
                          children: <Widget>[
                            Text(max, style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 11)),
                            Text(min, style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 11)),
                          ],
                        )
                      : Container(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  static charts.Color _chartColor(Color c) => SglChartPalette.chart(c);
}
