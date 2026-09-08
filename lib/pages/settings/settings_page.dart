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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/misc/screen_lock.dart';
import 'package:super_green_app/pages/settings/settings_bloc.dart';
import 'package:super_green_app/theme.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/sgl/settings_group.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    initPackageInfo();
  }

  Future<void> initPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
      Logger.log('APP VERSION: $version ($buildNumber)');
    });
  }

  void _createPinLock({bool isEdited = false }) {
    screenLockCreate(
      context: context,
      config: screenLockConfig,
      keyPadConfig: screenLockKeyPadConfig,
      cancelButton: const Icon(Icons.close, size: 36),
      title: isEdited
        ? const Text('Let\'s create a new PIN code')
        : const Text('Please enter PIN'),
      confirmTitle: Text('Great! Now confirm it'),
      onConfirmed: (value) {
        BlocProvider.of<SettingsBloc>(context).add(SettingsBlocEventSetPinLock(value));
        Navigator.of(context).pop();

        showSnackBar(context, isEdited
          ? 'All done! You can now use your new PIN code'
          : 'All done! The app is now protected with your PIN code'
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsBlocState>(
        bloc: BlocProvider.of<SettingsBloc>(context),
        builder: (context, state) => Scaffold(
              appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Settings')),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: <Widget>[
                  SettingsGroup(
                    title: 'Account',
                    rows: [
                      SettingsRow(
                        icon: Icons.person_outline,
                        title: 'SGL account',
                        subtitle: 'Backups, remote control, sharing',
                        onTap: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsAuth()),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Preferences',
                    rows: [
                      SettingsRow(
                        icon: Icons.straighten_outlined,
                        title: 'Units',
                        subtitle: state.freedomUnits ? 'Imperial · °F, in' : 'Metric · °C, cm',
                        trailing: SettingsRowAction(state.freedomUnits ? 'metric' : 'imperial'),
                        onTap: () => BlocProvider.of<SettingsBloc>(context)
                            .add(SettingsBlocEventSetFreedomUnit(!state.freedomUnits)),
                      ),
                      SettingsRow(
                        icon: Icons.pin_outlined,
                        title: 'PIN lock',
                        subtitle: state.pinLock.isEmpty ? 'Off · anyone can open the app' : 'On · asked at startup',
                        trailing: SettingsRowChip(state.pinLock.isEmpty ? 'off' : 'on', on: state.pinLock.isNotEmpty),
                        onTap: () => _onPinLockTapped(state),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Your garden',
                    rows: [
                      SettingsRow(
                        icon: Icons.local_florist_outlined,
                        title: 'Plants',
                        subtitle: 'Move to another lab, delete',
                        onTap: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsPlants()),
                      ),
                      SettingsRow(
                        icon: Icons.science_outlined,
                        title: 'Labs',
                        subtitle: 'Change controller, delete',
                        onTap: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsBoxes()),
                      ),
                      SettingsRow(
                        icon: Icons.developer_board_outlined,
                        title: 'Controllers',
                        subtitle: 'Wi-Fi, remote control, firmware',
                        onTap: () => BlocProvider.of<MainNavigatorBloc>(context).add(MainNavigateToSettingsDevices()),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Help',
                    rows: [
                      SettingsRow(
                        icon: Icons.chat_bubble_outline,
                        title: 'Send feedback',
                        subtitle: 'Opens your email app',
                        onTap: _sendFeedback,
                      ),
                      SettingsRow(
                        icon: Icons.description_outlined,
                        title: 'Send my logs',
                        subtitle: 'Attaches the app log file to an email',
                        onTap: _sendLogs,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Center(
                      child: Text(
                        'SUPERGREENAPP $version ($buildNumber)',
                        style: SglTextStyles.eyebrow.copyWith(color: context.sgl.ink3),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }

  void _onPinLockTapped(SettingsBlocState state) {
    if (state.pinLock.isEmpty) {
      _createPinLock(isEdited: false);
      return;
    }
    screenLock(
      context: context,
      config: screenLockConfig,
      keyPadConfig: screenLockKeyPadConfig,
      cancelButton: const Icon(Icons.close, size: 36),
      title: const Text('Please enter PIN'),
      correctString: state.pinLock,
      onUnlocked: () {
        Navigator.of(context).pop();
        final blocProvider = BlocProvider.of<SettingsBloc>(context);
        showModalBottomSheet<void>(
            context: context,
            isScrollControlled: false,
            useSafeArea: true,
            builder: (BuildContext context) {
              return Padding(
                padding: kPadding16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SglFilledGreenButton(
                      title: 'Change PIN code',
                      expanded: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _createPinLock(isEdited: true);
                      },
                    ),
                    context.vBox16,
                    SglOutlinedRedButton(
                      title: 'Remove PIN lock',
                      expanded: true,
                      onPressed: () {
                        Navigator.pop(context);
                        blocProvider.add(SettingsBlocEventSetPinLock(''));
                        showSnackBar(context, 'All done! PIN lock removed');
                      },
                    )
                  ],
                ),
              );
            });
      },
    );
  }

  Future<void> _sendFeedback() async {
    final Email email = Email(
      subject: 'App feedback',
      body: 'Hey guys,\n\nHere\' some feedback:\n\n\nCheers,\n',
      recipients: ['towelie@supergreenlab.com'],
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }

  Future<void> _sendLogs() async {
    File logFile = File(await Logger.logFilePath());
    final Directory tmpDir = await getTemporaryDirectory();
    String tmpLogFile = '${tmpDir.path}/log.txt';
    await logFile.copy(tmpLogFile);
    final Email email = Email(
      subject: 'Log file',
      body: 'Hey stant,\n\nhere\'s my log file\n\ncheers.',
      recipients: ['stant@supergreenlab.com'],
      attachmentPaths: [tmpLogFile],
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }
}
