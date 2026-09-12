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

  /// `Todo List`
  String get Todo_list {
    return Intl.message('Todo List', name: 'Todo_list', desc: '', args: []);
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

  /// `Add todo`
  String get Add_todo {
    return Intl.message('Add todo', name: 'Add_todo', desc: '', args: []);
  }

  /// `Todo..`
  String get Todo {
    return Intl.message('Todo..', name: 'Todo', desc: '', args: []);
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

  /// `Could not save your changes. Keep this note open and tap Done to retry.`
  String get Autosave_Failed {
    return Intl.message(
      'Could not save your changes. Keep this note open and tap Done to retry.',
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

  /// `Save your notes, checklists, folders, photos, and reminder dates in one Onlynote file. Includes notes in Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.`
  String get Backup_Export_Description {
    return Intl.message(
      'Save your notes, checklists, folders, photos, and reminder dates in one Onlynote file. Includes notes in Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.',
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

  /// `Restoring adds copies of the backed-up notes and folders. Your existing notes stay unchanged. Restoring the same file again adds another set of copies.`
  String get Backup_Restore_Description {
    return Intl.message(
      'Restoring adds copies of the backed-up notes and folders. Your existing notes stay unchanged. Restoring the same file again adds another set of copies.',
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

  /// `Could not create the backup. Check available storage and that all note photos are accessible. Backups must fit within 256 MB.`
  String get Backup_Export_Failed {
    return Intl.message(
      'Could not create the backup. Check available storage and that all note photos are accessible. Backups must fit within 256 MB.',
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
