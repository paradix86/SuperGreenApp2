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
import 'package:intl/intl.dart';
import 'package:super_green_app/device_daemon/device_daemon_bloc.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/pages/settings/devices/auth_modal/auth_modal_bloc.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/textfield.dart';

class AuthModalPage extends StatefulWidget {
  static String get authModalButton {
    return Intl.message(
      'NOTIFY ME',
      name: 'authModalButton',
      desc: 'Notification request button',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String authModalTitle(String name) {
    return Intl.message(
      'Controller $name requires authentication!',
      args: [name],
      name: 'authModalTitle',
      desc: 'Device auth modal form title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  @override
  _AuthModalPageState createState() => _AuthModalPageState();
}

class _AuthModalPageState extends State<AuthModalPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthModalBloc, AuthModalBlocState>(
      listener: (BuildContext context, AuthModalBlocState state) {
        if (state is AuthModalBlocStateDone) {
          BlocProvider.of<DeviceDaemonBloc>(context).add(DeviceDaemonBlocEventLoggedIn(state.device));
        }
      },
      child: BlocBuilder<AuthModalBloc, AuthModalBlocState>(
        builder: (BuildContext context, AuthModalBlocState state) {
          if (state is AuthModalBlocStateInit) {
            return Container(height: 345, child: FullscreenLoading());
          } else if (state is AuthModalBlocStateDone) {
            return Container(
              height: 345,
              child: Fullscreen(
                title: 'Done',
                child: Icon(
                  Icons.check,
                  color: context.sgl.accentDeep,
                  size: 100,
                ),
              ),
            );
          }
          return renderForm(context, state as AuthModalBlocStateLoaded);
        },
      ),
    );
  }

  Widget renderForm(BuildContext context, AuthModalBlocStateLoaded state) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 28, color: context.sgl.ink2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AuthModalPage.authModalTitle(state.device.name),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Username', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SGLTextField(
                    hintText: 'Ex: stant',
                    controller: _usernameController,
                    textCapitalization: TextCapitalization.none,
                    onChanged: (_) {
                      setState(() {});
                    }),
                const SizedBox(height: 16),
                Text('Password', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SGLTextField(
                    hintText: '***',
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (_) {
                      setState(() {});
                    }),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isValid()
                      ? () {
                          BlocProvider.of<AuthModalBloc>(context).add(AuthModalBlocEventAuth(
                              username: _usernameController.text, password: _passwordController.text));
                        }
                      : null,
                  child: const Text('Log in'),
                ),
              ]),
        ),
      ),
    );
  }

  bool isValid() {
    return _usernameController.text.length >= 4 && _passwordController.text.length >= 4;
  }
}
