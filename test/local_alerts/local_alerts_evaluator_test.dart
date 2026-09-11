import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/local_alerts/local_alert_settings.dart';
import 'package:super_green_app/local_alerts/local_alerts_evaluator.dart';

void main() {
  const LocalAlertSettings limits =
      LocalAlertSettings(enabled: true, tempMin: 18, tempMax: 28, humiMin: 40, humiMax: 75);
  final DateTime t0 = DateTime(2026, 9, 11, 10, 0);

  group('LocalAlertsEvaluator.onReading', () {
    test('stays silent while readings are inside the limits', () {
      final LocalAlertOutcome out =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: 25, humi: 60, now: t0);

      expect(out.events, isEmpty);
      expect(out.state.active, isEmpty);
    });

    test('notifies immediately when the temperature leaves the range', () {
      final LocalAlertOutcome out =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: 31, humi: 60, now: t0);

      expect(out.events, [const LocalAlertEvent(LocalAlertMetric.temperature, active: true, value: 31)]);
      expect(out.state.isActive(LocalAlertMetric.temperature), isTrue);
      expect(out.state.lastNotifiedAt[LocalAlertMetric.temperature], t0);
    });

    test('does not repeat an active alert before 30 minutes', () {
      final LocalAlertState active =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: 31, humi: 60, now: t0).state;

      final LocalAlertOutcome out = LocalAlertsEvaluator.onReading(limits, active,
          temp: 32, humi: 60, now: t0.add(const Duration(minutes: 29)));

      expect(out.events, isEmpty);
      expect(out.state.isActive(LocalAlertMetric.temperature), isTrue);
    });

    test('repeats an active alert after 30 minutes', () {
      final LocalAlertState active =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: 31, humi: 60, now: t0).state;
      final DateTime later = t0.add(const Duration(minutes: 30));

      final LocalAlertOutcome out = LocalAlertsEvaluator.onReading(limits, active, temp: 32, humi: 60, now: later);

      expect(out.events, [const LocalAlertEvent(LocalAlertMetric.temperature, active: true, value: 32)]);
      expect(out.state.lastNotifiedAt[LocalAlertMetric.temperature], later);
    });

    test('notifies once when the reading is back in range', () {
      final LocalAlertState active =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: 31, humi: 60, now: t0).state;

      final LocalAlertOutcome back = LocalAlertsEvaluator.onReading(limits, active,
          temp: 26, humi: 60, now: t0.add(const Duration(minutes: 5)));
      final LocalAlertOutcome quiet = LocalAlertsEvaluator.onReading(limits, back.state,
          temp: 26, humi: 60, now: t0.add(const Duration(minutes: 6)));

      expect(back.events, [const LocalAlertEvent(LocalAlertMetric.temperature, active: false, value: 26)]);
      expect(back.state.isActive(LocalAlertMetric.temperature), isFalse);
      expect(quiet.events, isEmpty);
    });

    test('handles temperature and humidity independently', () {
      final LocalAlertOutcome out =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: 12, humi: 90, now: t0);

      expect(out.events.map((e) => e.metric), [LocalAlertMetric.temperature, LocalAlertMetric.humidity]);
      expect(out.events.every((e) => e.active), isTrue);
    });

    test('ignores a metric the controller did not report', () {
      final LocalAlertOutcome out =
          LocalAlertsEvaluator.onReading(limits, const LocalAlertState(), temp: null, humi: 90, now: t0);

      expect(out.events.map((e) => e.metric), [LocalAlertMetric.humidity]);
    });

    test('closes a reachability alert on the first good poll', () {
      LocalAlertState state = const LocalAlertState();
      state = LocalAlertsEvaluator.onUnreachable(state, now: t0).state;
      state = LocalAlertsEvaluator.onUnreachable(state, now: t0.add(const Duration(minutes: 5))).state;
      expect(state.isActive(LocalAlertMetric.reachability), isTrue);

      final LocalAlertOutcome out = LocalAlertsEvaluator.onReading(limits, state,
          temp: 25, humi: 60, now: t0.add(const Duration(minutes: 6)));

      expect(out.events, [const LocalAlertEvent(LocalAlertMetric.reachability, active: false)]);
      expect(out.state.unreachableSince, isNull);
      expect(out.state.isActive(LocalAlertMetric.reachability), isFalse);
    });
  });

  group('LocalAlertsEvaluator.onUnreachable', () {
    test('tolerates a short outage without notifying', () {
      final LocalAlertOutcome first = LocalAlertsEvaluator.onUnreachable(const LocalAlertState(), now: t0);
      final LocalAlertOutcome second =
          LocalAlertsEvaluator.onUnreachable(first.state, now: t0.add(const Duration(minutes: 4)));

      expect(first.events, isEmpty);
      expect(second.events, isEmpty);
      expect(second.state.unreachableSince, t0);
    });

    test('notifies once the outage reaches 5 minutes, then repeats every 30', () {
      LocalAlertState state = LocalAlertsEvaluator.onUnreachable(const LocalAlertState(), now: t0).state;

      final LocalAlertOutcome at5 =
          LocalAlertsEvaluator.onUnreachable(state, now: t0.add(const Duration(minutes: 5)));
      final LocalAlertOutcome at20 =
          LocalAlertsEvaluator.onUnreachable(at5.state, now: t0.add(const Duration(minutes: 20)));
      final LocalAlertOutcome at35 =
          LocalAlertsEvaluator.onUnreachable(at20.state, now: t0.add(const Duration(minutes: 35)));

      expect(at5.events, [const LocalAlertEvent(LocalAlertMetric.reachability, active: true)]);
      expect(at20.events, isEmpty);
      expect(at35.events, [const LocalAlertEvent(LocalAlertMetric.reachability, active: true)]);
    });
  });

  group('LocalAlertSettings', () {
    test('round-trips through a map and falls back to defaults', () {
      const LocalAlertSettings s =
          LocalAlertSettings(enabled: true, tempMin: 20, tempMax: 27, humiMin: 45, humiMax: 70);

      expect(LocalAlertSettings.fromMap(s.toMap()), s);
      expect(LocalAlertSettings.fromMap(null), const LocalAlertSettings());
      expect(LocalAlertSettings.fromMap({'tempMin': 'x'}).tempMin, LocalAlertSettings.defaultTempMin);
    });
  });
}
