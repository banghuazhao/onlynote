import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';

String noteThemeLabel(NoteTheme theme, S strings) => switch (theme) {
      NoteTheme.classic => strings.Note_Theme_Classic,
      NoteTheme.sticky => strings.Note_Theme_Sticky,
      NoteTheme.legalPad => strings.Note_Theme_Legal_Pad,
      NoteTheme.ruledNotebook => strings.Note_Theme_Ruled_Notebook,
      NoteTheme.gridPaper => strings.Note_Theme_Grid_Paper,
      NoteTheme.dottedJournal => strings.Note_Theme_Dotted_Journal,
      NoteTheme.kraftNotebook => strings.Note_Theme_Kraft_Notebook,
      NoteTheme.parchment => strings.Note_Theme_Parchment,
    };
