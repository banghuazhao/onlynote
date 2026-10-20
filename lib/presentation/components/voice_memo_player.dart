import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_date_label.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/voice_memo_service.dart';
import 'package:onlynote/Tools/share_helper.dart';

class VoiceMemoPlayer extends StatefulWidget {
  const VoiceMemoPlayer(
      {super.key,
      required this.memo,
      required this.resolvePath,
      this.onRemove,
      this.onTranscriptChanged,
      this.onShare,
      this.transcriptBuilder,
      this.service});
  final VoiceMemo memo;
  final Future<String> Function(String) resolvePath;
  final Future<void> Function()? onRemove;
  final Future<void> Function(String?)? onTranscriptChanged;
  final Future<void> Function()? onShare;
  final VoiceMemoService? service;
  final Widget Function(String text)? transcriptBuilder;
  @override
  State<VoiceMemoPlayer> createState() => _VoiceMemoPlayerState();
}

class _VoiceMemoPlayerState extends State<VoiceMemoPlayer> {
  late final VoiceMemoService _service;
  String? _absolutePath;
  bool _busy = false;
  String? _error;
  final _menuKey = GlobalKey();
  int _memoRevision = 0;
  int _menuRevision = 0;

  bool _isCurrent(int revision) => mounted && revision == _memoRevision;

  void _releasePath(String? path) {
    if (path == null) return;
    unawaited(_service.stopPlaybackFor(path).catchError((Object error) {
      debugPrint('Recording playback cleanup deferred: $error');
    }));
    unawaited(_service.cancelTranscriptionFor(path).catchError((Object error) {
      debugPrint('Recording transcription cleanup deferred: $error');
    }));
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? VoiceMemoService.instance;
    _service.state.addListener(_changed);
    unawaited(_service.init());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _play() async {
    if (!mounted || _busy) return;
    final revision = _memoRevision;
    final memo = widget.memo;
    final resolvePath = widget.resolvePath;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = _absolutePath ?? await resolvePath(memo.path);
      if (!mounted || !_isCurrent(revision)) return;
      _absolutePath = path;
      if (_service.state.value.path == path && _service.state.value.playing) {
        await _service.pauseFor(path);
      } else {
        await _service.play(path);
      }
      if (!_isCurrent(revision)) _releasePath(path);
    } catch (_) {
      if (mounted && _isCurrent(revision)) {
        _error = S.of(context).Voice_Play_Failed;
      }
    } finally {
      if (_isCurrent(revision)) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    if (!mounted || _busy) return;
    final onRemove = widget.onRemove;
    if (onRemove == null) return;
    final revision = _memoRevision;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_absolutePath case final String path) {
        await _service.stopPlaybackFor(path);
      }
      if (!_isCurrent(revision)) return;
      await onRemove();
    } catch (_) {
      if (mounted && _isCurrent(revision)) {
        _error = S.of(context).Voice_Save_Failed;
      }
    } finally {
      if (_isCurrent(revision)) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (!mounted || _busy) return;
    final revision = _memoRevision;
    final memo = widget.memo;
    final onShare = widget.onShare;
    final resolvePath = widget.resolvePath;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = _absolutePath;
      if (path != null &&
          _service.state.value.path == path &&
          _service.state.value.playing) {
        await _service.pauseFor(path);
      }
      if (!mounted || !_isCurrent(revision)) return;
      if (onShare != null) {
        await onShare();
      } else {
        await ShareHelper.shareVoiceMemo(context, memo,
            resolvePath: resolvePath,
            sharePositionOrigin: ShareHelper.shareOriginFromKey(_menuKey));
      }
    } catch (_) {
      if (mounted && _isCurrent(revision)) {
        _error = S.of(context).Share_Audio_Failed;
      }
    } finally {
      if (_isCurrent(revision)) setState(() => _busy = false);
    }
  }

  Future<void> _editTranscript({String? initial, int? expectedRevision}) async {
    final revision = expectedRevision ?? _memoRevision;
    final onTranscriptChanged = widget.onTranscriptChanged;
    if (!mounted || !_isCurrent(revision) || onTranscriptChanged == null) {
      return;
    }
    final changed = await showVoiceTranscriptEditor(context,
        initial: initial ?? widget.memo.transcript ?? '');
    if (changed == null || !_isCurrent(revision)) return;
    try {
      await onTranscriptChanged(changed.isEmpty ? null : changed);
    } catch (_) {
      if (mounted && _isCurrent(revision)) {
        setState(() => _error = S.of(context).Voice_Save_Failed);
      }
    }
  }

  Future<void> _transcribe() async {
    if (!mounted || _busy || widget.onTranscriptChanged == null) return;
    final revision = _memoRevision;
    final memo = widget.memo;
    final resolvePath = widget.resolvePath;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = _absolutePath ?? await resolvePath(memo.path);
      if (!mounted || !_isCurrent(revision)) return;
      _absolutePath = path;
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode == 'zh'
          ? (locale.countryCode == 'HK' ? 'zh-HK' : 'zh-CN')
          : 'en-US';
      final text = await _service.transcribe(path, locale: language);
      if (_isCurrent(revision)) {
        await _editTranscript(initial: text, expectedRevision: revision);
      }
    } catch (error) {
      if (mounted && _isCurrent(revision)) {
        _error = error is PlatformException &&
                error.code == 'transcription_unavailable'
            ? S.of(context).Voice_Transcription_Unavailable
            : error is PlatformException && error.code == 'permission_denied'
                ? S.of(context).Voice_Permission_Denied
                : S.of(context).Voice_Transcription_Failed;
      }
    } finally {
      if (_isCurrent(revision)) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceMemoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.memo.id != oldWidget.memo.id ||
        widget.memo.path != oldWidget.memo.path) {
      _memoRevision++;
      _releasePath(_absolutePath);
      _absolutePath = null;
      _busy = false;
      _error = null;
    }
  }

  @override
  void dispose() {
    _service.state.removeListener(_changed);
    _memoRevision++;
    _releasePath(_absolutePath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.tokens;
    final state = _service.state.value;
    final active = _absolutePath != null && state.path == _absolutePath;
    final playing = active && state.playing;
    return Container(
      padding: EdgeInsets.all(tokens.space3),
      decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: BorderRadius.circular(tokens.radiusMedium)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconButton(
              onPressed: _busy ? null : _play,
              tooltip: playing ? l10n.Voice_Pause : l10n.Voice_Play,
              icon: Icon(playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded)),
          SizedBox(width: tokens.space2),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(l10n.Voice_Memo, style: context.textStyles.titleSmall),
                Text(
                    active
                        ? '${formatVoiceMemoDuration(state.positionMs)} / ${formatVoiceMemoDuration(widget.memo.durationMs)}'
                        : formatVoiceMemoDuration(widget.memo.durationMs),
                    style: context.textStyles.bodySmall),
                SizedBox(height: tokens.space1),
                VoiceMemoDateLabel(
                  createdAt: widget.memo.createdAt,
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ])),
          PopupMenuButton<String>(
              key: _menuKey,
              enabled: !_busy,
              onOpened: () => _menuRevision = _memoRevision,
              onSelected: (value) {
                if (_busy || !_isCurrent(_menuRevision)) return;
                if (value == 'share') unawaited(_share());
                if (value == 'remove') unawaited(_remove());
                if (value == 'transcript') unawaited(_editTranscript());
                if (value == 'transcribe') unawaited(_transcribe());
              },
              itemBuilder: (_) => [
                    PopupMenuItem(value: 'share', child: Text(l10n.Share)),
                    if (widget.onTranscriptChanged != null)
                      PopupMenuItem(
                          value: 'transcribe',
                          child: Text(l10n.Voice_Transcribe)),
                    if (widget.onTranscriptChanged != null)
                      PopupMenuItem(
                          value: 'transcript',
                          child: Text(l10n.Voice_Edit_Transcript)),
                    if (widget.onRemove != null)
                      PopupMenuItem(
                          value: 'remove', child: Text(l10n.Voice_Delete)),
                  ]),
        ]),
        if (active && state.durationMs > 0)
          Padding(
              padding: EdgeInsets.only(top: tokens.space2),
              child: LinearProgressIndicator(
                  value: (state.positionMs / state.durationMs).clamp(0, 1),
                  minHeight: 3)),
        if (widget.memo.transcript?.trim().isNotEmpty ?? false)
          Padding(
              padding: EdgeInsets.only(top: tokens.space3),
              child: widget.transcriptBuilder?.call(widget.memo.transcript!) ??
                  SelectableText(widget.memo.transcript!,
                      style: context.textStyles.bodyMedium)),
        if (_error != null)
          Padding(
              padding: EdgeInsets.only(top: tokens.space2),
              child: Text(_error!,
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: context.colors.error))),
      ]),
    );
  }
}

