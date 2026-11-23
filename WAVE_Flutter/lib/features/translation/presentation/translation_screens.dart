import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/native/wave_native.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../state/wave_scope.dart';
import '../../session_flow/presentation/live_network_widgets.dart';
import '../engine/microphone_input.dart';
import '../engine/models.dart';
import '../engine/session_controller.dart';
import '../engine/voice_output.dart';
import '../translation_configuration.dart';

const waveLanguages = <String>['English', 'Tamil'];

TranslationLanguage _lang(String value) => value == 'Tamil'
    ? TranslationLanguage.tamil : TranslationLanguage.english;

/// The WAVE session/network shell is kept intact. Only the former translation
/// placeholder is replaced by Sihan's microphone/gateway session controller.
class LiveTranslationHostScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback onEnd, onParticipants, onDetails;
  const LiveTranslationHostScreen({
    super.key, required this.sessionId, required this.onEnd,
    required this.onParticipants, required this.onDetails,
  });
  @override
  State<LiveTranslationHostScreen> createState() => _LiveTranslationHostScreenState();
}

class _LiveTranslationHostScreenState extends State<LiveTranslationHostScreen> {
  late final TranslationSessionController controller;
  Timer? _captionDebounce;
  String _lastObserved = '';
  String _lastShared = '';
  String? broadcastError;
  bool _initialized = false;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    controller = TranslationSessionController(
      microphone: RecordMicrophoneInput(),
      providerFactory: WaveTranslationConfiguration.create,
      voice: DeviceTranslatedVoiceOutput(),
      initialMockMode: WaveTranslationConfiguration.isDevelopmentMock,
    );
    // Host microphone must not hear its own translated TTS (feedback loop).
    controller.setVoiceEnabled(false);
    controller.addListener(_controllerChanged);
    WaveNative.instance.addListener(_onNativeSessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final s = WaveScope.of(context).getSession(widget.sessionId);
    if (s != null) {
      controller.setSource(_lang(s.sourceLanguage));
      controller.setTarget(_lang(s.targetLanguage));
    }
  }

  void _onNativeSessionChanged() {
    if (!WaveNative.instance.running || !WaveNative.instance.hosting ||
        WaveNative.instance.currentFeature != 'translation') {
      _captionDebounce?.cancel();
      if (controller.active) unawaited(controller.stop());
    }
  }

  void _controllerChanged() {
    if (!mounted) return;
    setState(() {});
    final segment = controller.latest;
    if (segment == null || segment.translated.trim().isEmpty) return;
    if (segment.isMock) return; // NEVER relay demo fixtures as real speech.
    final signature = '${segment.id}\u0000${segment.translated}';
    if (signature == _lastObserved) return;
    _lastObserved = signature;
    _captionDebounce?.cancel();
    // Realtime providers revise one stable caption ID many times; coalesce
    // transient deltas rather than reading every partial word on receivers.
    _captionDebounce = Timer(const Duration(milliseconds: 750), () {
      if (mounted && controller.active) unawaited(_shareLatest());
    });
  }

  Future<void> _shareLatest() async {
    final segment = controller.latest;
    if (segment == null || segment.translated.trim().isEmpty) return;
    final text = segment.translated.trim();
    if (text == _lastShared || !WaveNative.instance.running) return;
    if (WaveNative.instance.currentMode == 'bluetooth' &&
        utf8.encode(text).length > 360) {
      if (mounted) setState(() => broadcastError =
          'Bluetooth captions over 360 bytes need shorter speech segments.');
      return;
    }
    if (utf8.encode(text).length > 1200) {
      setState(() => broadcastError = 'Caption exceeds secure transport limit.');
      return;
    }
    try {
      await WaveNative.instance.broadcastTranslatedCaption(
        language: controller.target.code, text: text);
      _lastShared = text;
      if (mounted) setState(() => broadcastError = null);
    } catch (_) {
      if (mounted) setState(() => broadcastError =
          'Caption could not reach the room. Check the Host connection.');
    }
  }

