/*
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

/// OTA_STATUS values published by the controller (SuperGreenOS ota.h).
class OtaStatus {
  static const int idle = 0;
  static const int inProgress = 1;
  static const int disabled = 2;
  static const int failed = 3;
}

enum OtaWaitDecision {
  /// The controller reports the expected OTA_TIMESTAMP.
  done,

  /// Nothing conclusive yet (rebooting, still flashing, unreachable): poll again.
  keepWaiting,

  /// OTA_STATUS=3, the controller aborted (bad download, sha256 mismatch,
  /// backoff after previous failures).
  failed,

  /// OTA_STATUS=2, OTA is disabled in the controller settings.
  disabled,
}

/// Pure decision step of the post-upload polling loop, kept free of any
/// Flutter/IO dependency so it can be unit-tested.
///
/// [otaStatus] is null when the controller does not expose OTA_STATUS (older
/// firmware) or the read failed; [otaTimestamp] is null when unreadable.
OtaWaitDecision evaluateOtaWait({required int? otaStatus, required int? otaTimestamp, required int targetTimestamp}) {
  if (otaTimestamp == targetTimestamp) {
    return OtaWaitDecision.done;
  }
  if (otaStatus == OtaStatus.failed) {
    return OtaWaitDecision.failed;
  }
  if (otaStatus == OtaStatus.disabled) {
    return OtaWaitDecision.disabled;
  }
  return OtaWaitDecision.keepWaiting;
}
