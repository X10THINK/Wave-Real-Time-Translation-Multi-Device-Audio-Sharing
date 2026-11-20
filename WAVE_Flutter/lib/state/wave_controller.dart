import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/native/wave_native.dart';
import '../domain/models/wave_session.dart';
import '../domain/repositories/session_repository.dart';

class WaveController extends ChangeNotifier {
  final SessionRepository repository;
  final bool _observeNative;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<void> _saving = Future.value();
  bool _restoring = false;
  WaveController(this.repository, {bool observeNative = false})
    : _observeNative = observeNative {
    if (observeNative) WaveNative.instance.addListener(_onNativeChanged);
  }
  String displayName = 'WAVE User', defaultLanguage = 'Tamil';
  double defaultVolume = .8;
  bool introCompleted = false;
  List<WaveSession> get sessions => repository.getAll();
  List<WaveSession> get activeSessions =>
      sessions.where((s) => s.isActive).toList();
  List<WaveSession> get pastSessions =>
      sessions.where((s) => !s.isActive).toList();
  WaveSession? getSession(String id) => repository.findById(id);
  WaveSession? activeFor(WaveFeature feature) {
    for (final s in activeSessions) {
      if (s.feature == feature) return s;
    }
    return null;
  }

  SessionDraft draft(WaveFeature feature) =>
      SessionDraft(feature)
        ..displayName = displayName
        ..targetLanguage = defaultLanguage
        ..volume = defaultVolume;
  void _saveHistory() {
    if (_restoring) return;
    final data = jsonEncode(
      sessions
          .take(100)
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'feature': s.feature.name,
              'method': s.method.name,
              'role': s.role.name,
              'status': s.status.name,
              'created': s.createdAt.toIso8601String(),
              'participants': s.participants,
              'capacity': s.maxParticipants,
              'approval': s.joinApproval,
              'hostName': s.hostName,
              'source': s.audioSource.name,
              'language': s.targetLanguage,
            },
          )
          .toList(),
    );
    _saving = _saving
        .then((_) => _prefs.setString('sessions', data))
        .catchError((Object e) {
          debugPrint('History save: $e');
        });
  }

  void _onNativeChanged() {
    final n = WaveNative.instance;
    for (final s in activeSessions) {
      if (!n.running || n.currentRoom != s.id) {
        repository.put(s.copyWith(status: SessionStatus.ended));
        continue;
      }
      final st = n.state;
      final source = switch (n.captureSource) {
        'deviceAudio' => AudioSource.deviceAudio,
        'microphone' => AudioSource.microphone,
        _ => s.audioSource,
      };
      final status =
          !n.hosting && !n.joined
              ? SessionStatus.reconnecting
              : st['hostStreamPaused'] == true
              ? SessionStatus.paused
              : s.status == SessionStatus.lobby && n.captureSource == 'off'
              ? SessionStatus.lobby
              : SessionStatus.live;
      repository.put(
        s.copyWith(
          role: n.hosting ? SessionRole.host : SessionRole.receiver,
          status: status,
          participants: n.connected,
          audioSource: source,
          name:
              (st['sessionName'] as String?)?.isNotEmpty == true
                  ? st['sessionName'] as String
                  : null,
        ),
      );
    }
    // Save on state transitions, not on every audio statistics event.
    final signature = sessions
        .map(
          (s) =>
              '${s.id}:${s.status}:${s.role}:${s.name}:${s.audioSource}:${s.participants}',
        )
        .join('|');
    if (signature != _signature) {
      _signature = signature;
      _saveHistory();
      notifyListeners();
    }
  }

  String _signature = '';
  Future<void> restorePreferences() async {
    _restoring = true;
    try {
      displayName = await _prefs.getString('displayName') ?? 'WAVE User';
      final language = await _prefs.getString('language');
      defaultLanguage = language == 'English' ? 'English' : 'Tamil';
      defaultVolume = (await _prefs.getDouble('volume') ?? .8).clamp(0.0, 1.0);
      introCompleted = await _prefs.getBool('onboarded') ?? false;
      final raw = await _prefs.getString('sessions');
      if (raw != null) {
        try {
          for (final m in (jsonDecode(raw) as List).reversed) {
            repository.put(
              WaveSession(
                id: m['id'],
                name: m['name'],
                feature: WaveFeature.values.byName(m['feature']),
                method: TransferMethod.values.byName(m['method']),
                role: SessionRole.values.byName(m['role']),
                status: SessionStatus.values.byName(m['status']),
                createdAt: DateTime.parse(m['created']),
                participants: m['participants'] ?? 0,
                maxParticipants: m['capacity'] ?? 10,
                joinApproval: m['approval'] ?? false,
                hostName: m['hostName'] ?? 'Host',
                audioSource: AudioSource.values.byName(m['source'] ?? 'music'),
                targetLanguage: m['language'] ?? defaultLanguage,
              ),
            );
          }
        } catch (e) {
          debugPrint('Invalid saved history: $e');
        }
      }
      await WaveNative.instance.refresh();
      final n = WaveNative.instance;
      if (n.running && getSession(n.currentRoom)?.isActive != true) {
        final st = n.state;
        repository.put(
          WaveSession(
            id: n.currentRoom,
            name: st['sessionName']?.toString() ?? 'WAVE Room',
            feature:
                n.currentFeature == 'translation'
                    ? WaveFeature.translation
                    : WaveFeature.audio,
            method: TransferMethod.values.byName(n.currentMode),
            role: n.hosting ? SessionRole.host : SessionRole.receiver,
            status: SessionStatus.live,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (st['startedAt'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
            maxParticipants: (st['capacity'] as num?)?.toInt() ?? 10,
            joinApproval: st['approval'] == true,
          ),
        );
      }
      _onNativeChanged();
    } catch (e) {
      debugPrint('Restore: $e');
    } finally {
      _restoring = false;
      _saveHistory();
      notifyListeners();
    }
  }

  WaveSession createSession(SessionDraft d, {String? roomCode}) {
    final s = WaveSession(
      id: roomCode ?? 'WAVE-${DateTime.now().microsecondsSinceEpoch}',
      name: d.roomName.trim(),
      feature: d.feature,
      method: d.method ?? TransferMethod.wifi,
      role: d.role ?? SessionRole.host,
      status: SessionStatus.lobby,
      createdAt: DateTime.now(),
      maxParticipants: d.maxParticipants,
      joinApproval: d.joinApproval,
      hostName: displayName,
      audioSource: d.audioSource,
      targetLanguage: d.targetLanguage,
    );
    repository.put(s);
    _saveHistory();
    notifyListeners();
    return s;
  }

  WaveSession joinSession(SessionDraft d) {
    final st =
        _observeNative ? WaveNative.instance.state : const <String, dynamic>{};
    final s = WaveSession(
      id: d.roomCode,
      name:
          st['sessionName']?.toString().isNotEmpty == true
              ? st['sessionName'].toString()
              : 'WAVE Room',
      feature: d.feature,
      method: d.method ?? TransferMethod.wifi,
      role: SessionRole.receiver,
      status: SessionStatus.live,
      createdAt: DateTime.now(),
      targetLanguage: d.targetLanguage,
      sourceLanguage: d.sourceLanguage,
      maxParticipants: (st['capacity'] as num?)?.toInt() ?? 10,
      joinApproval: st['approval'] == true,
    );
    repository.put(s);
    _saveHistory();
    notifyListeners();
    return s;
  }

  void changeStatus(String id, SessionStatus status) {
    final s = getSession(id);
    if (s == null || !s.isActive) return;
    repository.put(s.copyWith(status: status));
    _saveHistory();
    notifyListeners();
  }

  void endSession(String id) => changeStatus(id, SessionStatus.ended);
  void setSessionLanguage(String id, String language) {
    final s = getSession(id);
    if (s == null) return;
    repository.put(s.copyWith(targetLanguage: language));
    _saveHistory();
    notifyListeners();
  }

  void setName(String next) {
    if (next.trim().isEmpty) return;
    displayName = next.trim();
    unawaited(_prefs.setString('displayName', displayName));
    notifyListeners();
  }

  void setLanguage(String next) {
    defaultLanguage = next;
    unawaited(_prefs.setString('language', next));
    notifyListeners();
  }

  void setVolume(double value) {
    defaultVolume = value.clamp(0, 1);
    unawaited(_prefs.setDouble('volume', defaultVolume));
    notifyListeners();
  }

  void completeIntro() {
    introCompleted = true;
    unawaited(_prefs.setBool('onboarded', true));
    notifyListeners();
  }

  Future<void> flush() => _saving;
  @override
  void dispose() {
    if (_observeNative) WaveNative.instance.removeListener(_onNativeChanged);
    super.dispose();
  }
}
