import 'package:flutter_test/flutter_test.dart';
import 'package:super_green_app/data/api/device/ota_wait.dart';

void main() {
  const int target = 1788705153;

  test('done as soon as OTA_TIMESTAMP matches, whatever OTA_STATUS says', () {
    expect(evaluateOtaWait(otaStatus: OtaStatus.idle, otaTimestamp: target, targetTimestamp: target),
        OtaWaitDecision.done);
    expect(evaluateOtaWait(otaStatus: null, otaTimestamp: target, targetTimestamp: target), OtaWaitDecision.done);
  });

  test('failed / disabled are reported from OTA_STATUS', () {
    expect(
        evaluateOtaWait(otaStatus: OtaStatus.failed, otaTimestamp: 1, targetTimestamp: target), OtaWaitDecision.failed);
    expect(evaluateOtaWait(otaStatus: OtaStatus.disabled, otaTimestamp: 1, targetTimestamp: target),
        OtaWaitDecision.disabled);
  });

  test('keeps waiting while flashing, rebooting, or on firmware without OTA_STATUS', () {
    expect(evaluateOtaWait(otaStatus: OtaStatus.inProgress, otaTimestamp: 1, targetTimestamp: target),
        OtaWaitDecision.keepWaiting);
    expect(evaluateOtaWait(otaStatus: null, otaTimestamp: null, targetTimestamp: target), OtaWaitDecision.keepWaiting);
    expect(evaluateOtaWait(otaStatus: OtaStatus.idle, otaTimestamp: 1, targetTimestamp: target),
        OtaWaitDecision.keepWaiting);
  });
}
