import 'dart:ui' show Color, Locale;

import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';

enum StoreScreenshotLanguage {
  english,
  simplifiedChinese,
  traditionalChinese,
}

enum StoreScreenshotScreen {
  home,
  formattedNote,
  checklist,
  cardStyle,
  starterTemplates,
  foldersSearch,
  reminderAgenda,
  voiceMemo,
}

class StoreScreenshotCaption {
  const StoreScreenshotCaption(this.heading, this.subtitle,
      {this.premiumQualifier});

  final String heading;
  final String subtitle;
  final String? premiumQualifier;
}

/// Synthetic, localized content shared by store captures on both platforms.
///
/// Media paths are references only. A capture that includes a photo or recording
/// must supply its own real sample file or the corresponding preview builder.
class StoreScreenshotContent {
  const StoreScreenshotContent(this.language);

  final StoreScreenshotLanguage language;

  static final referenceTime = DateTime(2026, 10, 8, 10);
  static const photoPath = 'note_images/store-photo.jpg';
  static const voicePath = 'note_audio/store-voice.m4a';
  static const voiceDurationMs = 42000;
  static const personalFolderId = 'store-personal';
  static const ideasFolderId = 'store-ideas';
  static const journalNoteId = 'store-journal';
  static const checklistNoteId = 'store-weekend';
  static const voiceNoteId = 'store-voice';

  DateTime get nowDate => referenceTime;
  String get searchFolderId => personalFolderId;

  String get outputCode => switch (language) {
        StoreScreenshotLanguage.english => 'en',
        StoreScreenshotLanguage.simplifiedChinese => 'zh-Hans',
        StoreScreenshotLanguage.traditionalChinese => 'zh-Hant',
      };

  Locale get locale => switch (language) {
        StoreScreenshotLanguage.english => const Locale('en'),
        StoreScreenshotLanguage.simplifiedChinese => const Locale('zh'),
        StoreScreenshotLanguage.traditionalChinese => const Locale('zh', 'HK'),
      };

  String _text(String english, String simplified, String traditional) =>
      switch (language) {
        StoreScreenshotLanguage.english => english,
        StoreScreenshotLanguage.simplifiedChinese => simplified,
        StoreScreenshotLanguage.traditionalChinese => traditional,
      };

  String get searchQuery => _text('weekend', '周末', '週末');

  List<Folder> get folders => [
        Folder(
            id: personalFolderId,
            name: _text('Personal', '生活', '生活'),
            sortOrder: 0),
        Folder(
            id: ideasFolderId, name: _text('Ideas', '灵感', '靈感'), sortOrder: 1),
      ];

