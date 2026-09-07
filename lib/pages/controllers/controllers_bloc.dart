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

import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:super_green_app/data/api/device/dash_history.dart';
import 'package:super_green_app/data/api/device/device_api.dart';
import 'package:super_green_app/data/api/device/device_dash.dart';
import 'package:super_green_app/data/api/device/device_status.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/data/rel/rel_db.dart';
import 'package:super_green_app/misc/bloc.dart';

/// A box driven by a controller, with the plants living in it and the last
/// readings the daemon wrote to the db.
class ControllerBox {
  final Box box;
  final List<String> plantNames;
  final int? temp;
  final int? humi;

  const ControllerBox({required this.box, required this.plantNames, this.temp, this.humi});
}

/// Everything the Controllers screen shows for one controller.
class ControllerEntry {
  final Device device;
  final List<ControllerBox> boxes;

  /// Last `/mqttdiag` reply, null until the first poll succeeds.
  final DeviceStatus? status;
  final DateTime? statusAt;

  /// Why [status] is missing: 'unsupported' (404 on old firmware),
  /// 'unreachable', 'failed', or null.
  final String? statusError;

  /// Last `/dash` payload (sensor health, controller time).
  final DeviceDash? dash;
  final DateTime? dashAt;

  /// Free heap samples from the last 3 h of polls, oldest first.
  final List<DashSample> heap;

  const ControllerEntry({
    required this.device,
    required this.boxes,
    this.status,
    this.statusAt,
    this.statusError,
    this.dash,
    this.dashAt,
    this.heap = const [],
  });

  int? get sensorHealthStatus => dash?.intValues['SENSOR_HEALTH_STATUS'];
  String? get sensorHealthAlert => dash?.stringValues['SENSOR_HEALTH_LAST_ALERT'];
  bool get hasSensorWarning => sensorHealthStatus == ControllersBloc.sensorHealthWarn;
}

abstract class ControllersBlocEvent extends Equatable {}

class ControllersBlocEventInit extends ControllersBlocEvent {
  @override
  List<Object> get props => [];
}

class ControllersBlocEventRefresh extends ControllersBlocEvent {
  final int rand = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object> get props => [rand];
}

abstract class ControllersBlocState extends Equatable {}

class ControllersBlocStateInit extends ControllersBlocState {
  @override
  List<Object> get props => [];
}

class ControllersBlocStateLoaded extends ControllersBlocState {
  final List<ControllerEntry> controllers;
  final DateTime at;

  ControllersBlocStateLoaded(this.controllers, this.at);

  @override
  List<Object> get props => [controllers, at];
}

/// Watches the paired controllers in the db (kept fresh by the device
/// daemon) and polls `/mqttdiag` on the reachable local ones every
/// [statusInterval]. Heap history survives tab switches so the sparkline is
/// useful right away.
class ControllersBloc extends LegacyBloc<ControllersBlocEvent, ControllersBlocState> {
  static const Duration statusInterval = Duration(seconds: 30);
  static const Duration heapWindow = Duration(hours: 3);
  static const int sensorHealthWarn = 3;
  static const String mqttdiagPath = '/mqttdiag';

  static final Map<int, List<DashSample>> _heapHistory = {};
  static final Map<int, DeviceStatus> _lastStatus = {};
  static final Map<int, DateTime> _lastStatusAt = {};
  static final Map<int, String> _lastStatusError = {};

  List<Device> _devices = [];
  List<Box> _boxes = [];
  List<Plant> _plants = [];

  StreamSubscription<List<Device>>? _devicesSub;
  StreamSubscription<List<Box>>? _boxesSub;
  StreamSubscription<List<Plant>>? _plantsSub;
  Timer? _timer;
  bool _polling = false;

  ControllersBloc() : super(ControllersBlocStateInit()) {
    add(ControllersBlocEventInit());
  }

