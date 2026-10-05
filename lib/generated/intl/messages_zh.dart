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

  static String m1(count) => "已完成（${count}）";

  static String m2(completed, total) => "已完成 ${completed} / ${total} 项";

  static String m3(count) => "${count} 条备忘录";

  static String m4(number) => "笔记颜色 ${number}";

  static String m5(time) => "下次提醒：${time}";

  static String m6(price) => "支付 ${price} 永久移除广告。";

  static String m7(items, photos) => "${items} 项 · ${photos} 张照片";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Add_Image": MessageLookupByLibrary.simpleMessage("添加照片"),
    "Add_Note": MessageLookupByLibrary.simpleMessage("添加备忘录"),
    "Add_Reminder": MessageLookupByLibrary.simpleMessage("添加日程提醒"),
    "Add_todo": MessageLookupByLibrary.simpleMessage("添加事项"),
    "Ads_Removed": MessageLookupByLibrary.simpleMessage("广告已移除"),
    "Ads_Removed_Description": MessageLookupByLibrary.simpleMessage(
      "此设备上的广告已永久移除。",
    ),
    "All_Notes": MessageLookupByLibrary.simpleMessage("全部备忘录"),
    "Allow_Notification": MessageLookupByLibrary.simpleMessage("允许推送"),
    "Appearance": MessageLookupByLibrary.simpleMessage("外观"),
    "Autosave_Failed": MessageLookupByLibrary.simpleMessage(
      "无法保存更改。请保持笔记打开，点击“完成”重试。",
    ),
    "Autosave_Retry": MessageLookupByLibrary.simpleMessage("尚未保存"),
    "Autosave_Saved": MessageLookupByLibrary.simpleMessage("已保存"),
    "Autosave_Saving": MessageLookupByLibrary.simpleMessage("正在保存…"),
    "Backup_Choose": MessageLookupByLibrary.simpleMessage("选择备份文件"),
    "Backup_Contents": m0,
    "Backup_Export": MessageLookupByLibrary.simpleMessage("创建备份"),
    "Backup_Export_Description": MessageLookupByLibrary.simpleMessage(
      "将笔记、清单、文件夹、照片、模板和提醒日期保存到一个 Onlynote 文件中，包含回收站中的笔记。在分享菜单中选择保存到文件或存储应用。文件大小上限：256 MB。",
    ),
    "Backup_Export_Failed": MessageLookupByLibrary.simpleMessage(
      "无法创建备份。请检查可用存储空间，并确认所有笔记照片均可访问。备份不能超过 256 MB。",
    ),
    "Backup_Invalid": MessageLookupByLibrary.simpleMessage(
      "这不是受支持的 Onlynote 备份，或文件已损坏或超过 256 MB。未导入任何内容。",
    ),
    "Backup_Preparing": MessageLookupByLibrary.simpleMessage("正在准备备份…"),
    "Backup_Reading": MessageLookupByLibrary.simpleMessage("正在检查备份文件…"),
    "Backup_Restore": MessageLookupByLibrary.simpleMessage("恢复备份"),
    "Backup_Restore_Description": MessageLookupByLibrary.simpleMessage(
      "恢复会将备份中笔记、文件夹和模板的副本添加到资料库。再次恢复同一文件会添加另一组副本。",
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
    "Card_Size": MessageLookupByLibrary.simpleMessage("卡片大小"),
    "Checklist_All_Done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "Checklist_Completed": m1,
    "Checklist_Item_Completed": MessageLookupByLibrary.simpleMessage("事项已完成"),
    "Checklist_Item_Reopened": MessageLookupByLibrary.simpleMessage("事项已重新打开"),
    "Checklist_Item_Unavailable": MessageLookupByLibrary.simpleMessage(
      "此清单事项已不可用。",
    ),
    "Checklist_Progress": m2,
    "Checklist_Reset": MessageLookupByLibrary.simpleMessage("重置清单"),
    "Checklist_Reset_Done": MessageLookupByLibrary.simpleMessage("清单已重置"),
    "Choose_From_Gallery": MessageLookupByLibrary.simpleMessage("从相册选择"),
    "Classical_Music_Box": MessageLookupByLibrary.simpleMessage("古典音乐盒"),
    "Clear_Filters": MessageLookupByLibrary.simpleMessage("清除筛选"),
    "Copy_Suffix": MessageLookupByLibrary.simpleMessage("(副本)"),
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
    "Done": MessageLookupByLibrary.simpleMessage("完成"),
    "Duplicate": MessageLookupByLibrary.simpleMessage("复制"),
    "Edit": MessageLookupByLibrary.simpleMessage("编辑"),
    "Empty_Trash": MessageLookupByLibrary.simpleMessage("清空回收站"),
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
    "Filter_Reminders": MessageLookupByLibrary.simpleMessage("提醒"),
    "Filter_Unfinished": MessageLookupByLibrary.simpleMessage("未完成"),
    "Folder_Created": MessageLookupByLibrary.simpleMessage("已创建文件夹"),
    "Folder_Deleted": MessageLookupByLibrary.simpleMessage("已删除文件夹"),
    "Folder_Name": MessageLookupByLibrary.simpleMessage("文件夹名称"),
    "Folder_Name_Required": MessageLookupByLibrary.simpleMessage("请输入文件夹名称。"),
    "Folder_Notes_Count": m3,
    "Folders": MessageLookupByLibrary.simpleMessage("文件夹"),
    "Font_Preview": MessageLookupByLibrary.simpleMessage("留一点空间，记录下一个好想法。"),
    "Font_Size": MessageLookupByLibrary.simpleMessage("字体大小"),
    "Font_Style": MessageLookupByLibrary.simpleMessage("字体样式"),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("咕噜滤镜"),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Large": MessageLookupByLibrary.simpleMessage("大"),
    "Manage_Folders": MessageLookupByLibrary.simpleMessage("管理文件夹"),
    "Medium": MessageLookupByLibrary.simpleMessage("中"),
    "Metronome_Go": MessageLookupByLibrary.simpleMessage("打拍节拍器"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("经典扫雷"),
    "Mint_Translate": MessageLookupByLibrary.simpleMessage("薄荷翻译"),
    "Money_Tracker": MessageLookupByLibrary.simpleMessage("极简记账"),
    "More_Apps": MessageLookupByLibrary.simpleMessage("更多App"),
    "More_Options": MessageLookupByLibrary.simpleMessage("更多选项"),
    "Move_To_Folder": MessageLookupByLibrary.simpleMessage("移至文件夹"),
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
    "Note_Color": m4,
    "Note_Deleted": MessageLookupByLibrary.simpleMessage("已删除备忘录"),
    "Note_Duplicated_Successfully": MessageLookupByLibrary.simpleMessage(
      "已成功复制备忘录",
    ),
    "Note_Moved": MessageLookupByLibrary.simpleMessage("已移动备忘录"),
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
    "Permanent_Delete_Confirm_Message": MessageLookupByLibrary.simpleMessage(
      "这些备忘录及其照片、提醒将被永久删除，且无法恢复。",
    ),
    "Permanent_Delete_Confirm_Title": MessageLookupByLibrary.simpleMessage(
      "永久删除？",
    ),
    "Pin": MessageLookupByLibrary.simpleMessage("置顶"),
    "Plain_Paper": MessageLookupByLibrary.simpleMessage("纯色纸张"),
    "Plain_Paper_Description": MessageLookupByLibrary.simpleMessage(
      "移除纹理、横线和卡片倾斜，让界面更简洁。",
    ),
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
    "Purchase_Success": MessageLookupByLibrary.simpleMessage("广告已移除。"),
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
    "Reminder_Next_Time": m5,
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
    "Reminder_Time": MessageLookupByLibrary.simpleMessage("时间"),
    "Reminder_Tomorrow": MessageLookupByLibrary.simpleMessage("明天早上"),
    "Remove_Ads": MessageLookupByLibrary.simpleMessage("移除广告"),
    "Remove_Ads_Price": m6,
    "Rename_Folder": MessageLookupByLibrary.simpleMessage("重命名文件夹"),
    "Rename_Template": MessageLookupByLibrary.simpleMessage("重命名模板"),
    "Reorder": MessageLookupByLibrary.simpleMessage("排序"),
    "Restore": MessageLookupByLibrary.simpleMessage("恢复"),
    "Restore_Nothing": MessageLookupByLibrary.simpleMessage("未找到以前的移除广告购买。"),
    "Restore_Purchases": MessageLookupByLibrary.simpleMessage("恢复购买"),
    "Restore_Reminder_Warning": MessageLookupByLibrary.simpleMessage(
      "笔记已恢复，但部分提醒未能安排。请打开相关笔记重新设置提醒。",
    ),
    "Restore_Success": MessageLookupByLibrary.simpleMessage("已恢复您的移除广告购买。"),
    "Retry": MessageLookupByLibrary.simpleMessage("重试"),
    "Save_As_Template": MessageLookupByLibrary.simpleMessage("保存为模板"),
    "Saving": MessageLookupByLibrary.simpleMessage("保存中"),
    "Search_Notes": MessageLookupByLibrary.simpleMessage("搜索备忘录"),
    "Select": MessageLookupByLibrary.simpleMessage("选择"),
    "Settings": MessageLookupByLibrary.simpleMessage("设置"),
    "Settings_Save_Failed": MessageLookupByLibrary.simpleMessage("无法保存设置，请重试。"),
    "Share": MessageLookupByLibrary.simpleMessage("分享"),
    "Share_Image": MessageLookupByLibrary.simpleMessage("图片"),
    "Share_Image_Description": MessageLookupByLibrary.simpleMessage(
      "将当前纸张视图分享为图片。",
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
    "Template_Details": m7,
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
    "Todo": MessageLookupByLibrary.simpleMessage("清单事项"),
    "Todo_list": MessageLookupByLibrary.simpleMessage("清单"),
    "Trash": MessageLookupByLibrary.simpleMessage("回收站"),
    "Trash_Empty": MessageLookupByLibrary.simpleMessage("回收站为空"),
    "Type_something": MessageLookupByLibrary.simpleMessage("写点儿什么..."),
    "Undo": MessageLookupByLibrary.simpleMessage("撤销"),
    "Unpin": MessageLookupByLibrary.simpleMessage("取消置顶"),
    "Use_Template": MessageLookupByLibrary.simpleMessage("使用模板"),
    "Water_Tracker": MessageLookupByLibrary.simpleMessage("喝水吧"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("弹钢琴"),
    "Widget": MessageLookupByLibrary.simpleMessage("主屏幕小组件"),
    "Widget_Add_To_Home": MessageLookupByLibrary.simpleMessage("添加到主屏幕"),
    "Widget_Add_Unsupported": MessageLookupByLibrary.simpleMessage(
      "当前桌面不支持自动添加，请按下面的步骤操作。",
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
