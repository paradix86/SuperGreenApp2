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

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/local_alerts/local_alert_settings.dart';
import 'package:super_green_app/local_alerts/local_alerts_evaluator.dart';
import 'package:super_green_app/local_alerts/local_alerts_service.dart';
import 'package:super_green_app/local_alerts/local_alerts_sync.dart';
import 'package:super_green_app/pages/feeds/home/common/settings/box_settings.dart';
import 'package:super_green_app/theme.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';

/// Limits for the alerts raised by the phone itself (LocalAlertsService):
/// no SGL account, no cloud, just the controller on the LAN or through a mesh
/// VPN that reaches it.
class LocalAlertThresholdsPage extends StatefulWidget {
  final Plant plant;

  const LocalAlertThresholdsPage({required this.plant, Key? key}) : super(key: key);

  @override
  _LocalAlertThresholdsPageState createState() => _LocalAlertThresholdsPageState();
}

class _LocalAlertThresholdsPageState extends State<LocalAlertThresholdsPage> {
  static const double _tempFloor = 0;
  static const double _tempCeil = 50;
  static const double _tempStep = 0.5;
  static const double _humiFloor = 0;
  static const double _humiCeil = 100;

  Box? _box;
  LocalAlertSettings _settings = const LocalAlertSettings();
  bool _batteryUnrestricted = true;
  bool _saving = false;