  @override
  void dispose() {
    _captionDebounce?.cancel();
    controller.removeListener(_controllerChanged);
    WaveNative.instance.removeListener(_onNativeSessionChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = WaveScope.of(context).getSession(widget.sessionId);
    if (session == null) return const WavePage(title: 'Session unavailable');
    final active = controller.active;
    final latest = controller.latest;
    return WavePage(
      title: 'Live Translation · Host',
      subtitle: '${session.name} · ${session.method.label}',
      children: [
        WaveGlassCard(
          colors: const [Color(0xFFFFFFFF), Color(0xFFE0F9F5)],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.translate_rounded, color: WaveColors.deepTeal, size: 34),
              SizedBox(width: 12),
              Expanded(child: Text('Speech Translation', style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: WaveColors.ink))),
            ]),
            const SizedBox(height: 10),
            Text('${controller.source.label} → ${controller.target.label}',
              style: const TextStyle(color: WaveColors.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(active ? 'Translating microphone speech' : 'Microphone stopped',
                style: const TextStyle(color: WaveColors.muted)),
          ]),
        ),
        const SizedBox(height: 14),
        if (!WaveTranslationConfiguration.configured)
          const WaveNote('AI gateway is not configured. Live Translation cannot run until a trusted gateway endpoint is supplied.'),
        const WaveNote('Cloud speech translation requires internet access, a running gateway and explicit microphone consent. Audio Share does not require cloud access.'),
        if (WaveTranslationConfiguration.isDevelopmentMock)
          const WaveNote('DEVELOPER MOCK: captions are sample phrases, NOT recognized speech. Never present them as real translations.'),
        const SizedBox(height: 14),
        WaveGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WaveLabel('SPEAKING LANGUAGE'),
          DropdownButtonFormField<TranslationLanguage>(
            key: ValueKey('source-${controller.source.name}'),
            initialValue: controller.source,
            items: TranslationLanguage.values.map((value) =>
                DropdownMenuItem(value: value, child: Text(value.label))).toList(),
            onChanged: active ? null : (value) {
              if (value != null) controller.setSource(value);
            },
          ),
          const SizedBox(height: 12),
          const WaveLabel('TRANSLATE INTO'),
          DropdownButtonFormField<TranslationLanguage>(
            key: ValueKey('target-${controller.target.name}'),
            initialValue: controller.target,
            items: TranslationLanguage.values.map((value) =>
                DropdownMenuItem(value: value, child: Text(value.label))).toList(),
            onChanged: active ? null : (value) {
              if (value != null) controller.setTarget(value);
            },
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I consent to sending microphone audio to the translation gateway.'),
            value: _consent,
            onChanged: active ? null : (v) {
              setState(() => _consent = v == true);
              controller.setCloudConsentGiven(v == true);
            },
          ),
          WavePrimaryButton(
            title: active ? 'Stop Translation' : 'Start Translation',
            icon: active ? Icons.stop_rounded : Icons.mic_rounded,
            onPressed: active ? () => unawaited(controller.stop())
                : (WaveTranslationConfiguration.configured && _consent)
                    ? () => unawaited(controller.start()) : null,
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            WaveNote(controller.errorMessage!),
          ],
          if (broadcastError != null) ...[
            const SizedBox(height: 8),
            WaveNote(broadcastError!),
          ],
        ])),
        const SizedBox(height: 14),
        WaveGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WaveLabel('LIVE CAPTIONS'),
          const SizedBox(height: 8),
          Text(latest?.original.isNotEmpty == true ? latest!.original : 'Original speech will appear here.',
              style: const TextStyle(color: WaveColors.muted)),
          const SizedBox(height: 9),
          Text(latest?.translated.isNotEmpty == true ? latest!.translated : 'Translated captions will appear here.',
              style: const TextStyle(color: WaveColors.ink, fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 9),
          Text(controller.mockMode ? 'MOCK samples · not actual translation'
              : 'Translated captions broadcast to admitted receivers when available',
              style: const TextStyle(color: WaveColors.muted, fontSize: 12)),
        ])),
        const SizedBox(height: 12),
        const LiveNetworkPanel(showApproval: true),
        WaveOptionTile(title: 'Participants', subtitle: 'Manage connected receivers',
            icon: Icons.groups_rounded, onTap: widget.onParticipants),
        WaveOptionTile(title: 'Session Details', subtitle: 'Room and network settings',
            icon: Icons.info_outline_rounded, onTap: widget.onDetails),
        const SizedBox(height: 12),
        WavePrimaryButton(title: 'End Session', icon: Icons.stop_circle_rounded,
            destructive: true, onPressed: widget.onEnd),
      ],
    );
  }
}

class LiveTranslationReceiverScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback onLeave, onSpeak, onDetails;
  const LiveTranslationReceiverScreen({
    super.key, required this.sessionId, required this.onLeave,
    required this.onSpeak, required this.onDetails,
  });
  @override
  State<LiveTranslationReceiverScreen> createState() =>
      _LiveTranslationReceiverScreenState();
}

class _LiveTranslationReceiverScreenState extends State<LiveTranslationReceiverScreen> {
  final FlutterTts _tts = FlutterTts();
  String language = 'Tamil';
  bool _initialized = false;
  bool _voiceEnabled = false;
  bool muted = false;
  double volume = .8;
  int _lastRevision = 0;
  String _caption = '';
  String _broadcastLanguage = '';
  String? _voiceError;

