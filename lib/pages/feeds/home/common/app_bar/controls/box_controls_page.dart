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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:super_green_app/data/api/device/device_params.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/l10n/common.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/add_device/select_device/select_device_page.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/common/widgets/app_bar_missing_controller.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/controls/box_controls_bloc.dart';
import 'package:super_green_app/pages/feeds/home/common/app_bar/controls/widgets/schedule_timeline.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/widgets/sgl/sgl_info.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';

/// Box controls: what the controller is doing for this box (schedule, light,
/// ventilation, alerts) with one card per control opening the matching form.
/// Built on [BoxControlsBloc]; works both inside a bottom sheet and inside
/// the box feed carousel because it is a plain scrollable list.
class BoxControlsPage extends StatefulWidget {
  static String get boxControlPageLoadingPlantData {
    return Intl.message(
      'Loading plant data',
      name: 'boxControlPageLoadingPlantData',
      desc: 'Box control page loading plant data',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  final void Function(Future<dynamic>?)? futureFn;

  const BoxControlsPage({Key? key, this.futureFn}) : super(key: key);

  @override
  _BoxControlsPageState createState() => _BoxControlsPageState();
}

class _BoxControlsPageState extends State<BoxControlsPage> {
  static const Duration staleAfter = Duration(seconds: 30);

  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoxControlsBloc, BoxControlsBlocState>(
      builder: (BuildContext context, BoxControlsBlocState state) {
        if (state is BoxControlsBlocStateNoDevice) {
          return _renderNoDevice(context, state);
        } else if (state is BoxControlsBlocStateLoaded) {
          return _renderLoaded(context, state);
        }
        return FullscreenLoading(title: BoxControlsPage.boxControlPageLoadingPlantData);
      },
    );
  }

  Widget _renderNoDevice(BuildContext context, BoxControlsBlocStateNoDevice state) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          children: [
            Row(children: [SglStatusChip(label: CommonL10N.connectionBadgeNoController, status: SglStatus.crit)]),
            const SizedBox(height: 10),
            _ScheduleCard(onMinutes: 6 * 60, offMinutes: 24 * 60, now: _now, onTap: null),
            const SizedBox(height: 10),
            _LevelCard(title: 'LED dim', icon: Icons.wb_sunny_outlined, value: 66, subtitle: '1 channel', onTap: null),
            const SizedBox(height: 10),
            _LevelCard(title: 'Blower', icon: Icons.air, value: 12, subtitle: 'duty right now', onTap: null),
          ],
        ),
        Positioned.fill(child: AppBarMissingController(state.box)),
      ],
    );
  }

  Widget _renderLoaded(BuildContext context, BoxControlsBlocStateLoaded state) {
    final BoxControlParamsController m = state.metrics;
    final Box box = state.box;
    final Plant? plant = state.plant;

    final bool scheduleAvailable = m.onHour.available && m.offHour.available;
    final bool lightAvailable = m.nLights > 0;
    final int dim = _averageDim(m.lightsDimming);
    final int lightNow = (dim * m.light.ivalue / 100.0).floor();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        _renderStatusRow(context, state),
        const SizedBox(height: 10),
        _ScheduleCard(
          onMinutes: m.onHour.ivalue * 60 + m.onMin.ivalue,
          offMinutes: m.offHour.ivalue * 60 + m.offMin.ivalue,
          now: _now,
          onTap: !scheduleAvailable
              ? null
              : _onEnvironmentControlTapped(
                  context,
                  ({pushAsReplacement = false}) => MainNavigateToFeedScheduleFormEvent(box,
                      pushAsReplacement: pushAsReplacement, futureFn: widget.futureFn),
                  tipID: 'TIP_BLOOM',
                  tipPaths: ['t/supergreenlab/SuperGreenTips/master/s/when_to_switch_to_bloom/l/en']),
        ),
        const SizedBox(height: 10),
        _LevelCard(
          title: 'LED dim',
          icon: Icons.wb_sunny_outlined,
          value: lightAvailable ? dim : null,
          subtitle: !lightAvailable
              ? 'No LED channel assigned to this box'
              : '${m.nLights} channel${m.nLights > 1 ? 's' : ''} · timer output ${m.light.ivalue} % · now $lightNow %',
          onTap: !lightAvailable
              ? null
              : _onEnvironmentControlTapped(
                  context,
                  ({pushAsReplacement = false}) => MainNavigateToFeedLightFormEvent(box,
                      pushAsReplacement: pushAsReplacement, futureFn: widget.futureFn),
                  tipID: 'TIP_STRETCH',
                  tipPaths: [
                      't/supergreenlab/SuperGreenTips/master/s/when_to_control_stretch_in_seedling/l/en',
                      't/supergreenlab/SuperGreenTips/master/s/how_to_control_stretch_in_seedling/l/en'
                    ]),
        ),
        const SizedBox(height: 10),
        _LevelCard(
          title: 'Blower',
          icon: Icons.air,
          value: m.blower.available ? m.blower.ivalue : null,
          subtitle: m.blower.available ? 'duty right now · tap to set min/max and reference' : 'No blower on this controller',
          onTap: !m.blower.available
              ? null
              : _onEnvironmentControlTapped(
                  context,
                  ({pushAsReplacement = false}) => MainNavigateToFeedVentilationFormEvent(box,
                      pushAsReplacement: pushAsReplacement, futureFn: widget.futureFn)),
        ),
        if (plant != null) ...[
          const SizedBox(height: 10),
          _AlertsCard(
            enabled: plant.alerts,
            onTap: () => BlocProvider.of<MainNavigatorBloc>(context)
                .add(MainNavigateToSettingsPlantAlerts(plant, futureFn: widget.futureFn)),
          ),
        ],
        const SizedBox(height: 10),
        _renderScreenRow(context, state),
      ],
    );
  }

  Widget _renderStatusRow(BuildContext context, BoxControlsBlocStateLoaded state) {
    final SglColors c = context.sgl;
    final Device device = state.device;
    final Duration age = _now.difference(state.updatedAt);
    final SglStatusChip chip;
    if (!device.isReachable && !device.isRemote) {
      chip = SglStatusChip(label: CommonL10N.connectionBadgeOffline, status: SglStatus.crit);
    } else if (age > staleAfter) {
      chip = SglStatusChip(label: CommonL10N.connectionBadgeStale, status: SglStatus.warn);
    } else if (device.isRemote) {
      chip = SglStatusChip(label: CommonL10N.connectionBadgeRemote, status: SglStatus.info);
    } else {
      chip = SglStatusChip(label: CommonL10N.connectionBadgeLocal, status: SglStatus.ok);
    }
    return Row(
      children: [
        chip,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${device.name} · updated ${_renderAge(age)}',
            style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _renderScreenRow(BuildContext context, BoxControlsBlocStateLoaded state) {
    final SglColors c = context.sgl;
    final bool canAdd = !state.device.isScreen && state.box.screenDevice == null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.tv_outlined, size: 18, color: c.ink3),
        const SizedBox(width: 6),
        if (canAdd)
          TextButton(
            onPressed: () {
              BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSelectDeviceEvent(
                  isScreen: true,
                  isController: false,
                  futureFn: (future) async {
                    dynamic res = await future;
                    if (res is SelectBoxDeviceData) {
                      BlocProvider.of<BoxControlsBloc>(context)
                          .add(BoxControlsBlocEventSetScreenDevice(res.device, res.deviceBox));
                    }
                  }));
            },
            child: const Text('Add a screen'),
          )
        else
          Text('Screen linked', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.ink3)),
      ],
    );
  }

  static int _averageDim(List<ParamController> dims) {
    if (dims.isEmpty) {
      return 0;
    }
    return dims.fold<int>(0, (sum, d) => sum + d.ivalue) ~/ dims.length;
  }

  static String _renderAge(Duration age) {
    if (age.inSeconds < 5) {
      return 'just now';
    } else if (age.inSeconds < 60) {
      return '${age.inSeconds}s ago';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m ago';
    }
    return '${age.inHours}h ago';
  }

  // TODO DRY this with plant_feed_page
  void Function() _onEnvironmentControlTapped(
      BuildContext context, MainNavigatorEvent Function({bool pushAsReplacement}) navigatorEvent,
      {String? tipID, List<String>? tipPaths}) {
    return () {
      if (tipPaths != null && !AppDB().isTipDone(tipID!)) {
        BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToTipEvent(
            tipID, tipPaths, navigatorEvent(pushAsReplacement: true) as MainNavigateToFeedFormEvent));
      } else {
        BlocProvider.of<MainNavigatorBloc>(context).add(navigatorEvent());
      }
    };
  }
}

