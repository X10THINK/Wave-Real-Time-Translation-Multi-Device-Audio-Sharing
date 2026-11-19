import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

/// Native Media3 playback persists across Flutter route/activity recreation.
/// OS force-stop / process death are NOT guaranteed to preserve playback.
class NativeMediaValue {
  final bool isInitialized, isPlaying;
  final Duration position, duration;
  final double aspectRatio;
  const NativeMediaValue({
    required this.isInitialized,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.aspectRatio,
  });
}

class NativeMediaController {
  NativeMediaValue value;
  NativeMediaController(this.value);
}

class WaveMediaPlayback extends ChangeNotifier {
  WaveMediaPlayback._() {
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => refresh(),
    );
  }
  static final WaveMediaPlayback instance = WaveMediaPlayback._();
  static const MethodChannel _native = MethodChannel('wave.native/commands');
  Timer? _pollTimer;
  NativeMediaController? player;
  String? fileName;
  String? nativeFile;
  bool movie = true, loading = false, buffering = false;
  double speed = 1;
  String? error;
  bool _changing = false, _polling = false;
  bool musicAccessGranted = false, libraryLoading = false;
  final List<WaveDeviceTrack> musicLibrary = [];
  static const audioExt = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
    'amr',
    'wma',
  };
  static const videoExt = {
    'mp4',
    'mkv',
    'webm',
    'mov',
    'm4v',
    '3gp',
    'avi',
    'ts',
  };

  Future<void> loadMusicLibrary({bool requestPermission = true}) async {
    if (libraryLoading) return;
    libraryLoading = true;
    error = null;
    notifyListeners();
    try {
      if (requestPermission) {
        musicAccessGranted =
            await _native.invokeMethod<bool>('musicPermission') ?? false;
      }
      if (!musicAccessGranted) {
        musicLibrary.clear();
        return;
      }
      final records =
          await _native.invokeListMethod<dynamic>('musicLibrary') ?? [];
      musicLibrary
        ..clear()
        ..addAll(
          records
              .whereType<Map>()
              .map(
                (m) => WaveDeviceTrack(
                  uri: (m['uri'] ?? '').toString(),
                  title: (m['title'] ?? 'Unknown track').toString(),
                  artist: (m['artist'] ?? '').toString(),
                  duration: Duration(
                    milliseconds: (m['durationMs'] as num?)?.toInt() ?? 0,
                  ),
                ),
              )
              .where((t) => t.uri.isNotEmpty),
        );
    } catch (e) {
      error = 'Music library unavailable: $e';
    } finally {
      libraryLoading = false;
      notifyListeners();
    }
  }

  Future<bool> openDeviceTrack(WaveDeviceTrack track) async =>
      openPath(track.uri, name: track.title, asMovie: false);

  Future<bool> openPath(
    String path, {
    required String name,
    required bool asMovie,
  }) async {
    if (_changing) return false;
    _changing = true;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _native.invokeMethod('mediaOpen', {
        'path': path,
        'title': name,
        'kind': asMovie ? 'video' : 'audio',
      });
      fileName = name;
      movie = asMovie;
      // Do not accidentally keep showing the previous media as ready.
      player = null;
      notifyListeners();
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await refresh();
        if (player?.value.isInitialized == true && nativeFile == path) break;
      }
      if (player?.value.isInitialized != true || nativeFile != path)
        throw StateError('Android player could not load this media');
      return true;
    } catch (e) {
      error = 'Cannot open media: $e';
      notifyListeners();
      return false;
    } finally {
      _changing = false;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_polling) return;
    _polling = true;
    try {
      final raw = await _native.invokeMapMethod<String, dynamic>('mediaState');
      if (raw == null) return;
      final priorMetadata =
          '$nativeFile|$movie|$fileName|$buffering|$error|$speed';
      nativeFile = (raw['file'] ?? '').toString();
      movie = raw['kind'] == 'video';
      fileName = raw['title']?.toString();
      buffering = raw['buffering'] == true;
      speed = (raw['speed'] as num?)?.toDouble() ?? 1;
      final nativeError = (raw['error'] ?? '').toString();
      if (nativeError.isNotEmpty) error = nativeError;
      final metadataChanged =
          priorMetadata !=
          '$nativeFile|$movie|$fileName|$buffering|$error|$speed';
      final initialized = raw['initialized'] == true;
      final state = NativeMediaValue(
        isInitialized: initialized,
        isPlaying: raw['isPlaying'] == true,
        position: Duration(
          milliseconds: (raw['positionMs'] as num?)?.toInt() ?? 0,
        ),
        duration: Duration(
          milliseconds: (raw['durationMs'] as num?)?.toInt() ?? 0,
        ),
        aspectRatio:
            ((raw['width'] as num?)?.toDouble() ?? 0) > 0 &&
                    ((raw['height'] as num?)?.toDouble() ?? 0) > 0
                ? (raw['width'] as num).toDouble() /
                    (raw['height'] as num).toDouble()
                : 16 / 9,
      );
      final old = player?.value;
      if (metadataChanged ||
          old == null ||
          old.isInitialized != state.isInitialized ||
          old.isPlaying != state.isPlaying ||
          (old.position - state.position).inMilliseconds.abs() > 350 ||
          old.duration != state.duration) {
        player = NativeMediaController(state);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Native media state: $e');
    } finally {
      _polling = false;
    }
  }

  Future<bool> pick({required bool asMovie}) async {
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: (asMovie ? videoExt : audioExt).toList(),
      );
      if (files == null || files.files.isEmpty) return false;
      final picked = files.files.single;
      final ext = picked.extension?.toLowerCase() ?? '';
      if (!(asMovie ? videoExt : audioExt).contains(ext)) {
        error = 'Choose a supported ${asMovie ? 'video' : 'audio'} file';
        notifyListeners();
        return false;
      }
      if (picked.path == null || picked.path!.isEmpty)
        throw StateError('Media path unavailable');
      return await openPath(picked.path!, name: picked.name, asMovie: asMovie);
    } catch (e) {
      error = 'Unable to select media: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> play() async {
    try {
      await _native.invokeMethod<void>('mediaPlay');
      await refresh();
    } catch (e) {
      error = 'Unable to play. Reopen the file and try again.';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (player?.value.isPlaying != true) return;
    try {
      await _native.invokeMethod<void>('mediaPause');
      await refresh();
    } catch (e) {
      error = 'Pause failed: $e';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    final current = player?.value;
    if (current?.isInitialized != true || _changing) return;
    try {
      await _native.invokeMethod(
        current!.isPlaying ? 'mediaPause' : 'mediaPlay',
      );
      await refresh();
    } catch (e) {
      error = 'Playback failed: $e';
      notifyListeners();
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _native.invokeMethod('mediaSpeed', {'speed': speed});
    } catch (e) {
      error = 'Speed control unavailable: $e';
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _native.invokeMethod('mediaSeek', {
        'position': position.inMilliseconds,
      });
      await refresh();
    } catch (e) {
      error = 'Seek failed: $e';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _native.invokeMethod('mediaStop');
      await refresh();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class WaveDeviceTrack {
  final String uri, title, artist;
  final Duration duration;
  const WaveDeviceTrack({
    required this.uri,
    required this.title,
    required this.artist,
    required this.duration,
  });
}
