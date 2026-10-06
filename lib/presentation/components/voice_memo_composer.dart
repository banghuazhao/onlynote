import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/services/voice_memo_service.dart';

Future<VoiceMemo?> showVoiceMemoComposer(
  BuildContext context, {
  VoiceMemoService? service,
  required Future<VoiceMemo> Function() createDraft,
  required Future<String> Function(String) resolvePath,
  required Future<VoiceMemo> Function(VoiceMemo) saveDraft,
  required Future<void> Function(VoiceMemo) discardDraft,
  Future<void> Function(VoiceMemo)? retainDraft,
}) =>
    showModalBottomSheet<VoiceMemo>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (_) => VoiceMemoComposer(
            service: service,
            createDraft: createDraft,
            resolvePath: resolvePath,
            saveDraft: saveDraft,
            discardDraft: discardDraft,
            retainDraft: retainDraft));

class VoiceMemoComposer extends StatefulWidget {
  const VoiceMemoComposer(
      {super.key,
      this.service,
      required this.createDraft,
      required this.resolvePath,
      required this.saveDraft,
      required this.discardDraft,
      this.retainDraft});
  final VoiceMemoService? service;
  final Future<VoiceMemo> Function() createDraft;
  final Future<String> Function(String) resolvePath;
  final Future<VoiceMemo> Function(VoiceMemo) saveDraft;
  final Future<void> Function(VoiceMemo) discardDraft;
  final Future<void> Function(VoiceMemo)? retainDraft;
  @override
  State<VoiceMemoComposer> createState() => _VoiceMemoComposerState();
}

class _VoiceMemoComposerState extends State<VoiceMemoComposer> {
  late final VoiceMemoService _service;
  final _transcript = TextEditingController();
  VoiceMemo? _draft;
  String? _absolutePath;
  String? _error;
  String? _locale;
  bool _busy = false;
  bool _closing = false;
  bool _transcribing = false;
  Future<void> _retains = Future.value();
  int _transcriptRevision = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? VoiceMemoService.instance;
    _service.state.addListener(_onState);
    unawaited(_service.init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _locale ??= locale.languageCode == 'zh'
        ? (locale.countryCode == 'HK' ? 'zh-HK' : 'zh-CN')
        : 'en-US';
  }

  void _onState() {
    if (!mounted || _closing) return;
    final state = _service.state.value;
    if (state.path == _absolutePath &&
        !state.recording &&
        state.durationMs > 0 &&
        _draft != null &&
        state.durationMs != _draft!.durationMs) {
      _draft = _draft!.copyWith(durationMs: state.durationMs);
      _retain();
    }
    setState(() {});
  }

  void _retain() {
    final memo = _draft;
    if (memo == null || widget.retainDraft == null) return;
    _retains = _retains
        .catchError((Object _) {})
        .then((_) => widget.retainDraft!(memo));
    unawaited(_retains.catchError((Object _) {
      if (mounted) setState(() => _error = S.of(context).Voice_Save_Failed);
    }));
  }

  String _mediaError(Object error, {bool transcription = false}) {
    final l10n = S.of(context);
    if (error is PlatformException) {
      if (error.code == 'permission_denied') {
        return l10n.Voice_Permission_Denied;
      }
      if (error.code == 'transcription_unavailable') {
        return l10n.Voice_Transcription_Unavailable;
      }
    }
    return transcription
        ? l10n.Voice_Transcription_Failed
        : l10n.Voice_Record_Failed;
  }

