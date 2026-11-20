import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave_flutter/data/repositories/in_memory_session_repository.dart';
import 'package:wave_flutter/domain/models/wave_session.dart';
import 'package:wave_flutter/state/wave_controller.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test('new host metadata is a lobby and can become live then ended', () {
    final state = WaveController(InMemorySessionRepository());
    final draft = SessionDraft(WaveFeature.audio)
      ..role = SessionRole.host
      ..method = TransferMethod.wifi
      ..roomName = 'Seminar';
    final session = state.createSession(draft);
    expect(session.name, 'Seminar');
    expect(session.role, SessionRole.host);
    expect(session.status, SessionStatus.lobby);
    expect(state.activeFor(WaveFeature.audio)?.id, session.id);
    state.changeStatus(session.id, SessionStatus.live);
    expect(state.getSession(session.id)?.status, SessionStatus.live);
    state.endSession(session.id);
    expect(state.activeFor(WaveFeature.audio), isNull);
    expect(state.pastSessions.length, 1);
    state.dispose();
  });

  test('verified transport join creates receiver session metadata', () {
    final state = WaveController(InMemorySessionRepository());
    final draft = SessionDraft(WaveFeature.translation)
      ..method = TransferMethod.hotspot
      ..role = SessionRole.receiver
      ..roomCode = 'TEST-123'
      ..targetLanguage = 'Tamil';
    final s = state.joinSession(draft);
    expect(s.role, SessionRole.receiver);
    expect(s.feature, WaveFeature.translation);
    expect(s.id, 'TEST-123');
    expect(s.participants, 0);
    state.dispose();
  });
}
