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
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Notes`
  String get notes {
    return Intl.message('Notes', name: 'notes', desc: '', args: []);
  }

  /// `Edit`
  String get Edit {
    return Intl.message('Edit', name: 'Edit', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Saving`
  String get Saving {
    return Intl.message('Saving', name: 'Saving', desc: '', args: []);
  }

  /// `Checklist`
  String get Todo_list {
    return Intl.message('Checklist', name: 'Todo_list', desc: '', args: []);
  }

  /// `Delete`
  String get Delete {
    return Intl.message('Delete', name: 'Delete', desc: '', args: []);
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

  /// `Add item`
  String get Add_todo {
    return Intl.message('Add item', name: 'Add_todo', desc: '', args: []);
  }

  /// `Checklist item`
  String get Todo {
    return Intl.message('Checklist item', name: 'Todo', desc: '', args: []);
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
    return Intl.message('Title', name: 'Title', desc: '', args: []);
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
    return Intl.message('Share', name: 'Share', desc: '', args: []);
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

  /// `This note will be moved to Trash. You can restore it later.`
  String get Delete_Note_Confirm_Message {
    return Intl.message(
      'This note will be moved to Trash. You can restore it later.',
      name: 'Delete_Note_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Undo`
  String get Undo {
    return Intl.message('Undo', name: 'Undo', desc: '', args: []);
  }

  /// `Moved to Trash`
  String get Notes_Moved_To_Trash {
    return Intl.message(
      'Moved to Trash',
      name: 'Notes_Moved_To_Trash',
      desc: '',
      args: [],
    );
  }

  /// `Notes restored`
  String get Notes_Restored {
    return Intl.message(
      'Notes restored',
      name: 'Notes_Restored',
      desc: '',
      args: [],
    );
  }

  /// `Notes permanently deleted`
  String get Notes_Permanently_Deleted {
    return Intl.message(
      'Notes permanently deleted',
      name: 'Notes_Permanently_Deleted',
      desc: '',
      args: [],
    );
  }

  /// `Delete forever?`
  String get Permanent_Delete_Confirm_Title {
    return Intl.message(
      'Delete forever?',
      name: 'Permanent_Delete_Confirm_Title',
      desc: '',
      args: [],
    );
  }

  /// `These notes will be permanently deleted along with their photos and reminders. This can't be undone.`
  String get Permanent_Delete_Confirm_Message {
    return Intl.message(
      'These notes will be permanently deleted along with their photos and reminders. This can\'t be undone.',
      name: 'Permanent_Delete_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Search notes`
  String get Search_Notes {
    return Intl.message(
      'Search notes',
      name: 'Search_Notes',
      desc: '',
      args: [],
    );
  }

  /// `Cancel searching`
  String get Cancel_Searching {
    return Intl.message(
      'Cancel searching',
      name: 'Cancel_Searching',
      desc: '',
      args: [],
    );
  }

  /// `Searching`
  String get Search_Active {
    return Intl.message('Searching', name: 'Search_Active', desc: '', args: []);
  }

  /// `Text in photo`
  String get Photo_Search_Text_In_Photo {
    return Intl.message(
      'Text in photo',
      name: 'Photo_Search_Text_In_Photo',
      desc: '',
      args: [],
    );
  }

  /// `Making photo text searchable…`
  String get Photo_Search_Indexing {
    return Intl.message(
      'Making photo text searchable…',
      name: 'Photo_Search_Indexing',
      desc: '',
      args: [],
    );
  }

  /// `No notes match your search.`
  String get No_Search_Results {
    return Intl.message(
      'No notes match your search.',
      name: 'No_Search_Results',
      desc: '',
      args: [],
    );
  }

  /// `No notes in this folder yet.\nTap + to add one.`
  String get No_Notes_In_Folder {
    return Intl.message(
      'No notes in this folder yet.\nTap + to add one.',
      name: 'No_Notes_In_Folder',
      desc: '',
      args: [],
    );
  }

  /// `Trash is empty`
  String get Trash_Empty {
    return Intl.message(
      'Trash is empty',
      name: 'Trash_Empty',
      desc: '',
      args: [],
    );
  }

  /// `Trash`
  String get Trash {
    return Intl.message('Trash', name: 'Trash', desc: '', args: []);
  }

  /// `All Notes`
  String get All_Notes {
    return Intl.message('All Notes', name: 'All_Notes', desc: '', args: []);
  }

  /// `Folders`
  String get Folders {
    return Intl.message('Folders', name: 'Folders', desc: '', args: []);
  }

  /// `Manage Folders`
  String get Manage_Folders {
    return Intl.message(
      'Manage Folders',
      name: 'Manage_Folders',
      desc: '',
      args: [],
    );
  }

  /// `No folders yet. Create one to organize your notes.`
  String get No_Folders {
    return Intl.message(
      'No folders yet. Create one to organize your notes.',
      name: 'No_Folders',
      desc: '',
      args: [],
    );
  }

  /// `{count} notes`
  String Folder_Notes_Count(Object count) {
    return Intl.message(
      '$count notes',
      name: 'Folder_Notes_Count',
      desc: '',
      args: [count],
    );
  }

  /// `New Folder`
  String get New_Folder {
    return Intl.message('New Folder', name: 'New_Folder', desc: '', args: []);
  }

  /// `Rename Folder`
  String get Rename_Folder {
    return Intl.message(
      'Rename Folder',
      name: 'Rename_Folder',
      desc: '',
      args: [],
    );
  }

  /// `Delete Folder`
  String get Delete_Folder {
    return Intl.message(
      'Delete Folder',
      name: 'Delete_Folder',
      desc: '',
      args: [],
    );
  }

  /// `Notes in this folder will stay in All Notes. The folder itself will be removed.`
  String get Delete_Folder_Confirm_Message {
    return Intl.message(
      'Notes in this folder will stay in All Notes. The folder itself will be removed.',
      name: 'Delete_Folder_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `Folder name`
  String get Folder_Name {
    return Intl.message('Folder name', name: 'Folder_Name', desc: '', args: []);
  }

  /// `Please enter a folder name.`
  String get Folder_Name_Required {
    return Intl.message(
      'Please enter a folder name.',
      name: 'Folder_Name_Required',
      desc: '',
      args: [],
    );
  }

  /// `Folder created`
  String get Folder_Created {
    return Intl.message(
      'Folder created',
      name: 'Folder_Created',
      desc: '',
      args: [],
    );
  }

  /// `Folder deleted`
  String get Folder_Deleted {
    return Intl.message(
      'Folder deleted',
      name: 'Folder_Deleted',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save folder, please try again.`
  String get Failed_to_save_folder {
    return Intl.message(
      'Failed to save folder, please try again.',
      name: 'Failed_to_save_folder',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete folder, please try again.`
  String get Failed_to_delete_folder {
    return Intl.message(
      'Failed to delete folder, please try again.',
      name: 'Failed_to_delete_folder',
      desc: '',
      args: [],
    );
  }

  /// `Failed to restore notes, please try again.`
  String get Failed_to_restore_notes {
    return Intl.message(
      'Failed to restore notes, please try again.',
      name: 'Failed_to_restore_notes',
      desc: '',
      args: [],
    );
  }

  /// `Move to Folder`
  String get Move_To_Folder {
    return Intl.message(
      'Move to Folder',
      name: 'Move_To_Folder',
      desc: '',
      args: [],
    );
  }

  /// `No Folder`
  String get No_Folder {
    return Intl.message('No Folder', name: 'No_Folder', desc: '', args: []);
  }

  /// `Note moved`
  String get Note_Moved {
    return Intl.message('Note moved', name: 'Note_Moved', desc: '', args: []);
  }

  /// `Pin`
  String get Pin {
    return Intl.message('Pin', name: 'Pin', desc: '', args: []);
  }

  /// `Unpin`
  String get Unpin {
    return Intl.message('Unpin', name: 'Unpin', desc: '', args: []);
  }

  /// `Restore`
  String get Restore {
    return Intl.message('Restore', name: 'Restore', desc: '', args: []);
  }

  /// `Delete Forever`
  String get Delete_Forever {
    return Intl.message(
      'Delete Forever',
      name: 'Delete_Forever',
      desc: '',
      args: [],
    );
  }

  /// `Empty Trash`
  String get Empty_Trash {
    return Intl.message('Empty Trash', name: 'Empty_Trash', desc: '', args: []);
  }

  /// `Add Note`
  String get Add_Note {
    return Intl.message('Add Note', name: 'Add_Note', desc: '', args: []);
  }

  /// `Skip`
  String get Onboarding_Skip {
    return Intl.message('Skip', name: 'Onboarding_Skip', desc: '', args: []);
  }

  /// `Next`
  String get Onboarding_Next {
    return Intl.message('Next', name: 'Onboarding_Next', desc: '', args: []);
  }

  /// `Get Started`
  String get Onboarding_Get_Started {
    return Intl.message(
      'Get Started',
      name: 'Onboarding_Get_Started',
      desc: '',
      args: [],
    );
  }

  /// `Write a note`
  String get Onboarding_Write_Note {
    return Intl.message(
      'Write a note',
      name: 'Onboarding_Write_Note',
      desc: '',
      args: [],
    );
  }

  /// `Make a checklist`
  String get Onboarding_Make_Checklist {
    return Intl.message(
      'Make a checklist',
      name: 'Onboarding_Make_Checklist',
      desc: '',
      args: [],
    );
  }

  /// `Capture anything`
  String get Onboarding_Title_1 {
    return Intl.message(
      'Capture anything',
      name: 'Onboarding_Title_1',
      desc: '',
      args: [],
    );
  }

  /// `Quick notes, checklists, and photos — all in one place.`
  String get Onboarding_Body_1 {
    return Intl.message(
      'Quick notes, checklists, and photos — all in one place.',
      name: 'Onboarding_Body_1',
      desc: '',
      args: [],
    );
  }

  /// `Stay organized`
  String get Onboarding_Title_2 {
    return Intl.message(
      'Stay organized',
      name: 'Onboarding_Title_2',
      desc: '',
      args: [],
    );
  }

  /// `Pin important notes, group them into folders, and find anything with search.`
  String get Onboarding_Body_2 {
    return Intl.message(
      'Pin important notes, group them into folders, and find anything with search.',
      name: 'Onboarding_Body_2',
      desc: '',
      args: [],
    );
  }

  /// `Never lose a thought`
  String get Onboarding_Title_3 {
    return Intl.message(
      'Never lose a thought',
      name: 'Onboarding_Title_3',
      desc: '',
      args: [],
    );
  }

  /// `Set reminders and recover deleted notes from Trash anytime.`
  String get Onboarding_Body_3 {
    return Intl.message(
      'Set reminders and recover deleted notes from Trash anytime.',
      name: 'Onboarding_Body_3',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate`
  String get Duplicate {
    return Intl.message('Duplicate', name: 'Duplicate', desc: '', args: []);
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
    return Intl.message('(Copy)', name: 'Copy_Suffix', desc: '', args: []);
  }

  /// `Select`
  String get Select {
    return Intl.message('Select', name: 'Select', desc: '', args: []);
  }

  /// `Reorder`
  String get Reorder {
    return Intl.message('Reorder', name: 'Reorder', desc: '', args: []);
  }

  /// `Done`
  String get Done {
    return Intl.message('Done', name: 'Done', desc: '', args: []);
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
    return Intl.message('Take Photo', name: 'Take_Photo', desc: '', args: []);
  }

  /// `Settings`
  String get Settings {
    return Intl.message('Settings', name: 'Settings', desc: '', args: []);
  }

  /// `Font Style`
  String get Font_Style {
    return Intl.message('Font Style', name: 'Font_Style', desc: '', args: []);
  }

  /// `Font Size`
  String get Font_Size {
    return Intl.message('Font Size', name: 'Font_Size', desc: '', args: []);
  }

  /// `Card Size`
  String get Card_Size {
    return Intl.message('Card Size', name: 'Card_Size', desc: '', args: []);
  }

  /// `Small`
  String get Small {
    return Intl.message('Small', name: 'Small', desc: '', args: []);
  }

  /// `Medium`
  String get Medium {
    return Intl.message('Medium', name: 'Medium', desc: '', args: []);
  }

  /// `Large`
  String get Large {
    return Intl.message('Large', name: 'Large', desc: '', args: []);
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message('Cancel', name: 'Cancel', desc: '', args: []);
  }

  /// `OK`
  String get OK {
    return Intl.message('OK', name: 'OK', desc: '', args: []);
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
    return Intl.message('Reminder', name: 'Reminder', desc: '', args: []);
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
    return Intl.message('Onlynote', name: 'Onlynote', desc: '', args: []);
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
    return Intl.message('More Apps', name: 'More_Apps', desc: '', args: []);
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
    return Intl.message('Image Guru', name: 'Image_Guru', desc: '', args: []);
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
    return Intl.message('Yes Habit', name: 'Yes_Habit', desc: '', args: []);
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
    return Intl.message('Novels Hub', name: 'Novels_Hub', desc: '', args: []);
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
    return Intl.message('Relaxing Up', name: 'Relaxing_Up', desc: '', args: []);
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
    return Intl.message('Shows', name: 'Shows', desc: '', args: []);
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

  /// `Purchases`
  String get Purchases {
    return Intl.message('Purchases', name: 'Purchases', desc: '', args: []);
  }

  /// `Remove Ads`
  String get Remove_Ads {
    return Intl.message('Remove Ads', name: 'Remove_Ads', desc: '', args: []);
  }

  /// `Ads Removed`
  String get Ads_Removed {
    return Intl.message('Ads Removed', name: 'Ads_Removed', desc: '', args: []);
  }

  /// `Ads are permanently removed on this device.`
  String get Ads_Removed_Description {
    return Intl.message(
      'Ads are permanently removed on this device.',
      name: 'Ads_Removed_Description',
      desc: '',
      args: [],
    );
  }

  /// `Restore Purchases`
  String get Restore_Purchases {
    return Intl.message(
      'Restore Purchases',
      name: 'Restore_Purchases',
      desc: '',
      args: [],
    );
  }

  /// `Remove ads permanently for {price}.`
  String Remove_Ads_Price(Object price) {
    return Intl.message(
      'Remove ads permanently for $price.',
      name: 'Remove_Ads_Price',
      desc: '',
      args: [price],
    );
  }

  /// `Contacting the App Store…`
  String get Purchase_Loading {
    return Intl.message(
      'Contacting the App Store…',
      name: 'Purchase_Loading',
      desc: '',
      args: [],
    );
  }

  /// `Remove Ads is currently unavailable.`
  String get Purchase_Unavailable {
    return Intl.message(
      'Remove Ads is currently unavailable.',
      name: 'Purchase_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Your purchase is pending approval.`
  String get Purchase_Pending {
    return Intl.message(
      'Your purchase is pending approval.',
      name: 'Purchase_Pending',
      desc: '',
      args: [],
    );
  }

  /// `Purchase cancelled.`
  String get Purchase_Cancelled {
    return Intl.message(
      'Purchase cancelled.',
      name: 'Purchase_Cancelled',
      desc: '',
      args: [],
    );
  }

  /// `The purchase could not be completed. Please try again.`
  String get Purchase_Failed {
    return Intl.message(
      'The purchase could not be completed. Please try again.',
      name: 'Purchase_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Ads have been removed.`
  String get Purchase_Success {
    return Intl.message(
      'Ads have been removed.',
      name: 'Purchase_Success',
      desc: '',
      args: [],
    );
  }

  /// `Your Remove Ads purchase was restored.`
  String get Restore_Success {
    return Intl.message(
      'Your Remove Ads purchase was restored.',
      name: 'Restore_Success',
      desc: '',
      args: [],
    );
  }

  /// `No previous Remove Ads purchase was found.`
  String get Restore_Nothing {
    return Intl.message(
      'No previous Remove Ads purchase was found.',
      name: 'Restore_Nothing',
      desc: '',
      args: [],
    );
  }

  /// `Notes on your Home Screen`
  String get Onboarding_Title_4 {
    return Intl.message(
      'Notes on your Home Screen',
      name: 'Onboarding_Title_4',
      desc: '',
      args: [],
    );
  }

  /// `Add the Onlynote widget to read your notes and start writing without opening the app.`
  String get Onboarding_Body_4 {
    return Intl.message(
      'Add the Onlynote widget to read your notes and start writing without opening the app.',
      name: 'Onboarding_Body_4',
      desc: '',
      args: [],
    );
  }

  /// `Home Screen Widget`
  String get Widget {
    return Intl.message(
      'Home Screen Widget',
      name: 'Widget',
      desc: '',
      args: [],
    );
  }

  /// `See your notes at a glance, without opening the app.`
  String get Widget_Description {
    return Intl.message(
      'See your notes at a glance, without opening the app.',
      name: 'Widget_Description',
      desc: '',
      args: [],
    );
  }

  /// `Add to Home Screen`
  String get Widget_Add_To_Home {
    return Intl.message(
      'Add to Home Screen',
      name: 'Widget_Add_To_Home',
      desc: '',
      args: [],
    );
  }

  /// `Your launcher can't add it automatically — follow the steps below instead.`
  String get Widget_Add_Unsupported {
    return Intl.message(
      'Your launcher can\'t add it automatically — follow the steps below instead.',
      name: 'Widget_Add_Unsupported',
      desc: '',
      args: [],
    );
  }

  /// `How to add it`
  String get Widget_Steps_Title {
    return Intl.message(
      'How to add it',
      name: 'Widget_Steps_Title',
      desc: '',
      args: [],
    );
  }

  /// `Touch and hold an empty area of your Home Screen until the icons jiggle.`
  String get Widget_Step_iOS_1 {
    return Intl.message(
      'Touch and hold an empty area of your Home Screen until the icons jiggle.',
      name: 'Widget_Step_iOS_1',
      desc: '',
      args: [],
    );
  }

  /// `Tap the + button in the top corner.`
  String get Widget_Step_iOS_2 {
    return Intl.message(
      'Tap the + button in the top corner.',
      name: 'Widget_Step_iOS_2',
      desc: '',
      args: [],
    );
  }

  /// `Search for “Onlynote”, then select it.`
  String get Widget_Step_iOS_3 {
    return Intl.message(
      'Search for “Onlynote”, then select it.',
      name: 'Widget_Step_iOS_3',
      desc: '',
      args: [],
    );
  }

  /// `Choose a size and tap Add Widget.`
  String get Widget_Step_iOS_4 {
    return Intl.message(
      'Choose a size and tap Add Widget.',
      name: 'Widget_Step_iOS_4',
      desc: '',
      args: [],
    );
  }

  /// `Touch and hold an empty area of your Home Screen.`
  String get Widget_Step_Android_1 {
    return Intl.message(
      'Touch and hold an empty area of your Home Screen.',
      name: 'Widget_Step_Android_1',
      desc: '',
      args: [],
    );
  }

  /// `Tap Widgets.`
  String get Widget_Step_Android_2 {
    return Intl.message(
      'Tap Widgets.',
      name: 'Widget_Step_Android_2',
      desc: '',
      args: [],
    );
  }

  /// `Find “Onlynote” in the list.`
  String get Widget_Step_Android_3 {
    return Intl.message(
      'Find “Onlynote” in the list.',
      name: 'Widget_Step_Android_3',
      desc: '',
      args: [],
    );
  }

  /// `Drag the widget where you want it.`
  String get Widget_Step_Android_4 {
    return Intl.message(
      'Drag the widget where you want it.',
      name: 'Widget_Step_Android_4',
      desc: '',
      args: [],
    );
  }

  /// `Tap a note in the widget to open it, or tap New to start writing.`
  String get Widget_Tip {
    return Intl.message(
      'Tap a note in the widget to open it, or tap New to start writing.',
      name: 'Widget_Tip',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get Privacy {
    return Intl.message('Privacy', name: 'Privacy', desc: '', args: []);
  }

  /// `Privacy Policy`
  String get Privacy_Policy {
    return Intl.message(
      'Privacy Policy',
      name: 'Privacy_Policy',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't open the privacy policy. Please try again.`
  String get Privacy_Policy_Failed {
    return Intl.message(
      'Couldn\'t open the privacy policy. Please try again.',
      name: 'Privacy_Policy_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Ad Privacy Settings`
  String get Privacy_Settings {
    return Intl.message(
      'Ad Privacy Settings',
      name: 'Privacy_Settings',
      desc: '',
      args: [],
    );
  }

  /// `Change or withdraw your choices about personalized ads.`
  String get Privacy_Settings_Description {
    return Intl.message(
      'Change or withdraw your choices about personalized ads.',
      name: 'Privacy_Settings_Description',
      desc: '',
      args: [],
    );
  }

  /// `Add Photo`
  String get Add_Image {
    return Intl.message('Add Photo', name: 'Add_Image', desc: '', args: []);
  }

  /// `A little space for your next big idea.`
  String get Font_Preview {
    return Intl.message(
      'A little space for your next big idea.',
      name: 'Font_Preview',
      desc: '',
      args: [],
    );
  }

  /// `Choose a time in the future for your reminder.`
  String get Reminder_Future_Time {
    return Intl.message(
      'Choose a time in the future for your reminder.',
      name: 'Reminder_Future_Time',
      desc: '',
      args: [],
    );
  }

  /// `Saved`
  String get Autosave_Saved {
    return Intl.message('Saved', name: 'Autosave_Saved', desc: '', args: []);
  }

  /// `Saving…`
  String get Autosave_Saving {
    return Intl.message('Saving…', name: 'Autosave_Saving', desc: '', args: []);
  }

  /// `Not saved`
  String get Autosave_Retry {
    return Intl.message(
      'Not saved',
      name: 'Autosave_Retry',
      desc: '',
      args: [],
    );
  }

  /// `Could not save your changes. Keep this note open and tap Not saved to retry.`
  String get Autosave_Failed {
    return Intl.message(
      'Could not save your changes. Keep this note open and tap Not saved to retry.',
      name: 'Autosave_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Backup & Restore`
  String get Backup_Title {
    return Intl.message(
      'Backup & Restore',
      name: 'Backup_Title',
      desc: '',
      args: [],
    );
  }

  /// `Create backup`
  String get Backup_Export {
    return Intl.message(
      'Create backup',
      name: 'Backup_Export',
      desc: '',
      args: [],
    );
  }

  /// `Save your notes, tags, saved views, folders, photos, recordings, history, templates, and reminder dates in one Onlynote file. Includes archived notes and Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.`
  String get Backup_Export_Description {
    return Intl.message(
      'Save your notes, tags, saved views, folders, photos, recordings, history, templates, and reminder dates in one Onlynote file. Includes archived notes and Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.',
      name: 'Backup_Export_Description',
      desc: '',
      args: [],
    );
  }

  /// `Restore backup`
  String get Backup_Restore {
    return Intl.message(
      'Restore backup',
      name: 'Backup_Restore',
      desc: '',
      args: [],
    );
  }

  /// `Restoring adds copies of the backed-up notes, folders, templates, and saved views to your library. Note links connect the restored copies. Restoring the same file again adds another set of copies.`
  String get Backup_Restore_Description {
    return Intl.message(
      'Restoring adds copies of the backed-up notes, folders, templates, and saved views to your library. Note links connect the restored copies. Restoring the same file again adds another set of copies.',
      name: 'Backup_Restore_Description',
      desc: '',
      args: [],
    );
  }

  /// `Choose backup file`
  String get Backup_Choose {
    return Intl.message(
      'Choose backup file',
      name: 'Backup_Choose',
      desc: '',
      args: [],
    );
  }

  /// `Preparing your backup…`
  String get Backup_Preparing {
    return Intl.message(
      'Preparing your backup…',
      name: 'Backup_Preparing',
      desc: '',
      args: [],
    );
  }

  /// `Checking the backup file…`
  String get Backup_Reading {
    return Intl.message(
      'Checking the backup file…',
      name: 'Backup_Reading',
      desc: '',
      args: [],
    );
  }

  /// `Restoring your notes and photos…`
  String get Backup_Restoring {
    return Intl.message(
      'Restoring your notes and photos…',
      name: 'Backup_Restoring',
      desc: '',
      args: [],
    );
  }

  /// `Could not create the backup. Check available storage and that all photos and recordings are accessible. Backups must fit within 256 MB.`
  String get Backup_Export_Failed {
    return Intl.message(
      'Could not create the backup. Check available storage and that all photos and recordings are accessible. Backups must fit within 256 MB.',
      name: 'Backup_Export_Failed',
      desc: '',
      args: [],
    );
  }

  /// `This is not a supported Onlynote backup, or the file is damaged or larger than 256 MB. Nothing was imported.`
  String get Backup_Invalid {
    return Intl.message(
      'This is not a supported Onlynote backup, or the file is damaged or larger than 256 MB. Nothing was imported.',
      name: 'Backup_Invalid',
      desc: '',
      args: [],
    );
  }

  /// `Could not restore the backup. Check available storage and try again. Your existing notes have not been overwritten.`
  String get Backup_Restore_Failed {
    return Intl.message(
      'Could not restore the backup. Check available storage and try again. Your existing notes have not been overwritten.',
      name: 'Backup_Restore_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Backup restored. Your notes are ready in the library.`
  String get Backup_Restored {
    return Intl.message(
      'Backup restored. Your notes are ready in the library.',
      name: 'Backup_Restored',
      desc: '',
      args: [],
    );
  }

  /// `Notes restored. Some reminder notifications could not be scheduled; open those notes to set them again.`
  String get Backup_Restored_No_Notifications {
    return Intl.message(
      'Notes restored. Some reminder notifications could not be scheduled; open those notes to set them again.',
      name: 'Backup_Restored_No_Notifications',
      desc: '',
      args: [],
    );
  }

  /// `Schedule future reminder notifications`
  String get Backup_Schedule_Reminders {
    return Intl.message(
      'Schedule future reminder notifications',
      name: 'Backup_Schedule_Reminders',
      desc: '',
      args: [],
    );
  }

  /// `{notes} notes · {folders} folders · {photos} photos`
  String Backup_Contents(Object notes, Object folders, Object photos) {
    return Intl.message(
      '$notes notes · $folders folders · $photos photos',
      name: 'Backup_Contents',
      desc: '',
      args: [notes, folders, photos],
    );
  }

  /// `In 1 hour`
  String get Reminder_In_One_Hour {
    return Intl.message(
      'In 1 hour',
      name: 'Reminder_In_One_Hour',
      desc: '',
      args: [],
    );
  }

  /// `Tomorrow morning`
  String get Reminder_Tomorrow {
    return Intl.message(
      'Tomorrow morning',
      name: 'Reminder_Tomorrow',
      desc: '',
      args: [],
    );
  }

  /// `In a week`
  String get Reminder_Next_Week {
    return Intl.message(
      'In a week',
      name: 'Reminder_Next_Week',
      desc: '',
      args: [],
    );
  }

  /// `Choose date & time`
  String get Reminder_Custom {
    return Intl.message(
      'Choose date & time',
      name: 'Reminder_Custom',
      desc: '',
      args: [],
    );
  }

  /// `Reminder set`
  String get Reminder_Saved {
    return Intl.message(
      'Reminder set',
      name: 'Reminder_Saved',
      desc: '',
      args: [],
    );
  }

  /// `Could not update the reminder. Please try again.`
  String get Reminder_Save_Failed {
    return Intl.message(
      'Could not update the reminder. Please try again.',
      name: 'Reminder_Save_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get Appearance {
    return Intl.message('Appearance', name: 'Appearance', desc: '', args: []);
  }

  /// `System`
  String get Theme_System {
    return Intl.message('System', name: 'Theme_System', desc: '', args: []);
  }

  /// `Light`
  String get Theme_Light {
    return Intl.message('Light', name: 'Theme_Light', desc: '', args: []);
  }

  /// `Dark`
  String get Theme_Dark {
    return Intl.message('Dark', name: 'Theme_Dark', desc: '', args: []);
  }

  /// `Plain paper`
  String get Plain_Paper {
    return Intl.message('Plain paper', name: 'Plain_Paper', desc: '', args: []);
  }

  /// `A calmer look without texture, ruled lines, or tilted cards.`
  String get Plain_Paper_Description {
    return Intl.message(
      'A calmer look without texture, ruled lines, or tilted cards.',
      name: 'Plain_Paper_Description',
      desc: '',
      args: [],
    );
  }

  /// `Could not save this setting. Please try again.`
  String get Settings_Save_Failed {
    return Intl.message(
      'Could not save this setting. Please try again.',
      name: 'Settings_Save_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Checklists`
  String get Filter_Checklists {
    return Intl.message(
      'Checklists',
      name: 'Filter_Checklists',
      desc: '',
      args: [],
    );
  }

  /// `Photos`
  String get Filter_Photos {
    return Intl.message('Photos', name: 'Filter_Photos', desc: '', args: []);
  }

  /// `Reminders`
  String get Filter_Reminders {
    return Intl.message(
      'Reminders',
      name: 'Filter_Reminders',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get Filter_Pinned {
    return Intl.message('Pinned', name: 'Filter_Pinned', desc: '', args: []);
  }

  /// `Clear filters`
  String get Clear_Filters {
    return Intl.message(
      'Clear filters',
      name: 'Clear_Filters',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get Share_Image {
    return Intl.message('Image', name: 'Share_Image', desc: '', args: []);
  }

  /// `Plain text`
  String get Share_Plain_Text {
    return Intl.message(
      'Plain text',
      name: 'Share_Plain_Text',
      desc: '',
      args: [],
    );
  }

  /// `Markdown`
  String get Share_Markdown {
    return Intl.message('Markdown', name: 'Share_Markdown', desc: '', args: []);
  }

  /// `PDF document`
  String get Share_PDF {
    return Intl.message('PDF document', name: 'Share_PDF', desc: '', args: []);
  }

  /// `Share the current paper view as a picture.`
  String get Share_Image_Description {
    return Intl.message(
      'Share the current paper view as a picture.',
      name: 'Share_Image_Description',
      desc: '',
      args: [],
    );
  }

  /// `Title, full text, checklist, and reminder. No photos.`
  String get Share_Text_Description {
    return Intl.message(
      'Title, full text, checklist, and reminder. No photos.',
      name: 'Share_Text_Description',
      desc: '',
      args: [],
    );
  }

  /// `A .md file with checklist formatting and photo attachments.`
  String get Share_Markdown_Description {
    return Intl.message(
      'A .md file with checklist formatting and photo attachments.',
      name: 'Share_Markdown_Description',
      desc: '',
      args: [],
    );
  }

  /// `Full note and photos, laid out across printable pages.`
  String get Share_PDF_Description {
    return Intl.message(
      'Full note and photos, laid out across printable pages.',
      name: 'Share_PDF_Description',
      desc: '',
      args: [],
    );
  }

  /// `Preparing your note…`
  String get Share_Preparing {
    return Intl.message(
      'Preparing your note…',
      name: 'Share_Preparing',
      desc: '',
      args: [],
    );
  }

  /// `This note has no text. Choose an image or PDF to include its photos.`
  String get Share_No_Text {
    return Intl.message(
      'This note has no text. Choose an image or PDF to include its photos.',
      name: 'Share_No_Text',
      desc: '',
      args: [],
    );
  }

  /// `Notes restored. Some reminders could not be scheduled. Open those notes to set their reminders again.`
  String get Restore_Reminder_Warning {
    return Intl.message(
      'Notes restored. Some reminders could not be scheduled. Open those notes to set their reminders again.',
      name: 'Restore_Reminder_Warning',
      desc: '',
      args: [],
    );
  }

  /// `Note color {number}`
  String Note_Color(Object number) {
    return Intl.message(
      'Note color $number',
      name: 'Note_Color',
      desc: '',
      args: [number],
    );
  }

  /// `Keep pinned notes in view`
  String get Widget_Discovery_Title {
    return Intl.message(
      'Keep pinned notes in view',
      name: 'Widget_Discovery_Title',
      desc: '',
      args: [],
    );
  }

  /// `Add a widget to your Home Screen for a quick glance at your notes.`
  String get Widget_Discovery_Body {
    return Intl.message(
      'Add a widget to your Home Screen for a quick glance at your notes.',
      name: 'Widget_Discovery_Body',
      desc: '',
      args: [],
    );
  }

  /// `Repeat`
  String get Reminder_Repeat {
    return Intl.message('Repeat', name: 'Reminder_Repeat', desc: '', args: []);
  }

  /// `Never`
  String get Reminder_Repeat_Never {
    return Intl.message(
      'Never',
      name: 'Reminder_Repeat_Never',
      desc: '',
      args: [],
    );
  }

  /// `Daily`
  String get Reminder_Repeat_Daily {
    return Intl.message(
      'Daily',
      name: 'Reminder_Repeat_Daily',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get Reminder_Repeat_Weekly {
    return Intl.message(
      'Weekly',
      name: 'Reminder_Repeat_Weekly',
      desc: '',
      args: [],
    );
  }

  /// `Time`
  String get Reminder_Time {
    return Intl.message('Time', name: 'Reminder_Time', desc: '', args: []);
  }

  /// `Day`
  String get Reminder_Day {
    return Intl.message('Day', name: 'Reminder_Day', desc: '', args: []);
  }

  /// `Set reminder`
  String get Reminder_Set {
    return Intl.message(
      'Set reminder',
      name: 'Reminder_Set',
      desc: '',
      args: [],
    );
  }

  /// `Next reminder: {time}`
  String Reminder_Next_Time(Object time) {
    return Intl.message(
      'Next reminder: $time',
      name: 'Reminder_Next_Time',
      desc: '',
      args: [time],
    );
  }

  /// `Templates`
  String get Templates {
    return Intl.message('Templates', name: 'Templates', desc: '', args: []);
  }

  /// `Start with a useful outline, then make it yours.`
  String get Templates_Description {
    return Intl.message(
      'Start with a useful outline, then make it yours.',
      name: 'Templates_Description',
      desc: '',
      args: [],
    );
  }

  /// `Use a template`
  String get Use_Template {
    return Intl.message(
      'Use a template',
      name: 'Use_Template',
      desc: '',
      args: [],
    );
  }

  /// `Shopping list`
  String get Template_Shopping_Title {
    return Intl.message(
      'Shopping list',
      name: 'Template_Shopping_Title',
      desc: '',
      args: [],
    );
  }

  /// `A checklist for groceries and household essentials.`
  String get Template_Shopping_Summary {
    return Intl.message(
      'A checklist for groceries and household essentials.',
      name: 'Template_Shopping_Summary',
      desc: '',
      args: [],
    );
  }

  /// `Fruit & vegetables\nBread & grains\nMilk or dairy alternatives\nHousehold essentials`
  String get Template_Shopping_Items {
    return Intl.message(
      'Fruit & vegetables\nBread & grains\nMilk or dairy alternatives\nHousehold essentials',
      name: 'Template_Shopping_Items',
      desc: '',
      args: [],
    );
  }

  /// `Packing list`
  String get Template_Packing_Title {
    return Intl.message(
      'Packing list',
      name: 'Template_Packing_Title',
      desc: '',
      args: [],
    );
  }

  /// `Keep travel essentials together before you leave.`
  String get Template_Packing_Summary {
    return Intl.message(
      'Keep travel essentials together before you leave.',
      name: 'Template_Packing_Summary',
      desc: '',
      args: [],
    );
  }

  /// `Travel documents\nPhone & charger\nClothes\nToiletries\nMedication`
  String get Template_Packing_Items {
    return Intl.message(
      'Travel documents\nPhone & charger\nClothes\nToiletries\nMedication',
      name: 'Template_Packing_Items',
      desc: '',
      args: [],
    );
  }

  /// `Daily plan`
  String get Template_Daily_Plan_Title {
    return Intl.message(
      'Daily plan',
      name: 'Template_Daily_Plan_Title',
      desc: '',
      args: [],
    );
  }

  /// `Choose a focus and leave room for a few clear priorities.`
  String get Template_Daily_Plan_Summary {
    return Intl.message(
      'Choose a focus and leave room for a few clear priorities.',
      name: 'Template_Daily_Plan_Summary',
      desc: '',
      args: [],
    );
  }

  /// `Today's focus\n\nNotes\n`
  String get Template_Daily_Plan_Body {
    return Intl.message(
      'Today\'s focus\n\nNotes\n',
      name: 'Template_Daily_Plan_Body',
      desc: '',
      args: [],
    );
  }

  /// `Choose today's priorities\nMake time for a break\nPlan tomorrow`
  String get Template_Daily_Plan_Items {
    return Intl.message(
      'Choose today\'s priorities\nMake time for a break\nPlan tomorrow',
      name: 'Template_Daily_Plan_Items',
      desc: '',
      args: [],
    );
  }

  /// `Meeting notes`
  String get Template_Meeting_Title {
    return Intl.message(
      'Meeting notes',
      name: 'Template_Meeting_Title',
      desc: '',
      args: [],
    );
  }

  /// `An outline for the agenda, decisions, and follow-up.`
  String get Template_Meeting_Summary {
    return Intl.message(
      'An outline for the agenda, decisions, and follow-up.',
      name: 'Template_Meeting_Summary',
      desc: '',
      args: [],
    );
  }

  /// `Date:\nAttendees:\n\nAgenda\n\nNotes\n\nDecisions\n`
  String get Template_Meeting_Body {
    return Intl.message(
      'Date:\nAttendees:\n\nAgenda\n\nNotes\n\nDecisions\n',
      name: 'Template_Meeting_Body',
      desc: '',
      args: [],
    );
  }

  /// `Send a summary\nFollow up on action items`
  String get Template_Meeting_Items {
    return Intl.message(
      'Send a summary\nFollow up on action items',
      name: 'Template_Meeting_Items',
      desc: '',
      args: [],
    );
  }

  /// `{completed} of {total} complete`
  String Checklist_Progress(Object completed, Object total) {
    return Intl.message(
      '$completed of $total complete',
      name: 'Checklist_Progress',
      desc: '',
      args: [completed, total],
    );
  }

  /// `Completed ({count})`
  String Checklist_Completed(Object count) {
    return Intl.message(
      'Completed ($count)',
      name: 'Checklist_Completed',
      desc: '',
      args: [count],
    );
  }

  /// `Reset checklist`
  String get Checklist_Reset {
    return Intl.message(
      'Reset checklist',
      name: 'Checklist_Reset',
      desc: '',
      args: [],
    );
  }

  /// `Checklist reset`
  String get Checklist_Reset_Done {
    return Intl.message(
      'Checklist reset',
      name: 'Checklist_Reset_Done',
      desc: '',
      args: [],
    );
  }

  /// `All done`
  String get Checklist_All_Done {
    return Intl.message(
      'All done',
      name: 'Checklist_All_Done',
      desc: '',
      args: [],
    );
  }

  /// `Snooze 10 min`
  String get Reminder_Snooze_10_Minutes {
    return Intl.message(
      'Snooze 10 min',
      name: 'Reminder_Snooze_10_Minutes',
      desc: '',
      args: [],
    );
  }

  /// `Snooze 1 hour`
  String get Reminder_Snooze_1_Hour {
    return Intl.message(
      'Snooze 1 hour',
      name: 'Reminder_Snooze_1_Hour',
      desc: '',
      args: [],
    );
  }

  /// `Unfinished`
  String get Filter_Unfinished {
    return Intl.message(
      'Unfinished',
      name: 'Filter_Unfinished',
      desc: '',
      args: [],
    );
  }

  /// `Item completed`
  String get Checklist_Item_Completed {
    return Intl.message(
      'Item completed',
      name: 'Checklist_Item_Completed',
      desc: '',
      args: [],
    );
  }

  /// `Item reopened`
  String get Checklist_Item_Reopened {
    return Intl.message(
      'Item reopened',
      name: 'Checklist_Item_Reopened',
      desc: '',
      args: [],
    );
  }

  /// `This checklist item is no longer available.`
  String get Checklist_Item_Unavailable {
    return Intl.message(
      'This checklist item is no longer available.',
      name: 'Checklist_Item_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Save as template`
  String get Save_As_Template {
    return Intl.message(
      'Save as template',
      name: 'Save_As_Template',
      desc: '',
      args: [],
    );
  }

  /// `Template name`
  String get Template_Name {
    return Intl.message(
      'Template name',
      name: 'Template_Name',
      desc: '',
      args: [],
    );
  }

  /// `My templates`
  String get My_Templates {
    return Intl.message(
      'My templates',
      name: 'My_Templates',
      desc: '',
      args: [],
    );
  }

  /// `Starter templates`
  String get Starter_Templates {
    return Intl.message(
      'Starter templates',
      name: 'Starter_Templates',
      desc: '',
      args: [],
    );
  }

  /// `Save any note as a template from its menu.`
  String get Templates_Create_Hint {
    return Intl.message(
      'Save any note as a template from its menu.',
      name: 'Templates_Create_Hint',
      desc: '',
      args: [],
    );
  }

  /// `My template`
  String get Template_Default_Name {
    return Intl.message(
      'My template',
      name: 'Template_Default_Name',
      desc: '',
      args: [],
    );
  }

  /// `Template saved`
  String get Template_Saved {
    return Intl.message(
      'Template saved',
      name: 'Template_Saved',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load your templates. Please try again.`
  String get Template_Load_Failed {
    return Intl.message(
      'Couldn\'t load your templates. Please try again.',
      name: 'Template_Load_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't save the template. Check available storage and photos, then try again.`
  String get Template_Save_Failed {
    return Intl.message(
      'Couldn\'t save the template. Check available storage and photos, then try again.',
      name: 'Template_Save_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't update the template. Please try again.`
  String get Template_Change_Failed {
    return Intl.message(
      'Couldn\'t update the template. Please try again.',
      name: 'Template_Change_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't create a note from the template. Check its photos and try again.`
  String get Template_Copy_Failed {
    return Intl.message(
      'Couldn\'t create a note from the template. Check its photos and try again.',
      name: 'Template_Copy_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Rename template`
  String get Rename_Template {
    return Intl.message(
      'Rename template',
      name: 'Rename_Template',
      desc: '',
      args: [],
    );
  }

  /// `Delete template`
  String get Delete_Template {
    return Intl.message(
      'Delete template',
      name: 'Delete_Template',
      desc: '',
      args: [],
    );
  }

  /// `Delete template?`
  String get Template_Delete_Confirm_Title {
    return Intl.message(
      'Delete template?',
      name: 'Template_Delete_Confirm_Title',
      desc: '',
      args: [],
    );
  }

  /// `This removes the saved template. Notes you've created from it stay in your library.`
  String get Template_Delete_Confirm_Message {
    return Intl.message(
      'This removes the saved template. Notes you\'ve created from it stay in your library.',
      name: 'Template_Delete_Confirm_Message',
      desc: '',
      args: [],
    );
  }

  /// `{items, plural, =0{0 items} one{1 item} other{{items} items}} · {photos, plural, =0{0 photos} one{1 photo} other{{photos} photos}}`
  String Template_Details(num items, num photos) {
    return Intl.message(
      '${Intl.plural(items, zero: '0 items', one: '1 item', other: '$items items')} · ${Intl.plural(photos, zero: '0 photos', one: '1 photo', other: '$photos photos')}',
      name: 'Template_Details',
      desc: '',
      args: [items, photos],
    );
  }

  /// `Manage template`
  String get Template_Manage {
    return Intl.message(
      'Manage template',
      name: 'Template_Manage',
      desc: '',
      args: [],
    );
  }

  /// `More options`
  String get More_Options {
    return Intl.message(
      'More options',
      name: 'More_Options',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get Retry {
    return Intl.message('Retry', name: 'Retry', desc: '', args: []);
  }

  /// `Today & Upcoming`
  String get Reminders_Title {
    return Intl.message(
      'Today & Upcoming',
      name: 'Reminders_Title',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get Reminders_Entry {
    return Intl.message('Today', name: 'Reminders_Entry', desc: '', args: []);
  }

  /// `Overdue`
  String get Reminders_Overdue {
    return Intl.message(
      'Overdue',
      name: 'Reminders_Overdue',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get Reminders_Today {
    return Intl.message('Today', name: 'Reminders_Today', desc: '', args: []);
  }

  /// `Upcoming`
  String get Reminders_Upcoming {
    return Intl.message(
      'Upcoming',
      name: 'Reminders_Upcoming',
      desc: '',
      args: [],
    );
  }

  /// `Nothing on your schedule`
  String get Reminders_Empty_Title {
    return Intl.message(
      'Nothing on your schedule',
      name: 'Reminders_Empty_Title',
      desc: '',
      args: [],
    );
  }

  /// `Add a reminder to a note to see it here.`
  String get Reminders_Empty_Message {
    return Intl.message(
      'Add a reminder to a note to see it here.',
      name: 'Reminders_Empty_Message',
      desc: '',
      args: [],
    );
  }

  /// `Could not load reminders. Try again.`
  String get Reminders_Load_Failed {
    return Intl.message(
      'Could not load reminders. Try again.',
      name: 'Reminders_Load_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Reschedule`
  String get Reminders_Reschedule {
    return Intl.message(
      'Reschedule',
      name: 'Reminders_Reschedule',
      desc: '',
      args: [],
    );
  }

  /// `Snooze`
  String get Reminders_Snooze {
    return Intl.message('Snooze', name: 'Reminders_Snooze', desc: '', args: []);
  }

  /// `Snoozed`
  String get Reminders_Snoozed {
    return Intl.message(
      'Snoozed',
      name: 'Reminders_Snoozed',
      desc: '',
      args: [],
    );
  }

  /// `Could not snooze this reminder. Try again.`
  String get Reminders_Snooze_Failed {
    return Intl.message(
      'Could not snooze this reminder. Try again.',
      name: 'Reminders_Snooze_Failed',
      desc: '',
      args: [],
    );
  }

  /// `This note is no longer available.`
  String get Reminders_Note_Unavailable {
    return Intl.message(
      'This note is no longer available.',
      name: 'Reminders_Note_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Could not add the photo. Try again or choose one from your library.`
  String get Photo_Capture_Failed {
    return Intl.message(
      'Could not add the photo. Try again or choose one from your library.',
      name: 'Photo_Capture_Failed',
      desc: '',
      args: [],
    );
  }

  /// `This reminder changed. Try again.`
  String get Reminders_Changed {
    return Intl.message(
      'This reminder changed. Try again.',
      name: 'Reminders_Changed',
      desc: '',
      args: [],
    );
  }

  /// `Remind me: {date}`
  String Reminder_Suggestion(Object date) {
    return Intl.message(
      'Remind me: $date',
      name: 'Reminder_Suggestion',
      desc: '',
      args: [date],
    );
  }

  /// `Dismiss suggestion`
  String get Reminder_Suggestion_Dismiss {
    return Intl.message(
      'Dismiss suggestion',
      name: 'Reminder_Suggestion_Dismiss',
      desc: '',
      args: [],
    );
  }

  /// `Use suggested time`
  String get Reminder_Suggestion_Confirm {
    return Intl.message(
      'Use suggested time',
      name: 'Reminder_Suggestion_Confirm',
      desc: '',
      args: [],
    );
  }

  /// `Could not import shared content. It is kept for retry when you reopen Onlynote.`
  String get Share_Import_Failed {
    return Intl.message(
      'Could not import shared content. It is kept for retry when you reopen Onlynote.',
      name: 'Share_Import_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Make a widget yours`
  String get Widget_Choose_Note_Title {
    return Intl.message(
      'Make a widget yours',
      name: 'Widget_Choose_Note_Title',
      desc: '',
      args: [],
    );
  }

  /// `Touch and hold your widget, choose Edit Widget, then select a note or checklist. Available on iOS 17 or later.`
  String get Widget_Choose_Note_iOS {
    return Intl.message(
      'Touch and hold your widget, choose Edit Widget, then select a note or checklist. Available on iOS 17 or later.',
      name: 'Widget_Choose_Note_iOS',
      desc: '',
      args: [],
    );
  }

  /// `When adding a widget, choose All notes or one note or checklist. Use Widget settings to change it later.`
  String get Widget_Choose_Note_Android {
    return Intl.message(
      'When adding a widget, choose All notes or one note or checklist. Use Widget settings to change it later.',
      name: 'Widget_Choose_Note_Android',
      desc: '',
      args: [],
    );
  }

  /// `Tap a checkbox to update your checklist without opening Onlynote.`
  String get Widget_Checklist_Tip {
    return Intl.message(
      'Tap a checkbox to update your checklist without opening Onlynote.',
      name: 'Widget_Checklist_Tip',
      desc: '',
      args: [],
    );
  }

  /// `Extract text`
  String get Photo_Text_Extract {
    return Intl.message(
      'Extract text',
      name: 'Photo_Text_Extract',
      desc: '',
      args: [],
    );
  }

  /// `Reading photo…`
  String get Photo_Text_Extracting {
    return Intl.message(
      'Reading photo…',
      name: 'Photo_Text_Extracting',
      desc: '',
      args: [],
    );
  }

  /// `Text from photo`
  String get Photo_Text_Review {
    return Intl.message(
      'Text from photo',
      name: 'Photo_Text_Review',
      desc: '',
      args: [],
    );
  }

  /// `Review and edit the text before inserting it into your note.`
  String get Photo_Text_Review_Hint {
    return Intl.message(
      'Review and edit the text before inserting it into your note.',
      name: 'Photo_Text_Review_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Insert text`
  String get Photo_Text_Insert {
    return Intl.message(
      'Insert text',
      name: 'Photo_Text_Insert',
      desc: '',
      args: [],
    );
  }

  /// `Copy text`
  String get Photo_Text_Copy {
    return Intl.message(
      'Copy text',
      name: 'Photo_Text_Copy',
      desc: '',
      args: [],
    );
  }

  /// `Text copied`
  String get Photo_Text_Copied {
    return Intl.message(
      'Text copied',
      name: 'Photo_Text_Copied',
      desc: '',
      args: [],
    );
  }

  /// `No text found. Try a clearer photo with larger text.`
  String get Photo_Text_No_Text {
    return Intl.message(
      'No text found. Try a clearer photo with larger text.',
      name: 'Photo_Text_No_Text',
      desc: '',
      args: [],
    );
  }

  /// `Text extraction is not available on this device.`
  String get Photo_Text_Unsupported {
    return Intl.message(
      'Text extraction is not available on this device.',
      name: 'Photo_Text_Unsupported',
      desc: '',
      args: [],
    );
  }

  /// `Could not read text from this photo. Please try again.`
  String get Photo_Text_Failed {
    return Intl.message(
      'Could not read text from this photo. Please try again.',
      name: 'Photo_Text_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Extracted text`
  String get Photo_Text_Field {
    return Intl.message(
      'Extracted text',
      name: 'Photo_Text_Field',
      desc: '',
      args: [],
    );
  }

  /// `Choose a photo`
  String get Photo_Text_Choose {
    return Intl.message(
      'Choose a photo',
      name: 'Photo_Text_Choose',
      desc: '',
      args: [],
    );
  }

  /// `Photo {number}`
  String Photo_Text_Photo(int number) {
    return Intl.message(
      'Photo $number',
      name: 'Photo_Text_Photo',
      desc: '',
      args: [number],
    );
  }

  /// `Text added to note`
  String get Photo_Text_Insert_Done {
    return Intl.message(
      'Text added to note',
      name: 'Photo_Text_Insert_Done',
      desc: '',
      args: [],
    );
  }

  /// `Note history`
  String get History_Title {
    return Intl.message(
      'Note history',
      name: 'History_Title',
      desc: '',
      args: [],
    );
  }

  /// `Saved changes will appear here.`
  String get History_Empty {
    return Intl.message(
      'Saved changes will appear here.',
      name: 'History_Empty',
      desc: '',
      args: [],
    );
  }

  /// `Saved {date}`
  String History_Version(String date) {
    return Intl.message(
      'Saved $date',
      name: 'History_Version',
      desc: '',
      args: [date],
    );
  }

  /// `Restore this version`
  String get History_Restore {
    return Intl.message(
      'Restore this version',
      name: 'History_Restore',
      desc: '',
      args: [],
    );
  }

  /// `Version restored`
  String get History_Restored {
    return Intl.message(
      'Version restored',
      name: 'History_Restored',
      desc: '',
      args: [],
    );
  }

  /// `Could not restore this version. Try again.`
  String get History_Restore_Failed {
    return Intl.message(
      'Could not restore this version. Try again.',
      name: 'History_Restore_Failed',
      desc: '',
      args: [],
    );
  }

  /// `This note or version is no longer available.`
  String get History_Unavailable {
    return Intl.message(
      'This note or version is no longer available.',
      name: 'History_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Already matches this version`
  String get History_Current {
    return Intl.message(
      'Already matches this version',
      name: 'History_Current',
      desc: '',
      args: [],
    );
  }

  /// `Version preview`
  String get History_Preview {
    return Intl.message(
      'Version preview',
      name: 'History_Preview',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{1 photo} other{{count} photos}}`
  String History_Photos(int count) {
    return Intl.plural(
      count,
      one: '1 photo',
      other: '$count photos',
      name: 'History_Photos',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 recording} other{{count} recordings}}`
  String History_Recordings(int count) {
    return Intl.plural(
      count,
      one: '1 recording',
      other: '$count recordings',
      name: 'History_Recordings',
      desc: '',
      args: [count],
    );
  }

  /// `Voice memo`
  String get Voice_Memo {
    return Intl.message('Voice memo', name: 'Voice_Memo', desc: '', args: []);
  }

  /// `Record`
  String get Voice_Record {
    return Intl.message('Record', name: 'Voice_Record', desc: '', args: []);
  }

  /// `Stop recording`
  String get Voice_Stop {
    return Intl.message(
      'Stop recording',
      name: 'Voice_Stop',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get Voice_Play {
    return Intl.message('Play', name: 'Voice_Play', desc: '', args: []);
  }

  /// `Pause`
  String get Voice_Pause {
    return Intl.message('Pause', name: 'Voice_Pause', desc: '', args: []);
  }

  /// `Transcribe`
  String get Voice_Transcribe {
    return Intl.message(
      'Transcribe',
      name: 'Voice_Transcribe',
      desc: '',
      args: [],
    );
  }

  /// `Transcribing…`
  String get Voice_Transcribing {
    return Intl.message(
      'Transcribing…',
      name: 'Voice_Transcribing',
      desc: '',
      args: [],
    );
  }

  /// `Review transcript`
  String get Voice_Review_Transcript {
    return Intl.message(
      'Review transcript',
      name: 'Voice_Review_Transcript',
      desc: '',
      args: [],
    );
  }

  /// `Save recording`
  String get Voice_Save {
    return Intl.message(
      'Save recording',
      name: 'Voice_Save',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get Voice_Cancel {
    return Intl.message('Cancel', name: 'Voice_Cancel', desc: '', args: []);
  }

  /// `Delete recording`
  String get Voice_Delete {
    return Intl.message(
      'Delete recording',
      name: 'Voice_Delete',
      desc: '',
      args: [],
    );
  }

  /// `Record up to 5 minutes. Transcription is optional.`
  String get Voice_Recording_Hint {
    return Intl.message(
      'Record up to 5 minutes. Transcription is optional.',
      name: 'Voice_Recording_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Recording stopped when the app was interrupted. Review it before saving.`
  String get Voice_Interrupted {
    return Intl.message(
      'Recording stopped when the app was interrupted. Review it before saving.',
      name: 'Voice_Interrupted',
      desc: '',
      args: [],
    );
  }

  /// `Could not record. Please try again.`
  String get Voice_Record_Failed {
    return Intl.message(
      'Could not record. Please try again.',
      name: 'Voice_Record_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Allow microphone access in Settings to record a voice memo.`
  String get Voice_Permission_Denied {
    return Intl.message(
      'Allow microphone access in Settings to record a voice memo.',
      name: 'Voice_Permission_Denied',
      desc: '',
      args: [],
    );
  }

  /// `On-device transcription is unavailable for this language or device. You can still save the recording.`
  String get Voice_Transcription_Unavailable {
    return Intl.message(
      'On-device transcription is unavailable for this language or device. You can still save the recording.',
      name: 'Voice_Transcription_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Could not transcribe. Your recording is safe; retry or save without text.`
  String get Voice_Transcription_Failed {
    return Intl.message(
      'Could not transcribe. Your recording is safe; retry or save without text.',
      name: 'Voice_Transcription_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Could not save the recording. Please try again.`
  String get Voice_Save_Failed {
    return Intl.message(
      'Could not save the recording. Please try again.',
      name: 'Voice_Save_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Could not discard the recording. Please try again.`
  String get Voice_Discard_Failed {
    return Intl.message(
      'Could not discard the recording. Please try again.',
      name: 'Voice_Discard_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Review and edit the transcript.`
  String get Voice_Transcript_Hint {
    return Intl.message(
      'Review and edit the transcript.',
      name: 'Voice_Transcript_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Transcription language`
  String get Voice_Transcription_Language {
    return Intl.message(
      'Transcription language',
      name: 'Voice_Transcription_Language',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get Voice_Language_English {
    return Intl.message(
      'English',
      name: 'Voice_Language_English',
      desc: '',
      args: [],
    );
  }

  /// `Chinese (Simplified)`
  String get Voice_Language_Chinese {
    return Intl.message(
      'Chinese (Simplified)',
      name: 'Voice_Language_Chinese',
      desc: '',
      args: [],
    );
  }

  /// `Chinese (Traditional)`
  String get Voice_Language_Chinese_Traditional {
    return Intl.message(
      'Chinese (Traditional)',
      name: 'Voice_Language_Chinese_Traditional',
      desc: '',
      args: [],
    );
  }

  /// `Edit transcript`
  String get Voice_Edit_Transcript {
    return Intl.message(
      'Edit transcript',
      name: 'Voice_Edit_Transcript',
      desc: '',
      args: [],
    );
  }

  /// `Could not copy text. Please try again.`
  String get Photo_Text_Copy_Failed {
    return Intl.message(
      'Could not copy text. Please try again.',
      name: 'Photo_Text_Copy_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Could not play this recording. Please try again.`
  String get Voice_Play_Failed {
    return Intl.message(
      'Could not play this recording. Please try again.',
      name: 'Voice_Play_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Archive`
  String get Archive {
    return Intl.message('Archive', name: 'Archive', desc: '', args: []);
  }

  /// `Archive note`
  String get Archive_Note {
    return Intl.message(
      'Archive note',
      name: 'Archive_Note',
      desc: '',
      args: [],
    );
  }

  /// `Unarchive note`
  String get Unarchive_Note {
    return Intl.message(
      'Unarchive note',
      name: 'Unarchive_Note',
      desc: '',
      args: [],
    );
  }

  /// `Note archived`
  String get Note_Archived {
    return Intl.message(
      'Note archived',
      name: 'Note_Archived',
      desc: '',
      args: [],
    );
  }

  /// `Note unarchived`
  String get Note_Unarchived {
    return Intl.message(
      'Note unarchived',
      name: 'Note_Unarchived',
      desc: '',
      args: [],
    );
  }

  /// `Your archived notes will appear here.`
  String get Archive_Empty {
    return Intl.message(
      'Your archived notes will appear here.',
      name: 'Archive_Empty',
      desc: '',
      args: [],
    );
  }

  /// `Tags`
  String get Tags {
    return Intl.message('Tags', name: 'Tags', desc: '', args: []);
  }

  /// `Edit tags`
  String get Edit_Tags {
    return Intl.message('Edit tags', name: 'Edit_Tags', desc: '', args: []);
  }

  /// `Add a tag`
  String get Tag_Hint {
    return Intl.message('Add a tag', name: 'Tag_Hint', desc: '', args: []);
  }

  /// `Use up to 20 tags, with 40 characters per tag.`
  String get Tag_Invalid {
    return Intl.message(
      'Use up to 20 tags, with 40 characters per tag.',
      name: 'Tag_Invalid',
      desc: '',
      args: [],
    );
  }

  /// `Filter by tags`
  String get Filter_Tags {
    return Intl.message(
      'Filter by tags',
      name: 'Filter_Tags',
      desc: '',
      args: [],
    );
  }

  /// `Saved views`
  String get Saved_Views {
    return Intl.message('Saved views', name: 'Saved_Views', desc: '', args: []);
  }

  /// `Save current view`
  String get Save_Current_View {
    return Intl.message(
      'Save current view',
      name: 'Save_Current_View',
      desc: '',
      args: [],
    );
  }

  /// `View name`
  String get Saved_View_Name {
    return Intl.message(
      'View name',
      name: 'Saved_View_Name',
      desc: '',
      args: [],
    );
  }

  /// `Save a search or filter to find it quickly next time.`
  String get Saved_View_Empty {
    return Intl.message(
      'Save a search or filter to find it quickly next time.',
      name: 'Saved_View_Empty',
      desc: '',
      args: [],
    );
  }

  /// `Delete this saved view?`
  String get Saved_View_Delete_Confirm {
    return Intl.message(
      'Delete this saved view?',
      name: 'Saved_View_Delete_Confirm',
      desc: '',
      args: [],
    );
  }

  /// `Could not save this view. Try again.`
  String get Saved_View_Failed {
    return Intl.message(
      'Could not save this view. Try again.',
      name: 'Saved_View_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Rename view`
  String get Rename_View {
    return Intl.message('Rename view', name: 'Rename_View', desc: '', args: []);
  }

  /// `Delete view`
  String get Delete_View {
    return Intl.message('Delete view', name: 'Delete_View', desc: '', args: []);
  }

  /// `View saved`
  String get View_Saved {
    return Intl.message('View saved', name: 'View_Saved', desc: '', args: []);
  }

  /// `Library filters`
  String get Library_Filters {
    return Intl.message(
      'Library filters',
      name: 'Library_Filters',
      desc: '',
      args: [],
    );
  }

  /// `Include archived notes`
  String get Include_Archived {
    return Intl.message(
      'Include archived notes',
      name: 'Include_Archived',
      desc: '',
      args: [],
    );
  }

  /// `Recordings`
  String get Share_Audio {
    return Intl.message('Recordings', name: 'Share_Audio', desc: '', args: []);
  }

  /// `Original audio files and reviewed transcripts`
  String get Share_Audio_Description {
    return Intl.message(
      'Original audio files and reviewed transcripts',
      name: 'Share_Audio_Description',
      desc: '',
      args: [],
    );
  }

  /// `Could not share this recording. Check that the audio file is available and try again.`
  String get Share_Audio_Failed {
    return Intl.message(
      'Could not share this recording. Check that the audio file is available and try again.',
      name: 'Share_Audio_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Linked notes`
  String get Linked_Notes {
    return Intl.message(
      'Linked notes',
      name: 'Linked_Notes',
      desc: '',
      args: [],
    );
  }

  /// `Linked from`
  String get Linked_From {
    return Intl.message('Linked from', name: 'Linked_From', desc: '', args: []);
  }

  /// `Link a note`
  String get Link_Note {
    return Intl.message('Link a note', name: 'Link_Note', desc: '', args: []);
  }

  /// `Choose linked notes`
  String get Choose_Linked_Notes {
    return Intl.message(
      'Choose linked notes',
      name: 'Choose_Linked_Notes',
      desc: '',
      args: [],
    );
  }

  /// `Search notes`
  String get Link_Search {
    return Intl.message(
      'Search notes',
      name: 'Link_Search',
      desc: '',
      args: [],
    );
  }

  /// `No notes to link yet. Create another note first.`
  String get Link_Empty {
    return Intl.message(
      'No notes to link yet. Create another note first.',
      name: 'Link_Empty',
      desc: '',
      args: [],
    );
  }

  /// `Note unavailable`
  String get Link_Unavailable {
    return Intl.message(
      'Note unavailable',
      name: 'Link_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Remove link`
  String get Link_Remove {
    return Intl.message('Remove link', name: 'Link_Remove', desc: '', args: []);
  }

  /// `Could not update this note. Try again.`
  String get Link_Save_Failed {
    return Intl.message(
      'Could not update this note. Try again.',
      name: 'Link_Save_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Untitled note`
  String get Note_Untitled {
    return Intl.message(
      'Untitled note',
      name: 'Note_Untitled',
      desc: '',
      args: [],
    );
  }

  /// `Open linked note`
  String get Open_Linked_Note {
    return Intl.message(
      'Open linked note',
      name: 'Open_Linked_Note',
      desc: '',
      args: [],
    );
  }

  /// `You can link up to 100 notes. Remove a link to add another.`
  String get Link_Limit {
    return Intl.message(
      'You can link up to 100 notes. Remove a link to add another.',
      name: 'Link_Limit',
      desc: '',
      args: [],
    );
  }

  /// `Bold`
  String get Format_Bold {
    return Intl.message('Bold', name: 'Format_Bold', desc: '', args: []);
  }

  /// `Heading`
  String get Format_Heading {
    return Intl.message('Heading', name: 'Format_Heading', desc: '', args: []);
  }

  /// `Bullets`
  String get Format_Bullets {
    return Intl.message('Bullets', name: 'Format_Bullets', desc: '', args: []);
  }

  /// `Text style`
  String get Format_Text {
    return Intl.message('Text style', name: 'Format_Text', desc: '', args: []);
  }

  /// `Move photo`
  String get Image_Move {
    return Intl.message('Move photo', name: 'Image_Move', desc: '', args: []);
  }

  /// `Resize photo`
  String get Image_Resize {
    return Intl.message(
      'Resize photo',
      name: 'Image_Resize',
      desc: '',
      args: [],
    );
  }

  /// `Remove photo`
  String get Image_Remove {
    return Intl.message(
      'Remove photo',
      name: 'Image_Remove',
      desc: '',
      args: [],
    );
  }

  /// `Move earlier`
  String get Image_Move_Before {
    return Intl.message(
      'Move earlier',
      name: 'Image_Move_Before',
      desc: '',
      args: [],
    );
  }

  /// `Move later`
  String get Image_Move_After {
    return Intl.message(
      'Move later',
      name: 'Image_Move_After',
      desc: '',
      args: [],
    );
  }

  /// `Drop photo here`
  String get Image_Drop_Here {
    return Intl.message(
      'Drop photo here',
      name: 'Image_Drop_Here',
      desc: '',
      args: [],
    );
  }

  /// `Edit photo`
  String get Photo_Edit {
    return Intl.message('Edit photo', name: 'Photo_Edit', desc: '', args: []);
  }

  /// `Drag the corners to crop. Rotate if needed.`
  String get Photo_Edit_Hint {
    return Intl.message(
      'Drag the corners to crop. Rotate if needed.',
      name: 'Photo_Edit_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Rotate`
  String get Photo_Rotate {
    return Intl.message('Rotate', name: 'Photo_Rotate', desc: '', args: []);
  }

  /// `Reset`
  String get Photo_Reset {
    return Intl.message('Reset', name: 'Photo_Reset', desc: '', args: []);
  }

  /// `Could not save this photo. Try again.`
  String get Photo_Edit_Failed {
    return Intl.message(
      'Could not save this photo. Try again.',
      name: 'Photo_Edit_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get Photo_Save {
    return Intl.message('Save', name: 'Photo_Save', desc: '', args: []);
  }

  /// `Find in note`
  String get Find_In_Note {
    return Intl.message(
      'Find in note',
      name: 'Find_In_Note',
      desc: '',
      args: [],
    );
  }

  /// `No matches`
  String get Find_No_Matches {
    return Intl.message(
      'No matches',
      name: 'Find_No_Matches',
      desc: '',
      args: [],
    );
  }

  /// `Previous match`
  String get Find_Previous {
    return Intl.message(
      'Previous match',
      name: 'Find_Previous',
      desc: '',
      args: [],
    );
  }

  /// `Next match`
  String get Find_Next {
    return Intl.message('Next match', name: 'Find_Next', desc: '', args: []);
  }

  /// `Close search`
  String get Find_Close {
    return Intl.message('Close search', name: 'Find_Close', desc: '', args: []);
  }

  /// `Today’s note`
  String get Today_Note {
    return Intl.message('Today’s note', name: 'Today_Note', desc: '', args: []);
  }

  /// `Could not open today’s note. Try again.`
  String get Today_Note_Open_Failed {
    return Intl.message(
      'Could not open today’s note. Try again.',
      name: 'Today_Note_Open_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Daily notes`
  String get Daily_Note_Calendar {
    return Intl.message(
      'Daily notes',
      name: 'Daily_Note_Calendar',
      desc: '',
      args: [],
    );
  }

  /// `No daily notes yet. Start with today's note.`
  String get Daily_Note_Calendar_Empty {
    return Intl.message(
      'No daily notes yet. Start with today\'s note.',
      name: 'Daily_Note_Calendar_Empty',
      desc: '',
      args: [],
    );
  }

  /// `No daily note for this date.`
  String get Daily_Note_Calendar_No_Note {
    return Intl.message(
      'No daily note for this date.',
      name: 'Daily_Note_Calendar_No_Note',
      desc: '',
      args: [],
    );
  }

  /// `Daily note available`
  String get Daily_Note_Calendar_Has_Note {
    return Intl.message(
      'Daily note available',
      name: 'Daily_Note_Calendar_Has_Note',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get Daily_Note_Calendar_Today {
    return Intl.message(
      'Today',
      name: 'Daily_Note_Calendar_Today',
      desc: '',
      args: [],
    );
  }

  /// `Previous month`
  String get Daily_Note_Calendar_Previous_Month {
    return Intl.message(
      'Previous month',
      name: 'Daily_Note_Calendar_Previous_Month',
      desc: '',
      args: [],
    );
  }

  /// `Next month`
  String get Daily_Note_Calendar_Next_Month {
    return Intl.message(
      'Next month',
      name: 'Daily_Note_Calendar_Next_Month',
      desc: '',
      args: [],
    );
  }

  /// `Choose month and year`
  String get Daily_Note_Calendar_Choose_Month {
    return Intl.message(
      'Choose month and year',
      name: 'Daily_Note_Calendar_Choose_Month',
      desc: '',
      args: [],
    );
  }

  /// `Could not open this daily note. Try again.`
  String get Daily_Note_Calendar_Open_Failed {
    return Intl.message(
      'Could not open this daily note. Try again.',
      name: 'Daily_Note_Calendar_Open_Failed',
      desc: '',
      args: [],
    );
  }

  /// `This daily note is no longer available.`
  String get Daily_Note_Calendar_Note_Unavailable {
    return Intl.message(
      'This daily note is no longer available.',
      name: 'Daily_Note_Calendar_Note_Unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Scan document`
  String get Document_Scan {
    return Intl.message(
      'Scan document',
      name: 'Document_Scan',
      desc: '',
      args: [],
    );
  }

  /// `Could not finish adding the scanned pages. Please try again.`
  String get Document_Scan_Failed {
    return Intl.message(
      'Could not finish adding the scanned pages. Please try again.',
      name: 'Document_Scan_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Document scanning is not available on this device.`
  String get Document_Scan_Unsupported {
    return Intl.message(
      'Document scanning is not available on this device.',
      name: 'Document_Scan_Unsupported',
      desc: '',
      args: [],
    );
  }

  /// `Allow camera access in Settings to scan documents.`
  String get Document_Scan_Permission {
    return Intl.message(
      'Allow camera access in Settings to scan documents.',
      name: 'Document_Scan_Permission',
      desc: '',
      args: [],
    );
  }

  /// `Scan up to 20 pages at a time. Please split this document into smaller scans.`
  String get Document_Scan_Too_Many {
    return Intl.message(
      'Scan up to 20 pages at a time. Please split this document into smaller scans.',
      name: 'Document_Scan_Too_Many',
      desc: '',
      args: [],
    );
  }

  /// `Your scan is still finishing. Try again in a moment.`
  String get Document_Scan_Pending {
    return Intl.message(
      'Your scan is still finishing. Try again in a moment.',
      name: 'Document_Scan_Pending',
      desc: '',
      args: [],
    );
  }

  /// `Highlight`
  String get Format_Highlight {
    return Intl.message(
      'Highlight',
      name: 'Format_Highlight',
      desc: '',
      args: [],
    );
  }

  /// `Remove highlight`
  String get Format_Remove_Highlight {
    return Intl.message(
      'Remove highlight',
      name: 'Format_Remove_Highlight',
      desc: '',
      args: [],
    );
  }

  /// `Select text to highlight`
  String get Format_Select_To_Highlight {
    return Intl.message(
      'Select text to highlight',
      name: 'Format_Select_To_Highlight',
      desc: '',
      args: [],
    );
  }

  /// `Outline`
  String get Note_Outline {
    return Intl.message('Outline', name: 'Note_Outline', desc: '', args: []);
  }

  /// `Tap a heading to jump to it`
  String get Note_Outline_Hint {
    return Intl.message(
      'Tap a heading to jump to it',
      name: 'Note_Outline_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Current section`
  String get Note_Outline_Current {
    return Intl.message(
      'Current section',
      name: 'Note_Outline_Current',
      desc: '',
      args: [],
    );
  }

  /// `Undo`
  String get Note_Undo {
    return Intl.message('Undo', name: 'Note_Undo', desc: '', args: []);
  }

  /// `Redo`
  String get Note_Redo {
    return Intl.message('Redo', name: 'Note_Redo', desc: '', args: []);
  }

  /// `Could not open this website.`
  String get Web_Link_Open_Failed {
    return Intl.message(
      'Could not open this website.',
      name: 'Web_Link_Open_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Focus writing`
  String get Note_FocusWriting {
    return Intl.message(
      'Focus writing',
      name: 'Note_FocusWriting',
      desc: '',
      args: [],
    );
  }

  /// `Show writing tools`
  String get Note_ShowWritingTools {
    return Intl.message(
      'Show writing tools',
      name: 'Note_ShowWritingTools',
      desc: '',
      args: [],
    );
  }

  /// `Edit match`
  String get Find_Edit_Match {
    return Intl.message(
      'Edit match',
      name: 'Find_Edit_Match',
      desc: '',
      args: [],
    );
  }

  /// `Replace`
  String get Find_Replace {
    return Intl.message('Replace', name: 'Find_Replace', desc: '', args: []);
  }

  /// `Replace with`
  String get Find_Replace_With {
    return Intl.message(
      'Replace with',
      name: 'Find_Replace_With',
      desc: '',
      args: [],
    );
  }

  /// `Replace all`
  String get Find_Replace_All {
    return Intl.message(
      'Replace all',
      name: 'Find_Replace_All',
      desc: '',
      args: [],
    );
  }

  /// `The note changed. Search again to replace.`
  String get Find_Replace_Changed {
    return Intl.message(
      'The note changed. Search again to replace.',
      name: 'Find_Replace_Changed',
      desc: '',
      args: [],
    );
  }

  /// `That replacement would make a title or checklist item too long.`
  String get Find_Replace_Limit {
    return Intl.message(
      'That replacement would make a title or checklist item too long.',
      name: 'Find_Replace_Limit',
      desc: '',
      args: [],
    );
  }

  /// `Replaced {count, plural, =1{1 match} other{{count} matches}}`
  String Find_Replaced(int count) {
    return Intl.message(
      'Replaced ${Intl.plural(count, one: '1 match', other: '$count matches')}',
      name: 'Find_Replaced',
      desc: '',
      args: [count],
    );
  }

  /// `Copy to note`
  String get Copy_Selection_To_Note {
    return Intl.message(
      'Copy to note',
      name: 'Copy_Selection_To_Note',
      desc: '',
      args: [],
    );
  }

  /// `Choose a note to add the selected text.`
  String get Copy_Selection_Destination {
    return Intl.message(
      'Choose a note to add the selected text.',
      name: 'Copy_Selection_Destination',
      desc: '',
      args: [],
    );
  }

  /// `New note`
  String get Copy_Selection_New_Note {
    return Intl.message(
      'New note',
      name: 'Copy_Selection_New_Note',
      desc: '',
      args: [],
    );
  }

  /// `Create a note with the selected text.`
  String get Copy_Selection_New_Note_Hint {
    return Intl.message(
      'Create a note with the selected text.',
      name: 'Copy_Selection_New_Note_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Search notes`
  String get Copy_Selection_Search_Notes {
    return Intl.message(
      'Search notes',
      name: 'Copy_Selection_Search_Notes',
      desc: '',
      args: [],
    );
  }

  /// `Create a new note to keep this text.`
  String get Copy_Selection_No_Notes {
    return Intl.message(
      'Create a new note to keep this text.',
      name: 'Copy_Selection_No_Notes',
      desc: '',
      args: [],
    );
  }

  /// `No matching notes`
  String get Copy_Selection_No_Matches {
    return Intl.message(
      'No matching notes',
      name: 'Copy_Selection_No_Matches',
      desc: '',
      args: [],
    );
  }

  /// `Text copied to note`
  String get Copy_Selection_Saved {
    return Intl.message(
      'Text copied to note',
      name: 'Copy_Selection_Saved',
      desc: '',
      args: [],
    );
  }

  /// `Could not save the copied text.`
  String get Copy_Selection_Failed {
    return Intl.message(
      'Could not save the copied text.',
      name: 'Copy_Selection_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Collapse {heading}`
  String Collapse_Section(String heading) {
    return Intl.message(
      'Collapse $heading',
      name: 'Collapse_Section',
      desc: '',
      args: [heading],
    );
  }

  /// `Expand {heading}`
  String Expand_Section(String heading) {
    return Intl.message(
      'Expand $heading',
      name: 'Expand_Section',
      desc: '',
      args: [heading],
    );
  }

  /// `Note info`
  String get Note_Info {
    return Intl.message('Note info', name: 'Note_Info', desc: '', args: []);
  }

  /// `Words`
  String get Note_Info_Words {
    return Intl.message('Words', name: 'Note_Info_Words', desc: '', args: []);
  }

  /// `Characters`
  String get Note_Info_Characters {
    return Intl.message(
      'Characters',
      name: 'Note_Info_Characters',
      desc: '',
      args: [],
    );
  }

  /// `Estimated reading time`
  String get Note_Info_Reading_Time {
    return Intl.message(
      'Estimated reading time',
      name: 'Note_Info_Reading_Time',
      desc: '',
      args: [],
    );
  }

  /// `0 min`
  String get Note_Info_Reading_Empty {
    return Intl.message(
      '0 min',
      name: 'Note_Info_Reading_Empty',
      desc: '',
      args: [],
    );
  }

  /// `Less than 1 min`
  String get Note_Info_Reading_Less_Than_Minute {
    return Intl.message(
      'Less than 1 min',
      name: 'Note_Info_Reading_Less_Than_Minute',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min`
  String Note_Info_Reading_Minutes(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'Note_Info_Reading_Minutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `Includes title, note text, checklist items, and transcripts. CJK characters count individually.`
  String get Note_Info_Counting_Hint {
    return Intl.message(
      'Includes title, note text, checklist items, and transcripts. CJK characters count individually.',
      name: 'Note_Info_Counting_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Add to checklist`
  String get Add_Selection_To_Checklist {
    return Intl.message(
      'Add to checklist',
      name: 'Add_Selection_To_Checklist',
      desc: '',
      args: [],
    );
  }

  /// `One line is too long for a checklist item. Select shorter lines.`
  String get Selection_Checklist_Too_Long {
    return Intl.message(
      'One line is too long for a checklist item. Select shorter lines.',
      name: 'Selection_Checklist_Too_Long',
      desc: '',
      args: [],
    );
  }

  /// `Added {count, plural, =1{1 checklist item} other{{count} checklist items}}`
  String Selection_Checklist_Added(int count) {
    return Intl.message(
      'Added ${Intl.plural(count, one: '1 checklist item', other: '$count checklist items')}',
      name: 'Selection_Checklist_Added',
      desc: '',
      args: [count],
    );
  }

  /// `Could not save the checklist items.`
  String get Selection_Checklist_Failed {
    return Intl.message(
      'Could not save the checklist items.',
      name: 'Selection_Checklist_Failed',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{1 linked note} other{{count} linked notes}}`
  String Card_Linked_Notes_Count(int count) {
    return Intl.plural(
      count,
      one: '1 linked note',
      other: '$count linked notes',
      name: 'Card_Linked_Notes_Count',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 scanned page} other{{count} scanned pages}}`
  String Card_Scanned_Pages_Count(int count) {
    return Intl.plural(
      count,
      one: '1 scanned page',
      other: '$count scanned pages',
      name: 'Card_Scanned_Pages_Count',
      desc: '',
      args: [count],
    );
  }

  /// `Insert`
  String get Editor_Insert {
    return Intl.message('Insert', name: 'Editor_Insert', desc: '', args: []);
  }

  /// `Use the buttons below to format selected text.`
  String get Editor_Tip_Formatting {
    return Intl.message(
      'Use the buttons below to format selected text.',
      name: 'Editor_Tip_Formatting',
      desc: '',
      args: [],
    );
  }

  /// `Tap a photo to resize it. Press and hold to move it.`
  String get Editor_Tip_Image_Layout {
    return Intl.message(
      'Tap a photo to resize it. Press and hold to move it.',
      name: 'Editor_Tip_Image_Layout',
      desc: '',
      args: [],
    );
  }

  /// `Card style`
  String get Card_Style {
    return Intl.message('Card style', name: 'Card_Style', desc: '', args: []);
  }

  /// `Default card style`
  String get Default_Card_Style {
    return Intl.message(
      'Default card style',
      name: 'Default_Card_Style',
      desc: '',
      args: [],
    );
  }

  /// `Choose how your notes look in the library`
  String get Default_Card_Style_Description {
    return Intl.message(
      'Choose how your notes look in the library',
      name: 'Default_Card_Style_Description',
      desc: '',
      args: [],
    );
  }

  /// `Live preview`
  String get Card_Style_Preview {
    return Intl.message(
      'Live preview',
      name: 'Card_Style_Preview',
      desc: '',
      args: [],
    );
  }

  /// `Use default`
  String get Card_Style_Use_Default {
    return Intl.message(
      'Use default',
      name: 'Card_Style_Use_Default',
      desc: '',
      args: [],
    );
  }

  /// `Use default style`
  String get Card_Style_Use_Default_All {
    return Intl.message(
      'Use default style',
      name: 'Card_Style_Use_Default_All',
      desc: '',
      args: [],
    );
  }

  /// `Notes without a custom style use these defaults.`
  String get Card_Style_Default_Hint {
    return Intl.message(
      'Notes without a custom style use these defaults.',
      name: 'Card_Style_Default_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Changes apply to this card only.`
  String get Card_Style_Note_Hint {
    return Intl.message(
      'Changes apply to this card only.',
      name: 'Card_Style_Note_Hint',
      desc: '',
      args: [],
    );
  }

  /// `Paper style`
  String get Card_Style_Paper {
    return Intl.message(
      'Paper style',
      name: 'Card_Style_Paper',
      desc: '',
      args: [],
    );
  }

  /// `Textured`
  String get Card_Style_Textured {
    return Intl.message(
      'Textured',
      name: 'Card_Style_Textured',
      desc: '',
      args: [],
    );
  }

  /// `Plain`
  String get Card_Style_Plain {
    return Intl.message('Plain', name: 'Card_Style_Plain', desc: '', args: []);
  }

  /// `Follow app appearance`
  String get Card_Style_Follow_App {
    return Intl.message(
      'Follow app appearance',
      name: 'Card_Style_Follow_App',
      desc: '',
      args: [],
    );
  }

  /// `Show date`
  String get Card_Style_Show_Date {
    return Intl.message(
      'Show date',
      name: 'Card_Style_Show_Date',
      desc: '',
      args: [],
    );
  }

  /// `Reset style`
  String get Card_Style_Reset {
    return Intl.message(
      'Reset style',
      name: 'Card_Style_Reset',
      desc: '',
      args: [],
    );
  }

  /// `Could not save card style. Please try again.`
  String get Card_Style_Save_Failed {
    return Intl.message(
      'Could not save card style. Please try again.',
      name: 'Card_Style_Save_Failed',
      desc: '',
      args: [],
    );
  }

  /// `Discard style changes?`
  String get Card_Style_Discard_Title {
    return Intl.message(
      'Discard style changes?',
      name: 'Card_Style_Discard_Title',
      desc: '',
      args: [],
    );
  }

  /// `Your card style changes have not been saved.`
  String get Card_Style_Discard_Message {
    return Intl.message(
      'Your card style changes have not been saved.',
      name: 'Card_Style_Discard_Message',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get Card_Style_Discard {
    return Intl.message(
      'Discard',
      name: 'Card_Style_Discard',
      desc: '',
      args: [],
    );
  }

  /// `A little inspiration`
  String get Card_Style_Preview_Title {
    return Intl.message(
      'A little inspiration',
      name: 'Card_Style_Preview_Title',
      desc: '',
      args: [],
    );
  }

  /// `Collect your ideas, plans, and everyday moments.`
  String get Card_Style_Preview_Body {
    return Intl.message(
      'Collect your ideas, plans, and everyday moments.',
      name: 'Card_Style_Preview_Body',
      desc: '',
      args: [],
    );
  }

  /// `Try something new`
  String get Card_Style_Preview_Task {
    return Intl.message(
      'Try something new',
      name: 'Card_Style_Preview_Task',
      desc: '',
      args: [],
    );
  }

  /// `Hide date`
  String get Card_Style_Hide_Date {
    return Intl.message(
      'Hide date',
      name: 'Card_Style_Hide_Date',
      desc: '',
      args: [],
    );
  }
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
