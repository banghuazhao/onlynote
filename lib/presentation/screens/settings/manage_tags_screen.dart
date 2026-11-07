import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/note_tag_editor.dart';
import 'package:onlynote/services/note_tag_management.dart';
import 'package:onlynote/services/note_tags.dart';

/// One tag spelling, with the notes that currently carry it.
class ManagedTag {
  const ManagedTag({required this.name, required this.count});
  final String name;
  final int count;

  String get key => tagKey(name);
}

/// Builds the tag catalog shown by [ManageTagsScreen].
///
/// Scope matches the library's own tag list: active and archived notes across
/// every folder. Repeated spellings of one tag count their note once, and the
/// first spelling stored is the one shown.
List<ManagedTag> managedTagsFromNotes(Iterable<NoteDto> notes) {
  final names = <String, String>{};
  final counts = <String, int>{};
  for (final note in notes) {
    if (note.isDeleted) continue;
    final seen = <String>{};
    for (final tag in note.tags ?? const <String>[]) {
      final name = normalizeTagName(tag);
      if (name.isEmpty) continue;
      final key = tagKey(name);
      names.putIfAbsent(key, () => name);
      if (seen.add(key)) counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  final tags = [
    for (final entry in names.entries)
      ManagedTag(name: entry.value, count: counts[entry.key] ?? 0),
  ]..sort((a, b) => a.key.compareTo(b.key));
  return List.unmodifiable(tags);
}

/// Filters the catalog by a search query, comparing it the way tags compare.
List<ManagedTag> filterManagedTags(List<ManagedTag> tags, String query) {
  final key = tagKey(query);
  if (key.isEmpty) return tags;
  return [
    for (final tag in tags)
      if (tag.key.contains(key)) tag,
  ];
}

/// Renames, merges, and removes tags across the whole library.
class ManageTagsScreen extends StatefulWidget {
  const ManageTagsScreen({super.key, this.editor, this.notes, this.revisions});

  /// Supplied by tests; the screen otherwise edits the stored library.
  final NoteTagEditor? editor;

  /// Reads the notes the catalog is built from. Defaults to stored notes.
  final List<NoteDto> Function()? notes;

  /// Notifies when stored notes change. Defaults to the notes box.
  final Listenable? revisions;

  @override
  State<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends State<ManageTagsScreen> {
  final _searchController = TextEditingController();

  /// The tag whose change is saving, so its own row shows the progress and
  /// every row's menu stays disabled until it finishes.
  String? _editingKey;

  /// The catalog is a pass over every stored note. Holding it means typing in
  /// the search field filters what is already built instead of reading the
  /// whole library again for each keystroke.
  List<ManagedTag>? _catalog;

  bool get _editing => _editingKey != null;

  late final NoteTagEditor _editor =
      widget.editor ?? NoteTagEditor(notes: getIt<NoteRepository>());

  // Subscribed to once. Building the box listenable inside build() would
  // resubscribe on every rebuild, including the rebuilds it causes.
  late final Listenable _revisions =
      widget.revisions ?? Hive.box(databaseBox).listenable();

  List<NoteDto> _notes() =>
      widget.notes?.call() ??
      Hive.box(databaseBox).values.whereType<NoteDto>().toList();

  @override
  void initState() {
    super.initState();
    _revisions.addListener(_onRevision);
  }

  @override
  void dispose() {
    _revisions.removeListener(_onRevision);
    _searchController.dispose();
    super.dispose();
  }

  void _onRevision() {
    if (mounted) setState(() => _catalog = null);
  }

  List<ManagedTag> _catalogue() => _catalog ??= managedTagsFromNotes(_notes());

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  /// Runs one tag change at a time: a second menu tap while a rename is
  /// saving would read the same notes and rewrite them from a stale list.
  Future<void> _apply(
    String key,
    Future<TagEditOutcome> Function() change,
    List<String> Function(List<String> tags) rewrite,
    String Function(S strings, int notes) message,
  ) async {
    if (_editing) return;
    setState(() => _editingKey = key);
    try {
      final outcome = await change();
      if (!mounted) return;
      final strings = S.of(context);
      final bloc = context.read<HomeBloc>();
      // Home keeps notes in memory; re-read them so the library, its tag
      // filters and its counts all show the new name.
      bloc.add(const HomeEvent.getAllNotes());
      _followSelectedTags(bloc, rewrite);
      if (!outcome.complete) {
        context.showToast(strings.Tag_Change_Incomplete, isError: true);
        return;
      }
      // The row the user tapped counts the tag's notes without Trash, so
      // report that same scope: a total including Trash reads as the number
      // changing on its own. Manage_Tags_Hint is what says Trash was
      // updated too.
      context.showToast(message(strings, outcome.libraryNotes));
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Tag_Change_Failed, isError: true);
      }
    } finally {
      // The notes box normally reports the change, but rebuild the catalog
      // here too so a finished edit always shows, whatever the store did.
      if (mounted) {
        setState(() {
          _catalog = null;
          _editingKey = null;
        });
      }
    }
  }

  /// Carries a library tag filter through the change the user just made.
  ///
  /// Without this, renaming the tag Home is filtering by would leave that
  /// filter pointing at a name no note carries — an empty library under a
  /// chip naming the old tag.
  void _followSelectedTags(
      HomeBloc bloc, List<String> Function(List<String> tags) rewrite) {
    final selected =
        bloc.state.mapOrNull(loaded: (state) => state.selectedTags.toList());
    if (selected == null || selected.isEmpty) return;
    final updated = rewrite(selected);
    if (sameNoteTags(selected, updated)) return;
    bloc.add(HomeEvent.tagsChanged(updated.toSet()));
  }

  Future<void> _rename(ManagedTag tag, List<ManagedTag> catalog) async {
    if (_editing) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => FolderNameDialog(
        title: S.of(context).Rename_Tag,
        initial: tag.name,
        labelText: S.of(context).Tag_Name,
        icon: Icons.sell_outlined,
      ),
    );
    if (name == null || !mounted) return;
    if (tagNameProblem(name) != null) {
      context.showToast(S.of(context).Tag_Name_Invalid, isError: true);
      return;
    }
    final replacement = normalizeTagName(name);
    if (replacement == tag.name) return;
    // Renaming onto a tag that already exists joins them. Say so first: the
    // other tag's notes change too, which the list alone does not show.
    if (tagKey(replacement) != tag.key &&
        catalog.any((value) => value.key == tagKey(replacement))) {
      final strings = S.of(context);
      final confirmed = await showConfirmDialog(
        context,
        title: strings.Tag_Merge_Confirm_Title,
        message: strings.Tag_Merge_Confirm_Message(replacement),
        confirmLabel: strings.Tag_Merge_Confirm_Action,
        icon: Icons.sell_outlined,
        destructive: false,
      );
      if (!confirmed || !mounted) return;
    }
    await _apply(
      tag.key,
      () => _editor.rename(from: tag.name, to: replacement),
      (tags) => renameTagIn(tags, from: tag.name, to: replacement),
      (strings, notes) => strings.Tag_Renamed_Count(notes),
    );
  }

  Future<void> _remove(ManagedTag tag) async {
    if (_editing) return;
    final strings = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.Remove_Tag,
      message: strings.Remove_Tag_Confirm_Message,
      confirmLabel: strings.Remove_Tag,
    );
    if (!confirmed || !mounted) return;
    await _apply(
      tag.key,
      () => _editor.remove(tag.name),
      (tags) => removeTagIn(tags, tag.name),
      (strings, notes) => strings.Tag_Removed_Count(notes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final countFormat = NumberFormat.decimalPattern(Intl.getCurrentLocale());

    return Scaffold(
      backgroundColor: DeskSurface.colorOf(context),
      appBar: AppBar(title: Text(strings.Manage_Tags)),
      body: DeskSurface(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
              child: Builder(
                builder: (context) {
                  final catalog = _catalogue();
                  final tags =
                      filterManagedTags(catalog, _searchController.text);
                  return ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      context.tokens.space4,
                      context.tokens.space2,
                      context.tokens.space4,
                      context.tokens.space6,
                    ),
                    itemCount: tags.isEmpty ? 2 : tags.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _header(catalog);
                      if (tags.isEmpty) return _empty(catalog);
                      final tag = tags[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            key: ValueKey('managed-tag-${tag.key}'),
                            leading: const Icon(Icons.sell_outlined),
                            title: SearchHighlight(tag.name,
                                query: _searchController.text,
                                overflow: TextOverflow.clip),
                            subtitle: Text(strings.Tag_Usage_Count(
                                tag.count, countFormat.format(tag.count))),
                            trailing: _editingKey == tag.key
                                ? const SizedBox(
                                    key: ValueKey('managed-tag-progress'),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : PopupMenuButton<_TagAction>(
                                    key:
                                        ValueKey('managed-tag-${tag.key}-menu'),
                                    tooltip: strings.Edit,
                                    enabled: !_editing,
                                    onSelected: (action) {
                                      switch (action) {
                                        case _TagAction.rename:
                                          _rename(tag, catalog);
                                        case _TagAction.remove:
                                          _remove(tag);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: _TagAction.rename,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                              Icons.drive_file_rename_outline),
                                          title: Text(strings.Rename_Tag),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _TagAction.remove,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.delete_outline,
                                              color: context.colors.error),
                                          title: Text(
                                            strings.Remove_Tag,
                                            style: TextStyle(
                                                color: context.colors.error),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(List<ManagedTag> catalog) {
    final strings = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            strings.Manage_Tags_Hint,
            key: const ValueKey('managed-tags-hint'),
            style: context.textStyles.bodySmall,
          ),
        ),
        if (catalog.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              key: const ValueKey('managed-tags-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: strings.Search_Tags,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('managed-tags-clear-search'),
                        tooltip: strings.Clear_Search,
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _empty(List<ManagedTag> catalog) => Padding(
        padding: EdgeInsets.all(context.tokens.space5),
        child: Semantics(
          liveRegion: catalog.isNotEmpty,
          child: Text(
            catalog.isEmpty
                ? S.of(context).No_Tags
                : S.of(context).Tags_Search_Empty,
            key: ValueKey(catalog.isEmpty
                ? 'managed-tags-empty'
                : 'managed-tags-search-empty'),
            textAlign: TextAlign.center,
            style: context.textStyles.bodyLarge,
          ),
        ),
      );
}

enum _TagAction { rename, remove }