  bool get _imperial => AppDB().getUserSettings().freedomUnits == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Box box = await RelDB.get().plantsDAO.getBox(widget.plant.box);
    final bool battery = await LocalAlertsSync.isBatteryUnrestricted();
    if (!mounted) {
      return;
    }
    setState(() {
      _box = box;
      _settings = BoxSettings.fromJSON(box.settings).alerts;
      _batteryUnrestricted = battery;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Box? box = _box;
    return Scaffold(
      appBar: SGLAppBar('Alerts from this phone'),
      body: box == null
          ? const FullscreenLoading(title: 'Loading')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildEnableCard(context, box),
                const SizedBox(height: 12),
                _buildTemperatureCard(context),
                const SizedBox(height: 12),
                _buildHumidityCard(context),
                const SizedBox(height: 12),
                _buildBatteryCard(context),
                const SizedBox(height: 24),
                SglFilledGreenButton(
                  title: _saving ? 'Saving…' : 'Save',
                  expanded: true,
                  onPressed: () {
                    if (!_saving) {
                      _save(box);
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildEnableCard(BuildContext context, Box box) {
    final SglColors c = context.sgl;
    final TextTheme t = Theme.of(context).textTheme;
    final bool hasController = box.device != null;
    return SglCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Watch this lab', style: t.titleMedium?.copyWith(color: c.ink))),
              Switch(
                value: _settings.enabled && hasController,
                onChanged: hasController ? (v) => setState(() => _settings = _settings.copyWith(enabled: v)) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasController
                ? 'Your phone reads the controller every ${LocalAlertsService.pollInterval.inSeconds} s and notifies you '
                    'when temperature or humidity leaves the range below, app closed or not. '
                    'A still-active alert is repeated every ${LocalAlertsEvaluator.repeatEvery.inMinutes} min, '
                    'and you get one notification when the controller stops answering for '
                    '${LocalAlertsEvaluator.unreachableAfter.inMinutes} min.'
                : 'This lab has no controller linked, so there is nothing to read. Link one from Lab settings.',
            style: t.bodyMedium?.copyWith(color: c.ink2, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Works on your home Wi-Fi or through a mesh VPN that reaches the controller. Nothing goes through the SuperGreenLab cloud.',
            style: t.bodySmall?.copyWith(color: c.ink3, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(BuildContext context) {
    final String unit = _imperial ? '°F' : '°C';
    return _RangeCard(
      title: 'Temperature',
      unit: unit,
      floor: _tempFloor,
      ceil: _tempCeil,
      divisions: ((_tempCeil - _tempFloor) / _tempStep).round(),
      low: _settings.tempMin,
      high: _settings.tempMax,
      format: (double celsius) => _imperial ? (celsius * 9 / 5 + 32).toStringAsFixed(0) : celsius.toStringAsFixed(1),
      onChanged: (RangeValues v) => setState(() => _settings = _settings.copyWith(tempMin: v.start, tempMax: v.end)),
    );
  }

  Widget _buildHumidityCard(BuildContext context) {
    return _RangeCard(
      title: 'Humidity',
      unit: '%',
      floor: _humiFloor,
      ceil: _humiCeil,
      divisions: (_humiCeil - _humiFloor).round(),
      low: _settings.humiMin,
      high: _settings.humiMax,
      format: (double v) => v.toStringAsFixed(0),
      onChanged: (RangeValues v) => setState(() => _settings = _settings.copyWith(humiMin: v.start, humiMax: v.end)),
    );
  }

  Widget _buildBatteryCard(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme t = Theme.of(context).textTheme;
    return SglCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _batteryUnrestricted ? Icons.battery_charging_full_outlined : Icons.battery_alert_outlined,
                color: _batteryUnrestricted ? c.accent : c.warn,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Keep it running', style: t.titleMedium?.copyWith(color: c.ink))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _batteryUnrestricted
                ? 'Battery use is unrestricted: Android will not stop the watcher.'
                : 'Android (Samsung above all) puts apps to sleep after a few days and the watcher dies with them. '
                    'Allow unrestricted battery use so the alerts keep coming.',
            style: t.bodyMedium?.copyWith(color: c.ink2, height: 1.4),
          ),
          if (!_batteryUnrestricted) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SglFilledGreenButton(
                title: 'Allow unrestricted',
                onPressed: () async {
                  final bool granted = await LocalAlertsSync.requestBatteryUnrestricted();
                  if (mounted) {
                    setState(() => _batteryUnrestricted = granted);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(Box box) async {
    setState(() => _saving = true);
    try {
      if (_settings.enabled) {
        final bool allowed = await LocalAlertsSync.requestNotificationPermission();
        if (!allowed && mounted) {
          showSnackBar(context, 'Notifications are blocked for this app: alerts cannot be shown.');
        }
      }
      final String settingsJSON = BoxSettings.fromJSON(box.settings).copyWith(alerts: _settings).toJSON();
      if (settingsJSON != box.settings) {
        await RelDB.get().plantsDAO.updateBox(
            BoxesCompanion(id: Value(box.id), settings: Value(settingsJSON), synced: const Value(false)));
      }
      await LocalAlertsSync.rebuild();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e, trace) {
      Logger.logError(e, trace);
      if (mounted) {
        setState(() => _saving = false);
        showSnackBar(context, 'Could not save the alert settings.');
      }
    }
  }
}

class _RangeCard extends StatelessWidget {
  final String title;
  final String unit;
  final double floor;
  final double ceil;
  final int divisions;
  final double low;
  final double high;
  final String Function(double) format;
  final ValueChanged<RangeValues> onChanged;

  const _RangeCard({
    required this.title,
    required this.unit,
    required this.floor,
    required this.ceil,
    required this.divisions,
    required this.low,
    required this.high,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme t = Theme.of(context).textTheme;
    return SglCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: t.titleMedium?.copyWith(color: c.ink))),
              Text(
                '${format(low)} – ${format(high)} $unit',
                style: SglTextStyles.reading.copyWith(color: c.accent, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Alert below the first value or above the second.', style: t.bodySmall?.copyWith(color: c.ink3)),
          RangeSlider(
            values: RangeValues(low.clamp(floor, ceil), high.clamp(floor, ceil)),
            min: floor,
            max: ceil,
            divisions: divisions,
            labels: RangeLabels(format(low), format(high)),
            onChanged: (RangeValues v) {
              if (v.end - v.start < (ceil - floor) / divisions) {
                return;
              }
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
