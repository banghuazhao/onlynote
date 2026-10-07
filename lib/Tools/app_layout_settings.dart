import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onlynote/domain/model/note_card_style.dart';

export 'package:onlynote/domain/model/note_card_style.dart' show NoteCardSize;

/// Home screen note card size preference, persisted via SharedPreferences.
class AppLayoutSettings extends ChangeNotifier {
  AppLayoutSettings._();
  static final AppLayoutSettings instance = AppLayoutSettings._();

  static const _cardSizeKey = 'app_note_card_size';

  NoteCardSize _cardSize = NoteCardSize.medium;

  NoteCardSize get cardSize => _cardSize;

  Future<void> load({bool notify = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedSize = prefs.getString(_cardSizeKey);
    _cardSize = NoteCardSize.values.firstWhere(
      (size) => size.name == storedSize,
      orElse: () => NoteCardSize.medium,
    );
    if (notify) notifyListeners();
  }

  Future<void> setCardSize(NoteCardSize cardSize) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_cardSizeKey, cardSize.name)) {
      throw StateError('Could not save layout');
    }
    _cardSize = cardSize;
    notifyListeners();
  }
}
