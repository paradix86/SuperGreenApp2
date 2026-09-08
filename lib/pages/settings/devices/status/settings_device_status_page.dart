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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:super_green_app/data/api/device/device_status.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/l10n/common.dart';
import 'package:super_green_app/pages/settings/devices/status/settings_device_status_bloc.dart';
import 'package:super_green_app/widgets/appbar.dart';
import 'package:super_green_app/widgets/fullscreen.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';
import 'package:super_green_app/widgets/green_button.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/widgets/section_title.dart';
import 'package:super_green_app/widgets/sgl/sgl_card.dart';

class SettingsDeviceStatusPage extends StatelessWidget {
  static const Color WARNING_BACKGROUND = Color(0xfffff0cc);
  static const Color OK_TEXT = Color(0xff2f6f2f);
  static const Color OK_BACKGROUND = Color(0xffdcf4dc);

  static const int BYTES_PER_KB = 1024;
  static const int SECONDS_PER_MINUTE = 60;
  static const int SECONDS_PER_HOUR = 3600;
  static const int SECONDS_PER_DAY = 86400;

  static String get settingsDeviceStatusPageTitle {
    return Intl.message(
      'Controller status',
      name: 'settingsDeviceStatusPageTitle',
      desc: 'Controller status page title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageRefresh {
    return Intl.message(
      'Refresh',
      name: 'settingsDeviceStatusPageRefresh',
      desc: 'Controller status refresh button',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageRetry {
    return Intl.message(
      'RETRY',
      name: 'settingsDeviceStatusPageRetry',
      desc: 'Controller status retry button',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageNotAvailable {
    return Intl.message(
      'n/a',
      name: 'settingsDeviceStatusPageNotAvailable',
      desc: 'Placeholder for a status value missing from the controller response',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageUnreachableTitle {
    return Intl.message(
      'Controller unreachable',
      name: 'settingsDeviceStatusPageUnreachableTitle',
      desc: 'Controller status error title when the controller is not on the local network',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageUnreachableSubtitle {
    return Intl.message(
      'The controller must be reachable on the local network to read its status. Make sure your phone is on the same wifi.',
      name: 'settingsDeviceStatusPageUnreachableSubtitle',
      desc: 'Controller status error message when the controller is not on the local network',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageUnsupportedTitle {
    return Intl.message(
      'Not supported',
      name: 'settingsDeviceStatusPageUnsupportedTitle',
      desc: 'Controller status error title when the firmware has no status endpoint',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageUnsupportedSubtitle {
    return Intl.message(
      'This controller firmware does not expose status diagnostics. Upgrade the firmware to use this page.',
      name: 'settingsDeviceStatusPageUnsupportedSubtitle',
      desc: 'Controller status error message when the firmware has no status endpoint',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageFailedTitle {
    return Intl.message(
      'Error',
      name: 'settingsDeviceStatusPageFailedTitle',
      desc: 'Controller status error title when the request failed',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageFailedSubtitle {
    return Intl.message(
      'Couldn\'t read the controller status, please try again.',
      name: 'settingsDeviceStatusPageFailedSubtitle',
      desc: 'Controller status error message when the request failed',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageSectionConnectivity {
    return Intl.message(
      'Connectivity',
      name: 'settingsDeviceStatusPageSectionConnectivity',
      desc: 'Controller status section title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageSectionHealth {
    return Intl.message(
      'Health',
      name: 'settingsDeviceStatusPageSectionHealth',
      desc: 'Controller status section title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageSectionLastReboot {
    return Intl.message(
      'Last reboot',
      name: 'settingsDeviceStatusPageSectionLastReboot',
      desc: 'Controller status section title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageSectionOta {
    return Intl.message(
      'OTA',
      name: 'settingsDeviceStatusPageSectionOta',
      desc: 'Controller status section title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageWifi {
    return Intl.message(
      'Wifi',
      name: 'settingsDeviceStatusPageWifi',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageMqtt {
    return Intl.message(
      'MQTT',
      name: 'settingsDeviceStatusPageMqtt',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageBrokerUrl {
    return Intl.message(
      'Broker',
      name: 'settingsDeviceStatusPageBrokerUrl',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageBrokerClientId {
    return Intl.message(
      'Client ID',
      name: 'settingsDeviceStatusPageBrokerClientId',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageConnected {
    return Intl.message(
      'Connected',
      name: 'settingsDeviceStatusPageConnected',
      desc: 'Controller status connected value',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageDisconnected {
    return Intl.message(
      'Disconnected',
      name: 'settingsDeviceStatusPageDisconnected',
      desc: 'Controller status disconnected value',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageUptime {
    return Intl.message(
      'Uptime',
      name: 'settingsDeviceStatusPageUptime',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageHeapFree {
    return Intl.message(
      'Free heap',
      name: 'settingsDeviceStatusPageHeapFree',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageHeapMinFree {
    return Intl.message(
      'Min free heap',
      name: 'settingsDeviceStatusPageHeapMinFree',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageHeapMinFreeAt {
    return Intl.message(
      'Min heap reached at uptime',
      name: 'settingsDeviceStatusPageHeapMinFreeAt',
      desc: 'Controller status row label: uptime at which the heap minimum was observed',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageHeapLowEvents {
    return Intl.message(
      'Low heap events (< 8 KB)',
      name: 'settingsDeviceStatusPageHeapLowEvents',
      desc: 'Controller status row label: times free heap dropped under the 8 KB floor',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageNvs {
    return Intl.message(
      'NVS entries (used / free)',
      name: 'settingsDeviceStatusPageNvs',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageClock {
    return Intl.message(
      'Clock',
      name: 'settingsDeviceStatusPageClock',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageClockValid {
    return Intl.message(
      'Synced',
      name: 'settingsDeviceStatusPageClockValid',
      desc: 'Controller status clock synced value',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageClockInvalid {
    return Intl.message(
      'Not synced',
      name: 'settingsDeviceStatusPageClockInvalid',
      desc: 'Controller status clock not synced value',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageRestarts {
    return Intl.message(
      'Restarts',
      name: 'settingsDeviceStatusPageRestarts',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageResetReason {
    return Intl.message(
      'Reason',
      name: 'settingsDeviceStatusPageResetReason',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageResetHistory {
    return Intl.message(
      'History (most recent first)',
      name: 'settingsDeviceStatusPageResetHistory',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get settingsDeviceStatusPageOtaStatus {
    return Intl.message(
      'Status',
      name: 'settingsDeviceStatusPageOtaStatus',
      desc: 'Controller status row label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String settingsDeviceStatusPageFetchedAt(String time) {
    return Intl.message(
      'Last read at $time',
      args: [time],
      name: 'settingsDeviceStatusPageFetchedAt',
      desc: 'Controller status footer with the time of the last read',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsDeviceStatusBloc, SettingsDeviceStatusBlocState>(
      builder: (BuildContext context, SettingsDeviceStatusBlocState state) {
        Widget body = FullscreenLoading(title: CommonL10N.loading);
        if (state is SettingsDeviceStatusBlocStateLoaded) {
          body = renderLoaded(context, state);
        } else if (state is SettingsDeviceStatusBlocStateError) {
          body = renderError(context, state);
        }
        bool isLoading = state is SettingsDeviceStatusBlocStateInit || state is SettingsDeviceStatusBlocStateLoading;
        return Scaffold(
          appBar: SGLAppBar(
            settingsDeviceStatusPageTitle,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                tooltip: settingsDeviceStatusPageRefresh,
                onPressed: isLoading ? null : () => _refresh(context),
              ),
            ],
          ),
          body: AnimatedSwitcher(duration: Duration(milliseconds: 200), child: body),
        );
      },
    );
  }

  void _refresh(BuildContext context) {
    BlocProvider.of<SettingsDeviceStatusBloc>(context).add(SettingsDeviceStatusBlocEventRefresh());
  }

  Widget renderError(BuildContext context, SettingsDeviceStatusBlocStateError state) {
    String title;
    String subtitle;
    IconData icon;
    switch (state.kind) {
      case SettingsDeviceStatusErrorKind.unreachable:
        title = settingsDeviceStatusPageUnreachableTitle;
        subtitle = settingsDeviceStatusPageUnreachableSubtitle;
        icon = Icons.wifi_off;
        break;
      case SettingsDeviceStatusErrorKind.unsupported:
        title = settingsDeviceStatusPageUnsupportedTitle;
        subtitle = settingsDeviceStatusPageUnsupportedSubtitle;
        icon = Icons.system_update;
        break;
      case SettingsDeviceStatusErrorKind.failed:
      default:
        title = settingsDeviceStatusPageFailedTitle;
        subtitle = settingsDeviceStatusPageFailedSubtitle;
        icon = Icons.error;
        break;
    }
    return Fullscreen(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          Icon(icon, color: context.sgl.warn, size: 100),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: GreenButton(title: settingsDeviceStatusPageRetry, onPressed: () => _refresh(context)),
          ),
        ],
      ),
    );
  }

  Widget renderLoaded(BuildContext context, SettingsDeviceStatusBlocStateLoaded state) {
    DeviceStatus status = state.status;
    return ListView(
      children: <Widget>[
        _renderSection(settingsDeviceStatusPageSectionConnectivity, 'assets/settings/icon_wifi.svg'),
        _renderRow(settingsDeviceStatusPageWifi, _renderConnectedBadge(status.wifiStatus, status.isWifiConnected)),
        _renderRow(settingsDeviceStatusPageMqtt, _renderConnectedBadge(status.mqttConnected, status.isMqttConnected)),
        _renderRow(settingsDeviceStatusPageBrokerUrl, _renderValue(status.brokerUrl)),
        _renderRow(settingsDeviceStatusPageBrokerClientId, _renderValue(status.brokerClientId)),
        _renderSection(settingsDeviceStatusPageSectionHealth, 'assets/settings/icon_controller.svg'),
        _renderRow(settingsDeviceStatusPageUptime, _renderValue(formatUptime(status.uptimeS))),
        _renderRow(settingsDeviceStatusPageHeapFree, _renderValue(formatKb(status.heapFree))),
        _renderRow(settingsDeviceStatusPageHeapMinFree, _renderValue(formatKb(status.heapMinFree))),
        _renderRow(settingsDeviceStatusPageHeapMinFreeAt, _renderValue(formatUptime(status.heapMinFreeAt))),
        _renderRow(settingsDeviceStatusPageHeapLowEvents, _renderHeapLowEvents(status.heapLowEvents)),
        if (status.heapMinCtx != null && status.heapMinCtx != 'none')
          _renderRow('At that moment', _renderValue(status.heapMinCtx)),
        _renderRow(settingsDeviceStatusPageNvs,
            _renderValue('${_orNa(status.nvsUsed?.toString())} / ${_orNa(status.nvsFree?.toString())}')),
        _renderRow(settingsDeviceStatusPageClock, _renderClockBadge(status)),
        _renderRow(settingsDeviceStatusPageRestarts, _renderValue(status.nRestarts?.toString())),
        _renderSection(settingsDeviceStatusPageSectionLastReboot, 'assets/settings/icon_warning.svg'),
        _renderRow(settingsDeviceStatusPageResetReason, _renderResetReasonBadge(status.resetReason)),
        _renderRow(settingsDeviceStatusPageResetHistory, _renderResetHistory(status.resetHistory)),
        _renderSection(settingsDeviceStatusPageSectionOta, 'assets/settings/icon_upgrade.svg'),
        _renderRow(settingsDeviceStatusPageOtaStatus, _renderOtaBadge(status.otaStatus)),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            settingsDeviceStatusPageFetchedAt(DateFormat.Hms().format(state.fetchedAt)),
            textAlign: TextAlign.center,
            style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _renderSection(String title, String icon) {
    return SectionTitle(
      title: title,
      icon: icon,
      elevation: 5,
    );
  }

  Widget _renderRow(String label, Widget value) {
    return Builder(builder: (BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: SglTextStyles.mono.copyWith(color: context.sgl.ink3, fontSize: 12)),
          ),
          SizedBox(width: 8),
          Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: value)),
        ],
      ),
    ));
  }

  Widget _renderValue(String? value) {
    return Builder(
        builder: (BuildContext context) =>
            Text(_orNa(value), textAlign: TextAlign.right, style: SglTextStyles.mono.copyWith(color: context.sgl.ink)));
  }

  Widget _renderConnectedBadge(int? rawValue, bool isConnected) {
    if (rawValue == null) {
      return _renderValue(null);
    }
    return _renderChip(isConnected ? settingsDeviceStatusPageConnected : settingsDeviceStatusPageDisconnected,
        ok: isConnected);
  }

  Widget _renderClockBadge(DeviceStatus status) {
    if (status.timeValid == null) {
      return _renderValue(null);
    }
    return _renderChip(status.isTimeValid ? settingsDeviceStatusPageClockValid : settingsDeviceStatusPageClockInvalid,
        ok: status.isTimeValid);
  }

  Widget _renderResetReasonBadge(int? reason) {
    if (reason == null) {
      return _renderValue(null);
    }
    return _renderChip(formatResetReason(reason), ok: !DeviceStatus.isAbnormalResetReason(reason));
  }

  Widget _renderHeapLowEvents(int? events) {
    if (events == null) {
      return _renderValue(null);
    }
    return _renderChip(events.toString(), ok: events == 0);
  }

  Widget _renderOtaBadge(int? otaStatus) {
    if (otaStatus == null) {
      return _renderValue(null);
    }
    return _renderChip(DeviceStatus.otaStatusLabel(otaStatus), ok: otaStatus == DeviceStatus.OTA_IDLE);
  }

  Widget _renderChip(String label, {required bool ok}) {
    return SglStatusChip(label: label, status: ok ? SglStatus.ok : SglStatus.warn);
  }

  Widget _renderResetHistory(List<int> history) {
    if (history.isEmpty) {
      return _renderValue(null);
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      runSpacing: 6,
      children: history
          .map<Widget>(
              (int reason) => _renderChip(formatResetReason(reason), ok: !DeviceStatus.isAbnormalResetReason(reason)))
          .toList(),
    );
  }

  String _orNa(String? value) {
    return value ?? settingsDeviceStatusPageNotAvailable;
  }

  static String formatResetReason(int reason) {
    return '${DeviceStatus.resetReasonLabel(reason)} ($reason)';
  }

  static String? formatKb(int? bytes) {
    if (bytes == null) {
      return null;
    }
    return '${(bytes / BYTES_PER_KB).toStringAsFixed(1)} KB';
  }

  /// Formats seconds as "3d 4h" when at least one day has elapsed, otherwise "hh:mm:ss".
  static String? formatUptime(int? seconds) {
    if (seconds == null || seconds < 0) {
      return null;
    }
    int days = seconds ~/ SECONDS_PER_DAY;
    int hours = (seconds % SECONDS_PER_DAY) ~/ SECONDS_PER_HOUR;
    if (days > 0) {
      return '${days}d ${hours}h';
    }
    int minutes = (seconds % SECONDS_PER_HOUR) ~/ SECONDS_PER_MINUTE;
    int secs = seconds % SECONDS_PER_MINUTE;
    return '${_pad2(hours)}:${_pad2(minutes)}:${_pad2(secs)}';
  }

  static String _pad2(int value) => value.toString().padLeft(2, '0');
}
