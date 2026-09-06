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
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/misc/bloc.dart';
import 'package:super_green_app/data/api/device/device_api.dart';
import 'package:super_green_app/data/api/device/device_helper.dart';
import 'package:super_green_app/data/api/device/ota_wait.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/main/main_navigator_bloc.dart';

abstract class SettingsUpgradeDeviceBlocEvent extends Equatable {}

class SettingsUpgradeDeviceBlocEventInit extends SettingsUpgradeDeviceBlocEvent {
  @override
  List<Object> get props => [];
}

class SettingsUpgradeDeviceBlocEventUpgrade extends SettingsUpgradeDeviceBlocEvent {
  @override
  List<Object> get props => [];
}

class SettingsUpgradeDeviceBlocEventUpgrading extends SettingsUpgradeDeviceBlocEvent {
  final String progressMessage;

  SettingsUpgradeDeviceBlocEventUpgrading(this.progressMessage);

  @override
  List<Object> get props => [progressMessage];
}

class SettingsUpgradeDeviceBlocEventCheckUpgradeDone extends SettingsUpgradeDeviceBlocEvent {
  final int rand = Random().nextInt(1 << 32);

  SettingsUpgradeDeviceBlocEventCheckUpgradeDone();

  @override
  List<Object> get props => [rand];
}

abstract class SettingsUpgradeDeviceBlocState extends Equatable {}

class SettingsUpgradeDeviceBlocStateInit extends SettingsUpgradeDeviceBlocState {
  @override
  List<Object> get props => [];
}

class SettingsUpgradeDeviceBlocStateLoaded extends SettingsUpgradeDeviceBlocState {
  final bool needsUpgrade;

  SettingsUpgradeDeviceBlocStateLoaded(this.needsUpgrade);

  @override
  List<Object> get props => [needsUpgrade];
}

class SettingsUpgradeDeviceBlocStateUpgrading extends SettingsUpgradeDeviceBlocState {
  final String progressMessage;

  SettingsUpgradeDeviceBlocStateUpgrading(this.progressMessage);

  @override
  List<Object> get props => [progressMessage];
}

class SettingsUpgradeDeviceBlocStateUpgradeDone extends SettingsUpgradeDeviceBlocState {
  SettingsUpgradeDeviceBlocStateUpgradeDone();

  @override
  List<Object> get props => [];
}

enum UpgradeErrorKind {
  /// Never got a reply from the controller after the upload.
  unreachable,

  /// The controller reported OTA_STATUS=3 (bad download, sha256 mismatch,
  /// or a rejected request while backing off after earlier failures).
  failed,

  /// The controller reported OTA_STATUS=2.
  disabled,

  /// Preparing the upgrade (uploading web app, setting OTA_* params) failed.
  setup,
}

class SettingsUpgradeDeviceBlocStateUpgradeError extends SettingsUpgradeDeviceBlocState {
  final UpgradeErrorKind kind;

  SettingsUpgradeDeviceBlocStateUpgradeError(this.kind);

  @override
  List<Object> get props => [kind];
}

class UpgradeException implements Exception {
  final UpgradeErrorKind kind;

  UpgradeException(this.kind);

  @override
  String toString() => 'UpgradeException($kind)';
}

class SettingsUpgradeDeviceBloc extends LegacyBloc<SettingsUpgradeDeviceBlocEvent, SettingsUpgradeDeviceBlocState> {
  /// After firmware.bin is served: 24 polls x 5 s. Flashing 1 MB over WiFi,
  /// rebooting and coming back on the network fits well inside that.
  static const int waitPolls = 24;
  static const Duration waitPollInterval = Duration(seconds: 5);

  final MainNavigateToSettingsUpgradeDevice args;

  HttpServer? server;

  late Param otaTimestamp;

  SettingsUpgradeDeviceBloc(this.args) : super(SettingsUpgradeDeviceBlocStateInit()) {
    add(SettingsUpgradeDeviceBlocEventInit());
  }

