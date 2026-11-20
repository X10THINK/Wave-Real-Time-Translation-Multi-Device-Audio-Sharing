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

  test('repository updates sessions without duplicate IDs', () {
    final repository = InMemorySessionRepository();

    final original = WaveSession(
      id: 'ROOM-101',
      name: 'Test Room',
      feature: WaveFeature.audio,
      method: TransferMethod.wifi,
      role: SessionRole.host,
      status: SessionStatus.lobby,
      createdAt: DateTime.utc(2026, 11, 20),
    );

    repository.put(original);
    repository.put(
      original.copyWith(
        status: SessionStatus.live,
        participants: 3,
      ),
    );

    expect(repository.getAll(), hasLength(1));
    expect(repository.findById('ROOM-101')?.status, SessionStatus.live);
    expect(repository.findById('ROOM-101')?.participants, 3);
    expect(repository.findById('UNKNOWN'), isNull);
    expect(() => repository.getAll().clear(), throwsUnsupportedError);
  });

  test('ended sessions cannot return to live through status update', () async {
    final controller = WaveController(InMemorySessionRepository());

    final draft = SessionDraft(WaveFeature.audio)
      ..roomName = 'Test Session'
      ..method = TransferMethod.wifi;

    final session = controller.createSession(
      draft,
      roomCode: 'ROOM-102',
    );

    controller.endSession(session.id);
    controller.changeStatus(session.id, SessionStatus.live);

    expect(controller.getSession(session.id)?.status, SessionStatus.ended);
    expect(controller.activeFor(WaveFeature.audio), isNull);
    expect(controller.pastSessions, hasLength(1));

    await controller.flush();
    controller.dispose();
  });


  test('host session metadata preserves draft translation preferences', () async {
    final controller = WaveController(InMemorySessionRepository());
    final draft = SessionDraft(WaveFeature.translation)
      ..roomName = 'Multilingual Discussion'
      ..method = TransferMethod.wifi
      ..sourceLanguage = 'Sinhala'
      ..targetLanguage = 'English'
      ..translatedVoice = false
      ..liveCaptions = false
      ..speakingRequests = true;

    final session = controller.createSession(draft, roomCode: 'HOST-TEST');

    expect(session.sourceLanguage, 'Sinhala');
    expect(session.targetLanguage, 'English');
    expect(session.translatedVoice, isFalse);
    expect(session.liveCaptions, isFalse);
    expect(session.speakingRequests, isTrue);

    await controller.flush();
    controller.dispose();
  });

  test('receiver session metadata preserves draft translation preferences', () async {
    final controller = WaveController(InMemorySessionRepository());
    final draft = SessionDraft(WaveFeature.translation)
      ..roomCode = 'RECV-TEST'
      ..method = TransferMethod.hotspot
      ..sourceLanguage = 'Sinhala'
      ..targetLanguage = 'English'
      ..translatedVoice = false
      ..liveCaptions = false
      ..speakingRequests = true;

    final session = controller.joinSession(draft);

    expect(session.sourceLanguage, 'Sinhala');
    expect(session.targetLanguage, 'English');
    expect(session.translatedVoice, isFalse);
    expect(session.liveCaptions, isFalse);
    expect(session.speakingRequests, isTrue);

    await controller.flush();
    controller.dispose();
  });

}
