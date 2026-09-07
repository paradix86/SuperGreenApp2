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

/// Single-line text input styled by the theme's InputDecorationTheme.
class SGLTextField extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final TextEditingController controller;
  final bool? enabled;
  final TextInputAction textInputAction;
  final Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool obscureText;
  final String? error;
  final TextCapitalization textCapitalization;

  const SGLTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.enabled,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.focusNode,
    this.obscureText = false,
    this.error,
    this.textCapitalization = TextCapitalization.sentences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
      enabled: enabled,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: error,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      obscureText: obscureText,
    );
  }
}
