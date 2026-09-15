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

import 'package:equatable/equatable.dart';
import 'package:super_green_app/local_alerts/local_alert_settings.dart';

/// Which reading an alert is about. New values are appended so the notification
/// id scheme (`metric.index`) stays stable for the existing metrics.
enum LocalAlertMetric { temperature, humidity, reachability, reboot }

/// One notification the service should show.
class LocalAlertEvent extends Equatable {
  final LocalAlertMetric metric;

  /// True while the reading is out of range (or the controller unreachable),
  /// false for the single "back to normal" notification.
  final bool active;

  /// Reading in °C or %, null for reachability events.
  final double? value;

  const LocalAlertEvent(this.metric, {required this.active, this.value});

  @override
  List<Object?> get props => [metric, active, value];
}

/// Per-lab alert memory: when each metric went out of range and when it was
/// last notified, so the service repeats a still-active alert only every
/// [LocalAlertsEvaluator.repeatEvery] and notifies the return to normal once.
class LocalAlertState extends Equatable {
  final Map<LocalAlertMetric, DateTime> lastNotifiedAt;
  final Set<LocalAlertMetric> active;

  /// First failed poll of the current outage, null while reachable.
  final DateTime? unreachableSince;

  /// The controller's restart counter as last seen, null until the first poll
  /// that read it. A reboot is an increase against this value between polls; the
  /// first observation only seeds it, so a reboot before watching started is not
  /// reported.
  final int? lastRestarts;

  const LocalAlertState({
    this.lastNotifiedAt = const {},
    this.active = const {},
    this.unreachableSince,
    this.lastRestarts,
  });

  bool isActive(LocalAlertMetric metric) => active.contains(metric);

  @override
  List<Object?> get props => [lastNotifiedAt, active, unreachableSince, lastRestarts];
}

/// Result of one evaluation: the new memory and the notifications to show.
class LocalAlertOutcome {
  final LocalAlertState state;
  final List<LocalAlertEvent> events;

  const LocalAlertOutcome(this.state, this.events);
}

/// Pure decision logic, no I/O: given the limits, the last memory and a fresh
/// reading (or a failed poll), says what to notify. Kept free of Flutter so it
/// runs in the background isolate and in plain unit tests.
class LocalAlertsEvaluator {
  /// A still-active alert is repeated at this interval.
  static const Duration repeatEvery = Duration(minutes: 30);

  /// Polls can fail for a moment (Wi-Fi roaming, controller reboot): only an
  /// outage longer than this is worth a notification.
  static const Duration unreachableAfter = Duration(minutes: 5);

  /// Evaluates a successful poll. [temp] in °C and [humi] in % may be null
  /// when the controller did not report them (sensor missing).
  static LocalAlertOutcome onReading(
    LocalAlertSettings limits,
    LocalAlertState previous, {
    double? temp,
    double? humi,
    int? nRestarts,
    required DateTime now,
  }) {
    final List<LocalAlertEvent> events = [];
    final Map<LocalAlertMetric, DateTime> notified = Map.of(previous.lastNotifiedAt);
    final Set<LocalAlertMetric> active = Set.of(previous.active);

    // Reachable again: close a reachability alert that was notified.
    if (previous.isActive(LocalAlertMetric.reachability)) {
      active.remove(LocalAlertMetric.reachability);
      events.add(const LocalAlertEvent(LocalAlertMetric.reachability, active: false));
    }

    _evaluateMetric(LocalAlertMetric.temperature, temp, limits.tempMin, limits.tempMax, now, notified, active, events);
    _evaluateMetric(LocalAlertMetric.humidity, humi, limits.humiMin, limits.humiMax, now, notified, active, events);
    final int? lastRestarts = _evaluateReboot(limits, previous.lastRestarts, nRestarts, events);

    return LocalAlertOutcome(
      LocalAlertState(lastNotifiedAt: notified, active: active, unreachableSince: null, lastRestarts: lastRestarts),
      events,
    );
  }

  /// Evaluates a failed poll (timeout, connection refused, bad payload).
  static LocalAlertOutcome onUnreachable(LocalAlertState previous, {required DateTime now}) {
    final DateTime since = previous.unreachableSince ?? now;
    final Map<LocalAlertMetric, DateTime> notified = Map.of(previous.lastNotifiedAt);
    final Set<LocalAlertMetric> active = Set.of(previous.active);
    final List<LocalAlertEvent> events = [];

    if (now.difference(since) >= unreachableAfter) {
      final DateTime? last = notified[LocalAlertMetric.reachability];
      final bool wasActive = active.contains(LocalAlertMetric.reachability);
      if (!wasActive || last == null || now.difference(last) >= repeatEvery) {
        active.add(LocalAlertMetric.reachability);
        notified[LocalAlertMetric.reachability] = now;
        events.add(const LocalAlertEvent(LocalAlertMetric.reachability, active: true));
      }
    }
    return LocalAlertOutcome(
      // Keep the last-seen restart count across the outage: a controller that
      // rebooted while unreachable must still be caught when it answers again.
      LocalAlertState(
          lastNotifiedAt: notified, active: active, unreachableSince: since, lastRestarts: previous.lastRestarts),
      events,
    );
  }

  /// A reboot is the restart counter going up between polls. It is an edge, not
  /// a sustained condition, so it fires once (no "back to normal") and needs no
  /// repeat timer: the counter advancing is its own dedup. Returns the value to
  /// remember for next time.
  static int? _evaluateReboot(
    LocalAlertSettings limits,
    int? previousRestarts,
    int? nRestarts,
    List<LocalAlertEvent> events,
  ) {
    if (!limits.rebootAlertEnabled) {
      // Not watching: forget the counter so turning the alarm back on later seeds
      // fresh and never fires for a reboot that happened while it was off.
      return null;
    }
    if (nRestarts == null) {
      // Watching, but no reading this poll (endpoint absent or fetch failed):
      // keep what we knew so a later poll can still compare against it.
      return previousRestarts;
    }
    if (previousRestarts != null && nRestarts > previousRestarts) {
      events.add(LocalAlertEvent(LocalAlertMetric.reboot, active: true, value: nRestarts.toDouble()));
    }
    // Seed on first read, advance on a reboot, and follow a counter that reset
    // lower (an NVS erase) without firing - only an increase is a reboot.
    return nRestarts;
  }

  static void _evaluateMetric(
    LocalAlertMetric metric,
    double? value,
    double min,
    double max,
    DateTime now,
    Map<LocalAlertMetric, DateTime> notified,
    Set<LocalAlertMetric> active,
    List<LocalAlertEvent> events,
  ) {
    if (value == null) {
      return;
    }
    final bool outOfRange = value < min || value > max;
    final bool wasActive = active.contains(metric);
    if (outOfRange) {
      final DateTime? last = notified[metric];
      if (!wasActive || last == null || now.difference(last) >= repeatEvery) {
        active.add(metric);
        notified[metric] = now;
        events.add(LocalAlertEvent(metric, active: true, value: value));
      }
      return;
    }
    if (wasActive) {
      active.remove(metric);
      events.add(LocalAlertEvent(metric, active: false, value: value));
    }
  }
}