  @override
  Stream<SettingsUpgradeDeviceBlocState> mapEventToState(SettingsUpgradeDeviceBlocEvent event) async* {
    if (event is SettingsUpgradeDeviceBlocEventInit) {
      otaTimestamp = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_TIMESTAMP');
      Param otaBaseDir = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_BASEDIR');

      String localOTATimestamp = await rootBundle.loadString('assets/firmware${otaBaseDir.svalue}/timestamp');
      yield SettingsUpgradeDeviceBlocStateLoaded(int.parse(localOTATimestamp) > otaTimestamp.ivalue!);
    } else if (event is SettingsUpgradeDeviceBlocEventUpgrade) {
      yield SettingsUpgradeDeviceBlocStateUpgrading('Setting parameters..');
      try {
        yield* _startUpgrade();
      } on UpgradeException catch (e) {
        yield SettingsUpgradeDeviceBlocStateUpgradeError(e.kind);
      } catch (e, trace) {
        Logger.logError(e, trace, data: {"ip": args.device.ip, "deviceID": args.device.identifier});
        yield SettingsUpgradeDeviceBlocStateUpgradeError(UpgradeErrorKind.setup);
      }
    } else if (event is SettingsUpgradeDeviceBlocEventUpgrading) {
      yield SettingsUpgradeDeviceBlocStateUpgrading(event.progressMessage);
    } else if (event is SettingsUpgradeDeviceBlocEventCheckUpgradeDone) {
      yield SettingsUpgradeDeviceBlocStateUpgrading('Firmware sent, waiting for controller..');
      try {
        await waitFirmwareUpgraded();
        yield SettingsUpgradeDeviceBlocStateUpgradeDone();
      } on UpgradeException catch (e) {
        yield SettingsUpgradeDeviceBlocStateUpgradeError(e.kind);
      } catch (e, trace) {
        Logger.logError(e, trace, data: {"ip": args.device.ip, "deviceID": args.device.identifier});
        yield SettingsUpgradeDeviceBlocStateUpgradeError(UpgradeErrorKind.unreachable);
      }
    }
  }

  Stream<SettingsUpgradeDeviceBlocState> _startUpgrade() async* {
    String? auth = AppDB().getDeviceAuth(args.device.identifier);
    Param otaServerIP = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_SERVER_IP');
    Param otaServerPort = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_SERVER_PORT');
    String myip = await DeviceAPI.fetchString('http://${args.device.ip}/myip', auth: auth);

    Param otaBaseDir = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_BASEDIR');
    ByteData config = await rootBundle.load('assets/firmware${otaBaseDir.svalue}/html_app/config.json');
    await DeviceAPI.uploadFile(args.device.ip, 'config.json', config, auth: auth);
    ByteData htmlApp = await rootBundle.load('assets/firmware${otaBaseDir.svalue}/html_app/app.html');
    await DeviceAPI.uploadFile(args.device.ip, 'app.html', htmlApp, auth: auth);

    server = await HttpServer.bind(InternetAddress.anyIPv6, 0);
    server!.listen(listenRequest);

    await Future.delayed(Duration(seconds: 1));
    await DeviceHelper.updateStringParam(args.device, otaServerIP, myip, forceLocal: true);
    await DeviceHelper.updateIntParam(args.device, otaServerPort, server!.port, forceLocal: true);

    Param? start;
    try {
      start = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_START');
    } catch (e) {
      // older firmware without OTA_START: fall back to a reboot, the
      // controller checks the OTA server at boot
    }
    if (start != null) {
      await DeviceHelper.updateIntParam(args.device, start, 1, nRetries: 1, forceLocal: true);
      // OTA_STATUS=3 right after OTA_START=1 means the request itself was
      // rejected (backoff after earlier failures): no point waiting for a
      // download that will not start.
      int? status = await _readOtaStatus(auth);
      if (status == OtaStatus.failed) {
        throw UpgradeException(UpgradeErrorKind.failed);
      } else if (status == OtaStatus.disabled) {
        throw UpgradeException(UpgradeErrorKind.disabled);
      }
    } else {
      Param reboot = await RelDB.get().devicesDAO.getParam(args.device.id, 'REBOOT');
      yield SettingsUpgradeDeviceBlocStateUpgrading('Rebooting controller..');
      try {
        await DeviceHelper.updateIntParam(args.device, reboot, 1, nRetries: 1, forceLocal: true);
      } catch (e, trace) {
        // the controller usually drops the connection while rebooting
        Logger.logError(e, trace, data: {"ip": args.device.ip, "step": "REBOOT"});
      }
    }
    yield SettingsUpgradeDeviceBlocStateUpgrading('Waiting controller connection..');
  }

