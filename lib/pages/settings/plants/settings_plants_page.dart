import 'package:flutter/material.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/pages/settings/plants/settings_plants_bloc.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:super_green_app/widgets/sgl/settings_group.dart';

class SettingsPlantsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsPlantsBloc, SettingsPlantsBlocState>(
      listener: (BuildContext context, SettingsPlantsBlocState state) {},
      child: BlocBuilder<SettingsPlantsBloc, SettingsPlantsBlocState>(
        bloc: BlocProvider.of<SettingsPlantsBloc>(context),
        builder: (BuildContext context, SettingsPlantsBlocState state) {
          Widget body = FullscreenLoading(
            title: 'Loading..',
          );

          if (state is SettingsPlantsBlocStateLoading) {
            body = FullscreenLoading(
              title: 'Loading..',
            );
          } else if (state is SettingsPlantsBlocStateLoaded) {
            if (state.plants.length == 0) {
              body = _renderNoPlant(context);
            } else {
              body = ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: state.boxes.length,
                itemBuilder: (BuildContext context, int index) {
                  Box box = state.boxes[index];
                  List<Plant> plants = state.plants.where((p) => p.box == box.id).toList();
                  if (plants.isEmpty) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SettingsGroup(
                      title: box.name,
                      rows: plants.map((p) {
                        return SettingsRow(
                          icon: Icons.eco_outlined,
                          title: p.name,
                          subtitle: 'Hold to delete',
                          trailing: SettingsRowChip(p.synced ? 'SYNCED' : 'LOCAL', on: p.synced),
                          onLongPress: () => _deletePlant(context, p),
                          onTap: () {
                            BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsPlant(p));
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            }
          }
          return Scaffold(
              appBar: SGLAppBar(
                'Plants',
                hideBackButton: !(state is SettingsPlantsBlocStateLoaded),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToCreatePlantEvent());
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

  Widget _renderNoPlant(BuildContext context) {
    return Column(
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
                    child: Text('You have no plant yet.', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  Text('Add your first', style: Theme.of(context).textTheme.bodyLarge),
                  Text('PLANT', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: context.sgl.accentDeep)),
                ],
              ),
            ),
            GreenButton(
              title: 'START',
              onPressed: () {
                BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToCreatePlantEvent());
              },
            ),
          ],
        )),
      ],
    );
  }

  void _deletePlant(BuildContext context, Plant plant) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete plant ${plant.name}?'),
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
      BlocProvider.of<SettingsPlantsBloc>(context).add(SettingsPlantsBlocEventDeletePlant(plant));
    }
  }
}