/// Light schedule as a 24 h timeline with the "on" window highlighted.
class _ScheduleCard extends StatelessWidget {
  final int onMinutes;
  final int offMinutes;
  final DateTime now;
  final VoidCallback? onTap;

  const _ScheduleCard({required this.onMinutes, required this.offMinutes, required this.now, this.onTap});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme text = Theme.of(context).textTheme;
    final int onLength = ((offMinutes - onMinutes) % 1440 + 1440) % 1440;
    final String hours = onLength % 60 == 0 ? '${onLength ~/ 60} h' : '${onLength ~/ 60} h ${onLength % 60} min';
    return SglCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SglCardHeader(
            title: 'Schedule',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SglInfoButton('schedule', size: 15),
                SglStatusChip(label: '$hours on', status: SglStatus.warn),
                if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right, color: c.ink3)],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_hhmm(onMinutes), style: SglTextStyles.reading.copyWith(color: c.ink, fontSize: 26)),
              Icon(Icons.arrow_forward, size: 18, color: c.ink3),
              Text(_hhmm(offMinutes), style: SglTextStyles.reading.copyWith(color: c.ink, fontSize: 26)),
            ],
          ),
          const SizedBox(height: 10),
          ScheduleTimeline(onMinutes: onMinutes, offMinutes: offMinutes, nowMinutes: now.hour * 60 + now.minute),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['00', '06', '12', '18', '24']
                .map((h) => Text(h, style: SglTextStyles.mono.copyWith(color: c.ink3, fontSize: 10.5)))
                .toList(),
          ),
          const SizedBox(height: 6),
          Text('Timer on the controller, shown in local time.', style: text.bodySmall!.copyWith(color: c.ink3)),
        ],
      ),
    );
  }

  static String _hhmm(int minutes) {
    final int m = ((minutes % 1440) + 1440) % 1440;
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }
}