  void listenRequest(HttpRequest request) async {
    final String path = request.requestedUri.pathSegments.last;
    if (path == 'last_timestamp') {
      add(SettingsUpgradeDeviceBlocEventUpgrading('Controller connected'));
      Param otaBaseDir = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_BASEDIR');
      String localOTATimestamp = await rootBundle.loadString('assets/firmware${otaBaseDir.svalue}/timestamp');
      request.response.statusCode = 200;
      request.response.write(localOTATimestamp);
      await request.response.flush();
      await request.response.close();
      return;
    } else if (path == 'firmware.bin.sha256') {
      // The controller fetches this before firmware.bin and refuses to boot a
      // download whose hash does not match; without it the flash is unverified.
      Param otaBaseDir = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_BASEDIR');
      ByteData firmwareBin = await rootBundle.load('assets/firmware${otaBaseDir.svalue}/firmware.bin');
      String hash = sha256.convert(firmwareBin.buffer.asUint8List()).toString();
      request.response.statusCode = 200;
      request.response.write('$hash\n');
      await request.response.flush();
      await request.response.close();
      return;
    } else if (path == 'firmware.bin') {
      add(SettingsUpgradeDeviceBlocEventUpgrading('Downloading firmware..'));
      Param otaBaseDir = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_BASEDIR');
      ByteData firmwareBin = await rootBundle.load('assets/firmware${otaBaseDir.svalue}/firmware.bin');
      request.response.statusCode = 200;
      request.response.add(firmwareBin.buffer.asInt8List());
      await request.response.flush();
      await request.response.close();
      await Future.delayed(Duration(seconds: 10));
      add(SettingsUpgradeDeviceBlocEventCheckUpgradeDone());
      return;
    }
    request.response.statusCode = 404;
    request.response.write('Page not found');
    await request.response.close();
  }

  /// null when the controller is unreachable (rebooting) or predates OTA_STATUS.
  Future<int?> _readOtaStatus(String? auth) async {
    try {
      return await DeviceAPI.fetchIntParam(args.device.ip, 'OTA_STATUS', timeout: 5, nRetries: 1, auth: auth);
    } catch (e) {
      return null;
    }
  }

  Future<int?> _readOtaTimestamp(String? auth) async {
    try {
      return await DeviceAPI.fetchIntParam(args.device.ip, 'OTA_TIMESTAMP', timeout: 5, nRetries: 1, auth: auth);
    } catch (e) {
      return null;
    }
  }

  Future<void> waitFirmwareUpgraded() async {
    Param otaBaseDir = await RelDB.get().devicesDAO.getParam(args.device.id, 'OTA_BASEDIR');
    String localOTATimestamp = await rootBundle.loadString('assets/firmware${otaBaseDir.svalue}/timestamp');
    int ts = int.parse(localOTATimestamp);
    String? auth = AppDB().getDeviceAuth(args.device.identifier);
    for (int i = 0; i < waitPolls; ++i) {
      await Future.delayed(waitPollInterval);
      int? status = await _readOtaStatus(auth);
      int? timestamp = await _readOtaTimestamp(auth);
      switch (evaluateOtaWait(otaStatus: status, otaTimestamp: timestamp, targetTimestamp: ts)) {
        case OtaWaitDecision.done:
          return;
        case OtaWaitDecision.failed:
          throw UpgradeException(UpgradeErrorKind.failed);
        case OtaWaitDecision.disabled:
          throw UpgradeException(UpgradeErrorKind.disabled);
        case OtaWaitDecision.keepWaiting:
          if (status == OtaStatus.inProgress) {
            add(SettingsUpgradeDeviceBlocEventUpgrading('Controller is flashing the firmware..'));
          }
          break;
      }
    }
    Logger.logError('OTA_TIMESTAMP never reached $ts', null,
        data: {"ip": args.device.ip, "deviceID": args.device.identifier});
    throw UpgradeException(UpgradeErrorKind.unreachable);
  }

  @override
  Future<void> close() async {
    await server?.close(force: true);
    return super.close();
  }
}
