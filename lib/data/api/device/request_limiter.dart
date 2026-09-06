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
import 'dart:collection';

/// Bounds the number of concurrent actions (HTTP exchanges with one controller).
///
/// Each open socket costs the ESP32 roughly 3-4 KB of heap; a load test with 4
/// requests in flight took its free heap from 40 KB to 23 KB. Callers queue in
/// FIFO order and get a slot as soon as one is released.
class RequestLimiter {
  final int maxInFlight;
  int _inFlight = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  RequestLimiter(this.maxInFlight) : assert(maxInFlight > 0);

  int get inFlight => _inFlight;
  int get waiting => _waiters.length;

  /// Runs [action] once a slot is free; the slot is released when it completes
  /// or throws.
  Future<T> run<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() {
    if (_inFlight < maxInFlight) {
      ++_inFlight;
      return Future<void>.value();
    }
    final Completer<void> waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      // hand the slot straight to the next waiter: _inFlight stays the same
      _waiters.removeFirst().complete();
      return;
    }
    --_inFlight;
  }
}
