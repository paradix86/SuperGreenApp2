/*
 * Copyright (C) 2026  SuperGreenLab <towelie@supergreenlab.com>
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
import 'package:super_green_app/theme/sgl_colors.dart';

/// One of the secondary panels of the Lab (controls, graphs, infos,
/// products): what used to be a page of the dotted carousel.
class LabPanel {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const LabPanel({required this.label, required this.icon, required this.builder});
}

/// Row of buttons opening each [LabPanel] in a bottom sheet.
class LabPanelsRow extends StatelessWidget {
  final List<LabPanel> panels;

  const LabPanelsRow({Key? key, required this.panels}) : super(key: key);

  static void open(BuildContext context, LabPanel panel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        // The panel's own vertical ListView picks up the sheet's controller
        // through PrimaryScrollController, so dragging the list past its top
        // shrinks and closes the sheet instead of only the title area.
        // snap: a release below the halfway point falls to minChildSize,
        // which closes the modal (shouldCloseOnMinExtent); above it the
        // sheet springs back to its full size.
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.82],
          builder: (BuildContext context, ScrollController scrollController) {
            return PrimaryScrollController(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(panel.label, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Expanded(child: panel.builder(context)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final SglColors c = context.sgl;
    return Row(
      children: panels
          .map((panel) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () => open(context, panel),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: c.surface,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(panel.icon, size: 20, color: c.ink2),
                        const SizedBox(height: 4),
                        Text(panel.label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: c.ink2)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