/// A 0–100 % level (LED dim, blower duty) with a read-only bar.
class _LevelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? value;
  final String subtitle;
  final VoidCallback? onTap;

  const _LevelCard({required this.title, required this.icon, required this.value, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    final TextTheme text = Theme.of(context).textTheme;
    final bool available = value != null;
    return Opacity(
      opacity: available ? 1 : 0.6,
      child: SglCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: available ? c.amber : c.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(children: [
                    Flexible(child: Text(title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    SglInfoButton(title == 'LED dim' ? 'led_dim' : 'blower', size: 15),
                  ]),
                ),
                Text(available ? '$value %' : 'n/a', style: SglTextStyles.reading.copyWith(color: c.ink, fontSize: 24)),
                if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right, color: c.ink3)],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (value ?? 0) / 100.0,
                minHeight: 6,
                color: c.accent,
                backgroundColor: c.bg2,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: text.bodySmall!.copyWith(color: c.ink2)),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AlertsCard({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return SglCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, size: 20, color: enabled ? c.accent : c.ink3),
          const SizedBox(width: 8),
          Expanded(child: Text('Alerts', style: Theme.of(context).textTheme.titleMedium)),
          SglStatusChip(label: enabled ? 'on' : 'off', status: enabled ? SglStatus.ok : SglStatus.off),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: c.ink3),
        ],
      ),
    );
  }
}
