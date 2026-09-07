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
import 'package:super_green_app/data/rel/checklist/actions.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/l10n/common.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/app_bar/checklist/actions/checklist_action_page.dart';
import 'package:super_green_app/pages/feeds/home/plant_feeds/local/app_bar/checklist/appbar_checklist_bloc.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';
import 'package:tuple/tuple.dart';

/// Today's checklist items, or the call to action to create the checklist.
class LabChecklistCard extends StatelessWidget {
  const LabChecklistCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppbarChecklistBloc, AppbarChecklistBlocState>(
      builder: (BuildContext context, AppbarChecklistBlocState state) {
        if (state is! AppbarChecklistBlocStateLoaded) {
          return const SizedBox.shrink();
        }
        if (state.checklist == null) {
          return _create(context, state);
        }
        return _loaded(context, state);
      },
    );
  }

  Widget _create(BuildContext context, AppbarChecklistBlocStateLoaded state) {
    final SglColors c = context.sgl;
    return SglCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SglCardHeader(title: 'Checklist'),
          const SizedBox(height: 4),
          Text(
            'Reminders for watering, pH checks and the rest of the grow, tailored to this plant.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.ink2),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: () {
                if (state.requiresLogin) {
                  _login(context);
                } else {
                  BlocProvider.of<AppbarChecklistBloc>(context).add(AppbarChecklistBlocEventCreate());
                }
              },
              child: const Text('Create checklist'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loaded(BuildContext context, AppbarChecklistBlocStateLoaded state) {
    final SglColors c = context.sgl;
    final List<Tuple3<ChecklistSeed, ChecklistAction, ChecklistLog>> actions = state.actions ?? [];
    final int due = state.nPendingLogs;
    return SglCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              BlocProvider.of<MainNavigatorBloc>(context)
                  .add(MainNavigateToChecklist(state.plant, state.box, state.checklist!));
            },
            child: SglCardHeader(
              title: 'Checklist',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SglStatusChip(
                    label: due == 0 ? 'all clear' : '$due due',
                    status: due == 0 ? SglStatus.ok : SglStatus.warn,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: c.ink3),
                ],
              ),
            ),
          ),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Nothing for today. 👌',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.ink2)),
            )
          else
            ...actions.map((action) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ChecklistActionButton.getActionPage(
                    plant: state.plant,
                    box: state.box,
                    checklistSeed: action.item1,
                    checklistAction: action.item2,
                    summarize: true,
                    onCheck: () => BlocProvider.of<AppbarChecklistBloc>(context)
                        .add(AppbarChecklistBlocEventCheckChecklistLog(action.item3)),
                    onSkip: () => BlocProvider.of<AppbarChecklistBloc>(context)
                        .add(AppbarChecklistBlocEventSkipChecklistLog(action.item3)),
                  ),
                )),
        ],
      ),
    );
  }

  void _login(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(CommonL10N.loginRequiredDialogTitle),
            content: Text(CommonL10N.loginRequiredDialogBody),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(CommonL10N.cancel)),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(CommonL10N.loginCreateAccount)),
            ],
          );
        });
    if (confirm ?? false) {
      BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsAuth());
    }
  }
}
