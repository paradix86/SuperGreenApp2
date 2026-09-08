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
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/settings/devices/settings_devices_bloc.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:super_green_app/widgets/sgl/settings_group.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsDevicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsDevicesBloc, SettingsDevicesBlocState>(
      listener: (BuildContext context, SettingsDevicesBlocState state) {},
      child: BlocBuilder<SettingsDevicesBloc, SettingsDevicesBlocState>(
        bloc: BlocProvider.of<SettingsDevicesBloc>(context),
        builder: (BuildContext context, SettingsDevicesBlocState state) {
          Widget body = FullscreenLoading(
            title: 'Loading..',
          );

          if (state is SettingsDevicesBlocStateLoading) {
            body = FullscreenLoading(
              title: 'Loading..',
            );
          } else if (state is SettingsDevicesBlocStateNotEmptyBox) {
            body = Fullscreen(
              child: Icon(Icons.do_not_disturb, color: context.sgl.crit, size: 100),
              title: 'Cannot delete lab',
              subtitle: 'Move all plants to another box first.',
            );
          } else if (state is SettingsDevicesBlocStateLoaded) {
            if (state.devices.length == 0) {
              body = _renderNoController(context);
            } else {
              body = ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  SettingsGroup(
                    title: 'Controllers',
                    rows: state.devices.map((device) {
                      bool isScreenOnly = device.isScreen && device.isController == false;
                      return SettingsRow(
                        icon: isScreenOnly ? Icons.tv_outlined : Icons.memory_outlined,
                        title: device.name,
                        subtitle: isScreenOnly ? 'Screen · hold to delete' : 'Hold to delete',
                        trailing: SettingsRowChip(device.synced ? 'SYNCED' : 'LOCAL', on: device.synced),
                        onLongPress: () => _deleteBox(context, device),
                        onTap: () {
                          BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsDevice(device));
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }
          }
          return Scaffold(
              appBar: SGLAppBar(
                'Controllers',
                hideBackButton: !(state is SettingsDevicesBlocStateLoaded),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToAddDeviceEvent());
                    },
                    child: Icon(Icons.add, color: context.sgl.ink),
                  ),
                ],
              ),
              body: AnimatedSwitcher(duration: Duration(milliseconds: 200), child: body));
        },
      ),
    );
  }

  Widget _renderNoController(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            'You have no controller yet.',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          'Add a first',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        Text('CONTROLLER',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: context.sgl.accentDeep)),
                      ],
                    ),
                  ),
                  GreenButton(
                    title: 'ADD',
                    onPressed: () {
                      BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToAddDeviceEvent());
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GreenButton(
                        title: 'SHOP NOW',
                        onPressed: () {
                          launchUrl(Uri.parse('https://www.supergreenlab.com/bundle/micro-box-bundle'));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('/'),
                      ),
                      GreenButton(
                        title: 'DIY NOW',
                        onPressed: () {
                          launchUrl(Uri.parse('https://picofarmled.com/guide/how-to-setup-pico-farm-os'));
                        },
                      ),
                    ],
                  ),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  void _deleteBox(BuildContext context, Device device) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete device ${device.name}?'),
            content: Text('This can\'t be reverted. Continue?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text('NO'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text('YES'),
              ),
            ],
          );
        });
    if (confirm ?? false) {
      BlocProvider.of<SettingsDevicesBloc>(context).add(SettingsDevicesBlocEventDeleteDevice(device));
    }
  }
}
