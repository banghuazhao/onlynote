// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  static String m0(notes, folders, photos) =>
      "${notes} 条笔记 · ${folders} 个文件夹 · ${photos} 张照片";

  static String m1(count) => "${count} 篇关联笔记";

  static String m2(count) => "${count} 页扫描文档";

  static String m3(count) => "已完成（${count}）";

  static String m4(count) => "已复制 ${count} 项待办事项";

  static String m5(completed, total) => "已完成 ${completed} / ${total} 项";

  static String m6(heading) => "收起${heading}";

  static String m7(heading) => "展开${heading}";

  static String m8(count) => "已替换 ${count} 处";

  static String m9(count) => "${count} 条备忘录";

  static String m10(count) => "${count} 张照片";

  static String m11(count) => "${count} 段录音";

  static String m12(date) => "保存于 ${date}";

  static String m13(number) => "笔记颜色 ${number}";

  static String m14(minutes) => "${minutes} 分钟";

  static String m15(number) => "照片 ${number}";

  static String m16(limit) => "免费版包含 ${limit} 个文件夹。升级即可创建无限文件夹。";

  static String m17(limit) => "免费版包含 ${limit} 条笔记。升级即可创建无限笔记。";

  static String m18(price) => "支付 ${price} 永久解锁";

  static String m19(limit) => "免费版包含 ${limit} 个自定义模板。升级即可保存无限模板。";

  static String m20(time) => "下次提醒：${time}";

  static String m21(date) => "提醒我：${date}";

  static String m22(price) => "支付 ${price} 永久移除广告。";

  static String m23(query) => "搜索：${query}";

  static String m24(tags) => "标签：${tags}";

  static String m25(count) => "${count} 条笔记";

  static String m26(count) => "已添加 ${count} 项清单";

  static String m27(items, photos) => "${items} 项 · ${photos} 张照片";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("添加照片"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("添加备忘录"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("添加日程提醒"),
    "Add_Selection_To_Checklist": MessageLookupByLibrary.simpleMessage("添加到清单"),
    "Add_todo": MessageLookupByLibrary.simpleMessage("添加事项"),
    "Ads_Removed": MessageLookupByLibrary.simpleMessage("广告已移除"),
    "Ads_Removed_Description": MessageLookupByLibrary.simpleMessage(
      "此设备上的广告已永久移除。",
    ),
    "All_Notes": MessageLookupByLibrary.simpleMessage("全部备忘录"),
    "Allow_Notification": MessageLookupByLibrary.simpleMessage("允许推送"),
    "Appearance": MessageLookupByLibrary.simpleMessage("外观"),
    "Archive": MessageLookupByLibrary.simpleMessage("封存"),
    "Archive_Empty": MessageLookupByLibrary.simpleMessage("封存的笔记会显示在这里。"),
    "Archive_Note": MessageLookupByLibrary.simpleMessage("封存笔记"),
    "Autosave_Failed": MessageLookupByLibrary.simpleMessage(
      "无法保存更改。请保持笔记打开，点击“尚未保存”重试。",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("尚未保存"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("已保存"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("正在保存…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("选择备份文件"),
    "Backup_Contents": m0,
    "Backup_Export": MessageLookupByLibrary.simpleMessage("创建备份"),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "将笔记、标签、已保存视图、文件夹、照片、录音、历史记录、模板和提醒日期保存在一个Onlynote文件中。包含封存笔记和废纸篓。可从分享菜单保存到文件或存储应用。文件最大256 MB。",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "无法创建备份。请检查可用存储空间，并确认所有照片和录音可用。备份必须小于256 MB。",
    ),
    "Backup_Invalid": MessageLookupByLibrary.simpleMessage(
      "这不是受支持的 Onlynote 备份，或文件已损坏或超过 256 MB。未导入任何内容。",
    ),
    "Backup_Preparing": MessageLookupByLibrary.simpleMessage("正在准备备份…"),
    "Backup_Reading": MessageLookupByLibrary.simpleMessage("正在检查备份文件…"),
    "Backup_Restore": MessageLookupByLibrary.simpleMessage("恢复备份"),
    "Backup_Restore_Description": MessageLookupByLibrary.simpleMessage(
      "恢复会将备份笔记、文件夹、模板和已保存视图的副本添加到笔记库。关联笔记会连接恢复后的副本。再次恢复同一文件会添加另一组副本。",
    ),
    "Backup_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "无法恢复备份。请检查可用存储空间后重试。现有笔记未被覆盖。",
    ),
    "Backup_Restored": MessageLookupByLibrary.simpleMessage("备份已恢复。笔记已添加到笔记库。"),
    "Backup_Restored_No_Notifications": MessageLookupByLibrary.simpleMessage(
      "笔记已恢复。部分提醒通知未能安排；请打开相应笔记重新设置。",
    ),
    "Backup_Restoring": MessageLookupByLibrary.simpleMessage("正在恢复笔记和照片…"),
    "Backup_Schedule_Reminders": MessageLookupByLibrary.simpleMessage(
      "安排未来的提醒通知",
    ),
    "Backup_Title": MessageLookupByLibrary.simpleMessage("备份与恢复"),
    "Cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "Cancel_Searching": MessageLookupByLibrary.simpleMessage("取消搜索"),
    "Card_Linked_Notes_Count": m1,
    "Card_Scanned_Pages_Count": m2,
    "Card_Size": MessageLookupByLibrary.simpleMessage("卡片大小"),
    "Card_Style": MessageLookupByLibrary.simpleMessage("卡片样式"),
    "Card_Style_Color": MessageLookupByLibrary.simpleMessage("颜色"),
    "Card_Style_Default_Color": MessageLookupByLibrary.simpleMessage("默认纸张颜色"),
    "Card_Style_Default_Hint": MessageLookupByLibrary.simpleMessage(
      "未自定义样式的笔记会使用这些默认设置。",
    ),
    "Card_Style_Discard": MessageLookupByLibrary.simpleMessage("放弃"),
    "Card_Style_Discard_Message": MessageLookupByLibrary.simpleMessage(
      "你的卡片样式更改尚未保存。",
    ),
    "Card_Style_Discard_Title": MessageLookupByLibrary.simpleMessage("放弃样式更改？"),
    "Card_Style_Follow_App": MessageLookupByLibrary.simpleMessage("跟随应用外观"),
    "Card_Style_Hide_Date": MessageLookupByLibrary.simpleMessage("隐藏日期"),
    "Card_Style_Layout": MessageLookupByLibrary.simpleMessage("布局"),
    "Card_Style_Note_Hint": MessageLookupByLibrary.simpleMessage("更改仅应用于此卡片。"),
    "Card_Style_Original_Color": MessageLookupByLibrary.simpleMessage("原始颜色"),
    "Card_Style_Paper": MessageLookupByLibrary.simpleMessage("纸张样式"),
    "Card_Style_Plain": MessageLookupByLibrary.simpleMessage("纯色"),
    "Card_Style_Preview": MessageLookupByLibrary.simpleMessage("即时预览"),
    "Card_Style_Preview_Body": MessageLookupByLibrary.simpleMessage(
      "记录你的想法、计划和日常时刻。",
    ),
    "Card_Style_Preview_Task": MessageLookupByLibrary.simpleMessage("尝试新事物"),
    "Card_Style_Preview_Title": MessageLookupByLibrary.simpleMessage("一点灵感"),
    "Card_Style_Reset": MessageLookupByLibrary.simpleMessage("重置样式"),
    "Card_Style_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "无法保存卡片样式，请重试。",
    ),
    "Card_Style_Show_Date": MessageLookupByLibrary.simpleMessage("显示日期"),
    "Card_Style_Text": MessageLookupByLibrary.simpleMessage("文字"),
    "Card_Style_Textured": MessageLookupByLibrary.simpleMessage("纹理"),
    "Card_Style_Use_Default": MessageLookupByLibrary.simpleMessage("使用默认"),
    "Card_Style_Use_Default_All": MessageLookupByLibrary.simpleMessage(
      "使用默认样式",
    ),
    "Checklist_All_Done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "Checklist_Completed": m3,
    "Checklist_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "无法复制待办事项，请重试。",
    ),
    "Checklist_Copy_Success": m4,
    "Checklist_Copy_Unfinished": MessageLookupByLibrary.simpleMessage(
      "复制未完成事项",
    ),
    "Checklist_Item_Completed": MessageLookupByLibrary.simpleMessage("事项已完成"),
    "Checklist_Item_Reopened": MessageLookupByLibrary.simpleMessage("事项已重新打开"),
    "Checklist_Item_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此清单事项已不可用。",
    ),
    "Checklist_Progress": m5,
    "Checklist_Reset": MessageLookupByLibrary.simpleMessage("重置清单"),
    "Checklist_Reset_Done": MessageLookupByLibrary.simpleMessage("清单已重置"),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage("从相册选择"),
    "Choose_Linked_Notes": MessageLookupByLibrary.simpleMessage("选择关联笔记"),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage("古典音乐盒"),
    "Clear_Filters": MessageLookupByLibrary.simpleMessage("清除筛选"),
    "Clear_Search": MessageLookupByLibrary.simpleMessage("清除搜索"),
    "Collapse_Section": m6,
    "Copy_Selection_Destination": MessageLookupByLibrary.simpleMessage(
      "选择笔记，添加所选文字。",
    ),
    "Copy_Selection_Failed": MessageLookupByLibrary.simpleMessage("无法保存复制的文字。"),
    "Copy_Selection_New_Note": MessageLookupByLibrary.simpleMessage("新建笔记"),
    "Copy_Selection_New_Note_Hint": MessageLookupByLibrary.simpleMessage(
      "用所选文字创建笔记。",
    ),
    "Copy_Selection_No_Matches": MessageLookupByLibrary.simpleMessage(
      "没有匹配的笔记",
    ),
    "Copy_Selection_No_Notes": MessageLookupByLibrary.simpleMessage(
      "新建笔记以保存这段文字。",
    ),
    "Copy_Selection_Saved": MessageLookupByLibrary.simpleMessage("文字已复制到笔记"),
    "Copy_Selection_Search_Notes": MessageLookupByLibrary.simpleMessage("搜索笔记"),
    "Copy_Selection_To_Note": MessageLookupByLibrary.simpleMessage("复制到笔记"),
    "Copy_Suffix": MessageLookupByLibrary.simpleMessage("(副本)"),
    "Daily_Note_Calendar": MessageLookupByLibrary.simpleMessage("每日笔记"),
    "Daily_Note_Calendar_Choose_Month": MessageLookupByLibrary.simpleMessage(
      "选择月份和年份",
    ),
    "Daily_Note_Calendar_Empty": MessageLookupByLibrary.simpleMessage(
      "还没有每日笔记，从今日笔记开始吧。",
    ),
    "Daily_Note_Calendar_Has_Note": MessageLookupByLibrary.simpleMessage(
      "有每日笔记",
    ),
    "Daily_Note_Calendar_Next_Month": MessageLookupByLibrary.simpleMessage(
      "下个月",
    ),
    "Daily_Note_Calendar_No_Note": MessageLookupByLibrary.simpleMessage(
      "这一天没有每日笔记。",
    ),
    "Daily_Note_Calendar_Note_Unavailable":
        MessageLookupByLibrary.simpleMessage("这篇每日笔记已不可用。"),
    "Daily_Note_Calendar_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "无法打开每日笔记，请重试。",
    ),
    "Daily_Note_Calendar_Previous_Month": MessageLookupByLibrary.simpleMessage(
      "上个月",
    ),
    "Daily_Note_Calendar_Today": MessageLookupByLibrary.simpleMessage("今天"),
    "Default_Card_Style": MessageLookupByLibrary.simpleMessage("默认卡片样式"),
    "Default_Card_Style_Description": MessageLookupByLibrary.simpleMessage(
      "设置笔记在列表中的显示样式",
    ),
    "Delete": MessageLookupByLibrary.simpleMessage("删除"),
    "Delete_Folder": MessageLookupByLibrary.simpleMessage("删除文件夹"),
    "Delete_Folder_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "文件夹中的备忘录将保留在全部备忘录中，仅删除文件夹。",
    ),
    "Delete_Forever": MessageLookupByLibrary.simpleMessage("永久删除"),
    "Delete_Note_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "此备忘录将移至回收站，之后可以恢复。",
    ),
    "Delete_Note_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "删除此备忘录？",
    ),
    "Delete_Template": MessageLookupByLibrary.simpleMessage("删除模板"),
    "Delete_Todo_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "此待办事项将被删除，且无法恢复。",
    ),
    "Delete_Todo_Confirm_Title": MessageLookupByLibrary.simpleMessage("删除此项？"),
    "Delete_View": MessageLookupByLibrary.simpleMessage("删除视图"),
    "Document_Scan": MessageLookupByLibrary.simpleMessage("扫描文档"),
    "Document_Scan_Failed": MessageLookupByLibrary.simpleMessage(
      "无法完成添加扫描页面，请重试。",
    ),
    "Document_Scan_Pending": MessageLookupByLibrary.simpleMessage(
      "扫描仍在处理中，请稍后重试。",
    ),
    "Document_Scan_Permission": MessageLookupByLibrary.simpleMessage(
      "请在设置中允许相机访问，以扫描文档。",
    ),
    "Document_Scan_Too_Many": MessageLookupByLibrary.simpleMessage(
      "每次最多扫描20页，请将文档分成几次扫描。",
    ),
    "Document_Scan_Unsupported": MessageLookupByLibrary.simpleMessage(
      "此设备不支持文档扫描。",
    ),
    "Done": MessageLookupByLibrary.simpleMessage("完成"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("复制"),
    "Edit": MessageLookupByLibrary.simpleMessage("编辑"),
    "Edit_Tags": MessageLookupByLibrary.simpleMessage("编辑标签"),
    "Editor_Insert": MessageLookupByLibrary.simpleMessage("插入"),
    "Editor_Tip_Formatting": MessageLookupByLibrary.simpleMessage(
      "使用下方按钮为选中的文字设置格式。",
    ),
    "Editor_Tip_Image_Layout": MessageLookupByLibrary.simpleMessage(
      "点按照片可调整大小，长按可移动位置。",
    ),
    "Empty_Trash": MessageLookupByLibrary.simpleMessage("清空回收站"),
    "Expand_Section": m7,
    "Express_Scan": MessageLookupByLibrary.simpleMessage("飞速扫描"),
    "Failed_to_Update_note_please_try_again":
        MessageLookupByLibrary.simpleMessage("更新备忘录失败, 请重试"),
    "Failed_to_add_note_Title_should_not_empty":
        MessageLookupByLibrary.simpleMessage("备忘录内容不能为空，请添加标题、内容、待办事项或照片"),
    "Failed_to_add_note_please_try_again": MessageLookupByLibrary.simpleMessage(
      "添加备忘录失败, 请重试",
    ),
    "Failed_to_delete_folder": MessageLookupByLibrary.simpleMessage(
      "删除文件夹失败，请重试。",
    ),
    "Failed_to_delete_note_please_try_again":
        MessageLookupByLibrary.simpleMessage("删除备忘录失败, 请重试"),
    "Failed_to_delete_notes": MessageLookupByLibrary.simpleMessage("删除备忘录失败"),
    "Failed_to_load_note_please_try_again":
        MessageLookupByLibrary.simpleMessage("加载备忘录失败, 请重试"),
    "Failed_to_load_notes_please_try_again":
        MessageLookupByLibrary.simpleMessage("加载备忘录失败, 请重试"),
    "Failed_to_restore_notes": MessageLookupByLibrary.simpleMessage(
      "恢复备忘录失败，请重试。",
    ),
    "Failed_to_save_folder": MessageLookupByLibrary.simpleMessage(
      "保存文件夹失败，请重试。",
    ),
    "Failed_to_update_note_Title_should_not_empty":
        MessageLookupByLibrary.simpleMessage("备忘录内容不能为空，请添加标题、内容、待办事项或照片"),
    "Filter_Checklists": MessageLookupByLibrary.simpleMessage("清单"),
    "Filter_Photos": MessageLookupByLibrary.simpleMessage("照片"),
    "Filter_Pinned": MessageLookupByLibrary.simpleMessage("置顶"),
    "Filter_Recordings": MessageLookupByLibrary.simpleMessage("录音"),
    "Filter_Reminders": MessageLookupByLibrary.simpleMessage("提醒"),
    "Filter_Scans": MessageLookupByLibrary.simpleMessage("扫描文档"),
    "Filter_Tags": MessageLookupByLibrary.simpleMessage("按标签筛选"),
    "Filter_Unfinished": MessageLookupByLibrary.simpleMessage("未完成"),
    "Find_Close": MessageLookupByLibrary.simpleMessage("关闭查找"),
    "Find_Edit_Match": MessageLookupByLibrary.simpleMessage("编辑匹配内容"),
    "Find_In_Note": MessageLookupByLibrary.simpleMessage("在笔记中查找"),
    "Find_Next": MessageLookupByLibrary.simpleMessage("下一个结果"),
    "Find_No_Matches": MessageLookupByLibrary.simpleMessage("没有匹配结果"),
    "Find_Previous": MessageLookupByLibrary.simpleMessage("上一个结果"),
    "Find_Replace": MessageLookupByLibrary.simpleMessage("替换"),
    "Find_Replace_All": MessageLookupByLibrary.simpleMessage("全部替换"),
    "Find_Replace_Changed": MessageLookupByLibrary.simpleMessage(
      "笔记已更改，请重新搜索后替换。",
    ),
    "Find_Replace_Limit": MessageLookupByLibrary.simpleMessage(
      "替换后标题或清单条目会太长。",
    ),
    "Find_Replace_With": MessageLookupByLibrary.simpleMessage("替换为"),
    "Find_Replaced": m8,
    "Folder_Created": MessageLookupByLibrary.simpleMessage("已创建文件夹"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("已删除文件夹"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("文件夹名称"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage("请输入文件夹名称。"),
    "Folder_Notes_Count": m9,
    "Folders": MessageLookupByLibrary.simpleMessage("文件夹"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage("留一点空间，记录下一个好想法。"),
    "Font_Size": MessageLookupByLibrary.simpleMessage("字体大小"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("字体样式"),
    "Format_Bold": MessageLookupByLibrary.simpleMessage("粗体"),
    "Format_Bullets": MessageLookupByLibrary.simpleMessage("项目符号"),
    "Format_Heading": MessageLookupByLibrary.simpleMessage("标题"),
    "Format_Highlight": MessageLookupByLibrary.simpleMessage("高亮"),
    "Format_Remove_Highlight": MessageLookupByLibrary.simpleMessage("取消高亮"),
    "Format_Select_To_Highlight": MessageLookupByLibrary.simpleMessage(
      "选中文字以高亮",
    ),
    "Format_Text": MessageLookupByLibrary.simpleMessage("文字样式"),
    "History_Current": MessageLookupByLibrary.simpleMessage("已与此版本相同"),
    "History_Empty": MessageLookupByLibrary.simpleMessage("保存的修改会显示在这里。"),
    "History_Photos": m10,
    "History_Preview": MessageLookupByLibrary.simpleMessage("版本预览"),
    "History_Recordings": m11,
    "History_Restore": MessageLookupByLibrary.simpleMessage("恢复此版本"),
    "History_Restore_Failed": MessageLookupByLibrary.simpleMessage(
      "无法恢复此版本，请重试。",
    ),
    "History_Restored": MessageLookupByLibrary.simpleMessage("已恢复版本"),
    "History_Title": MessageLookupByLibrary.simpleMessage("备忘录历史"),
    "History_Unavailable": MessageLookupByLibrary.simpleMessage("此备忘录或版本已不可用。"),
    "History_Version": m12,
    "Image_Drop_Here": MessageLookupByLibrary.simpleMessage("将照片放在这里"),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("咕噜滤镜"),
    "Image_Move": MessageLookupByLibrary.simpleMessage("移动照片"),
    "Image_Move_After": MessageLookupByLibrary.simpleMessage("向后移动"),
    "Image_Move_Before": MessageLookupByLibrary.simpleMessage("向前移动"),
    "Image_Remove": MessageLookupByLibrary.simpleMessage("移除照片"),
    "Image_Resize": MessageLookupByLibrary.simpleMessage("调整照片大小"),
    "Include_Archived": MessageLookupByLibrary.simpleMessage("包含封存笔记"),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Large": MessageLookupByLibrary.simpleMessage("大"),
    "Library_Filters": MessageLookupByLibrary.simpleMessage("笔记筛选"),
    "Link_Empty": MessageLookupByLibrary.simpleMessage("暂无可关联的笔记，请先创建其他笔记。"),
    "Link_Limit": MessageLookupByLibrary.simpleMessage(
      "最多关联100篇笔记。请移除一个关联后再添加。",
    ),
    "Link_Note": MessageLookupByLibrary.simpleMessage("关联笔记"),
    "Link_Remove": MessageLookupByLibrary.simpleMessage("移除关联"),
    "Link_Save_Failed": MessageLookupByLibrary.simpleMessage("无法更新笔记，请重试。"),
    "Link_Search": MessageLookupByLibrary.simpleMessage("搜索笔记"),
    "Link_Unavailable": MessageLookupByLibrary.simpleMessage("笔记不可用"),
    "Linked_From": MessageLookupByLibrary.simpleMessage("引用此笔记"),
    "Linked_Notes": MessageLookupByLibrary.simpleMessage("关联笔记"),
    "Manage_Folders": MessageLookupByLibrary.simpleMessage("管理文件夹"),
    "Medium": MessageLookupByLibrary.simpleMessage("中"),
    "Metronome_Go": MessageLookupByLibrary.simpleMessage("打拍节拍器"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("经典扫雷"),
    "Mint_Translate": MessageLookupByLibrary.simpleMessage("薄荷翻译"),
    "Money_Tracker": MessageLookupByLibrary.simpleMessage("极简记账"),
    "More_Apps": MessageLookupByLibrary.simpleMessage("更多App"),
    "More_Options": MessageLookupByLibrary.simpleMessage("更多选项"),
    "Move_Down": MessageLookupByLibrary.simpleMessage("下移"),
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("移至文件夹"),
    "Move_Up": MessageLookupByLibrary.simpleMessage("上移"),
    "My_Templates": MessageLookupByLibrary.simpleMessage("我的模板"),
    "New_Folder": MessageLookupByLibrary.simpleMessage("新建文件夹"),
    "No_Folder": MessageLookupByLibrary.simpleMessage("无文件夹"),
    "No_Folders": MessageLookupByLibrary.simpleMessage("暂无文件夹。创建文件夹来整理备忘录。"),
    "No_Notes_In_Folder": MessageLookupByLibrary.simpleMessage(
      "此文件夹暂无备忘录。\n点击 + 添加。",
    ),
    "No_Search_Results": MessageLookupByLibrary.simpleMessage("没有匹配的备忘录。"),
    "No_notes_found": MessageLookupByLibrary.simpleMessage(
      "目前没有备忘录..\n点击  +  添加",
    ),
    "Note_Added_Successfully": MessageLookupByLibrary.simpleMessage("已成功添加备忘录"),
    "Note_Archived": MessageLookupByLibrary.simpleMessage("笔记已封存"),
    "Note_Color": m13,
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("已删除备忘录"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功复制备忘录",
    ),
    "Note_FocusWriting": MessageLookupByLibrary.simpleMessage("专注写作"),
    "Note_Info": MessageLookupByLibrary.simpleMessage("笔记信息"),
    "Note_Info_Characters": MessageLookupByLibrary.simpleMessage("字符数"),
    "Note_Info_Checklist_Progress": MessageLookupByLibrary.simpleMessage(
      "清单进度",
    ),
    "Note_Info_Checklist_Remaining": MessageLookupByLibrary.simpleMessage(
      "待完成事项",
    ),
    "Note_Info_Counting_Hint": MessageLookupByLibrary.simpleMessage(
      "包含标题、正文、清单和语音转写。中日韩文字按字计数。",
    ),
    "Note_Info_Photos": MessageLookupByLibrary.simpleMessage("照片"),
    "Note_Info_Reading_Empty": MessageLookupByLibrary.simpleMessage("0 分钟"),
    "Note_Info_Reading_Less_Than_Minute": MessageLookupByLibrary.simpleMessage(
      "不到 1 分钟",
    ),
    "Note_Info_Reading_Minutes": m14,
    "Note_Info_Reading_Time": MessageLookupByLibrary.simpleMessage("预计阅读时间"),
    "Note_Info_Recording_Duration": MessageLookupByLibrary.simpleMessage(
      "录音总时长",
    ),
    "Note_Info_Recordings": MessageLookupByLibrary.simpleMessage("录音"),
    "Note_Info_Scanned_Pages": MessageLookupByLibrary.simpleMessage("扫描页数"),
    "Note_Info_Words": MessageLookupByLibrary.simpleMessage("字数"),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("已移动备忘录"),
    "Note_Outline": MessageLookupByLibrary.simpleMessage("大纲"),
    "Note_Outline_Current": MessageLookupByLibrary.simpleMessage("当前部分"),
    "Note_Outline_Hint": MessageLookupByLibrary.simpleMessage("轻点标题，跳转至该部分"),
    "Note_Redo": MessageLookupByLibrary.simpleMessage("重做"),
    "Note_ShowWritingTools": MessageLookupByLibrary.simpleMessage("显示写作工具"),
    "Note_Unarchived": MessageLookupByLibrary.simpleMessage("已取消封存"),
    "Note_Undo": MessageLookupByLibrary.simpleMessage("撤销"),
    "Note_Untitled": MessageLookupByLibrary.simpleMessage("无标题笔记"),
    "Note_Updated_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功更新备忘录",
    ),
    "Notes_Deleted_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功删除备忘录",
    ),
    "Notes_Moved_To_Trash": MessageLookupByLibrary.simpleMessage("已移至回收站"),
    "Notes_Permanently_Deleted": MessageLookupByLibrary.simpleMessage("已永久删除"),
    "Notes_Restored": MessageLookupByLibrary.simpleMessage("已恢复备忘录"),
    "Novels_Hub": MessageLookupByLibrary.simpleMessage("英文小说站"),
    "OK": MessageLookupByLibrary.simpleMessage("好的"),
    "Onboarding_Body_1": MessageLookupByLibrary.simpleMessage(
      "快速备忘、待办清单和照片，一处搞定。",
    ),
    "Onboarding_Body_2": MessageLookupByLibrary.simpleMessage(
      "置顶重要内容，用文件夹分组，搜索瞬间找到。",
    ),
    "Onboarding_Body_3": MessageLookupByLibrary.simpleMessage(
      "设置提醒，删除的备忘录可从回收站恢复。",
    ),
    "Onboarding_Body_4": MessageLookupByLibrary.simpleMessage(
      "添加极简备忘录小组件，不用打开 App 也能查看备忘录、随手记录。",
    ),
    "Onboarding_Get_Started": MessageLookupByLibrary.simpleMessage("开始使用"),
    "Onboarding_Make_Checklist": MessageLookupByLibrary.simpleMessage("创建待办清单"),
    "Onboarding_Next": MessageLookupByLibrary.simpleMessage("下一步"),
    "Onboarding_Skip": MessageLookupByLibrary.simpleMessage("跳过"),
    "Onboarding_Title_1": MessageLookupByLibrary.simpleMessage("随时记录"),
    "Onboarding_Title_2": MessageLookupByLibrary.simpleMessage("轻松整理"),
    "Onboarding_Title_3": MessageLookupByLibrary.simpleMessage("不再遗忘"),
    "Onboarding_Title_4": MessageLookupByLibrary.simpleMessage("备忘录放上主屏幕"),
    "Onboarding_Write_Note": MessageLookupByLibrary.simpleMessage("写备忘录"),
    "Onlynote": MessageLookupByLibrary.simpleMessage("极简备忘录"),
    "Open_Linked_Note": MessageLookupByLibrary.simpleMessage("打开关联笔记"),
    "Permanent_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "这些备忘录及其照片、提醒将被永久删除，且无法恢复。",
    ),
    "Permanent_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "永久删除？",
    ),
    "Photo_Capture_Failed": MessageLookupByLibrary.simpleMessage(
      "无法添加照片，请重试或从相册中选择。",
    ),
    "Photo_Edit": MessageLookupByLibrary.simpleMessage("编辑照片"),
    "Photo_Edit_Failed": MessageLookupByLibrary.simpleMessage("无法保存照片，请重试。"),
    "Photo_Edit_Hint": MessageLookupByLibrary.simpleMessage(
      "拖动边角裁剪照片，也可以旋转照片。",
    ),
    "Photo_Reset": MessageLookupByLibrary.simpleMessage("重置"),
    "Photo_Rotate": MessageLookupByLibrary.simpleMessage("旋转"),
    "Photo_Save": MessageLookupByLibrary.simpleMessage("保存"),
    "Photo_Search_Indexing": MessageLookupByLibrary.simpleMessage(
      "正在识别照片文字以便搜索…",
    ),
    "Photo_Search_Text_In_Photo": MessageLookupByLibrary.simpleMessage(
      "照片中的文字",
    ),
    "Photo_Text_Choose": MessageLookupByLibrary.simpleMessage("选择照片"),
    "Photo_Text_Copied": MessageLookupByLibrary.simpleMessage("已复制文字"),
    "Photo_Text_Copy": MessageLookupByLibrary.simpleMessage("复制文字"),
    "Photo_Text_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "无法复制文字。请重试。",
    ),
    "Photo_Text_Extract": MessageLookupByLibrary.simpleMessage("提取文字"),
    "Photo_Text_Extracting": MessageLookupByLibrary.simpleMessage("正在读取照片…"),
    "Photo_Text_Failed": MessageLookupByLibrary.simpleMessage(
      "无法读取照片中的文字，请重试。",
    ),
    "Photo_Text_Field": MessageLookupByLibrary.simpleMessage("提取的文字"),
    "Photo_Text_Insert": MessageLookupByLibrary.simpleMessage("插入文字"),
    "Photo_Text_Insert_Done": MessageLookupByLibrary.simpleMessage(
      "已将文字添加到备忘录",
    ),
    "Photo_Text_No_Text": MessageLookupByLibrary.simpleMessage(
      "未找到文字。请尝试文字更大、更清晰的照片。",
    ),
    "Photo_Text_Photo": m15,
    "Photo_Text_Review": MessageLookupByLibrary.simpleMessage("照片中的文字"),
    "Photo_Text_Review_Hint": MessageLookupByLibrary.simpleMessage(
      "添加到备忘录前，请检查并编辑文字。",
    ),
    "Photo_Text_Unsupported": MessageLookupByLibrary.simpleMessage(
      "此设备不支持提取文字。",
    ),
    "Pin": MessageLookupByLibrary.simpleMessage("置顶"),
    "Plain_Paper": MessageLookupByLibrary.simpleMessage("纯色纸张"),
    "Plain_Paper_Description": MessageLookupByLibrary.simpleMessage(
      "移除纹理、横线和卡片倾斜，让界面更简洁。",
    ),
    "Premium": MessageLookupByLibrary.simpleMessage("高级版"),
    "Premium_Active": MessageLookupByLibrary.simpleMessage("高级版已解锁"),
    "Premium_Card_Style": MessageLookupByLibrary.simpleMessage("单独设置卡片样式"),
    "Premium_Description": MessageLookupByLibrary.simpleMessage(
      "全部高级功能已解锁，且无广告。",
    ),
    "Premium_Existing_Purchase": MessageLookupByLibrary.simpleMessage(
      "已购买移除广告？您的购买已包含高级版。可在下方恢复购买。",
    ),
    "Premium_Feature_Required": MessageLookupByLibrary.simpleMessage(
      "升级到高级版即可解锁此功能。",
    ),
    "Premium_Folder_Limit": m16,
    "Premium_Folders": MessageLookupByLibrary.simpleMessage("无限文件夹"),
    "Premium_Free_Core": MessageLookupByLibrary.simpleMessage(
      "免费创建最多 10 条笔记，使用清单和普通提醒。",
    ),
    "Premium_Free_Limits": MessageLookupByLibrary.simpleMessage(
      "免费版包含 3 个文件夹和 3 个自定义模板。",
    ),
    "Premium_No_Ads": MessageLookupByLibrary.simpleMessage("无广告"),
    "Premium_Note_Limit": m17,
    "Premium_Notes": MessageLookupByLibrary.simpleMessage("无限笔记"),
    "Premium_One_Time_Description": MessageLookupByLibrary.simpleMessage(
      "一次性购买，无需订阅。",
    ),
    "Premium_One_Time_Price": m18,
    "Premium_Repeating_Reminders": MessageLookupByLibrary.simpleMessage("重复提醒"),
    "Premium_Template_Limit": m19,
    "Premium_Templates": MessageLookupByLibrary.simpleMessage("无限自定义模板"),
    "Premium_Voice_Memos": MessageLookupByLibrary.simpleMessage("语音备忘录"),
    "Privacy": MessageLookupByLibrary.simpleMessage("隐私"),
    "Privacy_Policy": MessageLookupByLibrary.simpleMessage("隐私政策"),
    "Privacy_Policy_Failed": MessageLookupByLibrary.simpleMessage(
      "无法打开隐私政策，请重试。",
    ),
    "Privacy_Settings": MessageLookupByLibrary.simpleMessage("广告隐私设置"),
    "Privacy_Settings_Description": MessageLookupByLibrary.simpleMessage(
      "更改或撤回你对个性化广告的选择。",
    ),
    "Purchase_Cancelled": MessageLookupByLibrary.simpleMessage("购买已取消。"),
    "Purchase_Failed": MessageLookupByLibrary.simpleMessage("无法完成购买，请重试。"),
    "Purchase_Loading": MessageLookupByLibrary.simpleMessage("正在连接 App Store…"),
    "Purchase_Pending": MessageLookupByLibrary.simpleMessage("购买正在等待批准。"),
    "Purchase_Success": MessageLookupByLibrary.simpleMessage("高级版已解锁。"),
    "Purchase_Unavailable": MessageLookupByLibrary.simpleMessage("移除广告目前不可用。"),
    "Purchases": MessageLookupByLibrary.simpleMessage("购买项目"),
    "Relaxing_Up": MessageLookupByLibrary.simpleMessage("冥想Up"),
    "Reminder": MessageLookupByLibrary.simpleMessage("提醒设置"),
    "Reminder_Custom": MessageLookupByLibrary.simpleMessage("选择日期和时间"),
    "Reminder_Day": MessageLookupByLibrary.simpleMessage("星期"),
    "Reminder_Future_Time": MessageLookupByLibrary.simpleMessage(
      "请选择将来的时间来设置提醒。",
    ),
    "Reminder_In_One_Hour": MessageLookupByLibrary.simpleMessage("1 小时后"),
    "Reminder_Next_Time": m20,
    "Reminder_Next_Week": MessageLookupByLibrary.simpleMessage("一周后"),
    "Reminder_Repeat": MessageLookupByLibrary.simpleMessage("重复"),
    "Reminder_Repeat_Daily": MessageLookupByLibrary.simpleMessage("每天"),
    "Reminder_Repeat_Never": MessageLookupByLibrary.simpleMessage("不重复"),
    "Reminder_Repeat_Weekly": MessageLookupByLibrary.simpleMessage("每周"),
    "Reminder_Save_Failed": MessageLookupByLibrary.simpleMessage("无法更新提醒，请重试。"),
    "Reminder_Saved": MessageLookupByLibrary.simpleMessage("提醒已设置"),
    "Reminder_Set": MessageLookupByLibrary.simpleMessage("设置提醒"),
    "Reminder_Snooze_10_Minutes": MessageLookupByLibrary.simpleMessage(
      "稍后 10 分钟提醒",
    ),
    "Reminder_Snooze_1_Hour": MessageLookupByLibrary.simpleMessage("稍后 1 小时提醒"),
    "Reminder_Suggestion": m21,
    "Reminder_Suggestion_Confirm": MessageLookupByLibrary.simpleMessage(
      "使用建议时间",
    ),
    "Reminder_Suggestion_Dismiss": MessageLookupByLibrary.simpleMessage("忽略建议"),
    "Reminder_Time": MessageLookupByLibrary.simpleMessage("时间"),
    "Reminder_Tomorrow": MessageLookupByLibrary.simpleMessage("明天早上"),
    "Reminders_Changed": MessageLookupByLibrary.simpleMessage("此提醒已更改，请重试。"),
    "Reminders_Empty_Message": MessageLookupByLibrary.simpleMessage(
      "为笔记添加提醒，即可在这里查看。",
    ),
    "Reminders_Empty_Title": MessageLookupByLibrary.simpleMessage("暂无提醒日程"),
    "Reminders_Entry": MessageLookupByLibrary.simpleMessage("今天"),
    "Reminders_Load_Failed": MessageLookupByLibrary.simpleMessage(
      "无法加载提醒，请重试。",
    ),
    "Reminders_Note_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此笔记已不可用。",
    ),
    "Reminders_Overdue": MessageLookupByLibrary.simpleMessage("已过期"),
    "Reminders_Reschedule": MessageLookupByLibrary.simpleMessage("重新安排"),
    "Reminders_Snooze": MessageLookupByLibrary.simpleMessage("稍后提醒"),
    "Reminders_Snooze_Failed": MessageLookupByLibrary.simpleMessage(
      "无法延后此提醒，请重试。",
    ),
    "Reminders_Snoozed": MessageLookupByLibrary.simpleMessage("已延后"),
    "Reminders_Title": MessageLookupByLibrary.simpleMessage("提醒日程"),
    "Reminders_Today": MessageLookupByLibrary.simpleMessage("今天"),
    "Reminders_Upcoming": MessageLookupByLibrary.simpleMessage("即将到来"),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("移除广告"),
    "Remove_Ads_Price": m22,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("重命名文件夹"),
    "Rename_Template": MessageLookupByLibrary.simpleMessage("重命名模板"),
    "Rename_View": MessageLookupByLibrary.simpleMessage("重命名视图"),
    "Reorder": MessageLookupByLibrary.simpleMessage("排序"),
    "Reorder_Hint": MessageLookupByLibrary.simpleMessage("长按卡片，然后拖动。"),
    "Reorder_Move_Earlier": MessageLookupByLibrary.simpleMessage("往前移"),
    "Reorder_Move_Later": MessageLookupByLibrary.simpleMessage("往后移"),
    "Reorder_Pinned_Hint": MessageLookupByLibrary.simpleMessage(
      "置顶笔记始终显示在最上方。",
    ),
    "Reorder_Save_Failed": MessageLookupByLibrary.simpleMessage("无法保存此顺序，请重试。"),
    "Restore": MessageLookupByLibrary.simpleMessage("恢复"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage("未找到此前购买的高级版。"),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage("恢复购买"),
    "Restore_Reminder_Warning": MessageLookupByLibrary.simpleMessage(
      "笔记已恢复，但部分提醒未能安排。请打开相关笔记重新设置提醒。",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage("已恢复您的高级版购买。"),
    "Retry": MessageLookupByLibrary.simpleMessage("重试"),
    "Save_As_Template": MessageLookupByLibrary.simpleMessage("保存为模板"),
    "Save_Current_View": MessageLookupByLibrary.simpleMessage("保存当前视图"),
    "Saved_View_Delete_Confirm": MessageLookupByLibrary.simpleMessage("删除此视图？"),
    "Saved_View_Empty": MessageLookupByLibrary.simpleMessage("保存搜索或筛选，下次快速打开。"),
    "Saved_View_Failed": MessageLookupByLibrary.simpleMessage("无法保存此视图，请重试。"),
    "Saved_View_Name": MessageLookupByLibrary.simpleMessage("视图名称"),
    "Saved_View_Search": m23,
    "Saved_View_Tags": m24,
    "Saved_Views": MessageLookupByLibrary.simpleMessage("已保存的视图"),
    "Saving": MessageLookupByLibrary.simpleMessage("保存中"),
    "Search_Active": MessageLookupByLibrary.simpleMessage("正在搜索"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("搜索备忘录"),
    "Search_Results_Count": m25,
    "Select": MessageLookupByLibrary.simpleMessage("选择"),
    "Selection_Checklist_Added": m26,
    "Selection_Checklist_Failed": MessageLookupByLibrary.simpleMessage(
      "无法保存清单项。",
    ),
    "Selection_Checklist_Too_Long": MessageLookupByLibrary.simpleMessage(
      "有一行过长，无法作为清单项。请选择较短的行。",
    ),
    "Settings": MessageLookupByLibrary.simpleMessage("设置"),
    "Settings_Save_Failed": MessageLookupByLibrary.simpleMessage("无法保存设置，请重试。"),
    "Share": MessageLookupByLibrary.simpleMessage("分享"),
    "Share_Audio": MessageLookupByLibrary.simpleMessage("录音"),
    "Share_Audio_Description": MessageLookupByLibrary.simpleMessage(
      "原始录音和已校对的文字",
    ),
    "Share_Audio_Failed": MessageLookupByLibrary.simpleMessage(
      "无法分享录音，请确认文件可用后重试。",
    ),
    "Share_Image": MessageLookupByLibrary.simpleMessage("图片"),
    "Share_Image_Description": MessageLookupByLibrary.simpleMessage(
      "将当前纸张视图分享为图片。",
    ),
    "Share_Import_Failed": MessageLookupByLibrary.simpleMessage(
      "无法导入分享内容。内容已保留，重新打开 Onlynote 时会重试。",
    ),
    "Share_Markdown": MessageLookupByLibrary.simpleMessage("Markdown"),
    "Share_Markdown_Description": MessageLookupByLibrary.simpleMessage(
      "包含清单格式和照片附件的 .md 文件。",
    ),
    "Share_No_Text": MessageLookupByLibrary.simpleMessage(
      "此笔记没有文本，请选择图片或 PDF 来分享照片。",
    ),
    "Share_Note_Failed": MessageLookupByLibrary.simpleMessage("分享备忘录失败, 请重试"),
    "Share_PDF": MessageLookupByLibrary.simpleMessage("PDF 文档"),
    "Share_PDF_Description": MessageLookupByLibrary.simpleMessage(
      "包含完整笔记和照片，自动分页，方便打印。",
    ),
    "Share_Plain_Text": MessageLookupByLibrary.simpleMessage("纯文本"),
    "Share_Preparing": MessageLookupByLibrary.simpleMessage("正在准备笔记…"),
    "Share_Text_Description": MessageLookupByLibrary.simpleMessage(
      "标题、全文、清单和提醒，不包含照片。",
    ),
    "Shows": MessageLookupByLibrary.simpleMessage("Shows"),
    "Simple_Calculator": MessageLookupByLibrary.simpleMessage("极简计算器"),
    "Small": MessageLookupByLibrary.simpleMessage("小"),
    "Starter_Templates": MessageLookupByLibrary.simpleMessage("入门模板"),
    "Sudoku_Lover": MessageLookupByLibrary.simpleMessage("数独迷"),
    "Tag_Hint": MessageLookupByLibrary.simpleMessage("添加标签"),
    "Tag_Invalid": MessageLookupByLibrary.simpleMessage(
      "最多添加20个标签，每个标签不超过40个字符。",
    ),
    "Tags": MessageLookupByLibrary.simpleMessage("标签"),
    "Take_Photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "Template_Change_Failed": MessageLookupByLibrary.simpleMessage(
      "无法更新模板，请重试。",
    ),
    "Template_Copy_Failed": MessageLookupByLibrary.simpleMessage(
      "无法从模板创建笔记，请检查照片后重试。",
    ),
    "Template_Daily_Plan_Body": MessageLookupByLibrary.simpleMessage(
      "今日重点\n\n笔记\n",
    ),
    "Template_Daily_Plan_Items": MessageLookupByLibrary.simpleMessage(
      "确定今日优先事项\n安排休息时间\n计划明天",
    ),
    "Template_Daily_Plan_Summary": MessageLookupByLibrary.simpleMessage(
      "确定今日重点，列出几个明确的优先事项。",
    ),
    "Template_Daily_Plan_Title": MessageLookupByLibrary.simpleMessage("每日计划"),
    "Template_Default_Name": MessageLookupByLibrary.simpleMessage("我的模板"),
    "Template_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "将删除此模板，已用此模板创建的笔记会保留。",
    ),
    "Template_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "删除模板？",
    ),
    "Template_Details": m27,
    "Template_Load_Failed": MessageLookupByLibrary.simpleMessage("无法加载模板，请重试。"),
    "Template_Manage": MessageLookupByLibrary.simpleMessage("管理模板"),
    "Template_Meeting_Body": MessageLookupByLibrary.simpleMessage(
      "日期：\n参会人员：\n\n议程\n\n记录\n\n决定\n",
    ),
    "Template_Meeting_Items": MessageLookupByLibrary.simpleMessage(
      "发送会议摘要\n跟进待办事项",
    ),
    "Template_Meeting_Summary": MessageLookupByLibrary.simpleMessage(
      "记录议程、决定和后续事项。",
    ),
    "Template_Meeting_Title": MessageLookupByLibrary.simpleMessage("会议记录"),
    "Template_Name": MessageLookupByLibrary.simpleMessage("模板名称"),
    "Template_Packing_Items": MessageLookupByLibrary.simpleMessage(
      "旅行证件\n手机和充电器\n衣物\n洗漱用品\n药品",
    ),
    "Template_Packing_Summary": MessageLookupByLibrary.simpleMessage(
      "出发前整理旅行必需品。",
    ),
    "Template_Packing_Title": MessageLookupByLibrary.simpleMessage("行李清单"),
    "Template_Save_Failed": MessageLookupByLibrary.simpleMessage(
      "无法保存模板。请检查存储空间和照片，然后重试。",
    ),
    "Template_Saved": MessageLookupByLibrary.simpleMessage("模板已保存"),
    "Template_Shopping_Items": MessageLookupByLibrary.simpleMessage(
      "水果和蔬菜\n面包和谷物\n牛奶或乳制品替代品\n日用品",
    ),
    "Template_Shopping_Summary": MessageLookupByLibrary.simpleMessage(
      "日用品和食品采购清单。",
    ),
    "Template_Shopping_Title": MessageLookupByLibrary.simpleMessage("购物清单"),
    "Templates": MessageLookupByLibrary.simpleMessage("模板"),
    "Templates_Create_Hint": MessageLookupByLibrary.simpleMessage(
      "在笔记菜单中将任意笔记保存为模板。",
    ),
    "Templates_Description": MessageLookupByLibrary.simpleMessage(
      "从实用的大纲开始，再按需要编辑。",
    ),
    "Theme_Dark": MessageLookupByLibrary.simpleMessage("深色"),
    "Theme_Light": MessageLookupByLibrary.simpleMessage("浅色"),
    "Theme_System": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "Title": MessageLookupByLibrary.simpleMessage("标题"),
    "To_get_notification": MessageLookupByLibrary.simpleMessage(
      "想要设置日程安排提醒，请前往设置打开通知",
    ),
    "Today_Note": MessageLookupByLibrary.simpleMessage("今日笔记"),
    "Today_Note_Open_Failed": MessageLookupByLibrary.simpleMessage(
      "无法打开今日笔记，请重试。",
    ),
    "Todo": MessageLookupByLibrary.simpleMessage("清单事项"),
    "Todo_list": MessageLookupByLibrary.simpleMessage("清单"),
    "Trash": MessageLookupByLibrary.simpleMessage("回收站"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("回收站为空"),
    "Type_something": MessageLookupByLibrary.simpleMessage("写点儿什么..."),
    "Unarchive_Note": MessageLookupByLibrary.simpleMessage("取消封存"),
    "Undo": MessageLookupByLibrary.simpleMessage("撤销"),
    "Unpin": MessageLookupByLibrary.simpleMessage("取消置顶"),
    "Upgrade_To_Premium": MessageLookupByLibrary.simpleMessage("升级到高级版"),
    "Use_Template": MessageLookupByLibrary.simpleMessage("使用模板"),
    "View_Saved": MessageLookupByLibrary.simpleMessage("视图已保存"),
    "Voice_Cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "Voice_Delete": MessageLookupByLibrary.simpleMessage("删除录音"),
    "Voice_Discard_Failed": MessageLookupByLibrary.simpleMessage("无法丢弃录音，请重试。"),
    "Voice_Edit_Transcript": MessageLookupByLibrary.simpleMessage("编辑转录文字"),
    "Voice_Interrupted": MessageLookupByLibrary.simpleMessage(
      "应用中断时录音已停止，请检查后保存。",
    ),
    "Voice_Language_Chinese": MessageLookupByLibrary.simpleMessage("中文（简体）"),
    "Voice_Language_Chinese_Traditional": MessageLookupByLibrary.simpleMessage(
      "中文（繁体）",
    ),
    "Voice_Language_English": MessageLookupByLibrary.simpleMessage("英语"),
    "Voice_Memo": MessageLookupByLibrary.simpleMessage("语音备忘录"),
    "Voice_Pause": MessageLookupByLibrary.simpleMessage("暂停"),
    "Voice_Permission_Denied": MessageLookupByLibrary.simpleMessage(
      "请在设置中允许使用麦克风以录制语音备忘录。",
    ),
    "Voice_Play": MessageLookupByLibrary.simpleMessage("播放"),
    "Voice_Play_Failed": MessageLookupByLibrary.simpleMessage("无法播放此录音。请重试。"),
    "Voice_Record": MessageLookupByLibrary.simpleMessage("录音"),
    "Voice_Record_Failed": MessageLookupByLibrary.simpleMessage("无法录音，请重试。"),
    "Voice_Recording_Hint": MessageLookupByLibrary.simpleMessage(
      "最多录制 5 分钟，可选择转成文字。",
    ),
    "Voice_Review_Transcript": MessageLookupByLibrary.simpleMessage("检查转录文字"),
    "Voice_Save": MessageLookupByLibrary.simpleMessage("保存录音"),
    "Voice_Save_Failed": MessageLookupByLibrary.simpleMessage("无法保存录音，请重试。"),
    "Voice_Stop": MessageLookupByLibrary.simpleMessage("停止录音"),
    "Voice_Transcribe": MessageLookupByLibrary.simpleMessage("转成文字"),
    "Voice_Transcribing": MessageLookupByLibrary.simpleMessage("正在转成文字…"),
    "Voice_Transcript_Hint": MessageLookupByLibrary.simpleMessage("检查并编辑转录文字。"),
    "Voice_Transcription_Failed": MessageLookupByLibrary.simpleMessage(
      "无法转成文字。录音已保留，可重试或直接保存录音。",
    ),
    "Voice_Transcription_Language": MessageLookupByLibrary.simpleMessage(
      "转录语言",
    ),
    "Voice_Transcription_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此语言或设备暂不支持本机转录，您仍可保存录音。",
    ),
    "Water_Tracker": MessageLookupByLibrary.simpleMessage("喝水吧"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("弹钢琴"),
    "Web_Link_Open_Failed": MessageLookupByLibrary.simpleMessage("无法打开此网站。"),
    "Widget": MessageLookupByLibrary.simpleMessage("主屏幕小组件"),
    "Widget_Add_To_Home": MessageLookupByLibrary.simpleMessage("添加到主屏幕"),
    "Widget_Add_Unsupported": MessageLookupByLibrary.simpleMessage(
      "当前桌面不支持自动添加，请按下面的步骤操作。",
    ),
    "Widget_Checklist_Tip": MessageLookupByLibrary.simpleMessage(
      "点击复选框即可更新待办清单，无需打开 Onlynote。",
    ),
    "Widget_Choose_Note_Android": MessageLookupByLibrary.simpleMessage(
      "添加小组件时，可选择所有笔记或一篇笔记或待办清单。之后可通过“小组件设置”进行更改。",
    ),
    "Widget_Choose_Note_Title": MessageLookupByLibrary.simpleMessage("自定义小组件"),
    "Widget_Choose_Note_iOS": MessageLookupByLibrary.simpleMessage(
      "长按小组件，选择“编辑小组件”，再选择笔记或待办清单。适用于 iOS 17 及以上版本。",
    ),
    "Widget_Description": MessageLookupByLibrary.simpleMessage(
      "不用打开 App，一眼看到你的备忘录。",
    ),
    "Widget_Discovery_Body": MessageLookupByLibrary.simpleMessage(
      "添加主屏幕小组件，一眼查看你的备忘录。",
    ),
    "Widget_Discovery_Title": MessageLookupByLibrary.simpleMessage(
      "让置顶备忘录随时可见",
    ),
    "Widget_Step_Android_1": MessageLookupByLibrary.simpleMessage("长按主屏幕空白处。"),
    "Widget_Step_Android_2": MessageLookupByLibrary.simpleMessage("点按“小部件”。"),
    "Widget_Step_Android_3": MessageLookupByLibrary.simpleMessage(
      "在列表中找到“极简备忘录”。",
    ),
    "Widget_Step_Android_4": MessageLookupByLibrary.simpleMessage(
      "把小部件拖到想要的位置。",
    ),
    "Widget_Step_iOS_1": MessageLookupByLibrary.simpleMessage(
      "长按主屏幕空白处，直到图标开始抖动。",
    ),
    "Widget_Step_iOS_2": MessageLookupByLibrary.simpleMessage("点按左上角的 + 按钮。"),
    "Widget_Step_iOS_3": MessageLookupByLibrary.simpleMessage(
      "搜索“极简备忘录”，然后选择它。",
    ),
    "Widget_Step_iOS_4": MessageLookupByLibrary.simpleMessage(
      "选择尺寸，然后点按“添加小组件”。",
    ),
    "Widget_Steps_Title": MessageLookupByLibrary.simpleMessage("添加方法"),
    "Widget_Tip": MessageLookupByLibrary.simpleMessage(
      "点按小组件里的备忘录即可打开；点按“新建”直接开始记录。",
    ),
    "World_Weather_Live": MessageLookupByLibrary.simpleMessage("极简天气"),
    "Yes_Habit": MessageLookupByLibrary.simpleMessage("签签习惯"),
    "notes": MessageLookupByLibrary.simpleMessage("备忘录"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
  };
}