  @override
  void initState() {
    super.initState();
    WaveNative.instance.addListener(_readCaption);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final s = WaveScope.of(context).getSession(widget.sessionId);
    language = s?.targetLanguage ?? 'Tamil';
    final state = WaveNative.instance.state;
    volume = (state['volume'] as num?)?.toDouble().clamp(0.0, 1.0)
        ?? WaveScope.of(context).defaultVolume;
    muted = state['playbackEnabled'] == false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readCaption();
    });
  }

  void _readCaption() {
    if (!mounted) return;
    final state = WaveNative.instance.state;
    if (state['running'] == false) {
      unawaited(_tts.stop());
      return;
    }
    if (state['feature'] != 'translation' || state['host'] == true ||
        state['joined'] != true) return;
    final revision = (state['translationRevision'] as num?)?.toInt() ?? 0;
    final text = (state['translationText'] as String?) ?? '';
    final incomingLanguage = (state['translationLanguage'] as String?) ?? '';
    if (revision <= _lastRevision || text.isEmpty) return;
    _lastRevision = revision;
    _broadcastLanguage = incomingLanguage;
    _caption = text;
    setState(() {});
    if (_voiceEnabled && !muted && incomingLanguage == _lang(language).code) {
      unawaited(_speak(text));
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(_lang(language).ttsLocale);
      await _tts.setSpeechRate(.48);
      await _tts.speak(text);
      if (mounted) setState(() => _voiceError = null);
    } catch (_) {
      if (mounted) setState(() => _voiceError =
          'Translated voice unavailable. Check Android language voice data.');
    }
  }

  @override
  void dispose() {
    WaveNative.instance.removeListener(_readCaption);
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WaveScope.of(context).getSession(widget.sessionId);
    if (s == null) return const WavePage(title: 'Session Unavailable');
    final selected = _lang(language).code;
    final compatible = _broadcastLanguage.isEmpty || _broadcastLanguage == selected;
    return WavePage(
      title: 'Live Translation · Receiver',
      subtitle: '${s.name} · ${s.method.label}',
      children: [
        WaveGlassCard(colors: const [Color(0xFFD6FDF9), Color(0xFF9DF4F0)],
            child: const Column(children: [
              Icon(Icons.headphones_rounded, size: 60, color: WaveColors.deepTeal),
              SizedBox(height: 9),
              Text('Live Translated Captions', style: TextStyle(
                color: WaveColors.ink, fontSize: 20, fontWeight: FontWeight.w800)),
            ])),
        const SizedBox(height: 14),
        WaveGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WaveLabel('PREFERRED LANGUAGE'),
          DropdownButtonFormField<String>(
            initialValue: language,
            items: waveLanguages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (value) {
              if (value == null) return;
              WaveScope.of(context).setSessionLanguage(widget.sessionId, value);
              unawaited(_tts.stop());
              setState(() => language = value);
            },
          ),
          const SizedBox(height: 12),
          if (!compatible)
            const WaveNote('The Host is broadcasting the other language. Ask the Host to select your language; per-receiver multi-language streams are not yet available.'),
          Text(compatible && _caption.isNotEmpty ? _caption
                  : 'Waiting for translated speech from the Host...',
              style: const TextStyle(color: WaveColors.ink,
                fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Speak translated captions'),
            subtitle: const Text('Uses Android text-to-speech on this phone'),
            value: _voiceEnabled,
            onChanged: (enabled) {
              if (!enabled) unawaited(_tts.stop());
              setState(() => _voiceEnabled = enabled);
            },
          ),
          if (_voiceError != null) WaveNote(_voiceError!),
        ])),
        const SizedBox(height: 12),
        WaveGlassCard(child: Row(children: [
          IconButton(tooltip: muted ? 'Unmute' : 'Mute',
            onPressed: () {
              setState(() => muted = !muted);
              if (muted) unawaited(_tts.stop());
              unawaited(WaveNative.instance.volume(volume, enabled: !muted));
            },
            icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded)),
          Expanded(child: Slider(value: volume, onChanged: (v) {
            setState(() { volume = v; muted = false; });
            unawaited(WaveNative.instance.volume(v));
          }, activeColor: WaveColors.deepTeal)),
          Text('${(muted ? 0 : volume * 100).round()}%'),
        ])),
        const SizedBox(height: 12),
        const LiveNetworkPanel(),
        WaveOptionTile(title: 'Session Details', subtitle: 'Room and network',
            icon: Icons.info_outline_rounded, onTap: widget.onDetails),
        const SizedBox(height: 12),
        WavePrimaryButton(title: 'Leave Session', icon: Icons.logout_rounded,
            destructive: true, onPressed: widget.onLeave),
      ],
    );
  }
}

class AuthorizedSpeakerScreen extends StatelessWidget {
  final VoidCallback onStop;
  const AuthorizedSpeakerScreen({super.key, required this.onStop});
  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Speaker Permission',
    children: [
      const WaveNote('Host-approved bidirectional translated Q&A requires verified speaker identity and upstream routing; this feature is not enabled yet.'),
      WavePrimaryButton(title: 'Back', onPressed: onStop),
    ],
  );
}
