import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/voice_memo_service.dart';

class VoiceMemoPlayer extends StatefulWidget {
  const VoiceMemoPlayer(
      {super.key,
      required this.memo,
      required this.resolvePath,
      this.onRemove,
      this.onTranscriptChanged,
      this.service});
  final VoiceMemo memo;
  final Future<String> Function(String) resolvePath;
  final Future<void> Function()? onRemove;
  final Future<void> Function(String?)? onTranscriptChanged;
  final VoiceMemoService? service;
  @override
  State<VoiceMemoPlayer> createState() => _VoiceMemoPlayerState();
}

class _VoiceMemoPlayerState extends State<VoiceMemoPlayer> {
  late final VoiceMemoService _service;
  String? _absolutePath;
  bool _busy = false;
  String? _error;
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
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _absolutePath ??= await widget.resolvePath(widget.memo.path);
      if (!mounted) return;
      if (_service.state.value.path == _absolutePath &&
          _service.state.value.playing) {
        await _service.pause();
      } else {
        await _service.play(_absolutePath!);
      }
    } catch (_) {
      if (mounted) _error = S.of(context).Voice_Play_Failed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_service.state.value.path == _absolutePath) {
        await _service.stopPlayback();
      }
      await widget.onRemove!();
    } catch (_) {
      if (mounted) _error = S.of(context).Voice_Save_Failed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editTranscript({String? initial}) async {
    final changed = await showDialog<String>(
        context: context,
        builder: (_) => _VoiceTranscriptDialog(
            initial: initial ?? widget.memo.transcript ?? ''));
    if (changed == null || !mounted) return;
    try {
      await widget.onTranscriptChanged!(changed.isEmpty ? null : changed);
    } catch (_) {
      if (mounted) setState(() => _error = S.of(context).Voice_Save_Failed);
    }
  }

  Future<void> _transcribe() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _absolutePath ??= await widget.resolvePath(widget.memo.path);
      if (!mounted) return;
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode == 'zh'
          ? (locale.countryCode == 'HK' ? 'zh-HK' : 'zh-CN')
          : 'en-US';
      final text = await _service.transcribe(_absolutePath!, locale: language);
      if (mounted) await _editTranscript(initial: text);
    } catch (error) {
      if (mounted) {
        _error = error is PlatformException &&
                error.code == 'transcription_unavailable'
            ? S.of(context).Voice_Transcription_Unavailable
            : error is PlatformException && error.code == 'permission_denied'
                ? S.of(context).Voice_Permission_Denied
                : S.of(context).Voice_Transcription_Failed;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceMemoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.memo.path != oldWidget.memo.path) _absolutePath = null;
  }

  @override
  void dispose() {
    _service.state.removeListener(_changed);
    if (_absolutePath != null && _service.state.value.path == _absolutePath) {
      unawaited(_service.stopPlayback());
    }
    if (_absolutePath != null) {
      unawaited(_service.cancelTranscriptionFor(_absolutePath!));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.tokens;
    final state = _service.state.value;
    final active = state.path == _absolutePath;
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
              ])),
          if (widget.onTranscriptChanged != null || widget.onRemove != null)
            PopupMenuButton<String>(
                enabled: !_busy,
                onSelected: (value) {
                  if (value == 'remove') unawaited(_remove());
                  if (value == 'transcript') unawaited(_editTranscript());
                  if (value == 'transcribe') unawaited(_transcribe());
                },
                itemBuilder: (_) => [
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
              child: SelectableText(widget.memo.transcript!,
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

class _VoiceTranscriptDialog extends StatefulWidget {
  const _VoiceTranscriptDialog({required this.initial});
  final String initial;
  @override
  State<_VoiceTranscriptDialog> createState() => _VoiceTranscriptDialogState();
}

class _VoiceTranscriptDialogState extends State<_VoiceTranscriptDialog> {
  late final TextEditingController _text;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initial);
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
                controller: _text,
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
