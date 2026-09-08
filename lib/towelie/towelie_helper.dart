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
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:super_green_app/data/assets/feed_entry.dart';
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/theme/sgl_typography.dart';
import 'package:super_green_app/towelie/towelie_bloc.dart';

class TowelieHelper extends StatefulWidget {
  final RouteSettings settings;

  const TowelieHelper({Key? key, required this.settings}) : super(key: key);

  @override
  _TowelieHelperState createState() => _TowelieHelperState();

  static Widget wrapWidget(RouteSettings settings, BuildContext context, Widget widget) {
    return WillPopScope(
      onWillPop: () async {
        BlocProvider.of<TowelieBloc>(context).add(TowelieBlocEventRoutePop(settings));
        return true;
      },
      child: Stack(children: [
        widget,
        TowelieHelper(settings: settings),
      ]),
    );
  }
}

class _TowelieHelperState extends State<TowelieHelper> {
  /// Hints the user already closed, per route: closing one must not bring it
  /// back on the next rebuild of the page (keyboard, text field, checkbox).
  static final Map<String, Set<String>> _dismissed = {};

  Timer? _timer;
  String text = '';
  bool visible = false;
  bool shown = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TowelieBloc, TowelieBlocState>(
      listener: (BuildContext context, TowelieBlocState state) {
        if (state is TowelieBlocStateHelper && state.settings.name == widget.settings.name) {
          if (_dismissed[widget.settings.name ?? '']?.contains(state.text) ?? false) {
            return;
          }
          _prepareShow(state);
        } else if (state is TowelieBlocStateHelperPop && state.settings.name == widget.settings.name) {
          _dismissed.remove(widget.settings.name ?? '');
          _prepareHide();
        }
      },
      child: BlocBuilder<TowelieBloc, TowelieBlocState>(
        buildWhen: (context, state) => state is TowelieBlocStateHelper && state.settings.name == widget.settings.name,
        builder: (BuildContext context, TowelieBlocState state) {
          if (visible && state is TowelieBlocStateHelper) {
            return _renderBody(state);
          }
          return Container();
        },
      ),
    );
  }

  void _dismiss() {
    (_dismissed[widget.settings.name ?? ''] ??= <String>{}).add(text);
    _prepareHide();
  }

  Widget _renderBody(TowelieBlocStateHelper state) {
    final SglColors c = context.sgl;
    final TextTheme t = Theme.of(context).textTheme;
    final List<Widget> actions = [];
    for (final Map<String, dynamic> button in state.buttons ?? const []) {
      actions.add(TextButton(
        style: TextButton.styleFrom(
          foregroundColor: c.accentDeep,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          BlocProvider.of<TowelieBloc>(context).add(TowelieBlocEventButtonPressed(context, button));
          _dismiss();
        },
        child: Text((button['title'] as String).toUpperCase(), style: SglTextStyles.mono.copyWith(fontSize: 12)),
      ));
    }
    if (state.hasNext) {
      actions.add(TextButton(
        style: TextButton.styleFrom(
          foregroundColor: c.accentDeep,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          BlocProvider.of<TowelieBloc>(context).add(TowelieBlocEventHelperNext(widget.settings));
        },
        child: Text('NEXT', style: SglTextStyles.mono.copyWith(fontSize: 12)),
      ));
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12 + MediaQuery.of(context).padding.bottom,
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Dismissible(
            direction: DismissDirection.down,
            key: const Key('Towelie'),
            onDismissed: (direction) => _dismiss(),
            child: Material(
              color: c.surface,
              elevation: 6,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.accentSoft),
                          clipBehavior: Clip.antiAlias,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: Image.asset(FeedEntryIcons[FE_TOWELIE_INFO]!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                child: Text('TOWELIE', style: SglTextStyles.eyebrow.copyWith(color: c.ink3)),
                              ),
                              MarkdownBody(
                                data: state.text,
                                styleSheet: MarkdownStyleSheet(
                                  p: t.bodyMedium?.copyWith(color: c.ink2, height: 1.35),
                                  strong: t.bodyMedium?.copyWith(color: c.ink, fontWeight: FontWeight.w600, height: 1.35),
                                  listBullet: t.bodyMedium?.copyWith(color: c.ink2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close, size: 20, color: c.ink3),
                          onPressed: _dismiss,
                        ),
                      ],
                    ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, top: 4),
                        child: Wrap(spacing: 4, children: actions),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _prepareShow(TowelieBlocStateHelper state) {
    setState(() {
      text = state.text;
      visible = true;
      shown = false;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 30), () {
      _timer = null;
      if (mounted) {
        setState(() {
          shown = true;
        });
      }
    });
  }

  void _prepareHide() {
    setState(() {
      shown = false;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 260), () {
      _timer = null;
      if (mounted) {
        setState(() {
          visible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
