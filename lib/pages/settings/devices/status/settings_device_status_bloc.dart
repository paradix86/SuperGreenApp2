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

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:super_green_app/data/api/device/device_api.dart';
import 'package:super_green_app/data/api/device/device_status.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/misc/bloc.dart';

abstract class SettingsDeviceStatusBlocEvent extends Equatable {}

class SettingsDeviceStatusBlocEventInit extends SettingsDeviceStatusBlocEvent {
  @override
  List<Object> get props => [];
}

class SettingsDeviceStatusBlocEventRefresh extends SettingsDeviceStatusBlocEvent {
  @override
  List<Object> get props => [];
}

enum SettingsDeviceStatusErrorKind {
  unreachable,
  unsupported,
  failed,
}

abstract class SettingsDeviceStatusBlocState extends Equatable {}

class SettingsDeviceStatusBlocStateInit extends SettingsDeviceStatusBlocState {
  @override
  List<Object> get props => [];
}

class SettingsDeviceStatusBlocStateLoading extends SettingsDeviceStatusBlocState {
  @override
  List<Object> get props => [];
}

class SettingsDeviceStatusBlocStateLoaded extends SettingsDeviceStatusBlocState {
  final DeviceStatus status;
  final DateTime fetchedAt;

  SettingsDeviceStatusBlocStateLoaded(this.status, this.fetchedAt);

  @override
  List<Object> get props => [status, fetchedAt];
}

class SettingsDeviceStatusBlocStateError extends SettingsDeviceStatusBlocState {
  final SettingsDeviceStatusErrorKind kind;
  final String? details;

  SettingsDeviceStatusBlocStateError(this.kind, {this.details});

  @override
  List<Object?> get props => [kind, details];
}

class SettingsDeviceStatusBloc extends LegacyBloc<SettingsDeviceStatusBlocEvent, SettingsDeviceStatusBlocState> {
  static const String MQTTDIAG_PATH = '/mqttdiag';

  final MainNavigateToSettingsDeviceStatus args;

  SettingsDeviceStatusBloc(this.args) : super(SettingsDeviceStatusBlocStateInit()) {
    add(SettingsDeviceStatusBlocEventInit());
  }

  @override
  Stream<SettingsDeviceStatusBlocState> mapEventToState(SettingsDeviceStatusBlocEvent event) async* {
    if (event is SettingsDeviceStatusBlocEventInit || event is SettingsDeviceStatusBlocEventRefresh) {
      yield SettingsDeviceStatusBlocStateLoading();
      yield await _load();
    }
  }

  Future<SettingsDeviceStatusBlocState> _load() async {
    if (!args.device.isReachable) {
      return SettingsDeviceStatusBlocStateError(SettingsDeviceStatusErrorKind.unreachable);
    }
    String? auth = AppDB().getDeviceAuth(args.device.identifier);
    String body;
    try {
      body = await DeviceAPI.fetchString('http://${args.device.ip}$MQTTDIAG_PATH', auth: auth, nRetries: 1);
    } catch (e) {
      if (_isNotFound(e)) {
        return SettingsDeviceStatusBlocStateError(SettingsDeviceStatusErrorKind.unsupported);
      }
      return SettingsDeviceStatusBlocStateError(SettingsDeviceStatusErrorKind.failed, details: e.toString());
    }
    return _parse(body);
  }

  SettingsDeviceStatusBlocState _parse(String body) {
    if (body.trim().isEmpty) {
      return SettingsDeviceStatusBlocStateError(SettingsDeviceStatusErrorKind.unsupported);
    }
    try {
      dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return SettingsDeviceStatusBlocStateError(SettingsDeviceStatusErrorKind.failed, details: 'Unexpected payload');
      }
      return SettingsDeviceStatusBlocStateLoaded(DeviceStatus.fromJson(decoded), DateTime.now());
    } catch (e, trace) {
      Logger.logError(e, trace, data: {"ip": args.device.ip, "deviceID": args.device.identifier});
      return SettingsDeviceStatusBlocStateError(SettingsDeviceStatusErrorKind.failed, details: e.toString());
    }
  }

  // DeviceAPI.fetchString throws the plain string 'Device request error: <code>' on non-2xx responses.
  static bool _isNotFound(dynamic error) {
    return error.toString().contains('Device request error: 404');
  }
}