  Note formattedNote({bool includePhoto = false}) {
    final opening =
        _text('A good day, in a few lines', '用几行文字，记下美好的一天', '用幾行文字，記下美好的一天');
    final first =
        _text('Read a chapter before coffee.', '喝咖啡前，先读一章书。', '喝咖啡前，先讀一章書。');
    final highlighted =
        _text('Take the long way home.', '绕一点路，慢慢回家。', '繞一點路，慢慢回家。');
    final third =
        _text('Save one idea worth exploring.', '留住一个值得探索的想法。', '留住一個值得探索的想法。');
    final secondHeading = _text('Tomorrow', '明天', '明天');
    final ending = _text('A quiet hour for the things that matter.',
        '留一个安静的小时，做真正想做的事。', '留一個安靜的小時，做真正想做的事。');
    final body =
        '$opening\n$first\n$highlighted\n$third\n\n$secondHeading\n$ending';
    final secondStart = body.indexOf(secondHeading);
    final highlightedStart = body.indexOf(highlighted);
    return Note(
      id: journalNoteId,
      title: _text('Little moments', '生活的小片刻', '生活的小片刻'),
      description: body,
      color: const Color(0xFFFFF4C2),
      dateTime: DateTime(2026, 10, 8, 9, 10),
      sortOrder: 0,
      folderId: personalFolderId,
      isPinned: true,
      textStyles: [
        NoteTextStyleRange(
            start: 0, end: opening.length, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(
            start: highlightedStart,
            end: highlightedStart + highlighted.length,
            kind: NoteTextStyleKind.highlight),
        NoteTextStyleRange(
            start: secondStart,
            end: secondStart + secondHeading.length,
            kind: NoteTextStyleKind.heading),
      ],
      imagePaths: includePhoto ? const [photoPath] : const [],
      imageLayouts: includePhoto
          ? [
              NoteImageLayout(
                  path: photoPath,
                  textOffset: secondStart,
                  widthFactor: .82,
                  xFactor: .5,
                  aspectRatio: 1.5)
            ]
          : const [],
    );
  }

  Note get checklistNote => Note(
        id: checklistNoteId,
        title: _text('A lovely weekend', '美好的周末', '美好的週末'),
        description: _text('A little time outdoors, a little time for myself.',
            '到户外走走，也留一点时间给自己。', '到戶外走走，也留一點時間給自己。'),
        color: const Color(0xFFD3EDE4),
        dateTime: DateTime(2026, 10, 8, 9, 20),
        sortOrder: 1,
        folderId: personalFolderId,
        todo: [
          Todo(
              id: 'store-weekend-coffee',
              title: _text('Find a new coffee spot', '找一家新的咖啡店', '找一家新的咖啡店'),
              completed: true),
          Todo(
              id: 'store-weekend-walk',
              title: _text('Walk by the sea', '去海边散步', '去海邊散步')),
          Todo(
              id: 'store-weekend-book',
              title: _text('Bring a good book', '带一本喜欢的书', '帶一本喜歡的書')),
          Todo(
              id: 'store-weekend-photo',
              title: _text('Take a photo of something lovely', '拍下一个美好的瞬间',
                  '拍下一個美好的瞬間')),
          Todo(
              id: 'store-weekend-journal',
              title: _text('Write a page before bed', '睡前写一页日记', '睡前寫一頁日記')),
        ],
      );

  /// A current library card for the appearance editor's live preview.
  Note get styleNote => checklistNote.copyWith(
        title: _text('Weekend', '周末', '週末'),
        description: _text('Slow down.', '慢下来。', '慢下來。'),
        todo: const [],
        cardStyle: const NoteCardStyle(
          fontFamily: 'Roboto',
          fontSize: AppFontSize.medium,
          cardSize: NoteCardSize.medium,
          paperStyle: NoteCardPaperStyle.textured,
          showDate: true,
        ),
      );

  Note get voiceNote => Note(
        id: voiceNoteId,
        title: _text('An idea on the go', '路上的灵感', '路上的靈感'),
        description: _text(
            'Thoughts for the weekend: a coastal walk and a small picnic.',
            '周末的想法：沿海边走走，再来一场小野餐。',
            '週末的想法：沿海邊走走，再來一場小野餐。'),
        color: const Color(0xFFD4E3F5),
        dateTime: DateTime(2026, 10, 8, 9, 30),
        sortOrder: 4,
        folderId: ideasFolderId,
        voiceMemos: [
          VoiceMemo(
            id: 'store-voice-recording',
            path: voicePath,
            durationMs: voiceDurationMs,
            createdAt: DateTime(2026, 10, 8, 9, 30),
            transcript: _text(
                'Let’s take the coastal path this weekend. '
                    'We can bring sandwiches and a flask of coffee. '
                    'Leave a little time to sit by the water. '
                    'I’ll pack a notebook for any ideas along the way.',
                '这个周末，沿海边的小路走走吧。'
                    '带上三明治和一壶咖啡。'
                    '留一点时间，坐在水边发会儿呆。'
                    '我会带一本笔记本，记下路上的灵感。',
                '這個週末，沿海邊的小路走走吧。'
                    '帶上三明治和一壺咖啡。'
                    '留一點時間，坐在水邊發會兒呆。'
                    '我會帶一本筆記本，記下路上的靈感。'),
          ),
        ],
      );

  List<Note> notes({bool includePhoto = false, bool includeVoice = true}) => [
        formattedNote(includePhoto: includePhoto),
        checklistNote,
        Note(
          id: 'store-reading',
          title: _text('Reading corner', '阅读角落', '閱讀角落'),
          description: _text(
              'One chapter, one new thought.\nKeep the lines I want to remember.',
              '读一章，收获一个新想法。\n留下想记住的句子。',
              '讀一章，收穫一個新想法。\n留下想記住的句子。'),
          color: const Color(0xFFE4D4F0),
          dateTime: DateTime(2026, 10, 8, 8, 50),
          sortOrder: 2,
          folderId: personalFolderId,
        ),
        Note(
          id: 'store-groceries',
          title: _text('For the kitchen', '厨房采购', '廚房採購'),
          description:
              _text('Little things for the weekend.', '周末需要的小东西。', '週末需要的小東西。'),
          color: const Color(0xFFFFE4C4),
          dateTime: DateTime(2026, 10, 8, 8, 40),
          sortOrder: 3,
          folderId: personalFolderId,
          todo: [
            Todo(
                id: 'store-groceries-coffee',
                title: _text('Coffee beans', '咖啡豆', '咖啡豆'),
                completed: true),
            Todo(
                id: 'store-groceries-bread',
                title: _text('Fresh bread', '新鲜面包', '新鮮麵包')),
            Todo(
                id: 'store-groceries-peaches',
                title: _text('Peaches', '桃子', '桃子')),
          ],
        ),
        if (includeVoice) voiceNote,
        Note(
          id: 'store-ideas-note',
          title: _text('Ideas to keep', '值得留下的灵感', '值得留下的靈感'),
          description: _text(
              'A photo journal.\nA weekend recipe.\nA letter to a friend.',
              '一本照片日记。\n一道周末食谱。\n一封写给朋友的信。',
              '一本照片日記。\n一道週末食譜。\n一封寫給朋友的信。'),
          color: const Color(0xFFF3D1E0),
          dateTime: DateTime(2026, 10, 8, 8, 30),
          sortOrder: 5,
          folderId: ideasFolderId,
        ),
      ];

  /// Use [referenceTime] in the injected agenda clock for stable date sections.
  List<Reminder> get reminders => [
        Reminder(
            noteId: 'store-groceries',
            reminderId: 7101,
            reminderDate: DateTime(2026, 10, 8, 12, 30)),
        Reminder(
            noteId: journalNoteId,
            reminderId: 7102,
            reminderDate: DateTime(2026, 10, 8, 20, 30),
            repeat: ReminderRepeat.daily),
        Reminder(
            noteId: checklistNoteId,
            reminderId: 7103,
            reminderDate: DateTime(2026, 10, 8, 17),
            repeat: ReminderRepeat.weekly),
      ];

  StoreScreenshotCaption caption(StoreScreenshotScreen screen,
      {bool ios = false}) {
    final premium = ios
        ? switch (screen) {
            StoreScreenshotScreen.cardStyle ||
            StoreScreenshotScreen.voiceMemo ||
            StoreScreenshotScreen.reminderAgenda =>
              'Premium',
            _ => null,
          }
        : null;
    final (heading, subtitle) = switch (screen) {
      StoreScreenshotScreen.home => (
          _text('Your day, in notes', '用笔记，记录每一天', '用筆記，記錄每一天'),
          _text('A welcoming place for thoughts, plans, and little lists.',
              '收好想法、计划和生活中的小清单。', '收好想法、計畫和生活中的小清單。')
        ),
      StoreScreenshotScreen.formattedNote => (
          _text('Write what matters', '写下重要的小事', '寫下重要的小事'),
          _text('Simple headings and highlights keep every note clear.',
              '简单的标题与高亮，让笔记更清楚。', '簡單的標題與螢光標記，讓筆記更清楚。')
        ),
      StoreScreenshotScreen.checklist => (
          _text('Small steps. Clear progress.', '一步一步，看见进度', '一步一步，看見進度'),
          _text('Check off tasks and put your list in the order you want.',
              '完成一项，勾选一项；顺序由你安排。', '完成一項，勾選一項；順序由你安排。')
        ),
      StoreScreenshotScreen.cardStyle => (
          _text('Make each card yours', '让每张卡片都有你的风格', '讓每張卡片都有你的風格'),
          _text('Choose a color, font, and size with a live preview.',
              '选择颜色、字体与大小，马上看到效果。', '選擇顏色、字體與大小，馬上看到效果。')
        ),
      StoreScreenshotScreen.starterTemplates => (
          _text('A good place to start', '从一个好模板开始', '從一個好範本開始'),
          _text('Plan a day, pack a bag, or start a shopping list.',
              '计划一天、整理行李，或列一份购物清单。', '規劃一天、整理行李，或列一份購物清單。')
        ),
      StoreScreenshotScreen.foldersSearch => (
          _text('Find the right note', '找到你需要的笔记', '找到你需要的筆記'),
          _text('Folders and search keep your ideas close at hand.',
              '用文件夹与搜索，让想法随手可得。', '用資料夾與搜尋，讓想法隨手可得。')
        ),
      StoreScreenshotScreen.reminderAgenda => (
          _text('Remember the little things', '记住生活中的小事', '記住生活中的小事'),
          _text('See upcoming reminders and open their notes in one tap.',
              '查看即将到来的提醒，轻点就能打开笔记。', '查看即將到來的提醒，輕點就能打開筆記。')
        ),
      StoreScreenshotScreen.voiceMemo => (
          _text('Keep a thought in your voice', '用声音，留下灵感', '用聲音，留下靈感'),
          _text('Attach a voice memo and listen when you need it.',
              '把语音备忘录附在笔记中，随时回听。', '把語音備忘錄附在筆記中，隨時回聽。')
        ),
    };
    return StoreScreenshotCaption(heading, subtitle, premiumQualifier: premium);
  }

  String heading(StoreScreenshotScreen screen, {bool ios = false}) =>
      caption(screen, ios: ios).heading;

  String subtitle(StoreScreenshotScreen screen, {bool ios = false}) {
    final copy = caption(screen, ios: ios);
    return copy.premiumQualifier == null
        ? copy.subtitle
        : '${copy.premiumQualifier} · ${copy.subtitle}';
  }
}
