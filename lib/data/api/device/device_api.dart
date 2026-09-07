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
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:super_green_app/data/api/device/dash_history.dart';
import 'package:super_green_app/data/api/device/device_dash.dart';
import 'package:super_green_app/data/api/device/request_limiter.dart';
import 'package:super_green_app/data/logger/logger.dart';
import 'package:super_green_app/data/rel/device/devices.dart';
import 'package:super_green_app/data/rel/rel_db.dart';

/// A controller HTTP request that completed with a non-2xx status, or whose
/// body could not be parsed. Connectivity failures (SocketException,
/// TimeoutException) are propagated as-is.
class DeviceRequestException implements Exception {
  final String url;
  final int? statusCode;
  final Object? cause;

  DeviceRequestException(this.url, {this.statusCode, this.cause});

  @override
  String toString() {
    if (statusCode != null) {
      return 'Device request error: $statusCode ($url)';
    }
    return 'Device request error: $cause ($url)';
  }
}

class DeviceAPI {
  /// Retries used to wait a fixed [wait] seconds between attempts; a controller
  /// that is rebooting or busy with an OTA is better served by backing off.
  static const int maxBackoffSeconds = 8;

  /// Requests in flight per controller host. Every open socket costs the ESP32
  /// ~3-4 KB of heap, and pages, the daemon and fetchAllParams all talk to it
  /// independently: 4 concurrent requests measured a 17 KB heap dip.
  static const int maxInFlightPerController = 2;

  static final Map<String, RequestLimiter> _limiters = {};

  static RequestLimiter limiterFor(String host) {
    return _limiters.putIfAbsent(host, () => RequestLimiter(maxInFlightPerController));
  }

  static Duration backoffDelay(int attempt, int baseSeconds) {
    if (attempt < 1 || baseSeconds <= 0) {
      return Duration.zero;
    }
    int seconds = baseSeconds << (attempt - 1);
    if (seconds > maxBackoffSeconds) {
      seconds = maxBackoffSeconds;
    }
    return Duration(seconds: seconds);
  }

  static String mdnsDomain(String name) {
    return name.toLowerCase().replaceAllMapped(RegExp(r'[\W_]+'), (match) => "");
  }

  static Future<String?> resolveLocalName(String name) async {
    if (name.endsWith('.local')) {
      name.replaceAll('.local', '');
    }
    name = '${DeviceAPI.mdnsDomain(name)}.local';
    // Temporary workaround, mdns discovery fails on the current version of the lib
    String? ip;
    if (Platform.isAndroid) {
      ip = await DeviceAPI.resolveLocalNameMDNS(name);
    } else if (Platform.isIOS) {
      ip = await DeviceAPI.fetchStringParam(name, 'WIFI_IP', wait: 5);
    }
    return ip;
  }

  static Future<String?> resolveLocalNameMDNS(String name) async {
    final MDnsClient client =
        MDnsClient(rawDatagramSocketFactory: (dynamic host, int port, {bool? reuseAddress, bool? reusePort, int? ttl}) {
      return RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: false, ttl: ttl!);
    });
    await client.start();

