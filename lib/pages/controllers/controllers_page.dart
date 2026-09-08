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
import 'package:super_green_app/data/api/device/device_status.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/device_daemon/device_daemon_bloc.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/controllers/controllers_bloc.dart';
import 'package:super_green_app/pages/settings/devices/status/settings_device_status_page.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/widgets/sgl/sgl_info.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';
import 'package:super_green_app/widgets/sgl/sparkline.dart';

/// First tab: the state of every paired controller, with the sensor alarm
/// on top when there is one. Replaces the old notification dashboard.
class ControllersPage extends StatelessWidget {
  const ControllersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ControllersBloc, ControllersBlocState>(
      builder: (BuildContext context, ControllersBlocState state) {
        final List<ControllerEntry> controllers = state is ControllersBlocStateLoaded ? state.controllers : const [];
        final int local = controllers.where((c) => c.device.isReachable && !c.device.isRemote).length;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Controllers', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  state is ControllersBlocStateLoaded
                      ? '$local local · polled every ${DeviceDaemonBloc.pollInterval.inSeconds} s'
                      : 'loading…',
                  style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add a controller',
                onPressed: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToAddDeviceEvent()),
              ),
            ],
          ),
          body: state is! ControllersBlocStateLoaded
              ? const FullscreenLoading(title: 'Loading controllers')
              : controllers.isEmpty
                  ? const _EmptyState()
                  : _renderList(context, controllers),
        );
      },
    );
  }

  Widget _renderList(BuildContext context, List<ControllerEntry> controllers) {
    final List<Widget> children = [];
    for (final ControllerEntry entry in controllers.where((c) => c.hasSensorWarning)) {
      children.add(_SensorAlertStrip(entry: entry));
      children.add(const SizedBox(height: 10));
    }
    for (final ControllerEntry entry in controllers) {
      children.add(_ControllerCard(entry: entry));
      children.add(const SizedBox(height: 10));
      children.add(_BoxesCard(entry: entry));
      children.add(const SizedBox(height: 16));
    }
    return ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 24), children: children);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.developer_board_outlined, size: 48, color: c.ink3),
          const SizedBox(height: 12),
          Text('No controller paired yet', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Pair a SuperGreenLab controller to see its Wi-Fi, MQTT, uptime and sensor health here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.ink2),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToAddDeviceEvent()),
              icon: const Icon(Icons.add),
              label: const Text('Add a controller'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorAlertStrip extends StatelessWidget {
  final ControllerEntry entry;

  const _SensorAlertStrip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final String alert = entry.sensorHealthAlert ?? 'sensor warning';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.amberSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: c.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_describe(alert), style: Theme.of(context).textTheme.titleSmall!.copyWith(color: c.amberInk)),
                Text('${entry.device.name} · sensor_health · $alert',
                    style: SglTextStyles.mono.copyWith(color: c.amberInk, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `box_0_sensor_stuck` -> "Box 1 sensor reads the same values";
  /// older firmwares send `box_0_temp_stuck` per metric.
  static String _describe(String alert) {
    final RegExp re = RegExp(r'^box_(\d+)_(temp|humi|vpd|co2|sensor)_stuck$');
    final RegExpMatch? m = re.firstMatch(alert);
    if (m == null) {
      if (alert.endsWith('_warmup')) {
        return 'Sensors are still warming up';
      }
      return 'Sensor health warning';
    }
    if (m.group(2) == 'sensor') {
      return 'Box ${int.parse(m.group(1)!) + 1} sensor reads the same values (frozen or unplugged?)';
    }
    const Map<String, String> names = {'temp': 'temperature', 'humi': 'humidity', 'vpd': 'VPD', 'co2': 'CO2'};
    return 'Box ${int.parse(m.group(1)!) + 1} ${names[m.group(2)]} reads the same value';
  }
}

class _ControllerCard extends StatelessWidget {
  final ControllerEntry entry;

  const _ControllerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme text = Theme.of(context).textTheme;
    final Device device = entry.device;
    final DeviceStatus? s = entry.status;

    final SglStatusChip chip;
    if (device.isRemote) {
      chip = const SglStatusChip(label: 'remote', status: SglStatus.info);
    } else if (device.isReachable) {
      chip = const SglStatusChip(label: 'reachable', status: SglStatus.ok);
    } else {
      chip = const SglStatusChip(label: 'offline', status: SglStatus.crit);
    }

    return SglCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: device.isReachable ? c.accent : c.crit),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${device.identifier} · ${device.ip}',
                        style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              chip,
            ],
          ),
          const SizedBox(height: 12),
          if (s != null) _renderStatus(context, s) else _renderNoStatus(context),
          if (entry.heap.length >= 2) ...[
            const SizedBox(height: 12),
            _renderHeap(context, s),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsDeviceStatus(device)),
                  child: const Text('Status'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsDevice(device)),
                  child: const Text('Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderStatus(BuildContext context, DeviceStatus s) {
    final String? fs = s.fsUsed != null && s.fsTotal != null
        ? '${SettingsDeviceStatusPage.formatKb(s.fsUsed)} / ${SettingsDeviceStatusPage.formatKb(s.fsTotal)}'
        : null;
    final List<MapEntry<String, String>> rows = [
      MapEntry('Wi-Fi', s.isWifiConnected ? 'connected' : 'status ${s.wifiStatus ?? '?'}'),
      MapEntry('MQTT', s.isMqttConnected ? 'connected' : 'disconnected'),
      MapEntry('Uptime', SettingsDeviceStatusPage.formatUptime(s.uptimeS) ?? 'n/a'),
      MapEntry('Restarts', '${s.nRestarts ?? 'n/a'}'),
      MapEntry('OTA', DeviceStatus.otaStatusLabel(s.otaStatus)),
      MapEntry('Clock', s.isTimeValid ? 'NTP · UTC' : 'not set'),
      MapEntry('Reset', DeviceStatus.resetReasonLabel(s.resetReason)),
      MapEntry('Flash', fs ?? '${SettingsDeviceStatusPage.formatKb(s.nvsUsed) ?? 'n/a'} NVS'),
    ];
    return _KeyValueGrid(rows: rows, warn: {
      'Wi-Fi': !s.isWifiConnected,
      'MQTT': !s.isMqttConnected,
      'Clock': !s.isTimeValid,
      'Reset': DeviceStatus.isAbnormalResetReason(s.resetReason),
    });
  }

  Widget _renderNoStatus(BuildContext context) {
    final SglColors c = context.sgl;
    final String why;
    switch (entry.statusError) {
      case 'unsupported':
        why = 'This firmware has no /mqttdiag endpoint: update it to see Wi-Fi, MQTT and heap details.';
        break;
      case 'unreachable':
        why = 'Controller not reachable on the local network right now.';
        break;
      case 'failed':
        why = 'Could not read /mqttdiag; retrying every ${ControllersBloc.statusInterval.inSeconds} s.';
        break;
      default:
        why = 'Reading status…';
    }
    return Text(why, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.ink2));
  }

  Widget _renderHeap(BuildContext context, DeviceStatus? s) {
    final SglColors c = context.sgl;
    final List<double> values = entry.heap.map((h) => h.value / 1024.0).toList();
    final double min = values.reduce((a, b) => a < b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SglEyebrow('Free heap'),
            const SglInfoButton('heap', size: 13),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${values.last.toStringAsFixed(1)} KB · min ${min.toStringAsFixed(1)}'
                '${s?.heapMinFree != null ? ' · boot min ${(s!.heapMinFree! / 1024).toStringAsFixed(1)}' : ''}',
                style: SglTextStyles.mono.copyWith(color: c.ink2, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Sparkline(values: values, color: c.info, height: 28),
      ],
    );
  }
}

