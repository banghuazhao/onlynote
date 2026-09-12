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

  static String m1(count) => "${count} notes";

  static String m2(price) => "Remove ads permanently for ${price}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("Add Photo"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("Add Note"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("Add Reminder"),
    "Add_todo": MessageLookupByLibrary.simpleMessage("Add todo"),
    "Ads_Removed": MessageLookupByLibrary.simpleMessage("Ads Removed"),
    "Ads_Removed_Description": MessageLookupByLibrary.simpleMessage(
      "Ads are permanently removed on this device.",
    ),
    "All_Notes": MessageLookupByLibrary.simpleMessage("All Notes"),
    "Allow_Notification": MessageLookupByLibrary.simpleMessage(
      "Allow Notification",
    ),
    "Autosave_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not save your changes. Keep this note open and tap Done to retry.",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("Not saved"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("Saved"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("Saving…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("Choose backup file"),
    "Backup_Contents": m0,
    "Backup_Export": MessageLookupByLibrary.simpleMessage("Create backup"),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "Save your notes, checklists, folders, photos, and reminder dates in one Onlynote file. Includes notes in Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not create the backup. Check available storage and that all note photos are accessible. Backups must fit within 256 MB.",
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
    "Backup_Restore": MessageLookupByLibrary.simpleMessage("Restore backup"),
    "Backup_Restore_Description": MessageLookupByLibrary.simpleMessage(
      "Restoring adds copies of the backed-up notes and folders. Your existing notes stay unchanged. Restoring the same file again adds another set of copies.",
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
    "Backup_Schedule_Reminders": MessageLookupByLibrary.simpleMessage(
      "Schedule future reminder notifications",
    ),
    "Backup_Title": MessageLookupByLibrary.simpleMessage("Backup & Restore"),
    "Cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "Card_Size": MessageLookupByLibrary.simpleMessage("Card Size"),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage(
      "Choose From Gallery",
    ),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage(
      "Classical Music Box",
    ),
    "Copy_Suffix": MessageLookupByLibrary.simpleMessage("(Copy)"),
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
    "Delete_Todo_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "This checklist item will be removed. This can\'t be undone.",
    ),
    "Delete_Todo_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete this item?",
    ),
    "Done": MessageLookupByLibrary.simpleMessage("Done"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "Edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "Empty_Trash": MessageLookupByLibrary.simpleMessage("Empty Trash"),
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
    "Folder_Created": MessageLookupByLibrary.simpleMessage("Folder created"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("Folder deleted"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("Folder name"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage(
      "Please enter a folder name.",
    ),
    "Folder_Notes_Count": m1,
    "Folders": MessageLookupByLibrary.simpleMessage("Folders"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage(
      "A little space for your next big idea.",
    ),
    "Font_Size": MessageLookupByLibrary.simpleMessage("Font Size"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("Font Style"),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("Image Guru"),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Large": MessageLookupByLibrary.simpleMessage("Large"),
    "Manage_Folders": MessageLookupByLibrary.simpleMessage("Manage Folders"),
    "Medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "Metronome_Go": MessageLookupByLibrary.simpleMessage("Metronome Go"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("Minesweeper Go"),
    "Mint_Translate": MessageLookupByLibrary.simpleMessage("Mint Translate"),
    "Money_Tracker": MessageLookupByLibrary.simpleMessage("Money Tracker"),
    "More_Apps": MessageLookupByLibrary.simpleMessage("More Apps"),
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("Move to Folder"),
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
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("Note Deleted"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "Note Duplicated Successfully",
    ),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("Note moved"),
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
    "Onlynote": MessageLookupByLibrary.simpleMessage("Onlynote"),
    "Permanent_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "These notes will be permanently deleted along with their photos and reminders. This can\'t be undone.",
    ),
    "Permanent_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete forever?",
    ),
    "Pin": MessageLookupByLibrary.simpleMessage("Pin"),
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
      "Ads have been removed.",
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
    "Reminder_Future_Time": MessageLookupByLibrary.simpleMessage(
      "Choose a time in the future for your reminder.",
    ),
    "Reminder_In_One_Hour": MessageLookupByLibrary.simpleMessage("In 1 hour"),
    "Reminder_Next_Week": MessageLookupByLibrary.simpleMessage("In a week"),
    "Reminder_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not update the reminder. Please try again.",
    ),
    "Reminder_Saved": MessageLookupByLibrary.simpleMessage("Reminder set"),
    "Reminder_Tomorrow": MessageLookupByLibrary.simpleMessage(
      "Tomorrow morning",
    ),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("Remove Ads"),
    "Remove_Ads_Price": m2,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("Rename Folder"),
    "Reorder": MessageLookupByLibrary.simpleMessage("Reorder"),
    "Restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage(
      "No previous Remove Ads purchase was found.",
    ),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage(
      "Restore Purchases",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage(
      "Your Remove Ads purchase was restored.",
    ),
    "Saving": MessageLookupByLibrary.simpleMessage("Saving"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("Search notes"),
    "Select": MessageLookupByLibrary.simpleMessage("Select"),
    "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "Share": MessageLookupByLibrary.simpleMessage("Share"),
    "Share_Note_Failed": MessageLookupByLibrary.simpleMessage(
      "Failed to share note, please try again.",
    ),
    "Shows": MessageLookupByLibrary.simpleMessage("Shows"),
    "Simple_Calculator": MessageLookupByLibrary.simpleMessage(
      "Simple Calculator",
    ),
    "Small": MessageLookupByLibrary.simpleMessage("Small"),
    "Sudoku_Lover": MessageLookupByLibrary.simpleMessage("Sudoku Lover"),
    "Take_Photo": MessageLookupByLibrary.simpleMessage("Take Photo"),
    "Title": MessageLookupByLibrary.simpleMessage("Title"),
    "To_get_notification": MessageLookupByLibrary.simpleMessage(
      "To get a reminder, please go to settings to open notification.",
    ),
    "Todo": MessageLookupByLibrary.simpleMessage("Todo.."),
    "Todo_list": MessageLookupByLibrary.simpleMessage("Todo List"),
    "Trash": MessageLookupByLibrary.simpleMessage("Trash"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("Trash is empty"),
    "Type_something": MessageLookupByLibrary.simpleMessage("Type something..."),
    "Undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "Unpin": MessageLookupByLibrary.simpleMessage("Unpin"),
    "Water_Tracker": MessageLookupByLibrary.simpleMessage("Water Tracker"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("We Play Piano"),
    "Widget": MessageLookupByLibrary.simpleMessage("Home Screen Widget"),
    "Widget_Add_To_Home": MessageLookupByLibrary.simpleMessage(
      "Add to Home Screen",
    ),
    "Widget_Add_Unsupported": MessageLookupByLibrary.simpleMessage(
      "Your launcher can\'t add it automatically — follow the steps below instead.",
    ),
    "Widget_Description": MessageLookupByLibrary.simpleMessage(
      "See your notes at a glance, without opening the app.",
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
    "Widget_Steps_Title": MessageLookupByLibrary.simpleMessage("How to add it"),
    "Widget_Tip": MessageLookupByLibrary.simpleMessage(
      "Tap a note in the widget to open it, or tap New to start writing.",
    ),
    "World_Weather_Live": MessageLookupByLibrary.simpleMessage(
      "World Weather Live",
    ),
    "Yes_Habit": MessageLookupByLibrary.simpleMessage("Yes Habit"),
    "notes": MessageLookupByLibrary.simpleMessage("Notes"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
  };
}