    String? foundIP;
    await for (IPAddressResourceRecord record
        in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(name))) {
      foundIP = record.address.address;
      break;
    }
    client.stop();
    return foundIP;
  }

  /// Runs [attempt] up to [nRetries] times with exponential backoff, logs the
  /// last failure with [logData] and rethrows it.
  static Future<T> _withRetries<T>(Future<T> Function() attempt,
      {required int nRetries, required int wait, required Map<String, dynamic> logData}) async {
    if (nRetries < 1) {
      nRetries = 1;
    }
    Object? lastError;
    StackTrace? lastTrace;
    for (int i = 0; i < nRetries; ++i) {
      if (i != 0) {
        await Future.delayed(backoffDelay(i, wait));
      }
      try {
        return await attempt();
      } catch (e, trace) {
        lastError = e;
        lastTrace = trace;
      }
    }
    Logger.logError(lastError, lastTrace, data: logData);
    throw lastError!;
  }

  /// One HTTP exchange with the controller. [timeout] bounds the whole
  /// exchange (connect + headers + body), not just the TCP connect: a
  /// controller that accepts the socket and then hangs used to leave the
  /// caller waiting forever.
  ///
  /// When [client] is given the connection is reused (HTTP keep-alive) and the
  /// caller owns its lifetime; otherwise a throw-away client is created and
  /// force-closed after the exchange.
  static Future<String> _exchange(String method, String url,
      {int? timeout, String? auth, void Function(HttpClientRequest req)? writeBody, HttpClient? client}) async {
    final bool ownsClient = client == null;
    final HttpClient httpClient = client ?? HttpClient();
    if (timeout != null) {
      httpClient.connectionTimeout = Duration(seconds: timeout);
    }
    final Uri uri = Uri.parse(url);
    Future<String> run() async {
      final HttpClientRequest req = await (method == 'POST' ? httpClient.postUrl(uri) : httpClient.getUrl(uri));
      if (auth != null) {
        req.headers.set('Authorization', 'Basic $auth');
      }
      if (writeBody != null) {
        writeBody(req);
        await req.flush();
      }
      final HttpClientResponse resp = await req.close();
      if ((resp.statusCode / 100).floor() != 2) {
        throw DeviceRequestException(url, statusCode: resp.statusCode);
      }
      if (resp.contentLength == 0) {
        return '';
      }
      return resp.transform(utf8.decoder).join();
    }

    // the timeout starts once a slot is granted: queueing behind other
    // requests must not count as the controller being unresponsive
    try {
      return await limiterFor(uri.host).run(() {
        if (timeout == null) {
          return run();
        }
        return run().timeout(Duration(seconds: timeout));
      });
    } finally {
      if (ownsClient) {
        httpClient.close(force: true);
      }
    }
  }

  static Future<String> fetchConfig(String controllerIP, {String? auth, HttpClient? client}) async {
    final String url = 'http://$controllerIP/fs/config.json';
    final String contents = await _exchange('GET', url, timeout: 10, auth: auth, client: client);
    if (contents.isEmpty) {
      throw DeviceRequestException(url, cause: 'empty config.json');
    }
    return contents;
  }

  static Future<String> fetchStringParam(String controllerIP, String paramName,
      {int? timeout = 5, int nRetries = 4, int wait = 1, String? auth, HttpClient? client}) async {
    return fetchString('http://$controllerIP/s?k=${paramName.toUpperCase()}',
        timeout: timeout, nRetries: nRetries, wait: wait, auth: auth, client: client);
  }

  static Future<String> fetchString(String url,
      {int? timeout = 5, int nRetries = 4, int wait = 0, String? auth, HttpClient? client}) async {
    return _withRetries(() => _exchange('GET', url, timeout: timeout, auth: auth, client: client),
        nRetries: nRetries, wait: wait, logData: {"url": url});
  }

  static Future<int> fetchIntParam(String controllerIP, String paramName,
      {int? timeout = 5, int nRetries = 4, int wait = 1, String? auth, HttpClient? client}) async {
    final String url = 'http://$controllerIP/i?k=${paramName.toUpperCase()}';
    return _withRetries(() async {
      final String contents = await _exchange('GET', url, timeout: timeout, auth: auth, client: client);
      try {
        return int.parse(contents.trim());
      } on FormatException catch (e) {
        throw DeviceRequestException(url, cause: e);
      }
    }, nRetries: nRetries, wait: wait, logData: {"controllerIP": controllerIP, "paramName": paramName});
  }

  static Future<String> setStringParam(String controllerIP, String paramName, String value,
      {int? timeout = 5, int nRetries = 4, int wait = 1, String? auth}) async {
    await post('http://$controllerIP/s?k=${paramName.toUpperCase()}&v=${Uri.encodeQueryComponent(value)}',
        timeout: timeout, nRetries: nRetries, wait: wait, auth: auth);
    return fetchStringParam(controllerIP, paramName, auth: auth);
  }

  static Future<int> setIntParam(String controllerIP, String paramName, int value,
      {int? timeout = 5, int nRetries = 4, int wait = 1, String? auth}) async {
    await post('http://$controllerIP/i?k=${paramName.toUpperCase()}&v=$value',
        timeout: timeout, nRetries: nRetries, wait: wait, auth: auth);
    return fetchIntParam(controllerIP, paramName, auth: auth);
  }

  static Future post(String url, {int? timeout = 5, int nRetries = 4, int wait = 1, String? auth}) async {
    await _withRetries(() => _exchange('POST', url, timeout: timeout, auth: auth),
        nRetries: nRetries, wait: wait, logData: {"url": url});
  }

  static Future uploadFile(String controllerIP, String fileName, ByteData data,
      {int? timeout = 5, int nRetries = 4, int wait = 1, String? auth}) async {
    final String url = 'http://$controllerIP/fs/$fileName';
    await _withRetries(
        () => _exchange('POST', url, timeout: timeout, auth: auth, writeBody: (HttpClientRequest req) {
              req.contentLength = data.lengthInBytes;
              req.add(data.buffer.asInt8List());
            }),
        nRetries: nRetries,
        wait: wait,
        logData: {"controllerIP": controllerIP, "fileName": fileName});
  }

  static Map<int, bool> fetchingAllParams = {};

  static Future fetchAllParams(String ip, int deviceID, Function(double) advancement,
      {bool delete = false, String? auth}) async {
    if (DeviceAPI.fetchingAllParams[deviceID] == true) {
      return;
    }
    DeviceAPI.fetchingAllParams[deviceID] = true;
    // A few hundred parameters are read one by one: reuse a single keep-alive
    // connection instead of opening (and making the ESP32 tear down) a TCP
    // socket per parameter, which drove its free heap down to ~3 KB.
    final HttpClient client = HttpClient()..maxConnectionsPerHost = 1;
    try {
      final db = RelDB.get().devicesDAO;
      final Map<String, int> modules = Map();

      final config = await DeviceAPI.fetchConfig(ip, auth: auth, client: client);

      Map<String, dynamic> keys = json.decode(config);

      if (delete) {
        await db.deleteParams(deviceID);
        await db.deleteModules(deviceID);
      }

      double total = keys['keys'].length.toDouble(), done = 0;
      for (Map<String, dynamic> k in keys['keys']) {
        var moduleName = k['module'];
        int moduleID;
        if (modules.containsKey(moduleName) == false) {
          bool isArray = k.containsKey('array');
          Module? exists;
          try {
            exists = await db.getModule(deviceID, moduleName);
          } catch (e) {
            // getModule throws when the module is not in the local db yet
          }
          if (exists == null) {
            ModulesCompanion module = ModulesCompanion.insert(
                device: deviceID, name: moduleName, isArray: isArray, arrayLen: isArray ? k['array']['len'] : 0);
            moduleID = await db.addModule(module);
          } else {
            moduleID = exists.id;
          }
          modules[moduleName] = moduleID;
        }
        int type = k['type'] == 'integer' ? INTEGER_TYPE : STRING_TYPE;
        Param? exists;
        try {
          exists = await db.getParam(deviceID, k['caps_name']);
        } catch (e) {
          // getParam throws when the param is not in the local db yet
        }
        if (type == INTEGER_TYPE) {
          try {
            final value = await DeviceAPI.fetchIntParam(ip, k['caps_name'], auth: auth, client: client);
            if (exists == null) {
              ParamsCompanion param = ParamsCompanion.insert(
                  device: deviceID,
                  module: modules[moduleName]!,
                  key: k['caps_name'],
                  type: type,
                  ivalue: Value(value));
              await db.addParam(param);
            } else {
              await db.updateParam(exists.copyWith(ivalue: Value(value)));
            }
          } catch (e, trace) {
            Logger.logError(e, trace, data: {"ip": ip, "deviceID": deviceID, "param": k['caps_name']}, fwdThrow: true);
          }
        } else {
          try {
            final value = await DeviceAPI.fetchStringParam(ip, k['caps_name'], auth: auth, client: client);
            if (exists == null) {
              ParamsCompanion param = ParamsCompanion.insert(
                  device: deviceID,
                  module: modules[moduleName]!,
                  key: k['caps_name'],
                  type: type,
                  svalue: Value(value));
              await db.addParam(param);
            } else {
              await db.updateParam(exists.copyWith(svalue: Value(value)));
            }
          } catch (e, trace) {
            Logger.logError(e, trace, data: {"ip": ip, "deviceID": deviceID, "param": k['caps_name']}, fwdThrow: true);
          }
        }
        ++done;
        advancement(done / total);
      }
      bool isController = (keys['isController'] ?? 'true') == 'true';
      bool isScreen = (keys['isScreen'] ?? 'false') == 'true';
      int nBoxes = 0;
      int nSensorPorts = 0;
      int nLeds = 0;
      int nMotors = 0;
      if (isController) {
        nBoxes = await _moduleArrayLen(deviceID, 'box');
        nSensorPorts = await _moduleArrayLen(deviceID, 'i2c');
        nLeds = await _moduleArrayLen(deviceID, 'led');
        nMotors = await _moduleArrayLen(deviceID, 'motor');
      }
      await db.updateDevice(DevicesCompanion(
        id: Value(deviceID),
        isController: Value(isController),
        isScreen: Value(isScreen),
        isSetup: Value(true),
        needsRefresh: Value(false),
        nBoxes: Value(nBoxes),
        nSensorPorts: Value(nSensorPorts),
        nLeds: Value(nLeds),
        nMotors: Value(nMotors),
        config: Value(config),
      ));
    } catch (e, trace) {
      Logger.logError(e, trace, data: {"ip": ip, "deviceID": deviceID}, fwdThrow: true);
    } finally {
      client.close(force: true);
      DeviceAPI.fetchingAllParams[deviceID] = false;
    }
  }

  /// One `GET /dash`: every box, the LEDs, the sensor health and the clock.
  /// Throws a [DeviceRequestException] with status 404 on firmwares that do
  /// not have the endpoint (before 2026-09-07).
  static Future<DeviceDash> fetchDash(String controllerIP, {int? timeout = 5, String? auth}) async {
    final String url = 'http://$controllerIP/dash';
    final String contents = await _exchange('GET', url, timeout: timeout, auth: auth);
    try {
      final dynamic decoded = json.decode(contents);
      if (decoded is! Map<String, dynamic>) {
        throw DeviceRequestException(url, cause: 'unexpected /dash payload');
      }
      return DeviceDash.fromJson(decoded);
    } on FormatException catch (e) {
      throw DeviceRequestException(url, cause: e);
    }
  }

  /// A param refreshed by `/dash` within this window is served from the local
  /// db instead of a `GET /i`: the daemon polls every 15 s, so three missed
  /// polls make the value stale again.
  static const Duration dashFreshness = Duration(seconds: 45);

  static final Map<int, DateTime> _dashAppliedAt = {};
  static final Map<int, Set<String>> _dashKeys = {};

  /// Records that [dash] was applied to [deviceID]'s params at [at].
  static void noteDashApplied(int deviceID, DeviceDash dash, {DateTime? at}) {
    _dashAppliedAt[deviceID] = at ?? DateTime.now();
    _dashKeys[deviceID] = {...dash.intValues.keys, ...dash.stringValues.keys};
  }

  /// True when [key] of [deviceID] was written by `/dash` less than
  /// [dashFreshness] ago, i.e. the local db is as good as a fresh `GET /i`.
  static bool isFreshFromDash(int deviceID, String key, {DateTime? now}) {
    final DateTime? appliedAt = _dashAppliedAt[deviceID];
    if (appliedAt == null || !(_dashKeys[deviceID]?.contains(key) ?? false)) {
      return false;
    }
    return (now ?? DateTime.now()).difference(appliedAt) < dashFreshness;
  }

  /// Writes the values of [dash] into the params the local db already has for
  /// [deviceID], skipping unknown keys and unchanged values (every write wakes
  /// up the widgets watching that param). Returns the number of params updated.
  static Future<int> applyDash(int deviceID, DeviceDash dash) async {
    final db = RelDB.get().devicesDAO;
    final List<Param> params = await db.getParams(deviceID);
    int updated = 0;
    for (final Param param in params) {
      Param? changed;
      if (param.type == INTEGER_TYPE) {
        final int? value = dash.intValues[param.key];
        if (value != null && value != param.ivalue) {
          changed = param.copyWith(ivalue: Value(value));
        }
      } else {
        final String? value = dash.stringValues[param.key];
        if (value != null && value != param.svalue) {
          changed = param.copyWith(svalue: Value(value));
        }
      }
      if (changed != null) {
        await db.updateParam(changed);
        ++updated;
      }
    }
    noteDashApplied(deviceID, dash);
    DashHistory.record(deviceID, dash);
    return updated;
  }

  /// 0 when the controller does not expose [moduleName] (getModule throws).
  static Future<int> _moduleArrayLen(int deviceID, String moduleName) async {
    try {
      final module = await RelDB.get().devicesDAO.getModule(deviceID, moduleName);
      return module.arrayLen;
    } catch (e) {
      return 0;
    }
  }
}