  @override
  Stream<ControllersBlocState> mapEventToState(ControllersBlocEvent event) async* {
    if (event is ControllersBlocEventInit) {
      final db = RelDB.get();
      _devicesSub = db.devicesDAO.watchDevices(isController: true).listen((devices) {
        _devices = devices;
        add(ControllersBlocEventRefresh());
      });
      _boxesSub = db.plantsDAO.watchBoxes().listen((boxes) {
        _boxes = boxes;
        add(ControllersBlocEventRefresh());
      });
      _plantsSub = db.plantsDAO.watchPlants().listen((plants) {
        _plants = plants;
        add(ControllersBlocEventRefresh());
      });
      _timer = Timer.periodic(statusInterval, (_) => _pollStatuses());
      // First poll right away, once the device list has arrived.
      Timer(const Duration(seconds: 2), _pollStatuses);
    } else if (event is ControllersBlocEventRefresh) {
      yield ControllersBlocStateLoaded(await _buildEntries(), DateTime.now());
    }
  }

  Future<List<ControllerEntry>> _buildEntries() async {
    final db = RelDB.get();
    final List<ControllerEntry> entries = [];
    for (final Device device in _devices) {
      final List<ControllerBox> boxes = [];
      for (final Box box in _boxes.where((b) => b.device == device.id)) {
        boxes.add(ControllerBox(
          box: box,
          plantNames: _plants.where((p) => p.box == box.id).map((p) => p.name).toList(),
          temp: await _intParam(db, device.id, 'BOX_${box.deviceBox}_TEMP'),
          humi: await _intParam(db, device.id, 'BOX_${box.deviceBox}_HUMI'),
        ));
      }
      boxes.sort((a, b) => (a.box.deviceBox ?? 0).compareTo(b.box.deviceBox ?? 0));
      entries.add(ControllerEntry(
        device: device,
        boxes: boxes,
        status: _lastStatus[device.id],
        statusAt: _lastStatusAt[device.id],
        statusError: _lastStatusError[device.id],
        dash: DeviceAPI.lastDash(device.id),
        dashAt: DeviceAPI.lastDashAt(device.id),
        heap: List.unmodifiable(_heapHistory[device.id] ?? const []),
      ));
    }
    return entries;
  }

  Future<int?> _intParam(RelDB db, int deviceID, String key) async {
    try {
      return (await db.devicesDAO.getParam(deviceID, key)).ivalue;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pollStatuses() async {
    if (_polling) {
      return;
    }
    _polling = true;
    try {
      for (final Device device in List<Device>.from(_devices)) {
        await _pollStatus(device);
      }
    } finally {
      _polling = false;
    }
    if (!isClosed) {
      add(ControllersBlocEventRefresh());
    }
  }

  Future<void> _pollStatus(Device device) async {
    if (!device.isReachable || device.isRemote) {
      _lastStatusError[device.id] = 'unreachable';
      return;
    }
    final String? auth = AppDB().getDeviceAuth(device.identifier);
    try {
      final String body = await DeviceAPI.fetchString('http://${device.ip}$mqttdiagPath', auth: auth, nRetries: 1);
      final dynamic decoded = body.trim().isEmpty ? null : jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        _lastStatusError[device.id] = 'unsupported';
        return;
      }
      final DeviceStatus status = DeviceStatus.fromJson(decoded);
      final DateTime now = DateTime.now();
      _lastStatus[device.id] = status;
      _lastStatusAt[device.id] = now;
      _lastStatusError.remove(device.id);
      if (status.heapFree != null) {
        final List<DashSample> heap = _heapHistory.putIfAbsent(device.id, () => []);
        heap.add(DashSample(now, status.heapFree!));
        heap.removeWhere((s) => now.difference(s.time) > heapWindow);
      }
    } catch (e, trace) {
      if (e is DeviceRequestException && e.statusCode == 404) {
        _lastStatusError[device.id] = 'unsupported';
      } else {
        _lastStatusError[device.id] = 'failed';
        Logger.logError(e, trace, data: {'ip': device.ip, 'deviceID': device.identifier});
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _devicesSub?.cancel();
    await _boxesSub?.cancel();
    await _plantsSub?.cancel();
    return super.close();
  }
}
