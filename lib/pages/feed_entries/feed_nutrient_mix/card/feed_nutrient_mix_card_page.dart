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
import 'package:super_green_app/theme/sgl_colors.dart';
import 'package:super_green_app/widgets/feed_card/feed_value_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:super_green_app/l10n.dart';
import 'package:super_green_app/pages/feed_entries/common/comments/card/comments_card_page.dart';
import 'package:super_green_app/data/assets/feed_entry.dart';
import 'package:super_green_app/pages/feed_entries/common/social_bar/social_bar_page.dart';
import 'package:super_green_app/pages/feed_entries/entry_params/feed_nutrient_mix.dart';
import 'package:super_green_app/pages/feed_entries/feed_nutrient_mix/form/feed_nutrient_mix_form_page.dart';
import 'package:super_green_app/pages/feeds/feed/bloc/feed_bloc.dart';
import 'package:super_green_app/pages/feeds/feed/bloc/state/feed_entry_state.dart';
import 'package:super_green_app/pages/feeds/feed/bloc/state/feed_state.dart';
import 'package:super_green_app/widgets/feed_card/feed_card.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_date.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_text.dart';
import 'package:super_green_app/widgets/feed_card/feed_card_title.dart';
import 'package:super_green_app/widgets/fullscreen_loading.dart';

class FeedNutrientMixCardPage extends StatefulWidget {
  static String get feedNutrientMixCardObservations {
    return Intl.message(
      'Observations',
      name: 'feedNutrientMixCardObservations',
      desc: 'Observation field label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get feedNutrientMixCardTitle {
    return Intl.message(
      'Nutrient mix',
      name: 'feedNutrientMixCardTitle',
      desc: 'Nutrient mix card title',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String get feedNutrientMixCardWaterQuantity {
    return Intl.message(
      'Water quantity',
      name: 'feedNutrientMixCardWaterQuantity',
      desc: 'Volume field label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String feedNutrientMixCardFrom(String basedOn) {
    return Intl.message(
      'From: $basedOn',
      args: [basedOn],
      name: 'feedNutrientMixCardFrom',
      desc: '"Based on" field label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  static String feedNutrientMixCardPhase(String phase) {
    return Intl.message(
      'Phase: $phase',
      args: [phase],
      name: 'feedNutrientMixCardPhase',
      desc: '"Phase" field label',
      locale: SGLLocalizations.current?.localeName,
    );
  }

  final Animation<double> animation;
  final FeedState feedState;
  final FeedEntryState state;
  final List<Widget> Function(BuildContext context, FeedEntryState feedEntryState)? cardActions;

  const FeedNutrientMixCardPage(this.animation, this.feedState, this.state, {Key? key, this.cardActions})
      : super(key: key);

  @override
  _FeedNutrientMixCardPageState createState() => _FeedNutrientMixCardPageState();
}

class _FeedNutrientMixCardPageState extends State<FeedNutrientMixCardPage> {
  bool editText = false;

  @override
  Widget build(BuildContext context) {
    if (widget.state is FeedEntryStateLoaded) {
      return _renderLoaded(context, widget.state as FeedEntryStateLoaded);
    }
    return _renderLoading(context);
  }

  Widget _renderLoading(BuildContext context) {
    return FeedCard(
      animation: widget.animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeedCardTitle(FeedEntryIcons[FE_NUTRIENT_MIX]!, FeedNutrientMixCardPage.feedNutrientMixCardTitle,
              widget.state.synced,
              showSyncStatus: !widget.state.isRemoteState,
              showControls: !widget.state.isRemoteState,
              actions: widget.cardActions != null ? widget.cardActions!(context, widget.state) : []),
          Container(
            height: 140,
            alignment: Alignment.center,
            child: FullscreenLoading(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FeedCardDate(widget.state, widget.feedState),
          ),
        ],
      ),
    );
  }

  Widget _renderLoaded(BuildContext context, FeedEntryStateLoaded state) {
    FeedNutrientMixParams params = state.params as FeedNutrientMixParams;
    List<Widget> cards = [
      renderCard('assets/feed_form/icon_volume.svg', FeedNutrientMixCardPage.feedNutrientMixCardWaterQuantity,
          '${params.volume} L'),
    ];
    if (params.ph != null) {
      cards.add(renderCard('assets/products/toolbox/icon_ph_ec.svg', 'PH', '${params.ph}'));
    }
    if (params.ec != null) {
      cards.add(renderCard('assets/products/toolbox/icon_ph_ec.svg', 'EC', '${params.ec}', detail: 'μS/cm'));
    }
    if (params.tds != null) {
      cards.add(renderCard('assets/products/toolbox/icon_ph_ec.svg', 'TDS', '${params.tds}', detail: 'ppm'));
    }
    cards.addAll(params.nutrientProducts.map((np) => renderNutrientProduct(np)).toList());
    return FeedCard(
      animation: widget.animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeedCardTitle(
            FeedEntryIcons[FE_NUTRIENT_MIX]!,
            FeedNutrientMixCardPage.feedNutrientMixCardTitle,
            state.synced,
            showSyncStatus: !state.isRemoteState,
            showControls: !state.isRemoteState,
            onEdit: () {
              setState(() {
                editText = true;
              });
            },
            onDelete: () {
              BlocProvider.of<FeedBloc>(context).add(FeedBlocEventDeleteEntry(state));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (params.basedOn ?? '') != ''
                    ? Text(FeedNutrientMixCardPage.feedNutrientMixCardFrom(params.basedOn!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.sgl.ink3))
                    : Container(),
                (params.phase ?? '') != ''
                    ? Text(FeedNutrientMixCardPage.feedNutrientMixCardPhase(nutrientMixPhasesUI[params.phase!]!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.sgl.ink3))
                    : Container(),
              ],
            ),
          ),
          FeedTileStrip(tiles: cards),
          SocialBarPage(
            state: state,
            feedState: widget.feedState,
          ),
          (params.message ?? '') != '' || editText == true
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(FeedNutrientMixCardPage.feedNutrientMixCardObservations, style: TextStyle()),
                )
              : Container(),
          (params.message ?? '') != '' || editText == true
              ? FeedCardText(
                  params.message ?? '',
                  edit: editText,
                  onEdited: (value) {
                    BlocProvider.of<FeedBloc>(context)
                        .add(FeedBlocEventEditParams(state, params.copyWith(message: value)));
                    setState(() {
                      editText = false;
                    });
                  },
                )
              : Container(),
          CommentsCardPage(
            state: state,
            feedState: widget.feedState,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FeedCardDate(state, widget.feedState),
          ),
        ],
      ),
    );
  }

  Widget renderNutrientProduct(NutrientProduct nutrientProduct) {
    return renderCard('assets/products/toolbox/icon_fertilizer.svg', nutrientProduct.product.name,
        '${nutrientProduct.quantity}', detail: nutrientProduct.unit);
  }

  Widget renderCard(String icon, String title, String value, {String? detail}) {
    return FeedValueTile(icon: icon, label: title, value: value, detail: detail);
  }
}
