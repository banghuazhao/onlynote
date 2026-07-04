import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NoteCardSize {
  large(1),
  medium(2),
  small(3);

  const NoteCardSize(this.columns);
  final int columns;
}

/// Home screen note card size preference, persisted via SharedPreferences.
class AppLayoutSettings extends ChangeNotifier {
  AppLayoutSettings._();
  static final AppLayoutSettings instance = AppLayoutSettings._();

  static const _cardSizeKey = 'app_note_card_size';

  NoteCardSize _cardSize = NoteCardSize.medium;

  NoteCardSize get cardSize => _cardSize;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSize = prefs.getString(_cardSizeKey);
    _cardSize = NoteCardSize.values.firstWhere(
      (size) => size.name == storedSize,
      orElse: () => NoteCardSize.medium,
    );
  }

  Future<void> setCardSize(NoteCardSize cardSize) async {
    _cardSize = cardSize;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardSizeKey, cardSize.name);
  }
}
