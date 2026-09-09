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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:super_green_app/data/api/backend/backend_api.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/misc/permissions.dart';
import 'package:super_green_app/notifications/notifications.dart';
import 'package:super_green_app/pages/feed_entries/common/widgets/user_avatar.dart';
import 'package:super_green_app/pages/image_picker/picker_widget.dart';
import 'package:super_green_app/pages/settings/auth/delete_account/delete_account_bloc.dart';
import 'package:super_green_app/pages/settings/auth/delete_account/delete_account_page.dart';
import 'package:super_green_app/pages/settings/auth/settings_auth_bloc.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

class SettingsAuthPage extends StatefulWidget {
  @override
  _SettingsAuthPageState createState() => _SettingsAuthPageState();
}

class _SettingsAuthPageState extends State<SettingsAuthPage> {
  bool _syncOverGSM = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsAuthBloc, SettingsAuthBlocState>(
      listener: (BuildContext context, SettingsAuthBlocState state) {
        if (state is SettingsAuthBlocStateLoaded) {
          setState(() {
            _syncOverGSM = state.syncOverGSM;
          });
        } else if (state is SettingsAuthBlocStateDone) {
          Timer(Duration(seconds: 2), () {
            BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigatorActionPop());
          });
        }
      },
      child: BlocBuilder<SettingsAuthBloc, SettingsAuthBlocState>(
        bloc: BlocProvider.of<SettingsAuthBloc>(context),
        builder: (BuildContext context, SettingsAuthBlocState state) {
          Widget body = FullscreenLoading(
            title: 'Loading..',
          );

          if (state is SettingsAuthBlocStateLoading) {
            body = FullscreenLoading(
              title: 'Loading..',
            );
          } else if (state is SettingsAuthBlocStateLoaded) {
            if (state.isAuth) {
              body = _renderAuthBody(context, state);
            } else {
              body = _renderUnauthBody(context, state);
            }
          } else if (state is SettingsAuthBlocStateDone) {
            body = Fullscreen(
              title: 'Done!',
              child: Icon(
                Icons.check,
                color: context.sgl.accentDeep,
                size: 100,
              ),
            );
          } else if (state is SettingsAuthBlocStateError) {
            body = Fullscreen(
              title: state.message,
              child: Icon(
                Icons.error,
                color: context.sgl.crit,
                size: 100,
              ),
            );
          }
          return Scaffold(
              appBar: SGLAppBar(
                'SGL account',
                hideBackButton: !(state is SettingsAuthBlocStateLoaded),
              ),
              body: AnimatedSwitcher(duration: Duration(milliseconds: 200), child: body));
        },
      ),
    );
  }

  Widget _renderAuthBody(BuildContext context, SettingsAuthBlocStateLoaded state) {
    String? pic = state.user?.pic;
    if (pic != null) {
      pic = BackendAPI().feedsAPI.absoluteFileURL(pic);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Permissions.checkCapturePermissions().then((granted) {
                      if (!granted) return;
                      _buildPicker(context);
                    });
                  },
                  child: Column(
                    children: [
                      UserAvatar(icon: pic, size: 120),
                      const SizedBox(height: 8),
                      Text(
                        "Tap to change",
                        style: TextStyle(color: context.sgl.info, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connected to your SGL account',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                state.user != null
                    ? Text(state.user!.nickname ?? 'User', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 8),
                          const Text('Loading user data..', style: TextStyle(fontSize: 13))
                        ],
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _renderOptionCheckbx(context, 'Sync over mobile data too', (bool? newValue) {
              setState(() {
                _syncOverGSM = newValue ?? false;
                BlocProvider.of<SettingsAuthBloc>(context).add(SettingsAuthBlocEventSetSyncedOverGSM(_syncOverGSM));
              });
            }, _syncOverGSM == true),
          ),
        ),
        const SizedBox(height: 12),
        if (!state.notificationEnabled)
          FilledButton(
            onPressed: () {
              BlocProvider.of<NotificationsBloc>(context).add(NotificationsBlocEventRequestPermission());
            },
            child: const Text('Enable notifications'),
          ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () { _requestDelete(context); },
          style: TextButton.styleFrom(foregroundColor: context.sgl.crit),
          child: const Text('Request account deletion'),
        ),
      ],
    );
  }

  Widget _renderUnauthBody(BuildContext context, SettingsAuthBlocStateLoaded state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Text(
              'Sign in or create a new account',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsLogin(futureFn: (future) async {
                  dynamic res = await future;
                  if (res == true) {
                    BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigatorActionPop(param: res));
                  }
                }));
              },
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('Log in'),
            ),
            const SizedBox(height: 16),
            Text(
              'or',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                BlocProvider.of<MainNavigatorBloc>(context)
                    .add(MainNavigateToSettingsCreateAccount(futureFn: (future) async {
                  dynamic res = await future;
                  if (res == true) {
                    BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigatorActionPop(param: res));
                  }
                }));
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('Create account'),
            )
          ],
        ),
      ),
    );
  }

  Widget _renderOptionCheckbx(BuildContext context, String text, Function(bool?) onChanged, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          onChanged: onChanged,
          value: value,
        ),
        InkWell(
          onTap: () {
            onChanged(!value);
          },
          child: MarkdownBody(
            fitContent: true,
            data: text,
            styleSheet: MarkdownStyleSheet(p: TextStyle(color: context.sgl.ink2, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  void _buildPicker(BuildContext context) {
    showModalBottomSheet<Set<MediaFile>>(
      context: context,
      builder: (BuildContext c) {
        return PickerWidget(
          withImages: true,
          withVideos: true,
          multiple: false,
          onDone: (Set<MediaFile?> selectedFiles) {
            Timer(Duration(milliseconds: 500), () {
              BlocProvider.of<SettingsAuthBloc>(context)
                  .add(SettingsAuthBlocEventUpdatePic(File(selectedFiles.toList()[0]!.path)));
            });
            Navigator.pop(c);
          },
          onCancel: () {
            Navigator.pop(c);
          },
        );
      },
    );
  }

  void _requestDelete(BuildContext pageContext) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return BlocProvider(
            create: (context) => DeleteAccountBloc(),
            child: DeleteAccountPage(onDone: () {
              //BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigatorActionPop());
              BlocProvider.of<SettingsAuthBloc>(pageContext).add(SettingsAuthBlocEventInit());
            }),
          );
        });
  }
}
