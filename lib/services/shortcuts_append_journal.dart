/// Shared with startup draft recovery so an interrupted capture stays under its
/// transaction's conflict checks instead of being replayed as ordinary typing.
const shortcutAppendJournalPrefix = '_shortcuts_append_v1.';

Set<String> shortcutAppendPendingNoteIds(Map<dynamic, dynamic> entries) => {
      for (final entry in entries.entries)
        if (entry.key is String &&
            (entry.key as String).startsWith(shortcutAppendJournalPrefix))
          if (entry.value case final Map record)
            if (record['noteId'] case final String id) id,
    };
