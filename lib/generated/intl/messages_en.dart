// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(notes, folders, photos) =>
      "${notes} notes · ${folders} folders · ${photos} photos";

  static String m1(date) => "Last backup saved: ${date}";

  static String m2(date) => "Last backup shared: ${date}";

  static String m3(count) =>
      "${Intl.plural(count, one: '1 linked note', other: '${count} linked notes')}";

  static String m4(date) => "Moved to Trash on ${date}";

  static String m5(count) =>
      "${Intl.plural(count, one: '1 scanned page', other: '${count} scanned pages')}";

  static String m6(count) => "Completed (${count})";

  static String m7(count) =>
      "${Intl.plural(count, one: '1 task copied', other: '${count} tasks copied')}";

  static String m8(completed, total) => "${completed} of ${total} complete";

  static String m9(heading) => "Collapse ${heading}";

  static String m10(heading) => "Expand ${heading}";

  static String m11(count) =>
      "${Intl.plural(count, one: '1 note could not be exported.', other: '${count} notes could not be exported.')}";

  static String m12(count) =>
      "Replaced ${Intl.plural(count, one: '1 match', other: '${count} matches')}";

  static String m13(count) => "${count} notes";

  static String m14(count) =>
      "${Intl.plural(count, one: '1 photo', other: '${count} photos')}";

  static String m15(count) =>
      "${Intl.plural(count, one: '1 recording', other: '${count} recordings')}";

  static String m16(date) => "Saved ${date}";

  static String m17(count) =>
      "${Intl.plural(count, one: '1 selected note hidden by search', other: '${count} selected notes hidden by search')}";

  static String m18(count) =>
      "${Intl.plural(count, one: '1 note selected', other: '${count} notes selected')}";

  static String m19(number) => "Note color ${number}";

  static String m20(minutes) => "${minutes} min";

  static String m21(name) => "Open ${name} in library";

  static String m22(number) => "Photo ${number}";

  static String m23(limit) =>
      "The free plan includes ${limit} folders. Upgrade for unlimited folders.";

  static String m24(limit) =>
      "The free plan includes ${limit} notes. Upgrade for unlimited notes.";

  static String m25(price) => "Unlock forever for ${price}";

  static String m26(limit) =>
      "The free plan includes ${limit} saved templates. Upgrade for unlimited templates.";

  static String m27(time) => "Next reminder: ${time}";

  static String m28(date) => "Remind me: ${date}";

  static String m29(price) => "Remove ads permanently for ${price}.";

  static String m30(criterion) => "Remove ${criterion}";

  static String m31(limit) =>
      "You can save up to ${limit} views. Delete a saved view to add another.";

  static String m32(query) => "Search: ${query}";

  static String m33(tags) => "Tags: ${tags}";

  static String m34(count) =>
      "${Intl.plural(count, zero: '0 notes found', one: '1 note found', other: '${count} notes found')}";

  static String m35(count) =>
      "Added ${Intl.plural(count, one: '1 checklist item', other: '${count} checklist items')}";

  static String m36(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} note', other: '${formattedCount} notes')}";

  static String m37(count) =>
      "${Intl.plural(count, one: '1 selected tag hidden by search', other: '${count} selected tags hidden by search')}";

  static String m38(count) =>
      "${Intl.plural(count, one: '1 tag selected', other: '${count} tags selected')}";

  static String m39(limit) =>
      "You can select up to ${limit} tags. Deselect a tag to choose another.";

  static String m40(items, photos) =>
      "${Intl.plural(items, zero: '0 items', one: '1 item', other: '${items} items')} · ${Intl.plural(photos, zero: '0 photos', one: '1 photo', other: '${photos} photos')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("Add Photo"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("Add Note"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("Add Reminder"),
    "Add_Selection_To_Checklist": MessageLookupByLibrary.simpleMessage(
      "Add to checklist",
    ),
    "Add_todo": MessageLookupByLibrary.simpleMessage("Add item"),
    "Ads_Removed": MessageLookupByLibrary.simpleMessage("Ads Removed"),
    "Ads_Removed_Description": MessageLookupByLibrary.simpleMessage(
      "Ads are permanently removed on this device.",
    ),
    "All_Notes": MessageLookupByLibrary.simpleMessage("All Notes"),
    "Allow_Notification": MessageLookupByLibrary.simpleMessage(
      "Allow Notification",
    ),
    "Appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "Archive": MessageLookupByLibrary.simpleMessage("Archive"),
    "Archive_Empty": MessageLookupByLibrary.simpleMessage(
      "Your archived notes will appear here.",
    ),
    "Archive_Note": MessageLookupByLibrary.simpleMessage("Archive note"),
    "Autosave_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save your changes. Keep this note open and tap Not saved to retry.",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("Not saved"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("Saved"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("Saving…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("Choose backup file"),
    "Backup_Contents": m0,
    "Backup_Created": MessageLookupByLibrary.simpleMessage("Backup created"),
    "Backup_Export": MessageLookupByLibrary.simpleMessage("Create backup"),
    "Backup_Export_Cancelled": MessageLookupByLibrary.simpleMessage(
      "Backup sharing cancelled.",
    ),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "Save your notes, tags, saved views, folders, photos, recordings, history, templates, and reminder dates in one Onlynote file. Includes archived notes and Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.",
    ),
    "Backup_Export_Desktop_Description": MessageLookupByLibrary.simpleMessage(
      "Save your notes, tags, saved views, folders, photos, recordings, history, templates, and reminder dates in one Onlynote file. Includes archived notes and Trash. Choose a location in the save dialog. Maximum file size: 256 MB.",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not create the backup. Check available storage and that all photos and recordings are accessible. Backups must fit within 256 MB.",
    ),
    "Backup_Export_Last_Saved": m1,
    "Backup_Export_Last_Shared": m2,
    "Backup_Export_No_Record": MessageLookupByLibrary.simpleMessage(
      "No backup export recorded",
    ),
    "Backup_Export_Prepared": MessageLookupByLibrary.simpleMessage(
      "Backup prepared. This device could not confirm whether it was shared.",
    ),
    "Backup_Export_Save_Cancelled": MessageLookupByLibrary.simpleMessage(
      "Backup save cancelled.",
    ),
    "Backup_Export_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save the backup. Check available storage and try again.",
    ),
    "Backup_Export_Saved": MessageLookupByLibrary.simpleMessage(
      "Backup saved.",
    ),
    "Backup_Export_Share_Failed": MessageLookupByLibrary.simpleMessage(
      "Backup prepared, but sharing failed. Please try again.",
    ),
    "Backup_Export_Shared": MessageLookupByLibrary.simpleMessage(
      "Backup sharing completed. Check the selected app to confirm it was saved.",
    ),
    "Backup_History_Versions": MessageLookupByLibrary.simpleMessage(
      "History versions",
    ),
    "Backup_Invalid": MessageLookupByLibrary.simpleMessage(
      "This is not a supported Onlynote backup, or the file is damaged or larger than 256 MB. Nothing was imported.",
    ),
    "Backup_Preparing": MessageLookupByLibrary.simpleMessage(
      "Preparing your backup…",
    ),
    "Backup_Reading": MessageLookupByLibrary.simpleMessage(
      "Checking the backup file…",
    ),
    "Backup_Recording_Files": MessageLookupByLibrary.simpleMessage(
      "Recording files",
    ),
    "Backup_Restore": MessageLookupByLibrary.simpleMessage("Restore backup"),
    "Backup_Restore_Description": MessageLookupByLibrary.simpleMessage(
      "Restoring adds copies of the backed-up notes, folders, templates, and saved views to your library. Note links connect the restored copies. Restoring the same file again adds another set of copies.",
    ),
    "Backup_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not restore the backup. Check available storage and try again. Your existing notes have not been overwritten.",
    ),
    "Backup_Restored": MessageLookupByLibrary.simpleMessage(
      "Backup restored. Your notes are ready in the library.",
    ),
    "Backup_Restored_No_Notifications": MessageLookupByLibrary.simpleMessage(
      "Notes restored. Some reminder notifications could not be scheduled; open those notes to set them again.",
    ),
    "Backup_Restoring": MessageLookupByLibrary.simpleMessage(
      "Restoring your notes and photos…",
    ),
    "Backup_Save_As": MessageLookupByLibrary.simpleMessage("Save backup…"),
    "Backup_Saved_Views": MessageLookupByLibrary.simpleMessage("Saved views"),
    "Backup_Schedule_Reminders": MessageLookupByLibrary.simpleMessage(
      "Schedule future reminder notifications",
    ),
    "Backup_Title": MessageLookupByLibrary.simpleMessage("Backup & Restore"),
    "Cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "Cancel_Searching": MessageLookupByLibrary.simpleMessage(
      "Cancel searching",
    ),
    "Card_Linked_Notes_Count": m3,
    "Card_Moved_To_Trash_On": m4,
    "Card_Scanned_Pages_Count": m5,
    "Card_Size": MessageLookupByLibrary.simpleMessage("Card Size"),
    "Card_Style": MessageLookupByLibrary.simpleMessage("Card style"),
    "Card_Style_Color": MessageLookupByLibrary.simpleMessage("Color"),
    "Card_Style_Default_Color": MessageLookupByLibrary.simpleMessage(
      "Default paper color",
    ),
    "Card_Style_Default_Hint": MessageLookupByLibrary.simpleMessage(
      "Notes without a custom style use these defaults.",
    ),
    "Card_Style_Discard": MessageLookupByLibrary.simpleMessage("Discard"),
    "Card_Style_Discard_Message": MessageLookupByLibrary.simpleMessage(
      "Your card style changes have not been saved.",
    ),
    "Card_Style_Discard_Title": MessageLookupByLibrary.simpleMessage(
      "Discard style changes?",
    ),
    "Card_Style_Follow_App": MessageLookupByLibrary.simpleMessage(
      "Follow app appearance",
    ),
    "Card_Style_Hide_Date": MessageLookupByLibrary.simpleMessage("Hide date"),
    "Card_Style_Layout": MessageLookupByLibrary.simpleMessage("Layout"),
    "Card_Style_Note_Hint": MessageLookupByLibrary.simpleMessage(
      "Changes apply to this card only.",
    ),
    "Card_Style_Original_Color": MessageLookupByLibrary.simpleMessage(
      "Original color",
    ),
    "Card_Style_Paper": MessageLookupByLibrary.simpleMessage("Paper style"),
    "Card_Style_Plain": MessageLookupByLibrary.simpleMessage("Plain"),
    "Card_Style_Preview": MessageLookupByLibrary.simpleMessage("Live preview"),
    "Card_Style_Preview_Body": MessageLookupByLibrary.simpleMessage(
      "Collect your ideas, plans, and everyday moments.",
    ),
    "Card_Style_Preview_Task": MessageLookupByLibrary.simpleMessage(
      "Try something new",
    ),
    "Card_Style_Preview_Title": MessageLookupByLibrary.simpleMessage(
      "A little inspiration",
    ),
    "Card_Style_Reset": MessageLookupByLibrary.simpleMessage("Reset style"),
    "Card_Style_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save card style. Please try again.",
    ),
    "Card_Style_Show_Date": MessageLookupByLibrary.simpleMessage("Show date"),
    "Card_Style_Text": MessageLookupByLibrary.simpleMessage("Text"),
    "Card_Style_Textured": MessageLookupByLibrary.simpleMessage("Textured"),
    "Card_Style_Theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "Card_Style_Use_Default": MessageLookupByLibrary.simpleMessage(
      "Use default",
    ),
    "Card_Style_Use_Default_All": MessageLookupByLibrary.simpleMessage(
      "Use default style",
    ),
    "Checklist_All_Done": MessageLookupByLibrary.simpleMessage("All done"),
    "Checklist_Completed": m6,
    "Checklist_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy tasks. Please try again.",
    ),
    "Checklist_Copy_Success": m7,
    "Checklist_Copy_Unfinished": MessageLookupByLibrary.simpleMessage(
      "Copy unfinished",
    ),
    "Checklist_Item_Completed": MessageLookupByLibrary.simpleMessage(
      "Item completed",
    ),
    "Checklist_Item_Reopened": MessageLookupByLibrary.simpleMessage(
      "Item reopened",
    ),
    "Checklist_Item_Unavailable": MessageLookupByLibrary.simpleMessage(
      "This checklist item is no longer available.",
    ),
    "Checklist_Progress": m8,
    "Checklist_Reset": MessageLookupByLibrary.simpleMessage("Reset checklist"),
    "Checklist_Reset_Done": MessageLookupByLibrary.simpleMessage(
      "Checklist reset",
    ),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage(
      "Choose From Gallery",
    ),
    "Choose_Image_File": MessageLookupByLibrary.simpleMessage(
      "Choose an image file",
    ),
    "Choose_Linked_Notes": MessageLookupByLibrary.simpleMessage(
      "Choose linked notes",
    ),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage(
      "Classical Music Box",
    ),
    "Clear_Filters": MessageLookupByLibrary.simpleMessage("Clear filters"),
    "Clear_Search": MessageLookupByLibrary.simpleMessage("Clear search"),
    "Collapse_Section": m9,
    "Copy_Selection_Destination": MessageLookupByLibrary.simpleMessage(
      "Choose a note to add the selected text.",
    ),
    "Copy_Selection_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save the copied text.",
    ),
    "Copy_Selection_New_Note": MessageLookupByLibrary.simpleMessage("New note"),
    "Copy_Selection_New_Note_Hint": MessageLookupByLibrary.simpleMessage(
      "Create a note with the selected text.",
    ),
    "Copy_Selection_No_Matches": MessageLookupByLibrary.simpleMessage(
      "No matching notes",
    ),
    "Copy_Selection_No_Notes": MessageLookupByLibrary.simpleMessage(
      "Create a new note to keep this text.",
    ),
    "Copy_Selection_Saved": MessageLookupByLibrary.simpleMessage(
      "Text copied to note",
    ),
    "Copy_Selection_Search_Notes": MessageLookupByLibrary.simpleMessage(
      "Search notes",
    ),
    "Copy_Selection_To_Note": MessageLookupByLibrary.simpleMessage(
      "Copy to note",
    ),
    "Copy_Suffix": MessageLookupByLibrary.simpleMessage("(Copy)"),
    "Daily_Note_Calendar": MessageLookupByLibrary.simpleMessage("Daily notes"),
    "Daily_Note_Calendar_Choose_Month": MessageLookupByLibrary.simpleMessage(
      "Choose month and year",
    ),
    "Daily_Note_Calendar_Empty": MessageLookupByLibrary.simpleMessage(
      "No daily notes yet. Start with today\'s note.",
    ),
    "Daily_Note_Calendar_Has_Note": MessageLookupByLibrary.simpleMessage(
      "Daily note available",
    ),
    "Daily_Note_Calendar_Next_Month": MessageLookupByLibrary.simpleMessage(
      "Next month",
    ),
    "Daily_Note_Calendar_No_Note": MessageLookupByLibrary.simpleMessage(
      "No daily note for this date.",
    ),
    "Daily_Note_Calendar_Note_Unavailable":
        MessageLookupByLibrary.simpleMessage(
          "This daily note is no longer available.",
        ),
    "Daily_Note_Calendar_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not open this daily note. Try again.",
    ),
    "Daily_Note_Calendar_Previous_Month": MessageLookupByLibrary.simpleMessage(
      "Previous month",
    ),
    "Daily_Note_Calendar_Today": MessageLookupByLibrary.simpleMessage("Today"),
    "Default_Card_Style": MessageLookupByLibrary.simpleMessage(
      "Default card style",
    ),
    "Default_Card_Style_Description": MessageLookupByLibrary.simpleMessage(
      "Choose how your notes look in the library",
    ),
    "Delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "Delete_Folder": MessageLookupByLibrary.simpleMessage("Delete Folder"),
    "Delete_Folder_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "Notes in this folder will stay in All Notes. The folder itself will be removed.",
    ),
    "Delete_Forever": MessageLookupByLibrary.simpleMessage("Delete Forever"),
    "Delete_Note_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "This note will be moved to Trash. You can restore it later.",
    ),
    "Delete_Note_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete this note?",
    ),
    "Delete_Template": MessageLookupByLibrary.simpleMessage("Delete template"),
    "Delete_Todo_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "This checklist item will be removed. This can\'t be undone.",
    ),
    "Delete_Todo_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete this item?",
    ),
    "Delete_View": MessageLookupByLibrary.simpleMessage("Delete view"),
    "Desktop_Menu_Close_Window": MessageLookupByLibrary.simpleMessage(
      "Close Window",
    ),
    "Desktop_Menu_File": MessageLookupByLibrary.simpleMessage("File"),
    "Desktop_Menu_New_Note": MessageLookupByLibrary.simpleMessage("New Note"),
    "Desktop_Menu_Quit": MessageLookupByLibrary.simpleMessage("Quit Onlynote"),
    "Desktop_Menu_Window": MessageLookupByLibrary.simpleMessage("Window"),
    "Document_Scan": MessageLookupByLibrary.simpleMessage("Scan document"),
    "Document_Scan_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not finish adding the scanned pages. Please try again.",
    ),
    "Document_Scan_Pending": MessageLookupByLibrary.simpleMessage(
      "Your scan is still finishing. Try again in a moment.",
    ),
    "Document_Scan_Permission": MessageLookupByLibrary.simpleMessage(
      "Allow camera access in Settings to scan documents.",
    ),
    "Document_Scan_Too_Many": MessageLookupByLibrary.simpleMessage(
      "Scan up to 20 pages at a time. Please split this document into smaller scans.",
    ),
    "Document_Scan_Unsupported": MessageLookupByLibrary.simpleMessage(
      "Document scanning is not available on this device.",
    ),
    "Done": MessageLookupByLibrary.simpleMessage("Done"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "Edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "Edit_Tags": MessageLookupByLibrary.simpleMessage("Edit tags"),
    "Editor_Insert": MessageLookupByLibrary.simpleMessage("Insert"),
    "Editor_Tip_Formatting": MessageLookupByLibrary.simpleMessage(
      "Use the buttons below to format selected text.",
    ),
    "Editor_Tip_Image_Layout": MessageLookupByLibrary.simpleMessage(
      "Tap a photo to resize it. Press and hold to move it.",
    ),
    "Empty_Trash": MessageLookupByLibrary.simpleMessage("Empty Trash"),
    "Expand_Section": m10,
    "Export_Notes": MessageLookupByLibrary.simpleMessage("Export notes"),
    "Export_Notes_Cancelled": MessageLookupByLibrary.simpleMessage(
      "Note export sharing cancelled.",
    ),
    "Export_Notes_Description": MessageLookupByLibrary.simpleMessage(
      "Save every note, including archived ones, as one zip of readable files — one file per note, with photos and recordings beside Markdown. Choose Save to Files or a storage app from the share menu.",
    ),
    "Export_Notes_Desktop_Description": MessageLookupByLibrary.simpleMessage(
      "Save every note, including archived ones, as one zip of readable files — one file per note, with photos and recordings beside Markdown. Choose a location in the save dialog.",
    ),
    "Export_Notes_Empty": MessageLookupByLibrary.simpleMessage(
      "There are no notes to export yet.",
    ),
    "Export_Notes_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not export your notes. Check available storage and that photos and recordings are accessible.",
    ),
    "Export_Notes_Format": MessageLookupByLibrary.simpleMessage("Format"),
    "Export_Notes_Incomplete": m11,
    "Export_Notes_Prepared": MessageLookupByLibrary.simpleMessage(
      "Notes exported. This device could not confirm whether they were shared.",
    ),
    "Export_Notes_Preparing": MessageLookupByLibrary.simpleMessage(
      "Exporting your notes…",
    ),
    "Export_Notes_Save_As": MessageLookupByLibrary.simpleMessage("Save notes…"),
    "Export_Notes_Save_Cancelled": MessageLookupByLibrary.simpleMessage(
      "Note export save cancelled.",
    ),
    "Export_Notes_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save the export. Check available storage and try again.",
    ),
    "Export_Notes_Saved": MessageLookupByLibrary.simpleMessage("Notes saved."),
    "Export_Notes_Share_Failed": MessageLookupByLibrary.simpleMessage(
      "Export prepared, but sharing failed. Please try again.",
    ),
    "Export_Notes_Shared": MessageLookupByLibrary.simpleMessage(
      "Note export completed. Check the selected app to confirm it was saved.",
    ),
    "Express_Scan": MessageLookupByLibrary.simpleMessage("Express Scan"),
    "Failed_to_Update_note_please_try_again":
        MessageLookupByLibrary.simpleMessage(
          "Failed to Update note, please try again.",
        ),
    "Failed_to_add_note_Title_should_not_empty":
        MessageLookupByLibrary.simpleMessage(
          "Can\'t save an empty note. Add a title, description, checklist item, or photo.",
        ),
    "Failed_to_add_note_please_try_again": MessageLookupByLibrary.simpleMessage(
      "Failed to add note, please try again.",
    ),
    "Failed_to_delete_folder": MessageLookupByLibrary.simpleMessage(
      "Failed to delete folder, please try again.",
    ),
    "Failed_to_delete_note_please_try_again":
        MessageLookupByLibrary.simpleMessage(
          "Failed to delete note, please try again.",
        ),
    "Failed_to_delete_notes": MessageLookupByLibrary.simpleMessage(
      "Failed to delete notes",
    ),
    "Failed_to_load_note_please_try_again":
        MessageLookupByLibrary.simpleMessage(
          "Failed to load note, please try again.",
        ),
    "Failed_to_load_notes_please_try_again":
        MessageLookupByLibrary.simpleMessage(
          "Failed to load notes, please try again.",
        ),
    "Failed_to_restore_notes": MessageLookupByLibrary.simpleMessage(
      "Failed to restore notes, please try again.",
    ),
    "Failed_to_save_folder": MessageLookupByLibrary.simpleMessage(
      "Failed to save folder, please try again.",
    ),
    "Failed_to_update_note_Title_should_not_empty":
        MessageLookupByLibrary.simpleMessage(
          "Can\'t save an empty note. Add a title, description, checklist item, or photo.",
        ),
    "Filter_Checklists": MessageLookupByLibrary.simpleMessage("Checklists"),
    "Filter_Photos": MessageLookupByLibrary.simpleMessage("Photos"),
    "Filter_Pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "Filter_Recordings": MessageLookupByLibrary.simpleMessage("Recordings"),
    "Filter_Reminders": MessageLookupByLibrary.simpleMessage("Reminders"),
    "Filter_Scans": MessageLookupByLibrary.simpleMessage("Scanned documents"),
    "Filter_Tags": MessageLookupByLibrary.simpleMessage("Filter by tags"),
    "Filter_Unfinished": MessageLookupByLibrary.simpleMessage("Unfinished"),
    "Find_Close": MessageLookupByLibrary.simpleMessage("Close search"),
    "Find_Edit_Match": MessageLookupByLibrary.simpleMessage("Edit match"),
    "Find_In_Note": MessageLookupByLibrary.simpleMessage("Find in note"),
    "Find_Next": MessageLookupByLibrary.simpleMessage("Next match"),
    "Find_No_Matches": MessageLookupByLibrary.simpleMessage("No matches"),
    "Find_Previous": MessageLookupByLibrary.simpleMessage("Previous match"),
    "Find_Replace": MessageLookupByLibrary.simpleMessage("Replace"),
    "Find_Replace_All": MessageLookupByLibrary.simpleMessage("Replace all"),
    "Find_Replace_Changed": MessageLookupByLibrary.simpleMessage(
      "The note changed. Search again to replace.",
    ),
    "Find_Replace_Limit": MessageLookupByLibrary.simpleMessage(
      "That replacement would make a title or checklist item too long.",
    ),
    "Find_Replace_With": MessageLookupByLibrary.simpleMessage("Replace with"),
    "Find_Replaced": m12,
    "Folder_Created": MessageLookupByLibrary.simpleMessage("Folder created"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("Folder deleted"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("Folder name"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage(
      "Please enter a folder name.",
    ),
    "Folder_Notes_Count": m13,
    "Folder_Search_Empty": MessageLookupByLibrary.simpleMessage(
      "No matching folders.",
    ),
    "Folder_Unavailable": MessageLookupByLibrary.simpleMessage(
      "This folder is no longer available.",
    ),
    "Folders": MessageLookupByLibrary.simpleMessage("Folders"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage(
      "A little space for your next big idea.",
    ),
    "Font_Size": MessageLookupByLibrary.simpleMessage("Font Size"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("Font Style"),
    "Format_Bold": MessageLookupByLibrary.simpleMessage("Bold"),
    "Format_Bullets": MessageLookupByLibrary.simpleMessage("Bullets"),
    "Format_Heading": MessageLookupByLibrary.simpleMessage("Heading"),
    "Format_Highlight": MessageLookupByLibrary.simpleMessage("Highlight"),
    "Format_Remove_Highlight": MessageLookupByLibrary.simpleMessage(
      "Remove highlight",
    ),
    "Format_Select_To_Highlight": MessageLookupByLibrary.simpleMessage(
      "Select text to highlight",
    ),
    "Format_Text": MessageLookupByLibrary.simpleMessage("Text style"),
    "History_Current": MessageLookupByLibrary.simpleMessage(
      "Already matches this version",
    ),
    "History_Empty": MessageLookupByLibrary.simpleMessage(
      "Saved changes will appear here.",
    ),
    "History_Photos": m14,
    "History_Preview": MessageLookupByLibrary.simpleMessage("Version preview"),
    "History_Recordings": m15,
    "History_Restore": MessageLookupByLibrary.simpleMessage(
      "Restore this version",
    ),
    "History_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not restore this version. Try again.",
    ),
    "History_Restored": MessageLookupByLibrary.simpleMessage(
      "Version restored",
    ),
    "History_Search": MessageLookupByLibrary.simpleMessage(
      "Search note history",
    ),
    "History_Search_Empty": MessageLookupByLibrary.simpleMessage(
      "No matching versions.",
    ),
    "History_Title": MessageLookupByLibrary.simpleMessage("Note history"),
    "History_Unavailable": MessageLookupByLibrary.simpleMessage(
      "This note or version is no longer available.",
    ),
    "History_Version": m16,
    "Image_Drop_Here": MessageLookupByLibrary.simpleMessage("Drop photo here"),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("Image Guru"),
    "Image_Move": MessageLookupByLibrary.simpleMessage("Move photo"),
    "Image_Move_After": MessageLookupByLibrary.simpleMessage("Move later"),
    "Image_Move_Before": MessageLookupByLibrary.simpleMessage("Move earlier"),
    "Image_Remove": MessageLookupByLibrary.simpleMessage("Remove photo"),
    "Image_Resize": MessageLookupByLibrary.simpleMessage("Resize photo"),
    "Include_Archived": MessageLookupByLibrary.simpleMessage(
      "Include archived notes",
    ),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Keyboard_Shortcuts": MessageLookupByLibrary.simpleMessage(
      "Keyboard shortcuts",
    ),
    "Keyboard_Shortcuts_Description": MessageLookupByLibrary.simpleMessage(
      "A quick reference for Onlynote on Mac.",
    ),
    "Keyboard_Shortcuts_Find_Context": MessageLookupByLibrary.simpleMessage(
      "Search the library, or find text in the open note.",
    ),
    "Large": MessageLookupByLibrary.simpleMessage("Large"),
    "Library_Filters": MessageLookupByLibrary.simpleMessage("Library filters"),
    "Link_Empty": MessageLookupByLibrary.simpleMessage(
      "No notes to link yet. Create another note first.",
    ),
    "Link_Hidden_By_Search_Count": m17,
    "Link_Limit": MessageLookupByLibrary.simpleMessage(
      "You can link up to 100 notes. Remove a link to add another.",
    ),
    "Link_Note": MessageLookupByLibrary.simpleMessage("Link a note"),
    "Link_Remove": MessageLookupByLibrary.simpleMessage("Remove link"),
    "Link_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not update this note. Try again.",
    ),
    "Link_Search": MessageLookupByLibrary.simpleMessage("Search notes"),
    "Link_Selected_Count": m18,
    "Link_Unavailable": MessageLookupByLibrary.simpleMessage(
      "Note unavailable",
    ),
    "Linked_From": MessageLookupByLibrary.simpleMessage("Linked from"),
    "Linked_Notes": MessageLookupByLibrary.simpleMessage("Linked notes"),
    "Manage_Folders": MessageLookupByLibrary.simpleMessage("Manage Folders"),
    "Medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "Metronome_Go": MessageLookupByLibrary.simpleMessage("Metronome Go"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("Minesweeper Go"),
    "Mint_Translate": MessageLookupByLibrary.simpleMessage("Mint Translate"),
    "Money_Tracker": MessageLookupByLibrary.simpleMessage("Money Tracker"),
    "More_Apps": MessageLookupByLibrary.simpleMessage("More Apps"),
    "More_Options": MessageLookupByLibrary.simpleMessage("More options"),
    "Move_Down": MessageLookupByLibrary.simpleMessage("Move down"),
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("Move to Folder"),
    "Move_Up": MessageLookupByLibrary.simpleMessage("Move up"),
    "My_Templates": MessageLookupByLibrary.simpleMessage("My templates"),
    "New_Folder": MessageLookupByLibrary.simpleMessage("New Folder"),
    "No_Folder": MessageLookupByLibrary.simpleMessage("No Folder"),
    "No_Folders": MessageLookupByLibrary.simpleMessage(
      "No folders yet. Create one to organize your notes.",
    ),
    "No_Notes_In_Folder": MessageLookupByLibrary.simpleMessage(
      "No notes in this folder yet.\nTap + to add one.",
    ),
    "No_Search_Results": MessageLookupByLibrary.simpleMessage(
      "No notes match your search.",
    ),
    "No_notes_found": MessageLookupByLibrary.simpleMessage(
      "No notes found..\nclick  +  to add new one.",
    ),
    "Note_Added_Successfully": MessageLookupByLibrary.simpleMessage(
      "Note Added Successfully",
    ),
    "Note_Archived": MessageLookupByLibrary.simpleMessage("Note archived"),
    "Note_Color": m19,
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("Note Deleted"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "Note Duplicated Successfully",
    ),
    "Note_FocusWriting": MessageLookupByLibrary.simpleMessage("Focus writing"),
    "Note_Info": MessageLookupByLibrary.simpleMessage("Note info"),
    "Note_Info_Characters": MessageLookupByLibrary.simpleMessage("Characters"),
    "Note_Info_Checklist_Progress": MessageLookupByLibrary.simpleMessage(
      "Checklist progress",
    ),
    "Note_Info_Checklist_Remaining": MessageLookupByLibrary.simpleMessage(
      "Tasks remaining",
    ),
    "Note_Info_Counting_Hint": MessageLookupByLibrary.simpleMessage(
      "Includes title, note text, checklist items, and transcripts. CJK characters count individually.",
    ),
    "Note_Info_Folder": MessageLookupByLibrary.simpleMessage("Folder"),
    "Note_Info_Last_Modified": MessageLookupByLibrary.simpleMessage(
      "Last modified",
    ),
    "Note_Info_Moved_To_Trash": MessageLookupByLibrary.simpleMessage(
      "Moved to Trash",
    ),
    "Note_Info_Photos": MessageLookupByLibrary.simpleMessage("Photos"),
    "Note_Info_Reading_Empty": MessageLookupByLibrary.simpleMessage("0 min"),
    "Note_Info_Reading_Less_Than_Minute": MessageLookupByLibrary.simpleMessage(
      "Less than 1 min",
    ),
    "Note_Info_Reading_Minutes": m20,
    "Note_Info_Reading_Time": MessageLookupByLibrary.simpleMessage(
      "Estimated reading time",
    ),
    "Note_Info_Recording_Duration": MessageLookupByLibrary.simpleMessage(
      "Total recording time",
    ),
    "Note_Info_Recordings": MessageLookupByLibrary.simpleMessage("Recordings"),
    "Note_Info_Scanned_Pages": MessageLookupByLibrary.simpleMessage(
      "Scanned pages",
    ),
    "Note_Info_Words": MessageLookupByLibrary.simpleMessage("Words"),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("Note moved"),
    "Note_Outline": MessageLookupByLibrary.simpleMessage("Outline"),
    "Note_Outline_Current": MessageLookupByLibrary.simpleMessage(
      "Current section",
    ),
    "Note_Outline_Hint": MessageLookupByLibrary.simpleMessage(
      "Tap a heading to jump to it",
    ),
    "Note_Redo": MessageLookupByLibrary.simpleMessage("Redo"),
    "Note_ShowWritingTools": MessageLookupByLibrary.simpleMessage(
      "Show writing tools",
    ),
    "Note_Theme": MessageLookupByLibrary.simpleMessage("Note theme"),
    "Note_Theme_Classic": MessageLookupByLibrary.simpleMessage("Classic"),
    "Note_Theme_Description": MessageLookupByLibrary.simpleMessage(
      "Choose a paper style for your notes.",
    ),
    "Note_Theme_Dotted_Journal": MessageLookupByLibrary.simpleMessage(
      "Dotted journal",
    ),
    "Note_Theme_Grid_Paper": MessageLookupByLibrary.simpleMessage("Grid paper"),
    "Note_Theme_Kraft_Notebook": MessageLookupByLibrary.simpleMessage(
      "Kraft notebook",
    ),
    "Note_Theme_Legal_Pad": MessageLookupByLibrary.simpleMessage("Legal pad"),
    "Note_Theme_Parchment": MessageLookupByLibrary.simpleMessage("Parchment"),
    "Note_Theme_Ruled_Notebook": MessageLookupByLibrary.simpleMessage(
      "Ruled notebook",
    ),
    "Note_Theme_Sticky": MessageLookupByLibrary.simpleMessage("Sticky note"),
    "Note_Unarchived": MessageLookupByLibrary.simpleMessage("Note unarchived"),
    "Note_Undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "Note_Untitled": MessageLookupByLibrary.simpleMessage("Untitled note"),
    "Note_Updated_Successfully": MessageLookupByLibrary.simpleMessage(
      "Note Updated Successfully",
    ),
    "Notes_Deleted_Successfully": MessageLookupByLibrary.simpleMessage(
      "Notes Deleted Successfully",
    ),
    "Notes_Moved_To_Trash": MessageLookupByLibrary.simpleMessage(
      "Moved to Trash",
    ),
    "Notes_Permanently_Deleted": MessageLookupByLibrary.simpleMessage(
      "Notes permanently deleted",
    ),
    "Notes_Restored": MessageLookupByLibrary.simpleMessage("Notes restored"),
    "Novels_Hub": MessageLookupByLibrary.simpleMessage("Novels Hub"),
    "OK": MessageLookupByLibrary.simpleMessage("OK"),
    "Onboarding_Body_1": MessageLookupByLibrary.simpleMessage(
      "Quick notes, checklists, and photos — all in one place.",
    ),
    "Onboarding_Body_2": MessageLookupByLibrary.simpleMessage(
      "Pin important notes, group them into folders, and find anything with search.",
    ),
    "Onboarding_Body_3": MessageLookupByLibrary.simpleMessage(
      "Set reminders and recover deleted notes from Trash anytime.",
    ),
    "Onboarding_Body_4": MessageLookupByLibrary.simpleMessage(
      "Add the Onlynote widget to read your notes and start writing without opening the app.",
    ),
    "Onboarding_Get_Started": MessageLookupByLibrary.simpleMessage(
      "Get Started",
    ),
    "Onboarding_Make_Checklist": MessageLookupByLibrary.simpleMessage(
      "Make a checklist",
    ),
    "Onboarding_Next": MessageLookupByLibrary.simpleMessage("Next"),
    "Onboarding_Skip": MessageLookupByLibrary.simpleMessage("Skip"),
    "Onboarding_Title_1": MessageLookupByLibrary.simpleMessage(
      "Capture anything",
    ),
    "Onboarding_Title_2": MessageLookupByLibrary.simpleMessage(
      "Stay organized",
    ),
    "Onboarding_Title_3": MessageLookupByLibrary.simpleMessage(
      "Never lose a thought",
    ),
    "Onboarding_Title_4": MessageLookupByLibrary.simpleMessage(
      "Notes on your Home Screen",
    ),
    "Onboarding_Write_Note": MessageLookupByLibrary.simpleMessage(
      "Write a note",
    ),
    "Onlynote": MessageLookupByLibrary.simpleMessage("Onlynote"),
    "Open_Folder_In_Library": m21,
    "Open_Linked_Note": MessageLookupByLibrary.simpleMessage(
      "Open linked note",
    ),
    "Permanent_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "These notes will be permanently deleted along with their photos and reminders. This can\'t be undone.",
    ),
    "Permanent_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete forever?",
    ),
    "Photo_Capture_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not add the photo. Try again or choose one from your library.",
    ),
    "Photo_Edit": MessageLookupByLibrary.simpleMessage("Edit photo"),
    "Photo_Edit_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save this photo. Try again.",
    ),
    "Photo_Edit_Hint": MessageLookupByLibrary.simpleMessage(
      "Drag the corners to crop. Rotate if needed.",
    ),
    "Photo_Reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "Photo_Rotate": MessageLookupByLibrary.simpleMessage("Rotate"),
    "Photo_Save": MessageLookupByLibrary.simpleMessage("Save"),
    "Photo_Search_Indexing": MessageLookupByLibrary.simpleMessage(
      "Making photo text searchable…",
    ),
    "Photo_Search_Text_In_Photo": MessageLookupByLibrary.simpleMessage(
      "Text in photo",
    ),
    "Photo_Text_Choose": MessageLookupByLibrary.simpleMessage("Choose a photo"),
    "Photo_Text_Copied": MessageLookupByLibrary.simpleMessage("Text copied"),
    "Photo_Text_Copy": MessageLookupByLibrary.simpleMessage("Copy text"),
    "Photo_Text_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy text. Please try again.",
    ),
    "Photo_Text_Extract": MessageLookupByLibrary.simpleMessage("Extract text"),
    "Photo_Text_Extracting": MessageLookupByLibrary.simpleMessage(
      "Reading photo…",
    ),
    "Photo_Text_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not read text from this photo. Please try again.",
    ),
    "Photo_Text_Field": MessageLookupByLibrary.simpleMessage("Extracted text"),
    "Photo_Text_Insert": MessageLookupByLibrary.simpleMessage("Insert text"),
    "Photo_Text_Insert_Done": MessageLookupByLibrary.simpleMessage(
      "Text added to note",
    ),
    "Photo_Text_No_Text": MessageLookupByLibrary.simpleMessage(
      "No text found. Try a clearer photo with larger text.",
    ),
    "Photo_Text_Photo": m22,
    "Photo_Text_Review": MessageLookupByLibrary.simpleMessage(
      "Text from photo",
    ),
    "Photo_Text_Review_Hint": MessageLookupByLibrary.simpleMessage(
      "Review and edit the text before inserting it into your note.",
    ),
    "Photo_Text_Unsupported": MessageLookupByLibrary.simpleMessage(
      "Text extraction is not available on this device.",
    ),
    "Pin": MessageLookupByLibrary.simpleMessage("Pin"),
    "Plain_Paper": MessageLookupByLibrary.simpleMessage("Plain paper"),
    "Plain_Paper_Description": MessageLookupByLibrary.simpleMessage(
      "A calmer look without texture, ruled lines, or tilted cards.",
    ),
    "Premium": MessageLookupByLibrary.simpleMessage("Premium"),
    "Premium_Active": MessageLookupByLibrary.simpleMessage("Premium unlocked"),
    "Premium_Card_Style": MessageLookupByLibrary.simpleMessage(
      "Individual card styles",
    ),
    "Premium_Description": MessageLookupByLibrary.simpleMessage(
      "All Premium features are unlocked, with no ads.",
    ),
    "Premium_Desktop_Description": MessageLookupByLibrary.simpleMessage(
      "All Premium features are unlocked.",
    ),
    "Premium_Desktop_Existing_Purchase": MessageLookupByLibrary.simpleMessage(
      "Already purchased Premium? Restore your purchase below.",
    ),
    "Premium_Existing_Purchase": MessageLookupByLibrary.simpleMessage(
      "Already removed ads? Your purchase includes Premium. Restore it below.",
    ),
    "Premium_Feature_Required": MessageLookupByLibrary.simpleMessage(
      "Unlock this feature with Premium.",
    ),
    "Premium_Folder_Limit": m23,
    "Premium_Folders": MessageLookupByLibrary.simpleMessage(
      "Unlimited folders",
    ),
    "Premium_Free_Core": MessageLookupByLibrary.simpleMessage(
      "Create up to 10 notes, with checklists and basic reminders for free.",
    ),
    "Premium_Free_Limits": MessageLookupByLibrary.simpleMessage(
      "Free includes 3 folders and 3 saved templates.",
    ),
    "Premium_No_Ads": MessageLookupByLibrary.simpleMessage("No ads"),
    "Premium_Note_Limit": m24,
    "Premium_Note_Themes": MessageLookupByLibrary.simpleMessage(
      "Premium note themes",
    ),
    "Premium_Note_Themes_Description": MessageLookupByLibrary.simpleMessage(
      "Unlock dotted journals, kraft notebooks, and parchment paper.",
    ),
    "Premium_Notes": MessageLookupByLibrary.simpleMessage("Unlimited notes"),
    "Premium_One_Time_Description": MessageLookupByLibrary.simpleMessage(
      "One-time purchase. No subscription.",
    ),
    "Premium_One_Time_Price": m25,
    "Premium_Repeating_Reminders": MessageLookupByLibrary.simpleMessage(
      "Repeating reminders",
    ),
    "Premium_Template_Limit": m26,
    "Premium_Templates": MessageLookupByLibrary.simpleMessage(
      "Unlimited saved templates",
    ),
    "Premium_Voice_Memos": MessageLookupByLibrary.simpleMessage("Voice memos"),
    "Privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
    "Privacy_Policy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "Privacy_Policy_Failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t open the privacy policy. Please try again.",
    ),
    "Privacy_Settings": MessageLookupByLibrary.simpleMessage(
      "Ad Privacy Settings",
    ),
    "Privacy_Settings_Description": MessageLookupByLibrary.simpleMessage(
      "Change or withdraw your choices about personalized ads.",
    ),
    "Purchase_Cancelled": MessageLookupByLibrary.simpleMessage(
      "Purchase cancelled.",
    ),
    "Purchase_Failed": MessageLookupByLibrary.simpleMessage(
      "The purchase could not be completed. Please try again.",
    ),
    "Purchase_Loading": MessageLookupByLibrary.simpleMessage(
      "Contacting the App Store…",
    ),
    "Purchase_Pending": MessageLookupByLibrary.simpleMessage(
      "Your purchase is pending approval.",
    ),
    "Purchase_Success": MessageLookupByLibrary.simpleMessage(
      "Premium is unlocked.",
    ),
    "Purchase_Unavailable": MessageLookupByLibrary.simpleMessage(
      "Remove Ads is currently unavailable.",
    ),
    "Purchases": MessageLookupByLibrary.simpleMessage("Purchases"),
    "Relaxing_Up": MessageLookupByLibrary.simpleMessage("Relaxing Up"),
    "Reminder": MessageLookupByLibrary.simpleMessage("Reminder"),
    "Reminder_Custom": MessageLookupByLibrary.simpleMessage(
      "Choose date & time",
    ),
    "Reminder_Day": MessageLookupByLibrary.simpleMessage("Day"),
    "Reminder_Future_Time": MessageLookupByLibrary.simpleMessage(
      "Choose a time in the future for your reminder.",
    ),
    "Reminder_In_One_Hour": MessageLookupByLibrary.simpleMessage("In 1 hour"),
    "Reminder_Next_Time": m27,
    "Reminder_Next_Week": MessageLookupByLibrary.simpleMessage("In a week"),
    "Reminder_Repeat": MessageLookupByLibrary.simpleMessage("Repeat"),
    "Reminder_Repeat_Daily": MessageLookupByLibrary.simpleMessage("Daily"),
    "Reminder_Repeat_Never": MessageLookupByLibrary.simpleMessage("Never"),
    "Reminder_Repeat_Weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "Reminder_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not update the reminder. Please try again.",
    ),
    "Reminder_Saved": MessageLookupByLibrary.simpleMessage("Reminder set"),
    "Reminder_Set": MessageLookupByLibrary.simpleMessage("Set reminder"),
    "Reminder_Snooze_10_Minutes": MessageLookupByLibrary.simpleMessage(
      "Snooze 10 min",
    ),
    "Reminder_Snooze_1_Hour": MessageLookupByLibrary.simpleMessage(
      "Snooze 1 hour",
    ),
    "Reminder_Suggestion": m28,
    "Reminder_Suggestion_Confirm": MessageLookupByLibrary.simpleMessage(
      "Use suggested time",
    ),
    "Reminder_Suggestion_Dismiss": MessageLookupByLibrary.simpleMessage(
      "Dismiss suggestion",
    ),
    "Reminder_Time": MessageLookupByLibrary.simpleMessage("Time"),
    "Reminder_Tomorrow": MessageLookupByLibrary.simpleMessage(
      "Tomorrow morning",
    ),
    "Reminders_Changed": MessageLookupByLibrary.simpleMessage(
      "This reminder changed. Try again.",
    ),
    "Reminders_Empty_Message": MessageLookupByLibrary.simpleMessage(
      "Add a reminder to a note to see it here.",
    ),
    "Reminders_Empty_Title": MessageLookupByLibrary.simpleMessage(
      "Nothing on your schedule",
    ),
    "Reminders_Entry": MessageLookupByLibrary.simpleMessage("Today"),
    "Reminders_Load_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not load reminders. Try again.",
    ),
    "Reminders_Note_Unavailable": MessageLookupByLibrary.simpleMessage(
      "This note is no longer available.",
    ),
    "Reminders_Overdue": MessageLookupByLibrary.simpleMessage("Overdue"),
    "Reminders_Reschedule": MessageLookupByLibrary.simpleMessage("Reschedule"),
    "Reminders_Search": MessageLookupByLibrary.simpleMessage(
      "Search reminders",
    ),
    "Reminders_Search_Empty_Message": MessageLookupByLibrary.simpleMessage(
      "Try another search or clear it to see all reminders.",
    ),
    "Reminders_Search_Empty_Title": MessageLookupByLibrary.simpleMessage(
      "No matching reminders",
    ),
    "Reminders_Snooze": MessageLookupByLibrary.simpleMessage("Snooze"),
    "Reminders_Snooze_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not snooze this reminder. Try again.",
    ),
    "Reminders_Snoozed": MessageLookupByLibrary.simpleMessage("Snoozed"),
    "Reminders_Title": MessageLookupByLibrary.simpleMessage("Today & Upcoming"),
    "Reminders_Today": MessageLookupByLibrary.simpleMessage("Today"),
    "Reminders_Upcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("Remove Ads"),
    "Remove_Ads_Price": m29,
    "Remove_Library_Criterion": m30,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("Rename Folder"),
    "Rename_Template": MessageLookupByLibrary.simpleMessage("Rename template"),
    "Rename_View": MessageLookupByLibrary.simpleMessage("Rename view"),
    "Reorder": MessageLookupByLibrary.simpleMessage("Reorder"),
    "Reorder_Hint": MessageLookupByLibrary.simpleMessage(
      "Touch and hold a card, then drag it.",
    ),
    "Reorder_Move_Earlier": MessageLookupByLibrary.simpleMessage(
      "Move earlier",
    ),
    "Reorder_Move_Later": MessageLookupByLibrary.simpleMessage("Move later"),
    "Reorder_Pinned_Hint": MessageLookupByLibrary.simpleMessage(
      "Pinned notes stay at the top.",
    ),
    "Reorder_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save this order. Please try again.",
    ),
    "Restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage(
      "No previous Premium purchase was found.",
    ),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage(
      "Restore Purchases",
    ),
    "Restore_Reminder_Warning": MessageLookupByLibrary.simpleMessage(
      "Notes restored. Some reminders could not be scheduled. Open those notes to set their reminders again.",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage(
      "Your Premium purchase was restored.",
    ),
    "Retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "Save_As_Template": MessageLookupByLibrary.simpleMessage(
      "Save as template",
    ),
    "Save_Current_View": MessageLookupByLibrary.simpleMessage(
      "Save current view",
    ),
    "Saved_View_Delete_Confirm": MessageLookupByLibrary.simpleMessage(
      "Delete this saved view?",
    ),
    "Saved_View_Empty": MessageLookupByLibrary.simpleMessage(
      "Save a search or filter to find it quickly next time.",
    ),
    "Saved_View_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save this view. Try again.",
    ),
    "Saved_View_Limit_Reached": m31,
    "Saved_View_Name": MessageLookupByLibrary.simpleMessage("View name"),
    "Saved_View_Search": m32,
    "Saved_View_Tags": m33,
    "Saved_Views": MessageLookupByLibrary.simpleMessage("Saved views"),
    "Saved_Views_Search_Empty": MessageLookupByLibrary.simpleMessage(
      "No matching saved views.",
    ),
    "Saving": MessageLookupByLibrary.simpleMessage("Saving"),
    "Search_Active": MessageLookupByLibrary.simpleMessage("Searching"),
    "Search_Folders": MessageLookupByLibrary.simpleMessage("Search folders"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("Search notes"),
    "Search_Results_Count": m34,
    "Search_Saved_Views": MessageLookupByLibrary.simpleMessage(
      "Search saved views",
    ),
    "Search_Tags": MessageLookupByLibrary.simpleMessage("Search tags"),
    "Search_Templates": MessageLookupByLibrary.simpleMessage(
      "Search templates",
    ),
    "Select": MessageLookupByLibrary.simpleMessage("Select"),
    "Selection_Checklist_Added": m35,
    "Selection_Checklist_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save the checklist items.",
    ),
    "Selection_Checklist_Too_Long": MessageLookupByLibrary.simpleMessage(
      "One line is too long for a checklist item. Select shorter lines.",
    ),
    "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "Settings_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save this setting. Please try again.",
    ),
    "Share": MessageLookupByLibrary.simpleMessage("Share"),
    "Share_Audio": MessageLookupByLibrary.simpleMessage("Recordings"),
    "Share_Audio_Description": MessageLookupByLibrary.simpleMessage(
      "Original audio files and reviewed transcripts",
    ),
    "Share_Audio_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not share this recording. Check that the audio file is available and try again.",
    ),
    "Share_Copy_Text": MessageLookupByLibrary.simpleMessage("Copy text"),
    "Share_Copy_Text_Description": MessageLookupByLibrary.simpleMessage(
      "Copy the title, body, transcripts, checklist, and reminder to the clipboard.",
    ),
    "Share_Image": MessageLookupByLibrary.simpleMessage("Image"),
    "Share_Image_Description": MessageLookupByLibrary.simpleMessage(
      "Share the current paper view as a picture.",
    ),
    "Share_Import_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not import shared content. It is kept for retry when you reopen Onlynote.",
    ),
    "Share_Markdown": MessageLookupByLibrary.simpleMessage("Markdown"),
    "Share_Markdown_Description": MessageLookupByLibrary.simpleMessage(
      "A .md file with checklist formatting and photo attachments.",
    ),
    "Share_No_Text": MessageLookupByLibrary.simpleMessage(
      "This note has no text. Choose an image or PDF to include its photos.",
    ),
    "Share_Note_Failed": MessageLookupByLibrary.simpleMessage(
      "Failed to share note, please try again.",
    ),
    "Share_PDF": MessageLookupByLibrary.simpleMessage("PDF document"),
    "Share_PDF_Description": MessageLookupByLibrary.simpleMessage(
      "Full note and photos, laid out across printable pages.",
    ),
    "Share_Plain_Text": MessageLookupByLibrary.simpleMessage("Plain text"),
    "Share_Preparing": MessageLookupByLibrary.simpleMessage(
      "Preparing your note…",
    ),
    "Share_Text_Copied": MessageLookupByLibrary.simpleMessage(
      "Note text copied.",
    ),
    "Share_Text_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy the note text. Try again.",
    ),
    "Share_Text_Description": MessageLookupByLibrary.simpleMessage(
      "Title, full text, checklist, and reminder. No photos.",
    ),
    "Shows": MessageLookupByLibrary.simpleMessage("Shows"),
    "Simple_Calculator": MessageLookupByLibrary.simpleMessage(
      "Simple Calculator",
    ),
    "Small": MessageLookupByLibrary.simpleMessage("Small"),
    "Sort_By": MessageLookupByLibrary.simpleMessage("Sort by"),
    "Sort_Manual": MessageLookupByLibrary.simpleMessage("Manual order"),
    "Sort_Modified_Newest": MessageLookupByLibrary.simpleMessage(
      "Last modified",
    ),
    "Sort_Modified_Oldest": MessageLookupByLibrary.simpleMessage(
      "Oldest first",
    ),
    "Sort_Switched_To_Manual": MessageLookupByLibrary.simpleMessage(
      "Switched to manual order",
    ),
    "Sort_Title_Asc": MessageLookupByLibrary.simpleMessage("Title A–Z"),
    "Sort_Title_Desc": MessageLookupByLibrary.simpleMessage("Title Z–A"),
    "Starter_Templates": MessageLookupByLibrary.simpleMessage(
      "Starter templates",
    ),
    "Sudoku_Lover": MessageLookupByLibrary.simpleMessage("Sudoku Lover"),
    "Tag_Hint": MessageLookupByLibrary.simpleMessage("Add a tag"),
    "Tag_Invalid": MessageLookupByLibrary.simpleMessage(
      "Use up to 20 tags, with 40 characters per tag.",
    ),
    "Tag_Usage_Count": m36,
    "Tag_Usage_Counts_Hint": MessageLookupByLibrary.simpleMessage(
      "Counts include active and archived notes across all folders. Search and filters do not change them.",
    ),
    "Tag_Usage_Counts_Trash_Hint": MessageLookupByLibrary.simpleMessage(
      "Counts include notes in Trash across all folders. Search and filters do not change them.",
    ),
    "Tags": MessageLookupByLibrary.simpleMessage("Tags"),
    "Tags_Hidden_By_Search_Count": m37,
    "Tags_Search_Empty": MessageLookupByLibrary.simpleMessage(
      "No tags match your search",
    ),
    "Tags_Selected_Count": m38,
    "Tags_Selection_Limit_Reached": m39,
    "Take_Photo": MessageLookupByLibrary.simpleMessage("Take Photo"),
    "Template_Change_Failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t update the template. Please try again.",
    ),
    "Template_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t create a note from the template. Check its photos and try again.",
    ),
    "Template_Daily_Plan_Body": MessageLookupByLibrary.simpleMessage(
      "Today\'s focus\n\nNotes\n",
    ),
    "Template_Daily_Plan_Items": MessageLookupByLibrary.simpleMessage(
      "Choose today\'s priorities\nMake time for a break\nPlan tomorrow",
    ),
    "Template_Daily_Plan_Summary": MessageLookupByLibrary.simpleMessage(
      "Choose a focus and leave room for a few clear priorities.",
    ),
    "Template_Daily_Plan_Title": MessageLookupByLibrary.simpleMessage(
      "Daily plan",
    ),
    "Template_Default_Name": MessageLookupByLibrary.simpleMessage(
      "My template",
    ),
    "Template_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "This removes the saved template. Notes you\'ve created from it stay in your library.",
    ),
    "Template_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete template?",
    ),
    "Template_Details": m40,
    "Template_Load_Failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load your templates. Please try again.",
    ),
    "Template_Manage": MessageLookupByLibrary.simpleMessage("Manage template"),
    "Template_Meeting_Body": MessageLookupByLibrary.simpleMessage(
      "Date:\nAttendees:\n\nAgenda\n\nNotes\n\nDecisions\n",
    ),
    "Template_Meeting_Items": MessageLookupByLibrary.simpleMessage(
      "Send a summary\nFollow up on action items",
    ),
    "Template_Meeting_Summary": MessageLookupByLibrary.simpleMessage(
      "An outline for the agenda, decisions, and follow-up.",
    ),
    "Template_Meeting_Title": MessageLookupByLibrary.simpleMessage(
      "Meeting notes",
    ),
    "Template_Name": MessageLookupByLibrary.simpleMessage("Template name"),
    "Template_Packing_Items": MessageLookupByLibrary.simpleMessage(
      "Travel documents\nPhone & charger\nClothes\nToiletries\nMedication",
    ),
    "Template_Packing_Summary": MessageLookupByLibrary.simpleMessage(
      "Keep travel essentials together before you leave.",
    ),
    "Template_Packing_Title": MessageLookupByLibrary.simpleMessage(
      "Packing list",
    ),
    "Template_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t save the template. Check available storage and photos, then try again.",
    ),
    "Template_Saved": MessageLookupByLibrary.simpleMessage("Template saved"),
    "Template_Shopping_Items": MessageLookupByLibrary.simpleMessage(
      "Fruit & vegetables\nBread & grains\nMilk or dairy alternatives\nHousehold essentials",
    ),
    "Template_Shopping_Summary": MessageLookupByLibrary.simpleMessage(
      "A checklist for groceries and household essentials.",
    ),
    "Template_Shopping_Title": MessageLookupByLibrary.simpleMessage(
      "Shopping list",
    ),
    "Templates": MessageLookupByLibrary.simpleMessage("Templates"),
    "Templates_Create_Hint": MessageLookupByLibrary.simpleMessage(
      "Save any note as a template from its menu.",
    ),
    "Templates_Description": MessageLookupByLibrary.simpleMessage(
      "Start with a useful outline, then make it yours.",
    ),
    "Templates_Search_Empty": MessageLookupByLibrary.simpleMessage(
      "No matching templates.",
    ),
    "Theme_Dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "Theme_Light": MessageLookupByLibrary.simpleMessage("Light"),
    "Theme_System": MessageLookupByLibrary.simpleMessage("System"),
    "Title": MessageLookupByLibrary.simpleMessage("Title"),
    "To_get_notification": MessageLookupByLibrary.simpleMessage(
      "To get a reminder, please go to settings to open notification.",
    ),
    "Today_Note": MessageLookupByLibrary.simpleMessage("Today’s note"),
    "Today_Note_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not open today’s note. Try again.",
    ),
    "Todo": MessageLookupByLibrary.simpleMessage("Checklist item"),
    "Todo_list": MessageLookupByLibrary.simpleMessage("Checklist"),
    "Trash": MessageLookupByLibrary.simpleMessage("Trash"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("Trash is empty"),
    "Type_something": MessageLookupByLibrary.simpleMessage("Type something..."),
    "Unarchive_Note": MessageLookupByLibrary.simpleMessage("Unarchive note"),
    "Undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "Unpin": MessageLookupByLibrary.simpleMessage("Unpin"),
    "Upgrade_To_Premium": MessageLookupByLibrary.simpleMessage(
      "Upgrade to Premium",
    ),
    "Use_Template": MessageLookupByLibrary.simpleMessage("Use a template"),
    "View_Saved": MessageLookupByLibrary.simpleMessage("View saved"),
    "Voice_Cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "Voice_Delete": MessageLookupByLibrary.simpleMessage("Delete recording"),
    "Voice_Discard_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not discard the recording. Please try again.",
    ),
    "Voice_Edit_Transcript": MessageLookupByLibrary.simpleMessage(
      "Edit transcript",
    ),
    "Voice_Interrupted": MessageLookupByLibrary.simpleMessage(
      "Recording stopped when the app was interrupted. Review it before saving.",
    ),
    "Voice_Language_Chinese": MessageLookupByLibrary.simpleMessage(
      "Chinese (Simplified)",
    ),
    "Voice_Language_Chinese_Traditional": MessageLookupByLibrary.simpleMessage(
      "Chinese (Traditional)",
    ),
    "Voice_Language_English": MessageLookupByLibrary.simpleMessage("English"),
    "Voice_Memo": MessageLookupByLibrary.simpleMessage("Voice memo"),
    "Voice_Pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "Voice_Permission_Denied": MessageLookupByLibrary.simpleMessage(
      "Allow microphone access in Settings to record a voice memo.",
    ),
    "Voice_Play": MessageLookupByLibrary.simpleMessage("Play"),
    "Voice_Play_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not play this recording. Please try again.",
    ),
    "Voice_Record": MessageLookupByLibrary.simpleMessage("Record"),
    "Voice_Record_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not record. Please try again.",
    ),
    "Voice_Recording_Hint": MessageLookupByLibrary.simpleMessage(
      "Record up to 5 minutes. Transcription is optional.",
    ),
    "Voice_Review_Transcript": MessageLookupByLibrary.simpleMessage(
      "Review transcript",
    ),
    "Voice_Save": MessageLookupByLibrary.simpleMessage("Save recording"),
    "Voice_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save the recording. Please try again.",
    ),
    "Voice_Stop": MessageLookupByLibrary.simpleMessage("Stop recording"),
    "Voice_Transcribe": MessageLookupByLibrary.simpleMessage("Transcribe"),
    "Voice_Transcribing": MessageLookupByLibrary.simpleMessage("Transcribing…"),
    "Voice_Transcript_Hint": MessageLookupByLibrary.simpleMessage(
      "Review and edit the transcript.",
    ),
    "Voice_Transcription_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not transcribe. Your recording is safe; retry or save without text.",
    ),
    "Voice_Transcription_Language": MessageLookupByLibrary.simpleMessage(
      "Transcription language",
    ),
    "Voice_Transcription_Unavailable": MessageLookupByLibrary.simpleMessage(
      "On-device transcription is unavailable for this language or device. You can still save the recording.",
    ),
    "Water_Tracker": MessageLookupByLibrary.simpleMessage("Water Tracker"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("We Play Piano"),
    "Web_Link_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not open this website.",
    ),
    "Widget": MessageLookupByLibrary.simpleMessage("Home Screen Widget"),
    "Widget_Add_To_Desktop": MessageLookupByLibrary.simpleMessage(
      "Add to Desktop",
    ),
    "Widget_Add_To_Home": MessageLookupByLibrary.simpleMessage(
      "Add to Home Screen",
    ),
    "Widget_Add_Unsupported": MessageLookupByLibrary.simpleMessage(
      "Your launcher can\'t add it automatically — follow the steps below instead.",
    ),
    "Widget_Checklist_Tip": MessageLookupByLibrary.simpleMessage(
      "Tap a checkbox to update your checklist without opening Onlynote.",
    ),
    "Widget_Choose_Note_Android": MessageLookupByLibrary.simpleMessage(
      "When adding a widget, choose All notes or one note or checklist. Use Widget settings to change it later.",
    ),
    "Widget_Choose_Note_Title": MessageLookupByLibrary.simpleMessage(
      "Make a widget yours",
    ),
    "Widget_Choose_Note_iOS": MessageLookupByLibrary.simpleMessage(
      "Touch and hold your widget, choose Edit Widget, then select a note or checklist. Available on iOS 17 or later.",
    ),
    "Widget_Choose_Note_macOS": MessageLookupByLibrary.simpleMessage(
      "Use an overview widget for several notes, or a note widget for one note or checklist. Right-click the note widget, choose Edit Widget, then select a note. Leave Top note selected to show the first note in your library.",
    ),
    "Widget_Description": MessageLookupByLibrary.simpleMessage(
      "See your notes at a glance, without opening the app.",
    ),
    "Widget_Description_macOS": MessageLookupByLibrary.simpleMessage(
      "Keep notes and checklists on your Mac desktop or in Notification Center. Desktop widgets require macOS 14 or later.",
    ),
    "Widget_Discovery_Body": MessageLookupByLibrary.simpleMessage(
      "Add a widget to your Home Screen for a quick glance at your notes.",
    ),
    "Widget_Discovery_Body_macOS": MessageLookupByLibrary.simpleMessage(
      "Add Onlynote widgets to your Mac desktop for a quick glance at your notes.",
    ),
    "Widget_Discovery_Title": MessageLookupByLibrary.simpleMessage(
      "Keep pinned notes in view",
    ),
    "Widget_Step_Android_1": MessageLookupByLibrary.simpleMessage(
      "Touch and hold an empty area of your Home Screen.",
    ),
    "Widget_Step_Android_2": MessageLookupByLibrary.simpleMessage(
      "Tap Widgets.",
    ),
    "Widget_Step_Android_3": MessageLookupByLibrary.simpleMessage(
      "Find “Onlynote” in the list.",
    ),
    "Widget_Step_Android_4": MessageLookupByLibrary.simpleMessage(
      "Drag the widget where you want it.",
    ),
    "Widget_Step_iOS_1": MessageLookupByLibrary.simpleMessage(
      "Touch and hold an empty area of your Home Screen until the icons jiggle.",
    ),
    "Widget_Step_iOS_2": MessageLookupByLibrary.simpleMessage(
      "Tap the + button in the top corner.",
    ),
    "Widget_Step_iOS_3": MessageLookupByLibrary.simpleMessage(
      "Search for “Onlynote”, then select it.",
    ),
    "Widget_Step_iOS_4": MessageLookupByLibrary.simpleMessage(
      "Choose a size and tap Add Widget.",
    ),
    "Widget_Step_macOS_1": MessageLookupByLibrary.simpleMessage(
      "Right-click an empty area of your desktop and choose Edit Widgets.",
    ),
    "Widget_Step_macOS_2": MessageLookupByLibrary.simpleMessage(
      "Search for Onlynote in the widget gallery.",
    ),
    "Widget_Step_macOS_3": MessageLookupByLibrary.simpleMessage(
      "Choose an overview or a note widget, then select a size.",
    ),
    "Widget_Step_macOS_4": MessageLookupByLibrary.simpleMessage(
      "Drag the widget onto your desktop, then click Done.",
    ),
    "Widget_Steps_Title": MessageLookupByLibrary.simpleMessage("How to add it"),
    "Widget_Style_Title": MessageLookupByLibrary.simpleMessage(
      "Paper and color",
    ),
    "Widget_Style_macOS": MessageLookupByLibrary.simpleMessage(
      "Choose paper and color with Card style in Onlynote. To show those colors on the desktop, open System Settings > Desktop & Dock and set Widget style to Full-color. On newer macOS versions, set Dim widgets on desktop to Never.",
    ),
    "Widget_Tip": MessageLookupByLibrary.simpleMessage(
      "Tap a note in the widget to open it, or tap New to start writing.",
    ),
    "Widget_Tip_macOS": MessageLookupByLibrary.simpleMessage(
      "Click a note in the widget to open it, or click New to start writing.",
    ),
    "Widget_macOS_Title": MessageLookupByLibrary.simpleMessage(
      "Desktop widgets",
    ),
    "World_Weather_Live": MessageLookupByLibrary.simpleMessage(
      "World Weather Live",
    ),
    "Yes_Habit": MessageLookupByLibrary.simpleMessage("Yes Habit"),
    "notes": MessageLookupByLibrary.simpleMessage("Notes"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
  };
}