/// Opens the transcript draft, optionally focusing the selected search match.
///
/// The caller persists the returned text. Cancel leaves the transcript unchanged.
Future<String?> showVoiceTranscriptEditor(
  BuildContext context, {
  required String initial,
  TextSelection? selection,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) =>
          _VoiceTranscriptDialog(initial: initial, selection: selection),
    );

class _VoiceTranscriptDialog extends StatefulWidget {
  const _VoiceTranscriptDialog({required this.initial, this.selection});
  final String initial;
  final TextSelection? selection;
  @override
  State<_VoiceTranscriptDialog> createState() => _VoiceTranscriptDialogState();
}

class _VoiceTranscriptDialogState extends State<_VoiceTranscriptDialog> {
  late final TextEditingController _text;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initial);
    final selection = widget.selection;
    if (selection != null) {
      _text.selection = selection.copyWith(
        baseOffset: selection.baseOffset.clamp(0, widget.initial.length),
        extentOffset: selection.extentOffset.clamp(0, widget.initial.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(S.of(context).Voice_Review_Transcript),
        content: SizedBox(
            width: 420,
            child: TextField(
                key: const ValueKey('voice-transcript-editor-input'),
                controller: _text,
                autofocus: widget.selection != null,
                selectAllOnFocus: widget.selection == null ? null : false,
                minLines: 3,
                maxLines: 8,
                maxLength: 20000,
                decoration: InputDecoration(
                    hintText: S.of(context).Voice_Transcript_Hint))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).Voice_Cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, _text.text.trim()),
              child: Text(S.of(context).Voice_Save))
        ],
      );
}
