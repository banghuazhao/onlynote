// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Notes`
  String get notes {
    return Intl.message(
      'Notes',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get Edit {
    return Intl.message(
      'Edit',
      name: 'Edit',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Saving`
  String get Saving {
    return Intl.message(
      'Saving',
      name: 'Saving',
      desc: '',
      args: [],
    );
  }

  /// `Todo List`
  String get Todo_list {
    return Intl.message(
      'Todo List',
      name: 'Todo_list',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get Delete {
    return Intl.message(
      'Delete',
      name: 'Delete',
      desc: '',
      args: [],
    );
  }

  /// `No notes found..\nclick  +  to add new one.`
  String get No_notes_found {
    return Intl.message(
      'No notes found..\nclick  +  to add new one.',
      name: 'No_notes_found',
      desc: '',
      args: [],
    );
  }

  /// `Add todo`
  String get Add_todo {
    return Intl.message(
      'Add todo',
      name: 'Add_todo',
      desc: '',
      args: [],
    );
  }

  /// `Todo..`
  String get Todo {
    return Intl.message(
      'Todo..',
      name: 'Todo',
      desc: '',
      args: [],
    );
  }

  /// `Type something...`
  String get Type_something {
    return Intl.message(
      'Type something...',
      name: 'Type_something',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get Title {
    return Intl.message(
      'Title',
      name: 'Title',
      desc: '',
      args: [],
    );
  }

  /// `Note Added Successfully`
  String get Note_Added_Successfully {
    return Intl.message(
      'Note Added Successfully',
      name: 'Note_Added_Successfully',
      desc: '',
      args: [],
    );
  }

  /// `Note Deleted`
  String get Note_Deleted {
    return Intl.message(
      'Note Deleted',
      name: 'Note_Deleted',
      desc: '',
      args: [],
    );
  }

  /// `Note Updated Successfully`
  String get Note_Updated_Successfully {
    return Intl.message(
      'Note Updated Successfully',
      name: 'Note_Updated_Successfully',
      desc: '',
      args: [],
    );
  }

  /// `Notes Deleted Successfully`
  String get Notes_Deleted_Successfully {
    return Intl.message(
      'Notes Deleted Successfully',
      name: 'Notes_Deleted_Successfully',
      desc: '',
      args: [],
    );
  }

  /// `Can't save an empty note. Add a title, description, checklist item, or photo.`
  String get Failed_to_add_note_Title_should_not_empty {
    return Intl.message(
      'Can\'t save an empty note. Add a title, description, checklist item, or photo.',
      name: 'Failed_to_add_note_Title_should_not_empty',
      desc: '',
      args: [],
    );
  }

  /// `Can't save an empty note. Add a title, description, checklist item, or photo.`
  String get Failed_to_update_note_Title_should_not_empty {
    return Intl.message(
      'Can\'t save an empty note. Add a title, description, checklist item, or photo.',
      name: 'Failed_to_update_note_Title_should_not_empty',
      desc: '',
      args: [],
    );
  }

  /// `Failed to add note, please try again.`
  String get Failed_to_add_note_please_try_again {
    return Intl.message(
      'Failed to add note, please try again.',
      name: 'Failed_to_add_note_please_try_again',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load note, please try again.`
  String get Failed_to_load_note_please_try_again {
    return Intl.message(
      'Failed to load note, please try again.',
      name: 'Failed_to_load_note_please_try_again',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load notes, please try again.`
  String get Failed_to_load_notes_please_try_again {
    return Intl.message(
      'Failed to load notes, please try again.',
      name: 'Failed_to_load_notes_please_try_again',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete note, please try again.`
  String get Failed_to_delete_note_please_try_again {
    return Intl.message(
      'Failed to delete note, please try again.',
      name: 'Failed_to_delete_note_please_try_again',
      desc: '',
      args: [],
    );
  }

  /// `Failed to Update note, please try again.`
  String get Failed_to_Update_note_please_try_again {
    return Intl.message(
      'Failed to Update note, please try again.',
      name: 'Failed_to_Update_note_please_try_again',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete notes`
  String get Failed_to_delete_notes {
    return Intl.message(
      'Failed to delete notes',
      name: 'Failed_to_delete_notes',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get Share {
    return Intl.message(
      'Share',
      name: 'Share',
      desc: '',
      args: [],
    );
  }

  /// `Failed to share note, please try again.`
  String get Share_Note_Failed {
    return Intl.message(
      'Failed to share note, please try again.',
      name: 'Share_Note_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Delete this item?`
  String get Delete_Todo_Confirm_Title {
    return Intl.message(
      'Delete this item?',
      name: 'Delete_Todo_Confirm_Title',
      desc: '',
      args: [],
    );
  }

  /// `This checklist item will be removed. This can't be undone.`
  String get Delete_Todo_Confirm_Message {
    return Intl.message(
      'This checklist item will be removed. This can\'t be undone.',
      name: 'Delete_Todo_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Delete this note?`
  String get Delete_Note_Confirm_Title {
    return Intl.message(
      'Delete this note?',
      name: 'Delete_Note_Confirm_Title',
      desc: '',
      args: [],
    );
  }

  /// `This note will be permanently deleted. This can't be undone.`
  String get Delete_Note_Confirm_Message {
    return Intl.message(
      'This note will be permanently deleted. This can\'t be undone.',
      name: 'Delete_Note_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate`
  String get Duplicate {
    return Intl.message(
      'Duplicate',
      name: 'Duplicate',
      desc: '',
      args: [],
    );
  }

  /// `Note Duplicated Successfully`
  String get Note_Duplicated_Successfully {
    return Intl.message(
      'Note Duplicated Successfully',
      name: 'Note_Duplicated_Successfully',
      desc: '',
      args: [],
    );
  }

  /// `(Copy)`
  String get Copy_Suffix {
    return Intl.message(
      '(Copy)',
      name: 'Copy_Suffix',
      desc: '',
      args: [],
    );
  }

  /// `Select`
  String get Select {
    return Intl.message(
      'Select',
      name: 'Select',
      desc: '',
      args: [],
    );
  }

  /// `Reorder`
  String get Reorder {
    return Intl.message(
      'Reorder',
      name: 'Reorder',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get Done {
    return Intl.message(
      'Done',
      name: 'Done',
      desc: '',
      args: [],
    );
  }

  /// `Choose From Gallery`
  String get Choose_From_Gallery {
    return Intl.message(
      'Choose From Gallery',
      name: 'Choose_From_Gallery',
      desc: '',
      args: [],
    );
  }

  /// `Take Photo`
  String get Take_Photo {
    return Intl.message(
      'Take Photo',
      name: 'Take_Photo',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get Settings {
    return Intl.message(
      'Settings',
      name: 'Settings',
      desc: '',
      args: [],
    );
  }

  /// `Font Style`
  String get Font_Style {
    return Intl.message(
      'Font Style',
      name: 'Font_Style',
      desc: '',
      args: [],
    );
  }

  /// `Font Size`
  String get Font_Size {
    return Intl.message(
      'Font Size',
      name: 'Font_Size',
      desc: '',
      args: [],
    );
  }

  /// `Card Size`
  String get Card_Size {
    return Intl.message(
      'Card Size',
      name: 'Card_Size',
      desc: '',
      args: [],
    );
  }

  /// `Small`
  String get Small {
    return Intl.message(
      'Small',
      name: 'Small',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get Medium {
    return Intl.message(
      'Medium',
      name: 'Medium',
      desc: '',
      args: [],
    );
  }

  /// `Large`
  String get Large {
    return Intl.message(
      'Large',
      name: 'Large',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message(
      'Cancel',
      name: 'Cancel',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get OK {
    return Intl.message(
      'OK',
      name: 'OK',
      desc: '',
      args: [],
    );
  }

  /// `Allow Notification`
  String get Allow_Notification {
    return Intl.message(
      'Allow Notification',
      name: 'Allow_Notification',
      desc: '',
      args: [],
    );
  }

  /// `Reminder`
  String get Reminder {
    return Intl.message(
      'Reminder',
      name: 'Reminder',
      desc: '',
      args: [],
    );
  }

  /// `To get a reminder, please go to settings to open notification.`
  String get To_get_notification {
    return Intl.message(
      'To get a reminder, please go to settings to open notification.',
      name: 'To_get_notification',
      desc: '',
      args: [],
    );
  }

  /// `Onlynote`
  String get Onlynote {
    return Intl.message(
      'Onlynote',
      name: 'Onlynote',
      desc: '',
      args: [],
    );
  }

  /// `Add Reminder`
  String get Add_Reminder {
    return Intl.message(
      'Add Reminder',
      name: 'Add_Reminder',
      desc: '',
      args: [],
    );
  }

  /// `More Apps`
  String get More_Apps {
    return Intl.message(
      'More Apps',
      name: 'More_Apps',
      desc: '',
      args: [],
    );
  }

  /// `World Weather Live`
  String get World_Weather_Live {
    return Intl.message(
      'World Weather Live',
      name: 'World_Weather_Live',
      desc: '',
      args: [],
    );
  }

  /// `Image Guru`
  String get Image_Guru {
    return Intl.message(
      'Image Guru',
      name: 'Image_Guru',
      desc: '',
      args: [],
    );
  }

  /// `We Play Piano`
  String get We_Play_Piano {
    return Intl.message(
      'We Play Piano',
      name: 'We_Play_Piano',
      desc: '',
      args: [],
    );
  }

  /// `Mint Translate`
  String get Mint_Translate {
    return Intl.message(
      'Mint Translate',
      name: 'Mint_Translate',
      desc: '',
      args: [],
    );
  }

  /// `Yes Habit`
  String get Yes_Habit {
    return Intl.message(
      'Yes Habit',
      name: 'Yes_Habit',
      desc: '',
      args: [],
    );
  }

  /// `Metronome Go`
  String get Metronome_Go {
    return Intl.message(
      'Metronome Go',
      name: 'Metronome_Go',
      desc: '',
      args: [],
    );
  }

  /// `Instant Face`
  String get Instant_Face {
    return Intl.message(
      'Instant Face',
      name: 'Instant_Face',
      desc: '',
      args: [],
    );
  }

  /// `Classical Music Box`
  String get Classical_Music_Box {
    return Intl.message(
      'Classical Music Box',
      name: 'Classical_Music_Box',
      desc: '',
      args: [],
    );
  }

  /// `Money Tracker`
  String get Money_Tracker {
    return Intl.message(
      'Money Tracker',
      name: 'Money_Tracker',
      desc: '',
      args: [],
    );
  }

  /// `Sudoku Lover`
  String get Sudoku_Lover {
    return Intl.message(
      'Sudoku Lover',
      name: 'Sudoku_Lover',
      desc: '',
      args: [],
    );
  }

  /// `Novels Hub`
  String get Novels_Hub {
    return Intl.message(
      'Novels Hub',
      name: 'Novels_Hub',
      desc: '',
      args: [],
    );
  }

  /// `Simple Calculator`
  String get Simple_Calculator {
    return Intl.message(
      'Simple Calculator',
      name: 'Simple_Calculator',
      desc: '',
      args: [],
    );
  }

  /// `Relaxing Up`
  String get Relaxing_Up {
    return Intl.message(
      'Relaxing Up',
      name: 'Relaxing_Up',
      desc: '',
      args: [],
    );
  }

  /// `Express Scan`
  String get Express_Scan {
    return Intl.message(
      'Express Scan',
      name: 'Express_Scan',
      desc: '',
      args: [],
    );
  }

  /// `Shows`
  String get Shows {
    return Intl.message(
      'Shows',
      name: 'Shows',
      desc: '',
      args: [],
    );
  }

  /// `Minesweeper Go`
  String get Minesweeper_Go {
    return Intl.message(
      'Minesweeper Go',
      name: 'Minesweeper_Go',
      desc: '',
      args: [],
    );
  }

  /// `Water Tracker`
  String get Water_Tracker {
    return Intl.message(
      'Water Tracker',
      name: 'Water_Tracker',
      desc: '',
      args: [],
    );
  }

  String get Purchases => Intl.message('Purchases', name: 'Purchases');
  String get Remove_Ads => Intl.message('Remove Ads', name: 'Remove_Ads');
  String get Ads_Removed => Intl.message('Ads Removed', name: 'Ads_Removed');
  String get Ads_Removed_Description => Intl.message(
        'Ads are permanently removed on this device.',
        name: 'Ads_Removed_Description',
      );
  String get Restore_Purchases =>
      Intl.message('Restore Purchases', name: 'Restore_Purchases');
  String Remove_Ads_Price(Object price) => Intl.message(
        'Remove ads permanently for $price.',
        name: 'Remove_Ads_Price',
        args: [price],
      );
  String get Purchase_Loading =>
      Intl.message('Contacting the App Store…', name: 'Purchase_Loading');
  String get Purchase_Unavailable => Intl.message(
        'Remove Ads is currently unavailable.',
        name: 'Purchase_Unavailable',
      );
  String get Purchase_Pending => Intl.message(
        'Your purchase is pending approval.',
        name: 'Purchase_Pending',
      );
  String get Purchase_Cancelled =>
      Intl.message('Purchase cancelled.', name: 'Purchase_Cancelled');
  String get Purchase_Failed => Intl.message(
        'The purchase could not be completed. Please try again.',
        name: 'Purchase_Failed',
      );
  String get Purchase_Success =>
      Intl.message('Ads have been removed.', name: 'Purchase_Success');
  String get Restore_Success => Intl.message(
        'Your Remove Ads purchase was restored.',
        name: 'Restore_Success',
      );
  String get Restore_Nothing => Intl.message(
        'No previous Remove Ads purchase was found.',
        name: 'Restore_Nothing',
      );
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
