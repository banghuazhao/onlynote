import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/premium_feature_gate.dart';
import 'package:onlynote/presentation/components/toast.dart';
import 'package:onlynote/services/markdown_import.dart';
import 'package:onlynote/services/markdown_import_files.dart';
import 'package:onlynote/services/markdown_import_service.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/premium_access.dart';

import 'markdown_import_content.dart';

MarkdownImportBatch _readPickedFiles(List<MarkdownImportPickedFile> files) {
  final docs = <MarkdownImportDocument>[];
  var skipped = 0;
  var expanded = 0;
  for (final file in files) {
    final batch = MarkdownImportReader.readBytes(file.name, file.bytes);
    docs.addAll(batch.documents);
    for (final document in batch.documents) {
      expanded += (document.note.description?.length ?? 0) * 2;
      for (final image in document.images) {
        expanded += image.bytes.length;
      }
    }
    if (expanded > MarkdownImportReader.maxExpandedBytes) {
      throw const FormatException('Combined import too large');
    }
    skipped += batch.skippedEmpty;
    if (docs.length > MarkdownImportReader.maxDocuments) {
      throw const FormatException('Too many notes');
    }
  }
  return MarkdownImportBatch(documents: docs, skippedEmpty: skipped);
}

class MarkdownImportScreen extends StatefulWidget {
  const MarkdownImportScreen(
      {super.key,
      this.pickFiles,
      this.readFiles,
      this.importDocuments,
      this.initialBatch,
      this.premiumAccess,
      this.noteCount});
  final Future<List<MarkdownImportPickedFile>> Function()? pickFiles;
  final Future<MarkdownImportBatch> Function(List<MarkdownImportPickedFile>)?
      readFiles;
  final Future<MarkdownImportResult> Function(List<MarkdownImportDocument>)?
      importDocuments;
  final MarkdownImportBatch? initialBatch;
  final PremiumAccess? premiumAccess;
  final int Function()? noteCount;

  @override
  State<MarkdownImportScreen> createState() => _MarkdownImportScreenState();
}

class _MarkdownImportScreenState extends State<MarkdownImportScreen> {
  late MarkdownImportBatch _batch =
      widget.initialBatch ?? const MarkdownImportBatch(documents: []);
  late Set<int> _selected = {
    for (var i = 0; i < _batch.documents.length; i++) i
  };
  late final MarkdownImportService _service = MarkdownImportService(
      repository: getIt<NoteRepository>(),
      imageStore: LocalMarkdownImportImageStore(),
      premiumAccess: widget.premiumAccess);
  late final VoidCallback _unregisterExit;
  bool _busy = false;
  bool _failed = false;
  bool get _canAct =>
      mounted && !_busy && ModalRoute.of(context)?.isCurrent == true;

  @override
  void initState() {
    super.initState();
    _unregisterExit =
        DesktopCommands.instance.registerEditor(() async => !_busy);
  }

  Future<void> _choose() async {
    if (!_canAct) return;
    setState(() => _busy = true);
    try {
      final files = await (widget.pickFiles ?? pickMarkdownImportFiles)();
      if (files.isEmpty || !mounted) return;
      final next = await (widget.readFiles?.call(files) ??
          compute(_readPickedFiles, files));
      if (!mounted) return;
      setState(() {
        _batch = next;
        _selected = {for (var i = 0; i < next.documents.length; i++) i};
        _failed = false;
      });
    } catch (_) {
      if (mounted) {
        context.showToast(S.of(context).Markdown_Import_Failed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _select(int index, bool value) {
    if (!_canAct) return;
    setState(() => value ? _selected.add(index) : _selected.remove(index));
  }

  void _toggleAll() {
    if (!_canAct) return;
    setState(() => _selected = _selected.length == _batch.documents.length
        ? {}
        : {for (var i = 0; i < _batch.documents.length; i++) i});
  }

  Future<void> _import() async {
    if (!_canAct || _selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      final selected = [
        for (var i = 0; i < _batch.documents.length; i++)
          if (_selected.contains(i)) _batch.documents[i]
      ];
      final access = widget.premiumAccess ?? PremiumAccess.instance;
      final count = (widget.noteCount ??
          () => NoteCreationLimit.count(getIt<NoteRepository>()))();
      final additions = widget.importDocuments == null
          ? _service.requiredNewNotes(selected)
          : selected.length;
      if (additions > 0 &&
          !access.allows(PremiumFeature.notes,
              currentCount: count + additions - 1)) {
        if (!mounted) return;
        final allowed = await ensurePremiumAccess(context, PremiumFeature.notes,
            currentCount: count + additions - 1, access: access);
        if (!mounted || !allowed || ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
      }
      final result =
          await (widget.importDocuments ?? _service.importDocuments)(selected);
      if (!mounted) return;
      if (result.failure == null && result.remaining.isEmpty) {
        setState(() {
          _busy = false;
          _batch = const MarkdownImportBatch(documents: []);
          _selected = {};
        });
        if (ModalRoute.of(context)?.isCurrent != true) return;
        context.showToast(S.of(context).Markdown_Import_Done);
        Navigator.pop(context, true);
      } else {
        setState(() {
          _batch = MarkdownImportBatch(documents: result.remaining);
          _selected = {for (var i = 0; i < result.remaining.length; i++) i};
          _failed = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _unregisterExit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: DeskSurface.colorOf(context),
          appBar: AppBar(title: Text(strings.Markdown_Import)),
          body: DeskSurface(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : MarkdownImportContent(
                      batch: _batch,
                      selected: _selected,
                      onSelected: _select,
                      onToggleAll: _toggleAll,
                      busy: _busy,
                      failed: _failed)),
          bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                            key: const ValueKey('markdown-import-choose'),
                            onPressed: _busy ? null : _choose,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(strings.Markdown_Import_Choose)),
                        FilledButton.icon(
                            key: const ValueKey('markdown-import-save'),
                            onPressed:
                                _busy || _selected.isEmpty ? null : _import,
                            icon: const Icon(Icons.note_add_outlined),
                            label: Text(strings.Markdown_Import_Import)),
                      ]))),
        ));
  }
}
