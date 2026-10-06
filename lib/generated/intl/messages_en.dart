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

  static String m1(count) => "Completed (${count})";

  static String m2(completed, total) => "${completed} of ${total} complete";

  static String m3(count) => "${count} notes";

  static String m4(count) => "${count} photos";

  static String m5(count) => "${count} recordings";

  static String m6(date) => "Saved ${date}";

  static String m7(number) => "Note color ${number}";

  static String m8(number) => "Photo ${number}";

  static String m9(time) => "Next reminder: ${time}";

  static String m10(date) => "Remind me: ${date}";

  static String m11(price) => "Remove ads permanently for ${price}.";

  static String m12(items, photos) =>
      "${Intl.plural(items, zero: '0 items', one: '1 item', other: '${items} items')} · ${Intl.plural(photos, zero: '0 photos', one: '1 photo', other: '${photos} photos')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("Add Photo"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("Add Note"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("Add Reminder"),
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
      "Could not save your changes. Keep this note open and tap Done to retry.",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("Not saved"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("Saved"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("Saving…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("Choose backup file"),
    "Backup_Contents": m0,
    "Backup_Export": MessageLookupByLibrary.simpleMessage("Create backup"),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "Save your notes, tags, saved views, folders, photos, recordings, history, templates, and reminder dates in one Onlynote file. Includes archived notes and Trash. Choose Save to Files or a storage app from the share menu. Maximum file size: 256 MB.",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not create the backup. Check available storage and that all photos and recordings are accessible. Backups must fit within 256 MB.",
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
    "Backup_Schedule_Reminders": MessageLookupByLibrary.simpleMessage(
      "Schedule future reminder notifications",
    ),
    "Backup_Title": MessageLookupByLibrary.simpleMessage("Backup & Restore"),
    "Cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "Card_Size": MessageLookupByLibrary.simpleMessage("Card Size"),
    "Checklist_All_Done": MessageLookupByLibrary.simpleMessage("All done"),
    "Checklist_Completed": m1,
    "Checklist_Item_Completed": MessageLookupByLibrary.simpleMessage(
      "Item completed",
    ),
    "Checklist_Item_Reopened": MessageLookupByLibrary.simpleMessage(
      "Item reopened",
    ),
    "Checklist_Item_Unavailable": MessageLookupByLibrary.simpleMessage(
      "This checklist item is no longer available.",
    ),
    "Checklist_Progress": m2,
    "Checklist_Reset": MessageLookupByLibrary.simpleMessage("Reset checklist"),
    "Checklist_Reset_Done": MessageLookupByLibrary.simpleMessage(
      "Checklist reset",
    ),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage(
      "Choose From Gallery",
    ),
    "Choose_Linked_Notes": MessageLookupByLibrary.simpleMessage(
      "Choose linked notes",
    ),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage(
      "Classical Music Box",
    ),
    "Clear_Filters": MessageLookupByLibrary.simpleMessage("Clear filters"),
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
    "Delete_Template": MessageLookupByLibrary.simpleMessage("Delete template"),
    "Delete_Todo_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "This checklist item will be removed. This can\'t be undone.",
    ),
    "Delete_Todo_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "Delete this item?",
    ),
    "Delete_View": MessageLookupByLibrary.simpleMessage("Delete view"),
    "Done": MessageLookupByLibrary.simpleMessage("Done"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "Edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "Edit_Tags": MessageLookupByLibrary.simpleMessage("Edit tags"),
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
    "Filter_Checklists": MessageLookupByLibrary.simpleMessage("Checklists"),
    "Filter_Photos": MessageLookupByLibrary.simpleMessage("Photos"),
    "Filter_Pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "Filter_Reminders": MessageLookupByLibrary.simpleMessage("Reminders"),
    "Filter_Tags": MessageLookupByLibrary.simpleMessage("Filter by tags"),
    "Filter_Unfinished": MessageLookupByLibrary.simpleMessage("Unfinished"),
    "Folder_Created": MessageLookupByLibrary.simpleMessage("Folder created"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("Folder deleted"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("Folder name"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage(
      "Please enter a folder name.",
    ),
    "Folder_Notes_Count": m3,
    "Folders": MessageLookupByLibrary.simpleMessage("Folders"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage(
      "A little space for your next big idea.",
    ),
    "Font_Size": MessageLookupByLibrary.simpleMessage("Font Size"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("Font Style"),
    "Format_Bold": MessageLookupByLibrary.simpleMessage("Bold"),
    "Format_Bullets": MessageLookupByLibrary.simpleMessage("Bullets"),
    "Format_Heading": MessageLookupByLibrary.simpleMessage("Heading"),
    "Format_Text": MessageLookupByLibrary.simpleMessage("Text style"),
    "History_Current": MessageLookupByLibrary.simpleMessage(
      "Already matches this version",
    ),
    "History_Empty": MessageLookupByLibrary.simpleMessage(
      "Saved changes will appear here.",
    ),
    "History_Photos": m4,
    "History_Preview": MessageLookupByLibrary.simpleMessage("Version preview"),
    "History_Recordings": m5,
    "History_Restore": MessageLookupByLibrary.simpleMessage(
      "Restore this version",
    ),
    "History_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not restore this version. Try again.",
    ),
    "History_Restored": MessageLookupByLibrary.simpleMessage(
      "Version restored",
    ),
    "History_Title": MessageLookupByLibrary.simpleMessage("Note history"),
    "History_Unavailable": MessageLookupByLibrary.simpleMessage(
      "This note or version is no longer available.",
    ),
    "History_Version": m6,
    "Image_Guru": MessageLookupByLibrary.simpleMessage("Image Guru"),
    "Include_Archived": MessageLookupByLibrary.simpleMessage(
      "Include archived notes",
    ),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Large": MessageLookupByLibrary.simpleMessage("Large"),
    "Library_Filters": MessageLookupByLibrary.simpleMessage("Library filters"),
    "Link_Empty": MessageLookupByLibrary.simpleMessage(
      "No notes to link yet. Create another note first.",
    ),
    "Link_Limit": MessageLookupByLibrary.simpleMessage(
      "You can link up to 100 notes. Remove a link to add another.",
    ),
    "Link_Note": MessageLookupByLibrary.simpleMessage("Link a note"),
    "Link_Remove": MessageLookupByLibrary.simpleMessage("Remove link"),
    "Link_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not update this note. Try again.",
    ),
    "Link_Search": MessageLookupByLibrary.simpleMessage("Search notes"),
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
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("Move to Folder"),
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
    "Note_Color": m7,
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("Note Deleted"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "Note Duplicated Successfully",
    ),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("Note moved"),
    "Note_Unarchived": MessageLookupByLibrary.simpleMessage("Note unarchived"),
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
    "Photo_Text_Photo": m8,
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
    "Reminder_Day": MessageLookupByLibrary.simpleMessage("Day"),
    "Reminder_Future_Time": MessageLookupByLibrary.simpleMessage(
      "Choose a time in the future for your reminder.",
    ),
    "Reminder_In_One_Hour": MessageLookupByLibrary.simpleMessage("In 1 hour"),
    "Reminder_Next_Time": m9,
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
    "Reminder_Suggestion": m10,
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
    "Reminders_Snooze": MessageLookupByLibrary.simpleMessage("Snooze"),
    "Reminders_Snooze_Failed": MessageLookupByLibrary.simpleMessage(
      "Could not snooze this reminder. Try again.",
    ),
    "Reminders_Snoozed": MessageLookupByLibrary.simpleMessage("Snoozed"),
    "Reminders_Title": MessageLookupByLibrary.simpleMessage("Today & Upcoming"),
    "Reminders_Today": MessageLookupByLibrary.simpleMessage("Today"),
    "Reminders_Upcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("Remove Ads"),
    "Remove_Ads_Price": m11,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("Rename Folder"),
    "Rename_Template": MessageLookupByLibrary.simpleMessage("Rename template"),
    "Rename_View": MessageLookupByLibrary.simpleMessage("Rename view"),
    "Reorder": MessageLookupByLibrary.simpleMessage("Reorder"),
    "Restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage(
      "No previous Remove Ads purchase was found.",
    ),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage(
      "Restore Purchases",
    ),
    "Restore_Reminder_Warning": MessageLookupByLibrary.simpleMessage(
      "Notes restored. Some reminders could not be scheduled. Open those notes to set their reminders again.",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage(
      "Your Remove Ads purchase was restored.",
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
    "Saved_View_Name": MessageLookupByLibrary.simpleMessage("View name"),
    "Saved_Views": MessageLookupByLibrary.simpleMessage("Saved views"),
    "Saving": MessageLookupByLibrary.simpleMessage("Saving"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("Search notes"),
    "Select": MessageLookupByLibrary.simpleMessage("Select"),
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
    "Share_Text_Description": MessageLookupByLibrary.simpleMessage(
      "Title, full text, checklist, and reminder. No photos.",
    ),
    "Shows": MessageLookupByLibrary.simpleMessage("Shows"),
    "Simple_Calculator": MessageLookupByLibrary.simpleMessage(
      "Simple Calculator",
    ),
    "Small": MessageLookupByLibrary.simpleMessage("Small"),
    "Starter_Templates": MessageLookupByLibrary.simpleMessage(
      "Starter templates",
    ),
    "Sudoku_Lover": MessageLookupByLibrary.simpleMessage("Sudoku Lover"),
    "Tag_Hint": MessageLookupByLibrary.simpleMessage("Add a tag"),
    "Tag_Invalid": MessageLookupByLibrary.simpleMessage(
      "Use up to 20 tags, with 40 characters per tag.",
    ),
    "Tags": MessageLookupByLibrary.simpleMessage("Tags"),
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
    "Template_Details": m12,
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
    "Theme_Dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "Theme_Light": MessageLookupByLibrary.simpleMessage("Light"),
    "Theme_System": MessageLookupByLibrary.simpleMessage("System"),
    "Title": MessageLookupByLibrary.simpleMessage("Title"),
    "To_get_notification": MessageLookupByLibrary.simpleMessage(
      "To get a reminder, please go to settings to open notification.",
    ),
    "Todo": MessageLookupByLibrary.simpleMessage("Checklist item"),
    "Todo_list": MessageLookupByLibrary.simpleMessage("Checklist"),
    "Trash": MessageLookupByLibrary.simpleMessage("Trash"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("Trash is empty"),
    "Type_something": MessageLookupByLibrary.simpleMessage("Type something..."),
    "Unarchive_Note": MessageLookupByLibrary.simpleMessage("Unarchive note"),
    "Undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "Unpin": MessageLookupByLibrary.simpleMessage("Unpin"),
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
    "Widget": MessageLookupByLibrary.simpleMessage("Home Screen Widget"),
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
    "Widget_Description": MessageLookupByLibrary.simpleMessage(
      "See your notes at a glance, without opening the app.",
    ),
    "Widget_Discovery_Body": MessageLookupByLibrary.simpleMessage(
      "Add a widget to your Home Screen for a quick glance at your notes.",
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
