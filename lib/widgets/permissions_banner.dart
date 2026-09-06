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
import 'package:permission_handler/permission_handler.dart';
import 'package:super_green_app/data/kv/app_db.dart';
import 'package:super_green_app/notifications/notifications.dart';
import 'package:super_green_app/notifications/remote_notifications.dart';

class PermissionsBanner extends StatefulWidget {
  const PermissionsBanner({Key? key}) : super(key: key);

  @override
  _PermissionsBannerState createState() => _PermissionsBannerState();
}

class _PermissionsBannerState extends State<PermissionsBanner> {
  static const String _dismissCacheKey = 'permissions_banner.dismissed';

  bool _loading = false;
  bool _showBanner = false;
  bool _notificationsGranted = true;
  bool _cameraGranted = true;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_showBanner == false) {
      return const SizedBox.shrink();
    }
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    final double topInset = mediaQuery?.padding.top ?? 0;
    final List<String> missing = [];
    if (!_notificationsGranted) {
      missing.add('notifications');
    }
    if (!_cameraGranted) {
      missing.add('camera');
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xfffff3cd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.security, color: Color(0xff8a5a00), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enable ${missing.join(' + ')} for full greenhouse control.',
                  style: const TextStyle(
                    color: Color(0xff8a5a00),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : _dismissBanner,
                child: const Text('NOT NOW'),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _enableMissingPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8a5a00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ENABLE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshPermissions() async {
    final bool notificationsGranted = await RemoteNotifications.checkPermissions();
    final PermissionStatus cameraStatus = await Permission.camera.status;
    final bool cameraGranted = cameraStatus.isGranted || cameraStatus.isLimited;
    final bool dismissed = AppDB().getCachedString(_dismissCacheKey) == '1';
    final bool missing = !notificationsGranted || !cameraGranted;

    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsGranted = notificationsGranted;
      _cameraGranted = cameraGranted;
      _showBanner = missing && !dismissed;
      _loading = false;
    });
  }

  void _dismissBanner() {
    AppDB().setCachedString(_dismissCacheKey, '1');
    setState(() {
      _showBanner = false;
    });
  }

  Future<void> _enableMissingPermissions() async {
    setState(() {
      _loading = true;
    });
    if (!_notificationsGranted) {
      await NotificationsBloc.remoteNotifications.requestPermissions();
    }
    if (!_cameraGranted) {
      await Permission.camera.request();
    }
    AppDB().deleteCacheString(_dismissCacheKey);
    await _refreshPermissions();
  }
}
