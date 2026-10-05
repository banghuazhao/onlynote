// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_HK locale. All the
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
  String get localeName => 'zh_HK';

  static String m0(notes, folders, photos) =>
      "${notes} 則筆記 · ${folders} 個資料夾 · ${photos} 張照片";

  static String m1(count) => "${count} 則備忘錄";

  static String m2(number) => "筆記顏色 ${number}";

  static String m3(time) => "下次提醒：${time}";

  static String m4(price) => "支付 ${price} 永久移除廣告。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("加入照片"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("新增備忘錄"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("添加日程提醒"),
    "Add_todo": MessageLookupByLibrary.simpleMessage("添加待辦"),
    "Ads_Removed": MessageLookupByLibrary.simpleMessage("廣告已移除"),
    "Ads_Removed_Description": MessageLookupByLibrary.simpleMessage(
      "此裝置上的廣告已永久移除。",
    ),
    "All_Notes": MessageLookupByLibrary.simpleMessage("全部備忘錄"),
    "Allow_Notification": MessageLookupByLibrary.simpleMessage("允許推送"),
    "Appearance": MessageLookupByLibrary.simpleMessage("外觀"),
    "Autosave_Failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存變更。請保持筆記開啟，點按「完成」重試。",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("尚未儲存"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("已儲存"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("正在儲存…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("選擇備份檔案"),
    "Backup_Contents": m0,
    "Backup_Export": MessageLookupByLibrary.simpleMessage("建立備份"),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "將筆記、清單、資料夾、照片及提醒日期儲存至一個 Onlynote 檔案，包含垃圾桶中的筆記。在分享選單中選擇儲存至檔案或儲存空間應用程式。檔案大小上限：256 MB。",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "無法建立備份。請檢查可用儲存空間，並確認所有筆記照片均可存取。備份不能超過 256 MB。",
    ),
    "Backup_Invalid": MessageLookupByLibrary.simpleMessage(
      "這不是支援的 Onlynote 備份，或檔案已損毀或超過 256 MB。未匯入任何內容。",
    ),
    "Backup_Preparing": MessageLookupByLibrary.simpleMessage("正在準備備份…"),
    "Backup_Reading": MessageLookupByLibrary.simpleMessage("正在檢查備份檔案…"),
    "Backup_Restore": MessageLookupByLibrary.simpleMessage("還原備份"),
    "Backup_Restore_Description": MessageLookupByLibrary.simpleMessage(
      "還原會加入備份中筆記與資料夾的副本，不會更改現有筆記。再次還原同一檔案會加入另一組副本。",
    ),
    "Backup_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "無法還原備份。請檢查可用儲存空間後重試。現有筆記未被覆寫。",
    ),
    "Backup_Restored": MessageLookupByLibrary.simpleMessage("備份已還原。筆記已加入筆記庫。"),
    "Backup_Restored_No_Notifications": MessageLookupByLibrary.simpleMessage(
      "筆記已還原。部分提醒通知未能排程；請開啟相應筆記重新設定。",
    ),
    "Backup_Restoring": MessageLookupByLibrary.simpleMessage("正在還原筆記與照片…"),
    "Backup_Schedule_Reminders": MessageLookupByLibrary.simpleMessage(
      "排程未來的提醒通知",
    ),
    "Backup_Title": MessageLookupByLibrary.simpleMessage("備份與還原"),
    "Cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "Card_Size": MessageLookupByLibrary.simpleMessage("卡片大小"),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage("從相冊選擇"),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage("古典音樂盒"),
    "Clear_Filters": MessageLookupByLibrary.simpleMessage("清除篩選"),
    "Copy_Suffix": MessageLookupByLibrary.simpleMessage("(副本)"),
    "Delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "Delete_Folder": MessageLookupByLibrary.simpleMessage("刪除資料夾"),
    "Delete_Folder_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "資料夾中的備忘錄會保留在全部備忘錄中，僅刪除資料夾。",
    ),
    "Delete_Forever": MessageLookupByLibrary.simpleMessage("永久刪除"),
    "Delete_Note_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "此備忘錄將移至回收站，之後可以還原。",
    ),
    "Delete_Note_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "刪除此備忘錄？",
    ),
    "Delete_Todo_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "此待辦事項將被刪除，且無法恢復。",
    ),
    "Delete_Todo_Confirm_Title": MessageLookupByLibrary.simpleMessage("刪除此項？"),
    "Done": MessageLookupByLibrary.simpleMessage("完成"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("複製"),
    "Edit": MessageLookupByLibrary.simpleMessage("編輯"),
    "Empty_Trash": MessageLookupByLibrary.simpleMessage("清空回收站"),
    "Express_Scan": MessageLookupByLibrary.simpleMessage("飛速掃描"),
    "Failed_to_Update_note_please_try_again":
        MessageLookupByLibrary.simpleMessage("更新備忘錄失敗, 請重試"),
    "Failed_to_add_note_Title_should_not_empty":
        MessageLookupByLibrary.simpleMessage("備忘錄內容不能為空，請添加標題、內容、待辦事項或照片"),
    "Failed_to_add_note_please_try_again": MessageLookupByLibrary.simpleMessage(
      "添加備忘錄失敗, 請重試",
    ),
    "Failed_to_delete_folder": MessageLookupByLibrary.simpleMessage(
      "刪除資料夾失敗，請重試。",
    ),
    "Failed_to_delete_note_please_try_again":
        MessageLookupByLibrary.simpleMessage("刪除備忘錄失敗, 請重試"),
    "Failed_to_delete_notes": MessageLookupByLibrary.simpleMessage("刪除備忘錄失敗"),
    "Failed_to_load_note_please_try_again":
        MessageLookupByLibrary.simpleMessage("加載備忘錄失敗, 請重試"),
    "Failed_to_load_notes_please_try_again":
        MessageLookupByLibrary.simpleMessage("加載備忘錄失敗, 請重試"),
    "Failed_to_restore_notes": MessageLookupByLibrary.simpleMessage(
      "還原備忘錄失敗，請重試。",
    ),
    "Failed_to_save_folder": MessageLookupByLibrary.simpleMessage(
      "儲存資料夾失敗，請重試。",
    ),
    "Failed_to_update_note_Title_should_not_empty":
        MessageLookupByLibrary.simpleMessage("備忘錄內容不能為空，請添加標題、內容、待辦事項或照片"),
    "Filter_Checklists": MessageLookupByLibrary.simpleMessage("清單"),
    "Filter_Photos": MessageLookupByLibrary.simpleMessage("相片"),
    "Filter_Pinned": MessageLookupByLibrary.simpleMessage("置頂"),
    "Filter_Reminders": MessageLookupByLibrary.simpleMessage("提醒"),
    "Folder_Created": MessageLookupByLibrary.simpleMessage("已建立資料夾"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("已刪除資料夾"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("資料夾名稱"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage("請輸入資料夾名稱。"),
    "Folder_Notes_Count": m1,
    "Folders": MessageLookupByLibrary.simpleMessage("資料夾"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage("留一點空間，記錄下一個好想法。"),
    "Font_Size": MessageLookupByLibrary.simpleMessage("字體大小"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("字體樣式"),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("咕嚕濾鏡"),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Large": MessageLookupByLibrary.simpleMessage("大"),
    "Manage_Folders": MessageLookupByLibrary.simpleMessage("管理資料夾"),
    "Medium": MessageLookupByLibrary.simpleMessage("中"),
    "Metronome_Go": MessageLookupByLibrary.simpleMessage("打拍節拍器"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("經典掃雷"),
    "Mint_Translate": MessageLookupByLibrary.simpleMessage("薄荷翻譯"),
    "Money_Tracker": MessageLookupByLibrary.simpleMessage("極簡記賬"),
    "More_Apps": MessageLookupByLibrary.simpleMessage("更多App"),
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("移至資料夾"),
    "New_Folder": MessageLookupByLibrary.simpleMessage("新增資料夾"),
    "No_Folder": MessageLookupByLibrary.simpleMessage("無資料夾"),
    "No_Folders": MessageLookupByLibrary.simpleMessage("暫無資料夾。建立資料夾來整理備忘錄。"),
    "No_Notes_In_Folder": MessageLookupByLibrary.simpleMessage(
      "此資料夾暫無備忘錄。\n點擊 + 新增。",
    ),
    "No_Search_Results": MessageLookupByLibrary.simpleMessage("沒有符合的備忘錄。"),
    "No_notes_found": MessageLookupByLibrary.simpleMessage(
      "目前沒有備忘錄..\n點擊  +  添加",
    ),
    "Note_Added_Successfully": MessageLookupByLibrary.simpleMessage("已成功添加備忘錄"),
    "Note_Color": m2,
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("已刪除備忘錄"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功複製備忘錄",
    ),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("已移動備忘錄"),
    "Note_Updated_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功更新備忘錄",
    ),
    "Notes_Deleted_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功刪除備忘錄",
    ),
    "Notes_Moved_To_Trash": MessageLookupByLibrary.simpleMessage("已移至回收站"),
    "Notes_Permanently_Deleted": MessageLookupByLibrary.simpleMessage("已永久刪除"),
    "Notes_Restored": MessageLookupByLibrary.simpleMessage("已還原備忘錄"),
    "Novels_Hub": MessageLookupByLibrary.simpleMessage("英文小說站"),
    "OK": MessageLookupByLibrary.simpleMessage("好的"),
    "Onboarding_Body_1": MessageLookupByLibrary.simpleMessage(
      "快速備忘、待辦清單和照片，一處搞定。",
    ),
    "Onboarding_Body_2": MessageLookupByLibrary.simpleMessage(
      "置頂重要內容，用資料夾分組，搜尋瞬間找到。",
    ),
    "Onboarding_Body_3": MessageLookupByLibrary.simpleMessage(
      "設定提醒，刪除的備忘錄可從回收站還原。",
    ),
    "Onboarding_Body_4": MessageLookupByLibrary.simpleMessage(
      "加入極簡備忘錄小工具，不用開啟 App 也能查看備忘錄、隨手記錄。",
    ),
    "Onboarding_Get_Started": MessageLookupByLibrary.simpleMessage("開始使用"),
    "Onboarding_Make_Checklist": MessageLookupByLibrary.simpleMessage("建立待辦清單"),
    "Onboarding_Next": MessageLookupByLibrary.simpleMessage("下一步"),
    "Onboarding_Skip": MessageLookupByLibrary.simpleMessage("略過"),
    "Onboarding_Title_1": MessageLookupByLibrary.simpleMessage("隨時記錄"),
    "Onboarding_Title_2": MessageLookupByLibrary.simpleMessage("輕鬆整理"),
    "Onboarding_Title_3": MessageLookupByLibrary.simpleMessage("不再遺忘"),
    "Onboarding_Title_4": MessageLookupByLibrary.simpleMessage("備忘錄放上主畫面"),
    "Onboarding_Write_Note": MessageLookupByLibrary.simpleMessage("寫備忘錄"),
    "Onlynote": MessageLookupByLibrary.simpleMessage("極簡備忘錄"),
    "Permanent_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "這些備忘錄及其照片、提醒將被永久刪除，且無法復原。",
    ),
    "Permanent_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "永久刪除？",
    ),
    "Pin": MessageLookupByLibrary.simpleMessage("置頂"),
    "Plain_Paper": MessageLookupByLibrary.simpleMessage("純色紙張"),
    "Plain_Paper_Description": MessageLookupByLibrary.simpleMessage(
      "移除紋理、橫線和卡片傾斜，讓介面更簡潔。",
    ),
    "Privacy": MessageLookupByLibrary.simpleMessage("私隱"),
    "Privacy_Policy": MessageLookupByLibrary.simpleMessage("私隱政策"),
    "Privacy_Policy_Failed": MessageLookupByLibrary.simpleMessage(
      "無法開啟私隱政策，請再試一次。",
    ),
    "Privacy_Settings": MessageLookupByLibrary.simpleMessage("廣告私隱設定"),
    "Privacy_Settings_Description": MessageLookupByLibrary.simpleMessage(
      "更改或撤回你對個人化廣告的選擇。",
    ),
    "Purchase_Cancelled": MessageLookupByLibrary.simpleMessage("購買已取消。"),
    "Purchase_Failed": MessageLookupByLibrary.simpleMessage("無法完成購買，請重試。"),
    "Purchase_Loading": MessageLookupByLibrary.simpleMessage("正在連接 App Store…"),
    "Purchase_Pending": MessageLookupByLibrary.simpleMessage("購買正在等待批准。"),
    "Purchase_Success": MessageLookupByLibrary.simpleMessage("廣告已移除。"),
    "Purchase_Unavailable": MessageLookupByLibrary.simpleMessage("移除廣告目前無法使用。"),
    "Purchases": MessageLookupByLibrary.simpleMessage("購買項目"),
    "Relaxing_Up": MessageLookupByLibrary.simpleMessage("冥想Up"),
    "Reminder": MessageLookupByLibrary.simpleMessage("提醒設置"),
    "Reminder_Custom": MessageLookupByLibrary.simpleMessage("選擇日期與時間"),
    "Reminder_Day": MessageLookupByLibrary.simpleMessage("星期"),
    "Reminder_Future_Time": MessageLookupByLibrary.simpleMessage(
      "請選擇將來的時間來設定提醒。",
    ),
    "Reminder_In_One_Hour": MessageLookupByLibrary.simpleMessage("1 小時後"),
    "Reminder_Next_Time": m3,
    "Reminder_Next_Week": MessageLookupByLibrary.simpleMessage("一星期後"),
    "Reminder_Repeat": MessageLookupByLibrary.simpleMessage("重複"),
    "Reminder_Repeat_Daily": MessageLookupByLibrary.simpleMessage("每天"),
    "Reminder_Repeat_Never": MessageLookupByLibrary.simpleMessage("不重複"),
    "Reminder_Repeat_Weekly": MessageLookupByLibrary.simpleMessage("每週"),
    "Reminder_Save_Failed": MessageLookupByLibrary.simpleMessage("無法更新提醒，請重試。"),
    "Reminder_Saved": MessageLookupByLibrary.simpleMessage("提醒已設定"),
    "Reminder_Set": MessageLookupByLibrary.simpleMessage("設定提醒"),
    "Reminder_Time": MessageLookupByLibrary.simpleMessage("時間"),
    "Reminder_Tomorrow": MessageLookupByLibrary.simpleMessage("明天早上"),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("移除廣告"),
    "Remove_Ads_Price": m4,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("重新命名資料夾"),
    "Reorder": MessageLookupByLibrary.simpleMessage("排序"),
    "Restore": MessageLookupByLibrary.simpleMessage("還原"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage("未找到以前的移除廣告購買。"),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage("恢復購買"),
    "Restore_Reminder_Warning": MessageLookupByLibrary.simpleMessage(
      "筆記已復原，但部分提醒未能安排。請開啟相關筆記重新設定提醒。",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage("已恢復您的移除廣告購買。"),
    "Saving": MessageLookupByLibrary.simpleMessage("保存中"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("搜尋備忘錄"),
    "Select": MessageLookupByLibrary.simpleMessage("選擇"),
    "Settings": MessageLookupByLibrary.simpleMessage("設置"),
    "Settings_Save_Failed": MessageLookupByLibrary.simpleMessage("無法儲存設定，請重試。"),
    "Share": MessageLookupByLibrary.simpleMessage("分享"),
    "Share_Image": MessageLookupByLibrary.simpleMessage("圖片"),
    "Share_Image_Description": MessageLookupByLibrary.simpleMessage(
      "將目前紙張畫面分享為圖片。",
    ),
    "Share_Markdown": MessageLookupByLibrary.simpleMessage("Markdown"),
    "Share_Markdown_Description": MessageLookupByLibrary.simpleMessage(
      "包含清單格式和相片附件的 .md 檔案。",
    ),
    "Share_No_Text": MessageLookupByLibrary.simpleMessage(
      "此筆記沒有文字，請選擇圖片或 PDF 來分享相片。",
    ),
    "Share_Note_Failed": MessageLookupByLibrary.simpleMessage("分享備忘錄失敗, 請重試"),
    "Share_PDF": MessageLookupByLibrary.simpleMessage("PDF 文件"),
    "Share_PDF_Description": MessageLookupByLibrary.simpleMessage(
      "包含完整筆記和相片，自動分頁，方便列印。",
    ),
    "Share_Plain_Text": MessageLookupByLibrary.simpleMessage("純文字"),
    "Share_Preparing": MessageLookupByLibrary.simpleMessage("正在準備筆記…"),
    "Share_Text_Description": MessageLookupByLibrary.simpleMessage(
      "標題、全文、清單和提醒，不包含相片。",
    ),
    "Shows": MessageLookupByLibrary.simpleMessage("Shows"),
    "Simple_Calculator": MessageLookupByLibrary.simpleMessage("極簡計算器"),
    "Small": MessageLookupByLibrary.simpleMessage("小"),
    "Sudoku_Lover": MessageLookupByLibrary.simpleMessage("數獨迷"),
    "Take_Photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "Theme_Dark": MessageLookupByLibrary.simpleMessage("深色"),
    "Theme_Light": MessageLookupByLibrary.simpleMessage("淺色"),
    "Theme_System": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "Title": MessageLookupByLibrary.simpleMessage("標題"),
    "To_get_notification": MessageLookupByLibrary.simpleMessage(
      "想要設置日程安排提醒，請前往設置打開通知",
    ),
    "Todo": MessageLookupByLibrary.simpleMessage("待辦.."),
    "Todo_list": MessageLookupByLibrary.simpleMessage("待辦清單"),
    "Trash": MessageLookupByLibrary.simpleMessage("回收站"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("回收站為空"),
    "Type_something": MessageLookupByLibrary.simpleMessage("寫點兒什麼..."),
    "Undo": MessageLookupByLibrary.simpleMessage("復原"),
    "Unpin": MessageLookupByLibrary.simpleMessage("取消置頂"),
    "Water_Tracker": MessageLookupByLibrary.simpleMessage("喝水吧"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("彈鋼琴"),
    "Widget": MessageLookupByLibrary.simpleMessage("主畫面小工具"),
    "Widget_Add_To_Home": MessageLookupByLibrary.simpleMessage("加入主畫面"),
    "Widget_Add_Unsupported": MessageLookupByLibrary.simpleMessage(
      "目前的桌面不支援自動加入，請依照下面的步驟操作。",
    ),
    "Widget_Description": MessageLookupByLibrary.simpleMessage(
      "不用開啟 App，一眼看到你的備忘錄。",
    ),
    "Widget_Discovery_Body": MessageLookupByLibrary.simpleMessage(
      "加入主畫面小工具，一眼查看你的備忘錄。",
    ),
    "Widget_Discovery_Title": MessageLookupByLibrary.simpleMessage(
      "讓置頂備忘錄隨時可見",
    ),
    "Widget_Step_Android_1": MessageLookupByLibrary.simpleMessage("長按主畫面空白處。"),
    "Widget_Step_Android_2": MessageLookupByLibrary.simpleMessage("點按「小工具」。"),
    "Widget_Step_Android_3": MessageLookupByLibrary.simpleMessage(
      "在清單中找到「極簡備忘錄」。",
    ),
    "Widget_Step_Android_4": MessageLookupByLibrary.simpleMessage(
      "把小工具拖到想要的位置。",
    ),
    "Widget_Step_iOS_1": MessageLookupByLibrary.simpleMessage(
      "長按主畫面空白處，直到圖示開始晃動。",
    ),
    "Widget_Step_iOS_2": MessageLookupByLibrary.simpleMessage("點按左上角的 + 按鈕。"),
    "Widget_Step_iOS_3": MessageLookupByLibrary.simpleMessage(
      "搜尋「極簡備忘錄」，然後選擇它。",
    ),
    "Widget_Step_iOS_4": MessageLookupByLibrary.simpleMessage(
      "選擇尺寸，然後點按「加入小工具」。",
    ),
    "Widget_Steps_Title": MessageLookupByLibrary.simpleMessage("加入方法"),
    "Widget_Tip": MessageLookupByLibrary.simpleMessage(
      "點按小工具裡的備忘錄即可開啟；點按「新增」直接開始記錄。",
    ),
    "World_Weather_Live": MessageLookupByLibrary.simpleMessage("極簡天氣"),
    "Yes_Habit": MessageLookupByLibrary.simpleMessage("簽簽習慣"),
    "notes": MessageLookupByLibrary.simpleMessage("備忘錄"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
  };
}