  Future<void> _record() async {
    if (_busy || _draft != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _draft = await widget.createDraft();
      _absolutePath = await widget.resolvePath(_draft!.path);
      await _service.startRecording(_absolutePath!);
    } catch (error) {
      if (_draft != null) {
        try {
          await widget.discardDraft(_draft!);
          _draft = null;
          _absolutePath = null;
        } catch (_) {
          /* Preserve the journal and allow explicit Cancel to retry. */
        }
      }
      if (mounted) _error = _mediaError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final duration = await _service.stopRecording();
      if (duration <= 0) throw PlatformException(code: 'invalid_audio');
      _draft = _draft!.copyWith(durationMs: duration);
      _retain();
      await _retains;
    } catch (error) {
      if (mounted) _error = _mediaError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play() async {
    try {
      if (_service.state.value.playing &&
          _service.state.value.path == _absolutePath) {
        await _service.pause();
      } else {
        await _service.play(_absolutePath!);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = S.of(context).Voice_Play_Failed);
      }
    }
  }

  Future<void> _transcribe() async {
    if (_transcribing || _busy || _absolutePath == null) return;
    final revision = _transcriptRevision;
    setState(() {
      _transcribing = true;
      _error = null;
    });
    try {
      final text = await _service.transcribe(_absolutePath!, locale: _locale);
      if (!mounted || _closing) return;
      // Don't replace text the user edited while recognition was in flight.
      if (_transcriptRevision == revision) {
        _transcript.text = text;
        _draft = _draft!.copyWith(transcript: text);
        _retain();
      }
    } catch (error) {
      if (mounted && !_closing) {
        _error = _mediaError(error, transcription: true);
      }
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _transcribing || _draft == null || _draft!.durationMs <= 0) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.stopPlayback();
      final text = _transcript.text.trim();
      _draft = _draft!.copyWith(
          transcript: text.isEmpty ? null : text,
          clearTranscript: text.isEmpty);
      _retain();
      await _retains;
      final saved = await widget.saveDraft(_draft!);
      if (!mounted) return;
      setState(() => _closing = true);
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) setState(() => _error = S.of(context).Voice_Save_Failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy || _closing) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.cancelTranscription();
      await _service.cancelRecording();
      await _service.stopPlayback();
      await _retains.catchError((Object _) {});
      if (_draft != null) await widget.discardDraft(_draft!);
      if (!mounted) return;
      setState(() => _closing = true);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = S.of(context).Voice_Discard_Failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _service.state.removeListener(_onState);
    _transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.tokens;
    final state = _service.state.value;
    final ownsSession = state.path == _absolutePath;
    final recording = ownsSession && state.recording;
    final ready = _draft != null && _draft!.durationMs > 0 && !recording;
    final duration = recording ? state.durationMs : _draft?.durationMs ?? 0;
    return PopScope(
        canPop: _closing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_cancel());
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              tokens.space4,
              tokens.space4,
              tokens.space4,
              tokens.space4 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
              child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.Voice_Memo, style: context.textStyles.titleLarge),
                  SizedBox(height: tokens.space2),
                  Text(l10n.Voice_Recording_Hint,
                      style: context.textStyles.bodyMedium),
                  SizedBox(height: tokens.space4),
                  Center(
                      child: Text(formatVoiceMemoDuration(duration),
                          key: const ValueKey('voice-duration'),
                          style: context.textStyles.headlineMedium)),
                  SizedBox(height: tokens.space3),
                  if (_draft == null)
                    FilledButton.icon(
                        key: const ValueKey('voice-record'),
                        onPressed: _busy ? null : _record,
                        icon: const Icon(Icons.mic_rounded),
                        label: Text(l10n.Voice_Record)),
                  if (recording)
                    FilledButton.icon(
                        key: const ValueKey('voice-stop'),
                        onPressed: _busy ? null : _stop,
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(l10n.Voice_Stop)),
                  if (ownsSession && state.interrupted && ready)
                    Padding(
                        padding: EdgeInsets.only(bottom: tokens.space3),
                        child: Text(l10n.Voice_Interrupted,
                            style: context.textStyles.bodySmall)),
                  if (ready) ...[
                    Wrap(
                        spacing: tokens.space2,
                        runSpacing: tokens.space2,
                        children: [
                          OutlinedButton.icon(
                              key: const ValueKey('voice-play'),
                              onPressed: _busy || _transcribing ? null : _play,
                              icon: Icon(ownsSession && state.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                              label: Text(ownsSession && state.playing
                                  ? l10n.Voice_Pause
                                  : l10n.Voice_Play)),
                          OutlinedButton.icon(
                              key: const ValueKey('voice-transcribe'),
                              onPressed:
                                  _busy || _transcribing ? null : _transcribe,
                              icon: _transcribing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.text_fields_rounded),
                              label: Text(_transcribing
                                  ? l10n.Voice_Transcribing
                                  : l10n.Voice_Transcribe)),
                        ]),
                    SizedBox(height: tokens.space3),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _locale,
                        decoration: InputDecoration(
                            labelText: l10n.Voice_Transcription_Language),
                        items: [
                          DropdownMenuItem(
                              value: 'en-US',
                              child: Text(l10n.Voice_Language_English,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'zh-CN',
                              child: Text(l10n.Voice_Language_Chinese,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'zh-HK',
                              child: Text(
                                  l10n.Voice_Language_Chinese_Traditional,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis))
                        ],
                        onChanged: _busy || _transcribing
                            ? null
                            : (value) => setState(() => _locale = value)),
                    SizedBox(height: tokens.space3),
                    TextField(
                        controller: _transcript,
                        key: const ValueKey('voice-transcript'),
                        minLines: 2,
                        maxLines: 6,
                        maxLength: 20000,
                        decoration: InputDecoration(
                            labelText: l10n.Voice_Review_Transcript,
                            hintText: l10n.Voice_Transcript_Hint),
                        onChanged: (text) {
                          _transcriptRevision++;
                          _draft = _draft!.copyWith(
                              transcript: text, clearTranscript: text.isEmpty);
                          _retain();
                        }),
                  ],
                  if (_error != null)
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: tokens.space3),
                        child: Text(_error!,
                            key: const ValueKey('voice-error'),
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: context.colors.error))),
                  SizedBox(height: tokens.space4),
                  Wrap(
                      alignment: WrapAlignment.end,
                      spacing: tokens.space2,
                      runSpacing: tokens.space2,
                      children: [
                        TextButton(
                            onPressed: _busy ? null : _cancel,
                            child: Text(l10n.Voice_Cancel)),
                        FilledButton(
                            key: const ValueKey('voice-save'),
                            onPressed: ready && !_busy && !_transcribing
                                ? _save
                                : null,
                            child: Text(l10n.Voice_Save)),
                      ]),
                ]),
          )),
        ));
  }
}
