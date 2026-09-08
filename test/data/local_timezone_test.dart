import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/local_timezone.dart';

void main() {
  group('LocalTimezone.posixFor', () {
    test('maps Rome and any other Europe/* zone to CET/CEST', () {
      expect(LocalTimezone.posixFor('Europe/Rome'), 'CET-1CEST,M3.5.0,M10.5.0/3');
      expect(LocalTimezone.posixFor('Europe/Berlin'), 'CET-1CEST,M3.5.0,M10.5.0/3');
    });

    test('keeps the exceptions inside Europe', () {
      expect(LocalTimezone.posixFor('Europe/London'), 'GMT0BST,M3.5.0/1,M10.5.0');
      expect(LocalTimezone.posixFor('Europe/Athens'), startsWith('EET-2EEST'));
    });

    test('returns null for an unknown zone', () {
      expect(LocalTimezone.posixFor('Mars/Olympus'), isNull);
    });
  });

  group('LocalTimezone.posixFromOffset', () {
    test('inverts the sign the POSIX way', () {
      expect(LocalTimezone.posixFromOffset(const Duration(hours: 2), 'CEST'), 'CEST-2');
      expect(LocalTimezone.posixFromOffset(const Duration(hours: -5), 'EST'), 'EST+5');
      expect(LocalTimezone.posixFromOffset(Duration.zero, 'UTC'), 'UTC0');
    });

    test('handles half-hour zones and non-alphabetic abbreviations', () {
      expect(LocalTimezone.posixFromOffset(const Duration(hours: 5, minutes: 30), 'IST'), 'IST-5:30');
      expect(LocalTimezone.posixFromOffset(const Duration(hours: 3), '+03'), '<+03>-3');
    });
  });
}
