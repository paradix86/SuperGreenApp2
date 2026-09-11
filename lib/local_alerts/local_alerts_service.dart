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
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_green_app/data/api/device/device_dash.dart';
import 'package:super_green_app/local_alerts/local_alerts_config.dart';
import 'package:super_green_app/local_alerts/local_alerts_evaluator.dart';
import 'package:super_green_app/notifications/model.dart';

/// Android foreground service that polls every watched controller's `/dash`
/// and raises a notification when a reading leaves its range, app closed or
/// not. It talks to the controller directly over the LAN (or a mesh VPN that
/// reaches the LAN), never through the SuperGreenLab cloud.
///
/// The service runs in its own isolate: it reads the JSON snapshot written by
/// [LocalAlertsSync] and never touches the database.
class LocalAlertsService {
  static const Duration pollInterval = Duration(seconds: 60);
  static const Duration requestTimeout = Duration(seconds: 8);

  static const String serviceChannelId = 'LOCAL_ALERTS_SERVICE';
  static const String alertsChannelId = 'LOCAL_ALERTS';
  static const int serviceNotificationId = 4100;

  /// Notification ids: one per lab and metric, so a repeat replaces the
  /// previous one instead of piling up.
  static const int _alertIdBase = 4200;

  static const String _reloadMethod = 'reload';
  static const String _stopMethod = 'stop';

  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Registers the service with the OS. Call once at app start, before
  /// [applyConfig]; the service itself is only started when a lab has alerts
  /// switched on.
  static Future<void> configure(FlutterLocalNotificationsPlugin notifications) async {
    if (!Platform.isAndroid) {
      return;
    }
    final AndroidFlutterLocalNotificationsPlugin? android =
        notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      serviceChannelId,
      'Lab watch',
      description: 'Shown while the app watches your labs in the background.',
      importance: Importance.low,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      alertsChannelId,
      'Local alerts',
      description: 'Temperature or humidity out of range, controller unreachable.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: localAlertsServiceOnStart,
        autoStart: false,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: serviceChannelId,
        initialNotificationTitle: 'SuperGreenLab',
        initialNotificationContent: 'Watching your labs',
        foregroundServiceNotificationId: serviceNotificationId,
        foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  /// Starts, reloads or stops the service to match [config].
  static Future<void> applyConfig(LocalAlertsConfig config) async {
    if (!Platform.isAndroid) {
      return;
    }
    final bool running = await _service.isRunning();
    if (!config.hasEnabledTargets) {
      if (running) {
        _service.invoke(_stopMethod);
      }
      return;
    }
    if (running) {
      _service.invoke(_reloadMethod);
    } else {
      await _service.startService();
    }
  }

  static Future<bool> isRunning() => _service.isRunning();

  static int alertNotificationId(int boxId, LocalAlertMetric metric) =>
      _alertIdBase + boxId * LocalAlertMetric.values.length + metric.index;
}

/// Entry point of the service isolate. Must be a top-level function: the
/// native side looks it up by name, and a static method inside a class is
/// rejected ("must be annotated") even with the pragma.
@pragma('vm:entry-point')
Future<void> localAlertsServiceOnStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final _Watcher watcher = _Watcher(service);
  await watcher.start();
}

/// The poll loop living in the service isolate.
class _Watcher {
  final ServiceInstance service;
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  final Map<int, LocalAlertState> _states = {};

  LocalAlertsConfig _config = const LocalAlertsConfig();
  Timer? _timer;
  bool _polling = false;

  _Watcher(this.service);

