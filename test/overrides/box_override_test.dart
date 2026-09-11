import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/overrides/box_override.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 9, 11, 10, 0);
  int at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

  group('TemporaryOverride', () {
    test('an inactive override is never expired and has no remaining time', () {
      const TemporaryOverride override = TemporaryOverride();
      expect(override.isExpired(t0), isFalse);
      expect(override.remaining(t0), isNull);
    });

    test('is not expired before expiresAt and expired at or after it', () {
      final TemporaryOverride override =
          TemporaryOverride(active: true, expiresAt: at(t0.add(const Duration(minutes: 30))));

      expect(override.isExpired(t0.add(const Duration(minutes: 29))), isFalse);
      expect(override.isExpired(t0.add(const Duration(minutes: 30))), isTrue);
      expect(override.isExpired(t0.add(const Duration(minutes: 31))), isTrue);
    });

    test('remaining counts down to zero and never goes negative', () {
      final TemporaryOverride override =
          TemporaryOverride(active: true, expiresAt: at(t0.add(const Duration(minutes: 10))));

      expect(override.remaining(t0), const Duration(minutes: 10));
      expect(override.remaining(t0.add(const Duration(minutes: 10))), Duration.zero);
      expect(override.remaining(t0.add(const Duration(minutes: 15))), Duration.zero);
    });

    test('round-trips through a map, restore values included', () {
      final TemporaryOverride override = TemporaryOverride(
        active: true,
        expiresAt: at(t0),
        restore: const {'BOX_0_TIMER_TYPE': 1, 'BOX_0_TIMER_OUTPUT': 80},
      );

      expect(TemporaryOverride.fromMap(override.toMap()), override);
    });

    test('a map with active false or missing collapses to the inactive default', () {
      expect(TemporaryOverride.fromMap(null), const TemporaryOverride());
      expect(TemporaryOverride.fromMap({'active': false, 'expiresAt': 123}), const TemporaryOverride());
    });
  });

  group('BoxOverrides', () {
    test('round-trips light and blower independently', () {
      final BoxOverrides overrides = BoxOverrides(
        light: TemporaryOverride(active: true, expiresAt: at(t0), restore: const {'BOX_0_TIMER_TYPE': 0}),
        blower: const TemporaryOverride(),
      );

      final BoxOverrides restored = BoxOverrides.fromMap(overrides.toMap());
      expect(restored, overrides);
      expect(restored.blower.active, isFalse);
    });

    test('defaults to both inactive', () {
      expect(BoxOverrides.fromMap(null), const BoxOverrides());
    });
  });
}
