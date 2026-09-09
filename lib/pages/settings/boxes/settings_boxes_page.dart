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
import 'package:super_green_app/pages/settings/boxes/settings_boxes_bloc.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:super_green_app/widgets/sgl/settings_group.dart';

class SettingsBoxesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBoxesBloc, SettingsBoxesBlocState>(
      listener: (BuildContext context, SettingsBoxesBlocState state) {},
      child: BlocBuilder<SettingsBoxesBloc, SettingsBoxesBlocState>(
        bloc: BlocProvider.of<SettingsBoxesBloc>(context),
        builder: (BuildContext context, SettingsBoxesBlocState state) {
          Widget body = FullscreenLoading(
            title: 'Loading..',
          );

          if (state is SettingsBoxesBlocStateLoading) {
            body = FullscreenLoading(
              title: 'Loading..',
            );
          } else if (state is SettingsBoxesBlocStateNotEmptyBox) {
            body = Fullscreen(
              child: Icon(Icons.do_not_disturb, color: context.sgl.crit, size: 100),
              title: 'Cannot delete lab',
              subtitle: 'Move all plants to another lab first.',
            );
          } else if (state is SettingsBoxesBlocStateLoaded) {
            if (state.boxes.length == 0) {
              body = _renderNoBox(context);
            } else {
              body = ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  SettingsGroup(
                    title: 'Labs',
                    rows: state.boxes.map((box) {
                      return SettingsRow(
                        icon: Icons.science_outlined,
                        title: box.name,
                        subtitle: 'Hold to delete',
                        trailing: SettingsRowChip(box.synced ? 'SYNCED' : 'LOCAL', on: box.synced),
                        onLongPress: () => _deleteBox(context, box),
                        onTap: () {
                          BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsBox(box));
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
                'Labs',
                hideBackButton: !(state is SettingsBoxesBlocStateLoaded),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToCreateBoxEvent());
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

  Widget _renderNoBox(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.science_outlined, size: 56, color: context.sgl.ink2),
            const SizedBox(height: 24),
            Text('No labs yet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('Create your first lab to get started', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToCreateBoxEvent());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create lab'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBox(BuildContext context, Box box) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete lab ${box.name}?'),
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
      BlocProvider.of<SettingsBoxesBloc>(context).add(SettingsBoxesBlocEventDeleteBox(box));
    }
  }
}
