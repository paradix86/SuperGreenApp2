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

/// The icon of the plant/box feed speed dial: a plus that turns into a cross
/// while the dial is open. It used to be a Rive animation
/// (assets/home/dial_button.riv); rive 0.14 rewrote its runtime and pulling a
/// native renderer for one icon was not worth it.
class PlantDialButton extends StatelessWidget {
  final bool openned;

  const PlantDialButton({Key? key, required this.openned}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: openned ? 0.125 : 0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: const Icon(Icons.add, size: 34, color: Colors.white),
    );
  }
}