/// Two-column label/value grid in the monospace face.
class _KeyValueGrid extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  final Map<String, bool> warn;

  const _KeyValueGrid({required this.rows, this.warn = const {}});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final List<Widget> cells = rows
        .map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => SglInfoButton.show(context, r.key.toLowerCase().replaceAll('-', '')),
                    child: Text(r.key, style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 11), softWrap: false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                    r.value,
                      style: SglTextStyles.mono.copyWith(color: (warn[r.key] ?? false) ? c.warn : c.ink, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
    final List<Widget> lines = [];
    for (int i = 0; i < cells.length; i += 2) {
      lines.add(Row(
        children: [
          Expanded(child: cells[i]),
          const SizedBox(width: 16),
          Expanded(child: i + 1 < cells.length ? cells[i + 1] : const SizedBox()),
        ],
      ));
    }
    return Column(children: lines);
  }
}

class _BoxesCard extends StatelessWidget {
  final ControllerEntry entry;

  const _BoxesCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme text = Theme.of(context).textTheme;
    final Device d = entry.device;
    final List<Widget> rows = [];
    for (final ControllerBox b in entry.boxes) {
      final String title = 'Box ${(b.box.deviceBox ?? 0) + 1} · ${b.plantNames.isEmpty ? b.box.name : b.plantNames.join(', ')}';
      final String value = b.temp == null ? 'no reading' : '${b.temp} °C · ${b.humi ?? '–'} %';
      rows.add(_line(context, title, value));
    }
    if (rows.isEmpty) {
      rows.add(Text('No box linked to this controller yet.', style: text.bodySmall!.copyWith(color: c.ink2)));
    }
    rows.add(Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${d.nBoxes} box · ${d.nLeds} LED channels · ${d.nMotors} motors · ${d.nSensorPorts} sensor ports',
        style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 11),
      ),
    ));
    return SglCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SglCardHeader(title: 'Boxes on this controller'),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final SglColors c = context.sgl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Text(value, style: SglTextStyles.mono.copyWith(color: c.ink2, fontSize: 12)),
        ],
      ),
    );
  }
}
