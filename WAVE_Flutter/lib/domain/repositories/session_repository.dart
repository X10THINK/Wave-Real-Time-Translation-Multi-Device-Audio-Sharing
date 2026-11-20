import '../models/wave_session.dart';

/// Contract isolates presentation from network / data implementation.
/// UI session metadata repository; the Android native transport owns live connections.
abstract class SessionRepository {
  List<WaveSession> getAll();
  void put(WaveSession session);
  WaveSession? findById(String id);
}
