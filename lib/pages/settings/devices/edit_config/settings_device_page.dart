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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/l10n/common.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/settings/devices/edit_config/settings_device_bloc.dart';
import 'package:super_green_app/pages/settings/devices/edit_config/widgets/settings_group.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsDevicePage extends StatelessWidget {
  static String get settingsDevicePageLoading {
    return Intl.message(
      'Refreshing..',
      name: 'settingsDevicePageLoading',
      desc: 'Loading screen while refreshing parameters',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String settingsDevicePageControllerDone(String name) {
    return Intl.message(
      'Controller $name updated!',
      args: [name],
      name: 'settingsDevicePageControllerDone',
      desc: 'Controller updated confirmation text',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageControllerNameSection {
    return Intl.message(
      'Controller name',
      name: 'settingsDevicePageControllerNameSection',
      desc: 'Controller name input section',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageControllerSettingsSection {
    return Intl.message(
      'Settings',
      name: 'settingsDevicePageControllerSettingsSection',
      desc: 'Controller name input section',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageWifiSettingsSection {
    return Intl.message(
      'Wifi config',
      name: 'settingsDevicePageWifiSettingsSection',
      desc: 'Wifi settings button',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageWifiSettingsLabel {
    return Intl.message(
      'Change your controller\'s wifi config',
      name: 'settingsDevicePageWifiSettingsLabel',
      desc: 'Wifi settings button label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageWifiConfigSuccess {
    return Intl.message(
      'Wifi config changed successfully',
      name: 'settingsDevicePageWifiConfigSuccess',
      desc: 'Wifi config successful message',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageWifiConfigFailed {
    return Intl.message(
      'Wifi config change failed',
      name: 'settingsDevicePageWifiConfigFailed',
      desc: 'Wifi config failed message',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageControllerStatusTitle {
    return Intl.message(
      'Controller status',
      name: 'settingsDevicePageControllerStatusTitle',
      desc: 'Controller status menu entry title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDevicePageControllerStatusLabel {
    return Intl.message(
      'Connectivity, memory, uptime and reboot diagnostics. Requires the controller to be reachable.',
      name: 'settingsDevicePageControllerStatusLabel',
      desc: 'Controller status menu entry label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  const SettingsDevicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsDeviceBloc, SettingsDeviceBlocState>(
      listener: (BuildContext context, SettingsDeviceBlocState state) {
        if (state is SettingsDeviceBlocStateLoaded && state.renamedTo != null) {
          _snack(context, settingsDevicePageControllerDone(state.renamedTo!));
        } else if (state is SettingsDeviceBlocStateUpdateFailed) {
          _snack(context, 'Rename failed, is the controller reachable?', error: true);
        } else if (state is SettingsDeviceBlocStateForgotten) {
          BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigatorActionPop(mustPop: true));
        }
      },
      child: BlocBuilder<SettingsDeviceBloc, SettingsDeviceBlocState>(
        builder: (BuildContext context, SettingsDeviceBlocState state) {
          final SettingsDeviceBlocStateLoaded? loaded = state is SettingsDeviceBlocStateLoaded ? state : null;
          return Scaffold(
            appBar: AppBar(
              title: _renderTitle(context, loaded),
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loaded == null ? FullscreenLoading(title: CommonL10N.loading) : _renderBody(context, loaded),
            ),
          );
        },
      ),
    );
  }

  Widget _renderTitle(BuildContext context, SettingsDeviceBlocStateLoaded? state) {
    final SglColors c = context.sgl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(state?.device.name ?? 'Device', maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          state == null
              ? 'DEVICE SETTINGS'
              : (state.isScreenOnly ? 'SCREEN SETTINGS' : 'CONTROLLER SETTINGS'),
          style: SglTextStyles.eyebrow.copyWith(color: c.ink3),
        ),
      ],
    );
  }

  Widget _renderBody(BuildContext context, SettingsDeviceBlocStateLoaded state) {
    final SglColors c = context.sgl;
    final Device device = state.device;
    final MainNavigatorBloc nav = BlocProvider.of<MainNavigatorBloc>(context);
    final SettingsDeviceBloc bloc = BlocProvider.of<SettingsDeviceBloc>(context);

    void reload() => bloc.add(SettingsDeviceBlocEventReload());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        SettingsGroup(
          title: 'Identity',
          rows: [
            SettingsRow(
              icon: Icons.badge_outlined,
              title: 'Name',
              subtitle: '${device.name} · ${state.mdnsDomain ?? device.mdns}.local',
              trailing: const SettingsRowAction('edit'),
              onTap: () => _rename(context, device.name),
            ),
            SettingsRow(
              icon: Icons.memory_outlined,
              title: 'Hardware',
              subtitle: state.isScreenOnly
                  ? 'Screen · ${device.identifier}'
                  : '${device.identifier} · ${device.nBoxes} box · ${device.nLeds} LED ch · ${device.nMotors} motors',
              trailing: const SettingsRowAction('copy'),
              onTap: () => _copy(context, device.identifier, 'Identifier copied'),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Connection',
          rows: [
            SettingsRow(
              icon: Icons.wifi,
              title: 'Wi-Fi',
              subtitle: state.wifiSsid ?? 'Network not known, tap to configure',
              onTap: () => nav.add(MainNavigateToDeviceWifiEvent(device, futureFn: (future) async {
                dynamic error = await future;
                reload();
                if (error == null) {
                  return;
                }
                _snack(context, error != true ? settingsDevicePageWifiConfigSuccess : settingsDevicePageWifiConfigFailed,
                    error: error == true);
              })),
            ),
            SettingsRow(
              icon: Icons.lan_outlined,
              title: 'Local address',
              subtitle: device.isReachable ? '${device.ip} · reachable' : '${device.ip} · not reachable right now',
              subtitleColor: device.isReachable ? null : c.warn,
              trailing: const SettingsRowAction('copy'),
              onTap: () => _copy(context, device.ip, 'Address copied'),
            ),
            if (!state.isScreenOnly)
              SettingsRow(
                icon: Icons.cloud_outlined,
                title: 'Remote control',
                subtitle: state.isPaired ? 'Paired · via SuperGreenLab broker' : 'Not paired, local network only',
                trailing: SettingsRowChip(state.isPaired ? 'paired' : 'off', on: state.isPaired),
                onTap: () => nav.add(MainNavigateToSettingsRemoteControl(device)),
              ),
            SettingsRow(
              icon: Icons.lock_outline,
              title: 'Password lock',
              subtitle: state.hasPassword ? 'Enabled on this phone' : 'Off · anyone on the Wi-Fi can change settings',
              trailing: SettingsRowChip(state.hasPassword ? 'on' : 'off', on: state.hasPassword),
              onTap: () => nav.add(MainNavigateToSettingsDeviceAuth(device)),
            ),
          ],
        ),
        if (!state.isScreenOnly)
          SettingsGroup(
            title: 'Ports',
            rows: [
              SettingsRow(
                icon: Icons.grid_view_outlined,
                title: 'Box slots',
                subtitle: '${device.nBoxes} slots · which box drives which plant',
                onTap: () => nav.add(MainNavigateToSelectDeviceBoxEvent(device)),
              ),
              SettingsRow(
                icon: Icons.settings_input_component_outlined,
                title: 'Motor ports',
                subtitle: '${device.nMotors} ports · fans, blowers and pumps',
                onTap: () => nav.add(MainNavigateToMotorPortEvent(device, null)),
              ),
            ],
          ),
        SettingsGroup(
          title: 'Firmware',
          rows: [
            SettingsRow(
              icon: Icons.system_update_alt_outlined,
              title: 'Update',
              subtitle: state.firmwareBuiltAt == null
                  ? 'Build date unknown · tap to check'
                  : 'Built ${DateFormat.yMMMd().format(state.firmwareBuiltAt!)} · tap to check',
              trailing: const SettingsRowAction('check'),
              onTap: () => nav.add(MainNavigateToSettingsUpgradeDevice(device, futureFn: (future) async {
                dynamic ret = await future;
                if (ret is bool && ret == true) {
                  nav.add(MainNavigateToRefreshParameters(device));
                }
                reload();
              })),
            ),
            SettingsRow(
              icon: Icons.monitor_heart_outlined,
              title: settingsDevicePageControllerStatusTitle,
              subtitle: 'Wi-Fi, MQTT, heap, uptime and reboot history',
              onTap: () => nav.add(MainNavigateToSettingsDeviceStatus(device)),
            ),
            SettingsRow(
              icon: Icons.sync_outlined,
              title: 'Refresh parameters',
              subtitle: '${state.nParams} keys in the app · re-read them all from the controller',
              onTap: () => nav.add(MainNavigateToRefreshParameters(device, futureFn: (future) async {
                await future;
                reload();
              })),
            ),
            SettingsRow(
              icon: Icons.terminal_outlined,
              title: 'Admin interface',
              subtitle: 'http://${device.ip}/fs/app.html · opens in the browser',
              trailing: const SettingsRowAction('open'),
              onTap: () => launchUrl(Uri.parse('http://${device.ip}/fs/app.html'), mode: LaunchMode.externalApplication),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Danger zone',
          rows: [
            SettingsRow(
              icon: Icons.delete_outline,
              title: 'Forget this device',
              subtitle: 'Removes it from the app only, the controller keeps running',
              titleColor: c.crit,
              iconColor: c.crit,
              onTap: () => _forget(context, device),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, String current) async {
    final SettingsDeviceBloc bloc = BlocProvider.of<SettingsDeviceBloc>(context);
    final TextEditingController controller = TextEditingController(text: current);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(settingsDevicePageControllerNameSection),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Ex: SuperGreenController'),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(CommonL10N.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Rename')),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == current) {
      return;
    }
    bloc.add(SettingsDeviceBlocEventUpdate(name));
  }

  Future<void> _forget(BuildContext context, Device device) async {
    final SettingsDeviceBloc bloc = BlocProvider.of<SettingsDeviceBloc>(context);
    final SglColors c = context.sgl;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Forget ${device.name}?'),
          content: const Text(
              'The controller is removed from this app and from your account. Plants in its boxes lose their controller. This can\'t be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(CommonL10N.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.crit, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Forget'),
            ),
          ],
        );
      },
    );
    if (confirm ?? false) {
      bloc.add(SettingsDeviceBlocEventForget());
    }
  }

  Future<void> _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      _snack(context, message);
    }
  }

  void _snack(BuildContext context, String message, {bool error = false}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? context.sgl.crit : null,
    ));
  }
}
