import '../../domain/models/wave_session.dart';
import '../../domain/repositories/session_repository.dart';

class InMemorySessionRepository implements SessionRepository {
  final List<WaveSession> _sessions = [];

  @override
  List<WaveSession> getAll() => List.unmodifiable(_sessions);

  @override
  WaveSession? findById(String id) {
    for (final s in _sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  void put(WaveSession session) {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
    } else {
      _sessions.insert(0, session);
    }
  }
}
