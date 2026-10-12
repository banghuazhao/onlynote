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

  static String m1(count) => "${count} 篇關聯筆記";

  static String m2(count) => "${count} 頁掃描文件";

  static String m3(count) => "已完成（${count}）";

  static String m4(completed, total) => "已完成 ${completed} / ${total} 項";

  static String m5(heading) => "收起${heading}";

  static String m6(heading) => "展開${heading}";

  static String m7(count) => "已取代 ${count} 處";

  static String m8(count) => "${count} 則備忘錄";

  static String m9(count) => "${count} 張照片";

  static String m10(count) => "${count} 段錄音";

  static String m11(date) => "儲存於 ${date}";

  static String m12(number) => "筆記顏色 ${number}";

  static String m13(minutes) => "${minutes} 分鐘";

  static String m14(number) => "照片 ${number}";

  static String m15(limit) => "免費版包含 ${limit} 個資料夾。升級即可建立無限資料夾。";

  static String m16(limit) => "免費版包含 ${limit} 則筆記。升級即可建立無限筆記。";

  static String m17(price) => "支付 ${price} 永久解鎖";

  static String m18(limit) => "免費版包含 ${limit} 個自訂範本。升級即可儲存無限範本。";

  static String m19(time) => "下次提醒：${time}";

  static String m20(date) => "提醒我：${date}";

  static String m21(price) => "支付 ${price} 永久移除廣告。";

  static String m22(count) => "${count} 則筆記";

  static String m23(count) => "已加入 ${count} 項清單";

  static String m24(items, photos) => "${items} 項 · ${photos} 張照片";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("加入照片"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("新增備忘錄"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("添加日程提醒"),
    "Add_Selection_To_Checklist": MessageLookupByLibrary.simpleMessage("加入清單"),
    "Add_todo": MessageLookupByLibrary.simpleMessage("新增項目"),
    "Ads_Removed": MessageLookupByLibrary.simpleMessage("廣告已移除"),
    "Ads_Removed_Description": MessageLookupByLibrary.simpleMessage(
      "此裝置上的廣告已永久移除。",
    ),
    "All_Notes": MessageLookupByLibrary.simpleMessage("全部備忘錄"),
    "Allow_Notification": MessageLookupByLibrary.simpleMessage("允許推送"),
    "Appearance": MessageLookupByLibrary.simpleMessage("外觀"),
    "Archive": MessageLookupByLibrary.simpleMessage("封存"),
    "Archive_Empty": MessageLookupByLibrary.simpleMessage("封存的筆記會顯示在這裡。"),
    "Archive_Note": MessageLookupByLibrary.simpleMessage("封存筆記"),
    "Autosave_Failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存變更。請保持筆記開啟，點按「尚未儲存」重試。",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("尚未儲存"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("已儲存"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("正在儲存…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("選擇備份檔案"),
    "Backup_Contents": m0,
    "Backup_Export": MessageLookupByLibrary.simpleMessage("建立備份"),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "將筆記、標籤、已儲存檢視、資料夾、照片、錄音、歷史記錄、範本和提醒日期儲存在一個Onlynote檔案中。包含封存筆記和垃圾桶。可從分享選單儲存至檔案或儲存空間App。檔案最大256 MB。",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "無法建立備份。請檢查可用儲存空間，並確認所有照片和錄音可用。備份必須小於256 MB。",
    ),
    "Backup_Invalid": MessageLookupByLibrary.simpleMessage(
      "這不是支援的 Onlynote 備份，或檔案已損毀或超過 256 MB。未匯入任何內容。",
    ),
    "Backup_Preparing": MessageLookupByLibrary.simpleMessage("正在準備備份…"),
    "Backup_Reading": MessageLookupByLibrary.simpleMessage("正在檢查備份檔案…"),
    "Backup_Restore": MessageLookupByLibrary.simpleMessage("還原備份"),
    "Backup_Restore_Description": MessageLookupByLibrary.simpleMessage(
      "回復會將備份筆記、資料夾、範本和已儲存檢視的副本新增至筆記庫。連結筆記會連接回復後的副本。再次回復同一檔案會新增另一組副本。",
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
    "Cancel_Searching": MessageLookupByLibrary.simpleMessage("取消搜尋"),
    "Card_Linked_Notes_Count": m1,
    "Card_Scanned_Pages_Count": m2,
    "Card_Size": MessageLookupByLibrary.simpleMessage("卡片大小"),
    "Card_Style": MessageLookupByLibrary.simpleMessage("卡片樣式"),
    "Card_Style_Color": MessageLookupByLibrary.simpleMessage("顏色"),
    "Card_Style_Default_Color": MessageLookupByLibrary.simpleMessage("預設紙張顏色"),
    "Card_Style_Default_Hint": MessageLookupByLibrary.simpleMessage(
      "未自訂樣式的筆記會使用這些預設設定。",
    ),
    "Card_Style_Discard": MessageLookupByLibrary.simpleMessage("捨棄"),
    "Card_Style_Discard_Message": MessageLookupByLibrary.simpleMessage(
      "你的卡片樣式更改尚未儲存。",
    ),
    "Card_Style_Discard_Title": MessageLookupByLibrary.simpleMessage("捨棄樣式更改？"),
    "Card_Style_Follow_App": MessageLookupByLibrary.simpleMessage("跟隨應用程式外觀"),
    "Card_Style_Hide_Date": MessageLookupByLibrary.simpleMessage("隱藏日期"),
    "Card_Style_Layout": MessageLookupByLibrary.simpleMessage("版面"),
    "Card_Style_Note_Hint": MessageLookupByLibrary.simpleMessage("更改只套用於此卡片。"),
    "Card_Style_Original_Color": MessageLookupByLibrary.simpleMessage("原始顏色"),
    "Card_Style_Paper": MessageLookupByLibrary.simpleMessage("紙張樣式"),
    "Card_Style_Plain": MessageLookupByLibrary.simpleMessage("純色"),
    "Card_Style_Preview": MessageLookupByLibrary.simpleMessage("即時預覽"),
    "Card_Style_Preview_Body": MessageLookupByLibrary.simpleMessage(
      "記錄你的想法、計劃與日常時刻。",
    ),
    "Card_Style_Preview_Task": MessageLookupByLibrary.simpleMessage("嘗試新事物"),
    "Card_Style_Preview_Title": MessageLookupByLibrary.simpleMessage("一點靈感"),
    "Card_Style_Reset": MessageLookupByLibrary.simpleMessage("重設樣式"),
    "Card_Style_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存卡片樣式，請重試。",
    ),
    "Card_Style_Show_Date": MessageLookupByLibrary.simpleMessage("顯示日期"),
    "Card_Style_Text": MessageLookupByLibrary.simpleMessage("文字"),
    "Card_Style_Textured": MessageLookupByLibrary.simpleMessage("紋理"),
    "Card_Style_Use_Default": MessageLookupByLibrary.simpleMessage("使用預設"),
    "Card_Style_Use_Default_All": MessageLookupByLibrary.simpleMessage(
      "使用預設樣式",
    ),
    "Checklist_All_Done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "Checklist_Completed": m3,
    "Checklist_Item_Completed": MessageLookupByLibrary.simpleMessage("項目已完成"),
    "Checklist_Item_Reopened": MessageLookupByLibrary.simpleMessage("項目已重新開啟"),
    "Checklist_Item_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此清單項目已無法使用。",
    ),
    "Checklist_Progress": m4,
    "Checklist_Reset": MessageLookupByLibrary.simpleMessage("重設清單"),
    "Checklist_Reset_Done": MessageLookupByLibrary.simpleMessage("清單已重設"),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage("從相冊選擇"),
    "Choose_Linked_Notes": MessageLookupByLibrary.simpleMessage("選擇連結筆記"),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage("古典音樂盒"),
    "Clear_Filters": MessageLookupByLibrary.simpleMessage("清除篩選"),
    "Clear_Search": MessageLookupByLibrary.simpleMessage("清除搜尋"),
    "Collapse_Section": m5,
    "Copy_Selection_Destination": MessageLookupByLibrary.simpleMessage(
      "選擇筆記，加入所選文字。",
    ),
    "Copy_Selection_Failed": MessageLookupByLibrary.simpleMessage("無法儲存複製的文字。"),
    "Copy_Selection_New_Note": MessageLookupByLibrary.simpleMessage("新增筆記"),
    "Copy_Selection_New_Note_Hint": MessageLookupByLibrary.simpleMessage(
      "用所選文字建立筆記。",
    ),
    "Copy_Selection_No_Matches": MessageLookupByLibrary.simpleMessage(
      "沒有相符的筆記",
    ),
    "Copy_Selection_No_Notes": MessageLookupByLibrary.simpleMessage(
      "新增筆記以儲存這段文字。",
    ),
    "Copy_Selection_Saved": MessageLookupByLibrary.simpleMessage("文字已複製到筆記"),
    "Copy_Selection_Search_Notes": MessageLookupByLibrary.simpleMessage("搜尋筆記"),
    "Copy_Selection_To_Note": MessageLookupByLibrary.simpleMessage("複製到筆記"),
    "Copy_Suffix": MessageLookupByLibrary.simpleMessage("(副本)"),
    "Daily_Note_Calendar": MessageLookupByLibrary.simpleMessage("每日筆記"),
    "Daily_Note_Calendar_Choose_Month": MessageLookupByLibrary.simpleMessage(
      "選擇月份和年份",
    ),
    "Daily_Note_Calendar_Empty": MessageLookupByLibrary.simpleMessage(
      "還沒有每日筆記，從今日筆記開始吧。",
    ),
    "Daily_Note_Calendar_Has_Note": MessageLookupByLibrary.simpleMessage(
      "有每日筆記",
    ),
    "Daily_Note_Calendar_Next_Month": MessageLookupByLibrary.simpleMessage(
      "下個月",
    ),
    "Daily_Note_Calendar_No_Note": MessageLookupByLibrary.simpleMessage(
      "這一天沒有每日筆記。",
    ),
    "Daily_Note_Calendar_Note_Unavailable":
        MessageLookupByLibrary.simpleMessage("這篇每日筆記已不可用。"),
    "Daily_Note_Calendar_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "無法開啟每日筆記，請再試一次。",
    ),
    "Daily_Note_Calendar_Previous_Month": MessageLookupByLibrary.simpleMessage(
      "上個月",
    ),
    "Daily_Note_Calendar_Today": MessageLookupByLibrary.simpleMessage("今天"),
    "Default_Card_Style": MessageLookupByLibrary.simpleMessage("預設卡片樣式"),
    "Default_Card_Style_Description": MessageLookupByLibrary.simpleMessage(
      "設定筆記在列表中的顯示樣式",
    ),
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
    "Delete_Template": MessageLookupByLibrary.simpleMessage("刪除範本"),
    "Delete_Todo_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "此待辦事項將被刪除，且無法恢復。",
    ),
    "Delete_Todo_Confirm_Title": MessageLookupByLibrary.simpleMessage("刪除此項？"),
    "Delete_View": MessageLookupByLibrary.simpleMessage("刪除檢視"),
    "Document_Scan": MessageLookupByLibrary.simpleMessage("掃描文件"),
    "Document_Scan_Failed": MessageLookupByLibrary.simpleMessage(
      "無法完成加入掃描頁面，請重試。",
    ),
    "Document_Scan_Pending": MessageLookupByLibrary.simpleMessage(
      "掃描仍在處理中，請稍後重試。",
    ),
    "Document_Scan_Permission": MessageLookupByLibrary.simpleMessage(
      "請在設定中允許相機存取，以掃描文件。",
    ),
    "Document_Scan_Too_Many": MessageLookupByLibrary.simpleMessage(
      "每次最多掃描20頁，請將文件分成幾次掃描。",
    ),
    "Document_Scan_Unsupported": MessageLookupByLibrary.simpleMessage(
      "此裝置不支援文件掃描。",
    ),
    "Done": MessageLookupByLibrary.simpleMessage("完成"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("複製"),
    "Edit": MessageLookupByLibrary.simpleMessage("編輯"),
    "Edit_Tags": MessageLookupByLibrary.simpleMessage("編輯標籤"),
    "Editor_Insert": MessageLookupByLibrary.simpleMessage("插入"),
    "Editor_Tip_Formatting": MessageLookupByLibrary.simpleMessage(
      "使用下方按鈕為選取的文字設定格式。",
    ),
    "Editor_Tip_Image_Layout": MessageLookupByLibrary.simpleMessage(
      "點按照片可調整大小，長按可移動位置。",
    ),
    "Empty_Trash": MessageLookupByLibrary.simpleMessage("清空回收站"),
    "Expand_Section": m6,
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
    "Filter_Tags": MessageLookupByLibrary.simpleMessage("依標籤篩選"),
    "Filter_Unfinished": MessageLookupByLibrary.simpleMessage("未完成"),
    "Find_Close": MessageLookupByLibrary.simpleMessage("關閉尋找"),
    "Find_Edit_Match": MessageLookupByLibrary.simpleMessage("編輯符合內容"),
    "Find_In_Note": MessageLookupByLibrary.simpleMessage("在筆記中尋找"),
    "Find_Next": MessageLookupByLibrary.simpleMessage("下一個結果"),
    "Find_No_Matches": MessageLookupByLibrary.simpleMessage("沒有符合的結果"),
    "Find_Previous": MessageLookupByLibrary.simpleMessage("上一個結果"),
    "Find_Replace": MessageLookupByLibrary.simpleMessage("取代"),
    "Find_Replace_All": MessageLookupByLibrary.simpleMessage("全部取代"),
    "Find_Replace_Changed": MessageLookupByLibrary.simpleMessage(
      "筆記已變更，請重新搜尋後取代。",
    ),
    "Find_Replace_Limit": MessageLookupByLibrary.simpleMessage(
      "取代後標題或清單項目會太長。",
    ),
    "Find_Replace_With": MessageLookupByLibrary.simpleMessage("取代為"),
    "Find_Replaced": m7,
    "Folder_Created": MessageLookupByLibrary.simpleMessage("已建立資料夾"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("已刪除資料夾"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("資料夾名稱"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage("請輸入資料夾名稱。"),
    "Folder_Notes_Count": m8,
    "Folders": MessageLookupByLibrary.simpleMessage("資料夾"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage("留一點空間，記錄下一個好想法。"),
    "Font_Size": MessageLookupByLibrary.simpleMessage("字體大小"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("字體樣式"),
    "Format_Bold": MessageLookupByLibrary.simpleMessage("粗體"),
    "Format_Bullets": MessageLookupByLibrary.simpleMessage("項目符號"),
    "Format_Heading": MessageLookupByLibrary.simpleMessage("標題"),
    "Format_Highlight": MessageLookupByLibrary.simpleMessage("螢光標記"),
    "Format_Remove_Highlight": MessageLookupByLibrary.simpleMessage("移除螢光標記"),
    "Format_Select_To_Highlight": MessageLookupByLibrary.simpleMessage(
      "選取文字以加入螢光標記",
    ),
    "Format_Text": MessageLookupByLibrary.simpleMessage("文字樣式"),
    "History_Current": MessageLookupByLibrary.simpleMessage("已與此版本相同"),
    "History_Empty": MessageLookupByLibrary.simpleMessage("儲存的修改會顯示在這裡。"),
    "History_Photos": m9,
    "History_Preview": MessageLookupByLibrary.simpleMessage("版本預覽"),
    "History_Recordings": m10,
    "History_Restore": MessageLookupByLibrary.simpleMessage("還原此版本"),
    "History_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "無法還原此版本，請重試。",
    ),
    "History_Restored": MessageLookupByLibrary.simpleMessage("已還原版本"),
    "History_Title": MessageLookupByLibrary.simpleMessage("備忘錄歷史"),
    "History_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此備忘錄或版本已無法使用。",
    ),
    "History_Version": m11,
    "Image_Drop_Here": MessageLookupByLibrary.simpleMessage("將照片放在這裡"),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("咕嚕濾鏡"),
    "Image_Move": MessageLookupByLibrary.simpleMessage("移動照片"),
    "Image_Move_After": MessageLookupByLibrary.simpleMessage("向後移動"),
    "Image_Move_Before": MessageLookupByLibrary.simpleMessage("向前移動"),
    "Image_Remove": MessageLookupByLibrary.simpleMessage("移除照片"),
    "Image_Resize": MessageLookupByLibrary.simpleMessage("調整照片大小"),
    "Include_Archived": MessageLookupByLibrary.simpleMessage("包含封存筆記"),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Large": MessageLookupByLibrary.simpleMessage("大"),
    "Library_Filters": MessageLookupByLibrary.simpleMessage("筆記篩選"),
    "Link_Empty": MessageLookupByLibrary.simpleMessage("暫無可連結的筆記，請先建立其他筆記。"),
    "Link_Limit": MessageLookupByLibrary.simpleMessage(
      "最多連結100篇筆記。請移除一個連結後再新增。",
    ),
    "Link_Note": MessageLookupByLibrary.simpleMessage("連結筆記"),
    "Link_Remove": MessageLookupByLibrary.simpleMessage("移除連結"),
    "Link_Save_Failed": MessageLookupByLibrary.simpleMessage("無法更新筆記，請再試一次。"),
    "Link_Search": MessageLookupByLibrary.simpleMessage("搜尋筆記"),
    "Link_Unavailable": MessageLookupByLibrary.simpleMessage("筆記無法使用"),
    "Linked_From": MessageLookupByLibrary.simpleMessage("引用此筆記"),
    "Linked_Notes": MessageLookupByLibrary.simpleMessage("連結筆記"),
    "Manage_Folders": MessageLookupByLibrary.simpleMessage("管理資料夾"),
    "Medium": MessageLookupByLibrary.simpleMessage("中"),
    "Metronome_Go": MessageLookupByLibrary.simpleMessage("打拍節拍器"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("經典掃雷"),
    "Mint_Translate": MessageLookupByLibrary.simpleMessage("薄荷翻譯"),
    "Money_Tracker": MessageLookupByLibrary.simpleMessage("極簡記賬"),
    "More_Apps": MessageLookupByLibrary.simpleMessage("更多App"),
    "More_Options": MessageLookupByLibrary.simpleMessage("更多選項"),
    "Move_Down": MessageLookupByLibrary.simpleMessage("下移"),
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("移至資料夾"),
    "Move_Up": MessageLookupByLibrary.simpleMessage("上移"),
    "My_Templates": MessageLookupByLibrary.simpleMessage("我的範本"),
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
    "Note_Archived": MessageLookupByLibrary.simpleMessage("筆記已封存"),
    "Note_Color": m12,
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("已刪除備忘錄"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功複製備忘錄",
    ),
    "Note_FocusWriting": MessageLookupByLibrary.simpleMessage("專注寫作"),
    "Note_Info": MessageLookupByLibrary.simpleMessage("筆記資訊"),
    "Note_Info_Characters": MessageLookupByLibrary.simpleMessage("字元數"),
    "Note_Info_Counting_Hint": MessageLookupByLibrary.simpleMessage(
      "包含標題、內文、清單和語音轉寫。中日韓文字按字計數。",
    ),
    "Note_Info_Photos": MessageLookupByLibrary.simpleMessage("照片"),
    "Note_Info_Reading_Empty": MessageLookupByLibrary.simpleMessage("0 分鐘"),
    "Note_Info_Reading_Less_Than_Minute": MessageLookupByLibrary.simpleMessage(
      "不到 1 分鐘",
    ),
    "Note_Info_Reading_Minutes": m13,
    "Note_Info_Reading_Time": MessageLookupByLibrary.simpleMessage("預計閱讀時間"),
    "Note_Info_Recording_Duration": MessageLookupByLibrary.simpleMessage(
      "錄音總時長",
    ),
    "Note_Info_Recordings": MessageLookupByLibrary.simpleMessage("錄音"),
    "Note_Info_Words": MessageLookupByLibrary.simpleMessage("字數"),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("已移動備忘錄"),
    "Note_Outline": MessageLookupByLibrary.simpleMessage("大綱"),
    "Note_Outline_Current": MessageLookupByLibrary.simpleMessage("目前部分"),
    "Note_Outline_Hint": MessageLookupByLibrary.simpleMessage("輕點標題，跳至該部分"),
    "Note_Redo": MessageLookupByLibrary.simpleMessage("重做"),
    "Note_ShowWritingTools": MessageLookupByLibrary.simpleMessage("顯示寫作工具"),
    "Note_Unarchived": MessageLookupByLibrary.simpleMessage("已取消封存"),
    "Note_Undo": MessageLookupByLibrary.simpleMessage("復原"),
    "Note_Untitled": MessageLookupByLibrary.simpleMessage("無標題筆記"),
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
    "Open_Linked_Note": MessageLookupByLibrary.simpleMessage("開啟連結筆記"),
    "Permanent_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "這些備忘錄及其照片、提醒將被永久刪除，且無法復原。",
    ),
    "Permanent_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "永久刪除？",
    ),
    "Photo_Capture_Failed": MessageLookupByLibrary.simpleMessage(
      "無法加入照片，請重試或從相簿中選擇。",
    ),
    "Photo_Edit": MessageLookupByLibrary.simpleMessage("編輯照片"),
    "Photo_Edit_Failed": MessageLookupByLibrary.simpleMessage("無法儲存照片，請再試一次。"),
    "Photo_Edit_Hint": MessageLookupByLibrary.simpleMessage(
      "拖動邊角裁剪照片，也可以旋轉照片。",
    ),
    "Photo_Reset": MessageLookupByLibrary.simpleMessage("重設"),
    "Photo_Rotate": MessageLookupByLibrary.simpleMessage("旋轉"),
    "Photo_Save": MessageLookupByLibrary.simpleMessage("儲存"),
    "Photo_Search_Indexing": MessageLookupByLibrary.simpleMessage(
      "正在辨識照片文字以便搜尋…",
    ),
    "Photo_Search_Text_In_Photo": MessageLookupByLibrary.simpleMessage(
      "照片中的文字",
    ),
    "Photo_Text_Choose": MessageLookupByLibrary.simpleMessage("選擇照片"),
    "Photo_Text_Copied": MessageLookupByLibrary.simpleMessage("已複製文字"),
    "Photo_Text_Copy": MessageLookupByLibrary.simpleMessage("複製文字"),
    "Photo_Text_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "無法複製文字。請重試。",
    ),
    "Photo_Text_Extract": MessageLookupByLibrary.simpleMessage("提取文字"),
    "Photo_Text_Extracting": MessageLookupByLibrary.simpleMessage("正在讀取照片…"),
    "Photo_Text_Failed": MessageLookupByLibrary.simpleMessage(
      "無法讀取照片中的文字，請重試。",
    ),
    "Photo_Text_Field": MessageLookupByLibrary.simpleMessage("提取的文字"),
    "Photo_Text_Insert": MessageLookupByLibrary.simpleMessage("插入文字"),
    "Photo_Text_Insert_Done": MessageLookupByLibrary.simpleMessage("已將文字加入備忘錄"),
    "Photo_Text_No_Text": MessageLookupByLibrary.simpleMessage(
      "未找到文字。請嘗試文字更大、更清晰的照片。",
    ),
    "Photo_Text_Photo": m14,
    "Photo_Text_Review": MessageLookupByLibrary.simpleMessage("照片中的文字"),
    "Photo_Text_Review_Hint": MessageLookupByLibrary.simpleMessage(
      "加入備忘錄前，請檢查並編輯文字。",
    ),
    "Photo_Text_Unsupported": MessageLookupByLibrary.simpleMessage(
      "此裝置不支援提取文字。",
    ),
    "Pin": MessageLookupByLibrary.simpleMessage("置頂"),
    "Plain_Paper": MessageLookupByLibrary.simpleMessage("純色紙張"),
    "Plain_Paper_Description": MessageLookupByLibrary.simpleMessage(
      "移除紋理、橫線和卡片傾斜，讓介面更簡潔。",
    ),
    "Premium": MessageLookupByLibrary.simpleMessage("進階版"),
    "Premium_Active": MessageLookupByLibrary.simpleMessage("進階版已解鎖"),
    "Premium_Card_Style": MessageLookupByLibrary.simpleMessage("獨立設定卡片樣式"),
    "Premium_Description": MessageLookupByLibrary.simpleMessage(
      "所有進階功能已解鎖，並且無廣告。",
    ),
    "Premium_Existing_Purchase": MessageLookupByLibrary.simpleMessage(
      "已購買移除廣告？您的購買已包含進階版。可在下方恢復購買。",
    ),
    "Premium_Feature_Required": MessageLookupByLibrary.simpleMessage(
      "升級至進階版即可解鎖此功能。",
    ),
    "Premium_Folder_Limit": m15,
    "Premium_Folders": MessageLookupByLibrary.simpleMessage("無限資料夾"),
    "Premium_Free_Core": MessageLookupByLibrary.simpleMessage(
      "免費建立最多 10 則筆記，使用清單和基本提醒。",
    ),
    "Premium_Free_Limits": MessageLookupByLibrary.simpleMessage(
      "免費版包含 3 個資料夾和 3 個自訂範本。",
    ),
    "Premium_No_Ads": MessageLookupByLibrary.simpleMessage("無廣告"),
    "Premium_Note_Limit": m16,
    "Premium_Notes": MessageLookupByLibrary.simpleMessage("無限筆記"),
    "Premium_One_Time_Description": MessageLookupByLibrary.simpleMessage(
      "一次性購買，無需訂閱。",
    ),
    "Premium_One_Time_Price": m17,
    "Premium_Repeating_Reminders": MessageLookupByLibrary.simpleMessage("重複提醒"),
    "Premium_Template_Limit": m18,
    "Premium_Templates": MessageLookupByLibrary.simpleMessage("無限自訂範本"),
    "Premium_Voice_Memos": MessageLookupByLibrary.simpleMessage("語音備忘錄"),
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
    "Purchase_Success": MessageLookupByLibrary.simpleMessage("進階版已解鎖。"),
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
    "Reminder_Next_Time": m19,
    "Reminder_Next_Week": MessageLookupByLibrary.simpleMessage("一星期後"),
    "Reminder_Repeat": MessageLookupByLibrary.simpleMessage("重複"),
    "Reminder_Repeat_Daily": MessageLookupByLibrary.simpleMessage("每天"),
    "Reminder_Repeat_Never": MessageLookupByLibrary.simpleMessage("不重複"),
    "Reminder_Repeat_Weekly": MessageLookupByLibrary.simpleMessage("每週"),
    "Reminder_Save_Failed": MessageLookupByLibrary.simpleMessage("無法更新提醒，請重試。"),
    "Reminder_Saved": MessageLookupByLibrary.simpleMessage("提醒已設定"),
    "Reminder_Set": MessageLookupByLibrary.simpleMessage("設定提醒"),
    "Reminder_Snooze_10_Minutes": MessageLookupByLibrary.simpleMessage(
      "10 分鐘後提醒",
    ),
    "Reminder_Snooze_1_Hour": MessageLookupByLibrary.simpleMessage("1 小時後提醒"),
    "Reminder_Suggestion": m20,
    "Reminder_Suggestion_Confirm": MessageLookupByLibrary.simpleMessage(
      "使用建議時間",
    ),
    "Reminder_Suggestion_Dismiss": MessageLookupByLibrary.simpleMessage("忽略建議"),
    "Reminder_Time": MessageLookupByLibrary.simpleMessage("時間"),
    "Reminder_Tomorrow": MessageLookupByLibrary.simpleMessage("明天早上"),
    "Reminders_Changed": MessageLookupByLibrary.simpleMessage("此提醒已更改，請重試。"),
    "Reminders_Empty_Message": MessageLookupByLibrary.simpleMessage(
      "為筆記加入提醒，即可在這裡查看。",
    ),
    "Reminders_Empty_Title": MessageLookupByLibrary.simpleMessage("暫無提醒日程"),
    "Reminders_Entry": MessageLookupByLibrary.simpleMessage("今天"),
    "Reminders_Load_Failed": MessageLookupByLibrary.simpleMessage(
      "無法載入提醒，請重試。",
    ),
    "Reminders_Note_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此筆記已不可用。",
    ),
    "Reminders_Overdue": MessageLookupByLibrary.simpleMessage("已過期"),
    "Reminders_Reschedule": MessageLookupByLibrary.simpleMessage("重新安排"),
    "Reminders_Snooze": MessageLookupByLibrary.simpleMessage("稍後提醒"),
    "Reminders_Snooze_Failed": MessageLookupByLibrary.simpleMessage(
      "無法延後此提醒，請重試。",
    ),
    "Reminders_Snoozed": MessageLookupByLibrary.simpleMessage("已延後"),
    "Reminders_Title": MessageLookupByLibrary.simpleMessage("提醒日程"),
    "Reminders_Today": MessageLookupByLibrary.simpleMessage("今天"),
    "Reminders_Upcoming": MessageLookupByLibrary.simpleMessage("即將到來"),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("移除廣告"),
    "Remove_Ads_Price": m21,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("重新命名資料夾"),
    "Rename_Template": MessageLookupByLibrary.simpleMessage("重新命名範本"),
    "Rename_View": MessageLookupByLibrary.simpleMessage("重新命名檢視"),
    "Reorder": MessageLookupByLibrary.simpleMessage("排序"),
    "Reorder_Hint": MessageLookupByLibrary.simpleMessage("長按卡片，然後拖曳。"),
    "Reorder_Move_Earlier": MessageLookupByLibrary.simpleMessage("往前移"),
    "Reorder_Move_Later": MessageLookupByLibrary.simpleMessage("往後移"),
    "Reorder_Pinned_Hint": MessageLookupByLibrary.simpleMessage(
      "置頂筆記始終顯示在最上方。",
    ),
    "Reorder_Save_Failed": MessageLookupByLibrary.simpleMessage("無法儲存此順序，請重試。"),
    "Restore": MessageLookupByLibrary.simpleMessage("還原"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage("未找到之前購買的進階版。"),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage("恢復購買"),
    "Restore_Reminder_Warning": MessageLookupByLibrary.simpleMessage(
      "筆記已復原，但部分提醒未能安排。請開啟相關筆記重新設定提醒。",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage("已恢復您的進階版購買。"),
    "Retry": MessageLookupByLibrary.simpleMessage("重試"),
    "Save_As_Template": MessageLookupByLibrary.simpleMessage("儲存為範本"),
    "Save_Current_View": MessageLookupByLibrary.simpleMessage("儲存目前檢視"),
    "Saved_View_Delete_Confirm": MessageLookupByLibrary.simpleMessage("刪除此檢視？"),
    "Saved_View_Empty": MessageLookupByLibrary.simpleMessage("儲存搜尋或篩選，下次快速開啟。"),
    "Saved_View_Failed": MessageLookupByLibrary.simpleMessage("無法儲存此檢視，請再試一次。"),
    "Saved_View_Name": MessageLookupByLibrary.simpleMessage("檢視名稱"),
    "Saved_Views": MessageLookupByLibrary.simpleMessage("已儲存的檢視"),
    "Saving": MessageLookupByLibrary.simpleMessage("保存中"),
    "Search_Active": MessageLookupByLibrary.simpleMessage("正在搜尋"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("搜尋備忘錄"),
    "Search_Results_Count": m22,
    "Select": MessageLookupByLibrary.simpleMessage("選擇"),
    "Selection_Checklist_Added": m23,
    "Selection_Checklist_Failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存清單項目。",
    ),
    "Selection_Checklist_Too_Long": MessageLookupByLibrary.simpleMessage(
      "有一行過長，無法作為清單項目。請選擇較短的行。",
    ),
    "Settings": MessageLookupByLibrary.simpleMessage("設置"),
    "Settings_Save_Failed": MessageLookupByLibrary.simpleMessage("無法儲存設定，請重試。"),
    "Share": MessageLookupByLibrary.simpleMessage("分享"),
    "Share_Audio": MessageLookupByLibrary.simpleMessage("錄音"),
    "Share_Audio_Description": MessageLookupByLibrary.simpleMessage(
      "原始錄音和已校對的文字",
    ),
    "Share_Audio_Failed": MessageLookupByLibrary.simpleMessage(
      "無法分享錄音，請確認檔案可用後再試一次。",
    ),
    "Share_Image": MessageLookupByLibrary.simpleMessage("圖片"),
    "Share_Image_Description": MessageLookupByLibrary.simpleMessage(
      "將目前紙張畫面分享為圖片。",
    ),
    "Share_Import_Failed": MessageLookupByLibrary.simpleMessage(
      "無法匯入分享內容。內容已保留，重新開啟 Onlynote 時會重試。",
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
    "Starter_Templates": MessageLookupByLibrary.simpleMessage("入門範本"),
    "Sudoku_Lover": MessageLookupByLibrary.simpleMessage("數獨迷"),
    "Tag_Hint": MessageLookupByLibrary.simpleMessage("新增標籤"),
    "Tag_Invalid": MessageLookupByLibrary.simpleMessage(
      "最多新增20個標籤，每個標籤不超過40個字元。",
    ),
    "Tags": MessageLookupByLibrary.simpleMessage("標籤"),
    "Take_Photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "Template_Change_Failed": MessageLookupByLibrary.simpleMessage(
      "無法更新範本，請重試。",
    ),
    "Template_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "無法從範本建立筆記，請檢查照片後重試。",
    ),
    "Template_Daily_Plan_Body": MessageLookupByLibrary.simpleMessage(
      "今日重點\n\n筆記\n",
    ),
    "Template_Daily_Plan_Items": MessageLookupByLibrary.simpleMessage(
      "確定今日優先事項\n安排休息時間\n計畫明天",
    ),
    "Template_Daily_Plan_Summary": MessageLookupByLibrary.simpleMessage(
      "確定今日重點，列出幾個明確的優先事項。",
    ),
    "Template_Daily_Plan_Title": MessageLookupByLibrary.simpleMessage("每日計畫"),
    "Template_Default_Name": MessageLookupByLibrary.simpleMessage("我的範本"),
    "Template_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "將刪除此範本，已用此範本建立的筆記會保留。",
    ),
    "Template_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "刪除範本？",
    ),
    "Template_Details": m24,
    "Template_Load_Failed": MessageLookupByLibrary.simpleMessage("無法載入範本，請重試。"),
    "Template_Manage": MessageLookupByLibrary.simpleMessage("管理範本"),
    "Template_Meeting_Body": MessageLookupByLibrary.simpleMessage(
      "日期：\n與會人員：\n\n議程\n\n記錄\n\n決定\n",
    ),
    "Template_Meeting_Items": MessageLookupByLibrary.simpleMessage(
      "傳送會議摘要\n追蹤待辦事項",
    ),
    "Template_Meeting_Summary": MessageLookupByLibrary.simpleMessage(
      "記錄議程、決定和後續事項。",
    ),
    "Template_Meeting_Title": MessageLookupByLibrary.simpleMessage("會議記錄"),
    "Template_Name": MessageLookupByLibrary.simpleMessage("範本名稱"),
    "Template_Packing_Items": MessageLookupByLibrary.simpleMessage(
      "旅行證件\n手機和充電器\n衣物\n盥洗用品\n藥品",
    ),
    "Template_Packing_Summary": MessageLookupByLibrary.simpleMessage(
      "出發前整理旅行必需品。",
    ),
    "Template_Packing_Title": MessageLookupByLibrary.simpleMessage("行李清單"),
    "Template_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存範本。請檢查儲存空間和照片，然後重試。",
    ),
    "Template_Saved": MessageLookupByLibrary.simpleMessage("範本已儲存"),
    "Template_Shopping_Items": MessageLookupByLibrary.simpleMessage(
      "水果和蔬菜\n麵包和穀物\n牛奶或乳製品替代品\n日用品",
    ),
    "Template_Shopping_Summary": MessageLookupByLibrary.simpleMessage(
      "日用品和食品採購清單。",
    ),
    "Template_Shopping_Title": MessageLookupByLibrary.simpleMessage("購物清單"),
    "Templates": MessageLookupByLibrary.simpleMessage("範本"),
    "Templates_Create_Hint": MessageLookupByLibrary.simpleMessage(
      "在筆記選單中將任何筆記儲存為範本。",
    ),
    "Templates_Description": MessageLookupByLibrary.simpleMessage(
      "從實用的大綱開始，再按需要編輯。",
    ),
    "Theme_Dark": MessageLookupByLibrary.simpleMessage("深色"),
    "Theme_Light": MessageLookupByLibrary.simpleMessage("淺色"),
    "Theme_System": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "Title": MessageLookupByLibrary.simpleMessage("標題"),
    "To_get_notification": MessageLookupByLibrary.simpleMessage(
      "想要設置日程安排提醒，請前往設置打開通知",
    ),
    "Today_Note": MessageLookupByLibrary.simpleMessage("今日筆記"),
    "Today_Note_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "無法開啟今日筆記，請再試一次。",
    ),
    "Todo": MessageLookupByLibrary.simpleMessage("清單項目"),
    "Todo_list": MessageLookupByLibrary.simpleMessage("清單"),
    "Trash": MessageLookupByLibrary.simpleMessage("回收站"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("回收站為空"),
    "Type_something": MessageLookupByLibrary.simpleMessage("寫點兒什麼..."),
    "Unarchive_Note": MessageLookupByLibrary.simpleMessage("取消封存"),
    "Undo": MessageLookupByLibrary.simpleMessage("復原"),
    "Unpin": MessageLookupByLibrary.simpleMessage("取消置頂"),
    "Upgrade_To_Premium": MessageLookupByLibrary.simpleMessage("升級至進階版"),
    "Use_Template": MessageLookupByLibrary.simpleMessage("使用範本"),
    "View_Saved": MessageLookupByLibrary.simpleMessage("檢視已儲存"),
    "Voice_Cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "Voice_Delete": MessageLookupByLibrary.simpleMessage("刪除錄音"),
    "Voice_Discard_Failed": MessageLookupByLibrary.simpleMessage("無法捨棄錄音，請重試。"),
    "Voice_Edit_Transcript": MessageLookupByLibrary.simpleMessage("編輯轉錄文字"),
    "Voice_Interrupted": MessageLookupByLibrary.simpleMessage(
      "App 中斷時錄音已停止，請檢查後儲存。",
    ),
    "Voice_Language_Chinese": MessageLookupByLibrary.simpleMessage("中文（簡體）"),
    "Voice_Language_Chinese_Traditional": MessageLookupByLibrary.simpleMessage(
      "中文（繁體）",
    ),
    "Voice_Language_English": MessageLookupByLibrary.simpleMessage("英語"),
    "Voice_Memo": MessageLookupByLibrary.simpleMessage("語音備忘錄"),
    "Voice_Pause": MessageLookupByLibrary.simpleMessage("暫停"),
    "Voice_Permission_Denied": MessageLookupByLibrary.simpleMessage(
      "請在設定中允許使用咪高峰以錄製語音備忘錄。",
    ),
    "Voice_Play": MessageLookupByLibrary.simpleMessage("播放"),
    "Voice_Play_Failed": MessageLookupByLibrary.simpleMessage("無法播放此錄音。請重試。"),
    "Voice_Record": MessageLookupByLibrary.simpleMessage("錄音"),
    "Voice_Record_Failed": MessageLookupByLibrary.simpleMessage("無法錄音，請重試。"),
    "Voice_Recording_Hint": MessageLookupByLibrary.simpleMessage(
      "最多錄製 5 分鐘，可選擇轉成文字。",
    ),
    "Voice_Review_Transcript": MessageLookupByLibrary.simpleMessage("檢查轉錄文字"),
    "Voice_Save": MessageLookupByLibrary.simpleMessage("儲存錄音"),
    "Voice_Save_Failed": MessageLookupByLibrary.simpleMessage("無法儲存錄音，請重試。"),
    "Voice_Stop": MessageLookupByLibrary.simpleMessage("停止錄音"),
    "Voice_Transcribe": MessageLookupByLibrary.simpleMessage("轉成文字"),
    "Voice_Transcribing": MessageLookupByLibrary.simpleMessage("正在轉成文字…"),
    "Voice_Transcript_Hint": MessageLookupByLibrary.simpleMessage("檢查並編輯轉錄文字。"),
    "Voice_Transcription_Failed": MessageLookupByLibrary.simpleMessage(
      "無法轉成文字。錄音已保留，可重試或直接儲存錄音。",
    ),
    "Voice_Transcription_Language": MessageLookupByLibrary.simpleMessage(
      "轉錄語言",
    ),
    "Voice_Transcription_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此語言或裝置暫不支援本機轉錄，您仍可儲存錄音。",
    ),
    "Water_Tracker": MessageLookupByLibrary.simpleMessage("喝水吧"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("彈鋼琴"),
    "Web_Link_Open_Failed": MessageLookupByLibrary.simpleMessage("無法開啟此網站。"),
    "Widget": MessageLookupByLibrary.simpleMessage("主畫面小工具"),
    "Widget_Add_To_Home": MessageLookupByLibrary.simpleMessage("加入主畫面"),
    "Widget_Add_Unsupported": MessageLookupByLibrary.simpleMessage(
      "目前的桌面不支援自動加入，請依照下面的步驟操作。",
    ),
    "Widget_Checklist_Tip": MessageLookupByLibrary.simpleMessage(
      "點按核取方塊即可更新待辦清單，無需開啟 Onlynote。",
    ),
    "Widget_Choose_Note_Android": MessageLookupByLibrary.simpleMessage(
      "加入小工具時，可選擇所有筆記或一篇筆記或待辦清單。之後可透過「小工具設定」進行更改。",
    ),
    "Widget_Choose_Note_Title": MessageLookupByLibrary.simpleMessage("自訂小工具"),
    "Widget_Choose_Note_iOS": MessageLookupByLibrary.simpleMessage(
      "長按小工具，選擇「編輯小工具」，再選擇筆記或待辦清單。適用於 iOS 17 及以上版本。",
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