  Future<void> start() async {
    await notifications.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_notification')),
    );
    service.on('reload').listen((_) => _reload());
    service.on('stop').listen((_) async {
      _timer?.cancel();
      await service.stopSelf();
    });
    await _reload();
    _timer = Timer.periodic(LocalAlertsService.pollInterval, (_) => _pollAll());
    await _pollAll();
  }

  /// The service isolate has no Logger (it owns no file): plain prints, which
  /// land in logcat under the "flutter" tag.
  void _log(String message) => print('[LocalAlerts] $message');

  Future<void> _reload() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    _config = await LocalAlertsConfig.read(documents);
    // Forget labs that are no longer watched so a re-enable starts clean.
    final Set<int> watched = _config.enabledTargets.map((t) => t.boxId).toSet();
    _states.removeWhere((boxId, _) => !watched.contains(boxId));
    _log('config loaded: ${_config.targets.length} labs, ${watched.length} watched');
    await _updateServiceNotification();
  }

  Future<void> _updateServiceNotification() async {
    final ServiceInstance s = service;
    if (s is! AndroidServiceInstance) {
      return;
    }
    final List<LocalAlertTarget> targets = _config.enabledTargets;
    final String labs = targets.map((t) => t.label).join(', ');
    await s.setForegroundNotificationInfo(
      title: 'SuperGreenLab',
      content: targets.isEmpty ? 'No lab to watch' : 'Watching $labs',
    );
  }

  Future<void> _pollAll() async {
    if (_polling) {
      return;
    }
    _polling = true;
    try {
      for (final LocalAlertTarget target in _config.enabledTargets) {
        await _poll(target);
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _poll(LocalAlertTarget target) async {
    final DateTime now = DateTime.now();
    final LocalAlertState previous = _states[target.boxId] ?? const LocalAlertState();
    LocalAlertOutcome outcome;
    try {
      final DeviceDash dash = await _fetchDash(target.deviceIp);
      final int prefixIndex = target.boxIndex;
      if (dash.intValues['BOX_${prefixIndex}_ENABLED'] == 0) {
        // A box switched off is not growing: nothing to alert about.
        _states[target.boxId] = const LocalAlertState();
        return;
      }
      final double? temp = dash.intValues['BOX_${prefixIndex}_TEMP']?.toDouble();
      final double? humi = dash.intValues['BOX_${prefixIndex}_HUMI']?.toDouble();
      _log('${target.label}: temp=$temp humi=$humi limits ${target.alerts.tempMin}-${target.alerts.tempMax}');
      outcome = LocalAlertsEvaluator.onReading(target.alerts, previous, temp: temp, humi: humi, now: now);
    } catch (e) {
      _log('${target.label}: poll failed: $e');
      outcome = LocalAlertsEvaluator.onUnreachable(previous, now: now);
    }
    _states[target.boxId] = outcome.state;
    _log('${target.label}: active=${outcome.state.active} events=${outcome.events.length}');
    for (final LocalAlertEvent event in outcome.events) {
      await _notify(target, event);
    }
  }

  Future<DeviceDash> _fetchDash(String ip) async {
    final HttpClient client = HttpClient()..connectionTimeout = LocalAlertsService.requestTimeout;
    try {
      final HttpClientRequest request =
          await client.getUrl(Uri.parse('http://$ip/dash')).timeout(LocalAlertsService.requestTimeout);
      final HttpClientResponse response = await request.close().timeout(LocalAlertsService.requestTimeout);
      if (response.statusCode != 200) {
        throw HttpException('/dash answered ${response.statusCode}', uri: request.uri);
      }
      final String body = await response.transform(utf8.decoder).join().timeout(LocalAlertsService.requestTimeout);
      final dynamic decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('unexpected /dash payload');
      }
      return DeviceDash.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _notify(LocalAlertTarget target, LocalAlertEvent event) async {
    final NotificationDataLocalAlert data = NotificationDataLocalAlert(
      id: LocalAlertsService.alertNotificationId(target.boxId, event.metric),
      title: _title(target, event),
      body: _body(target, event),
      plantID: target.plantId,
      boxID: target.boxId,
    );
    _log('notify ${data.id}: ${data.title}');
    await notifications.show(
      id: data.id,
      title: data.title,
      body: data.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          LocalAlertsService.alertsChannelId,
          'Local alerts',
          channelDescription: 'Temperature or humidity out of range, controller unreachable.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      payload: data.toJSON(),
    );
  }

  String _title(LocalAlertTarget target, LocalAlertEvent event) {
    switch (event.metric) {
      case LocalAlertMetric.temperature:
        return event.active
            ? '${target.label}: temperature out of range'
            : '${target.label}: temperature back to normal';
      case LocalAlertMetric.humidity:
        return event.active ? '${target.label}: humidity out of range' : '${target.label}: humidity back to normal';
      case LocalAlertMetric.reachability:
        return event.active ? '${target.label}: controller unreachable' : '${target.label}: controller back online';
    }
  }

  String _body(LocalAlertTarget target, LocalAlertEvent event) {
    final bool imperial = _config.freedomUnits;
    switch (event.metric) {
      case LocalAlertMetric.temperature:
        final String now = _formatTemp(event.value!, imperial);
        final String range =
            '${_formatTemp(target.alerts.tempMin, imperial)} – ${_formatTemp(target.alerts.tempMax, imperial)}';
        return 'Now $now, limits $range.';
      case LocalAlertMetric.humidity:
        final String range = '${target.alerts.humiMin.round()} – ${target.alerts.humiMax.round()} %';
        return 'Now ${event.value!.round()} %, limits $range.';
      case LocalAlertMetric.reachability:
        final int minutes = LocalAlertsEvaluator.unreachableAfter.inMinutes;
        return event.active
            ? 'No answer from ${target.deviceName} (${target.deviceIp}) for $minutes min. Power, Wi-Fi or VPN?'
            : '${target.deviceName} answers again.';
    }
  }

  static String _formatTemp(double celsius, bool imperial) {
    if (imperial) {
      return '${(celsius * 9 / 5 + 32).round()} °F';
    }
    return '${celsius.round()} °C';
  }
}
