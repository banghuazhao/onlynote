import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:open_store/open_store.dart';

class MoreAppsPage extends StatelessWidget {
  const MoreAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _items(context)
        .where((item) => Platform.isIOS || item.androidId.isNotEmpty)
        .toList();
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).More_Apps)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
                tokens.space4, tokens.space2, tokens.space4, tokens.space6),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: tokens.space2),
            itemBuilder: (context, index) => _MoreAppsRow(item: items[index]),
          ),
        ),
      ),
    );
  }

  List<_MoreAppItem> _items(BuildContext context) => [
        _MoreAppItem('relaxing_up', S.of(context).Relaxing_Up, '1618712178',
            'com.appsbay.relaxing_up'),
        _MoreAppItem('image_guru', S.of(context).Image_Guru, '1625021625', ''),
        _MoreAppItem('mint_translate', S.of(context).Mint_Translate,
            '1638456603', 'com.appsbay.mint_translate'),
        _MoreAppItem('yes_habit', S.of(context).Yes_Habit, '1637643734', ''),
        _MoreAppItem('we_play_piano', S.of(context).We_Play_Piano, '1625018611',
            'com.appsbay.we_play_piano'),
        _MoreAppItem('minesweeper_go', S.of(context).Minesweeper_Go,
            '1621899572', 'com.appsbay.classic_minesweeper'),
        _MoreAppItem('metronome_go', S.of(context).Metronome_Go, '1635462172',
            'com.appsbay.metronome_go'),
        _MoreAppItem('instant_face', S.of(context).Instant_Face, '1638563222',
            'com.appsbay.instant_face'),
        _MoreAppItem('world_weather_live', S.of(context).World_Weather_Live,
            '1612773646', 'com.appsbay.world_weather_live'),
        _MoreAppItem(
            'shows', S.of(context).Shows, '1624910011', 'com.appsbay.shows'),
        _MoreAppItem('classical_music_box', S.of(context).Classical_Music_Box,
            '1613096431', 'com.appsbay.classical_music_box'),
        _MoreAppItem(
            'money_tracker', S.of(context).Money_Tracker, '1534244892', ''),
        _MoreAppItem('sudoku_lover', S.of(context).Sudoku_Lover, '1620749798',
            'com.appsbay.sudoku_lovers'),
        _MoreAppItem('express_scan', S.of(context).Express_Scan, '1625121991',
            'com.appsbay.express_scan'),
        _MoreAppItem(
            'water_tracker', S.of(context).Water_Tracker, '1534891702', ''),
        _MoreAppItem('novels_hub', S.of(context).Novels_Hub, '1528820845',
            'com.appsbay.novelshub'),
        _MoreAppItem('simple_calculator', S.of(context).Simple_Calculator,
            '1610829871', 'com.appsbay.simple_calculator'),
      ];
}

class _MoreAppItem {
  const _MoreAppItem(
      this.assetName, this.title, this.appStoreId, this.androidId);
  final String assetName;
  final String title;
  final String appStoreId;
  final String androidId;
}

class _MoreAppsRow extends StatelessWidget {
  const _MoreAppsRow({required this.item});
  final _MoreAppItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.all(context.tokens.space2),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(context.tokens.radiusSmall),
          child: Image.asset(
            'assets/app_icons/${item.assetName}.png',
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            semanticLabel: item.title,
          ),
        ),
        title: Text(item.title),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: () => OpenStore.instance.open(
          appStoreId: item.appStoreId,
          androidAppBundleId: item.androidId,
        ),
      ),
    );
  }
}
