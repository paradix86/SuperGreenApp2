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

import 'package:equatable/equatable.dart';
import 'package:super_green_app/data/api/device/device_helper.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/kv/models/device_data.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';
import 'package:super_green_app/misc/bloc.dart';

abstract class SettingsDeviceBlocEvent extends Equatable {}

class SettingsDeviceBlocEventInit extends SettingsDeviceBlocEvent {
  @override
  List<Object> get props => [];
}

/// Re-read the device row and its params (after a sub-page popped).
class SettingsDeviceBlocEventReload extends SettingsDeviceBlocEvent {
  final int rand = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object> get props => [rand];
}

class SettingsDeviceBlocEventUpdate extends SettingsDeviceBlocEvent {
  final String name;

  SettingsDeviceBlocEventUpdate(this.name);

  @override
  List<Object> get props => [name];
}

/// Remove the device from the app only (the controller keeps running).
class SettingsDeviceBlocEventForget extends SettingsDeviceBlocEvent {
  @override
  List<Object> get props => [];
}

abstract class SettingsDeviceBlocState extends Equatable {}

class SettingsDeviceBlocStateLoading extends SettingsDeviceBlocState {
  @override
  List<Object> get props => [];
}

/// What the settings screen shows for one device. Every optional field is
/// null when the param is missing from the local db.
class SettingsDeviceBlocStateLoaded extends SettingsDeviceBlocState {
  final Device device;
  final String? wifiSsid;
  final String? mdnsDomain;

  /// Firmware build time, from OTA_TIMESTAMP.
  final DateTime? firmwareBuiltAt;
  final int nParams;
  final bool isPaired;
  final bool hasPassword;

  /// Set once after a successful rename, cleared on the next reload.
  final String? renamedTo;

  SettingsDeviceBlocStateLoaded(
    this.device, {
    this.wifiSsid,
    this.mdnsDomain,
    this.firmwareBuiltAt,
    this.nParams = 0,
    this.isPaired = false,
    this.hasPassword = false,
    this.renamedTo,
  });

  bool get isScreenOnly => device.isScreen && device.isController == false;

  @override
  List<Object?> get props => [device, wifiSsid, mdnsDomain, firmwareBuiltAt, nParams, isPaired, hasPassword, renamedTo];
}

/// Rename failed (controller unreachable, ...). The screen shows a snackbar
/// and stays on the loaded state that follows.
class SettingsDeviceBlocStateUpdateFailed extends SettingsDeviceBlocState {
  final int rand = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object> get props => [rand];
}

class SettingsDeviceBlocStateForgotten extends SettingsDeviceBlocState {
  final String name;

  SettingsDeviceBlocStateForgotten(this.name);

  @override
  List<Object> get props => [name];
}

class SettingsDeviceBloc extends LegacyBloc<SettingsDeviceBlocEvent, SettingsDeviceBlocState> {
  final MainNavigateToSettingsDevice args;

  SettingsDeviceBloc(this.args) : super(SettingsDeviceBlocStateLoading()) {
    add(SettingsDeviceBlocEventInit());
  }

  @override
  Stream<SettingsDeviceBlocState> mapEventToState(SettingsDeviceBlocEvent event) async* {
    if (event is SettingsDeviceBlocEventInit || event is SettingsDeviceBlocEventReload) {
      yield await _load();
    } else if (event is SettingsDeviceBlocEventUpdate) {
      yield SettingsDeviceBlocStateLoading();
      try {
        await DeviceHelper.updateDeviceName(args.device, event.name);
        yield await _load(renamedTo: event.name);
      } catch (e, trace) {
        Logger.logError(e, trace, data: {'deviceID': args.device.identifier});
        yield SettingsDeviceBlocStateUpdateFailed();
        yield await _load();
      }
    } else if (event is SettingsDeviceBlocEventForget) {
      yield SettingsDeviceBlocStateLoading();
      final String name = args.device.name;
      await DeviceHelper.deleteDevice(args.device);
      yield SettingsDeviceBlocStateForgotten(name);
    }
  }

  Future<SettingsDeviceBlocStateLoaded> _load({String? renamedTo}) async {
    final RelDB db = RelDB.get();
    final Device device = await db.devicesDAO.getDevice(args.device.id);
    final DeviceData deviceData = AppDB().getDeviceData(device.identifier);
    final List<Param> params = await db.devicesDAO.getParams(device.id);
    final Map<String, Param> byKey = {for (final Param p in params) p.key: p};
    final int? otaTimestamp = byKey['OTA_TIMESTAMP']?.ivalue;
    return SettingsDeviceBlocStateLoaded(
      device,
      wifiSsid: _nonEmpty(byKey['WIFI_SSID']?.svalue),
      mdnsDomain: _nonEmpty(byKey['MDNS_DOMAIN']?.svalue) ?? _nonEmpty(device.mdns),
      firmwareBuiltAt:
          otaTimestamp == null || otaTimestamp <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(otaTimestamp * 1000),
      nParams: params.length,
      isPaired: deviceData.signing != null && deviceData.signing!.isNotEmpty,
      hasPassword: deviceData.auth != null && deviceData.auth!.isNotEmpty,
      renamedTo: renamedTo,
    );
  }

  static String? _nonEmpty(String? value) => value == null || value.isEmpty ? null : value;
}
