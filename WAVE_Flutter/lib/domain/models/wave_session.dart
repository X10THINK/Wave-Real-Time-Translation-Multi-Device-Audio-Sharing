enum WaveFeature { audio, translation }

enum TransferMethod { wifi, bluetooth, hotspot }

enum SessionRole { host, receiver }

enum SessionStatus { lobby, live, paused, reconnecting, ended }

enum AudioSource { microphone, music, video, deviceAudio }

extension FeatureLabel on WaveFeature {
  String get label =>
      this == WaveFeature.audio ? 'Audio Share' : 'Original Voice';
}

extension TransferLabel on TransferMethod {
  String get label {
    switch (this) {
      case TransferMethod.wifi:
        return 'Wi-Fi';
      case TransferMethod.bluetooth:
        return 'Bluetooth';
      case TransferMethod.hotspot:
        return 'Mobile Hotspot';
    }
  }
}

extension RoleLabel on SessionRole {
  String get label => this == SessionRole.host ? 'Host' : 'Receiver';
}

extension StatusLabel on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.lobby:
        return 'Lobby';
      case SessionStatus.live:
        return 'Live';
      case SessionStatus.paused:
        return 'Paused';
      case SessionStatus.reconnecting:
        return 'Reconnecting';
      case SessionStatus.ended:
        return 'Ended';
    }
  }
}

extension AudioSourceLabel on AudioSource {
  String get label {
    switch (this) {
      case AudioSource.microphone:
        return 'Microphone';
      case AudioSource.music:
        return 'Music Player';
      case AudioSource.video:
        return 'Video / Movie';
      case AudioSource.deviceAudio:
        return 'Device Audio';
    }
  }
}

class WaveTrack {
  final String title;
  final String artist;
  final Duration duration;
  const WaveTrack(this.title, this.artist, this.duration);
}

const localMediaPlaceholder = WaveTrack(
  'Select a local file',
  'Local media',
  Duration.zero,
);

class SessionDraft {
  final WaveFeature feature;
  TransferMethod? method;
  SessionRole? role;
  String roomName = '';
  String roomCode = '';
  String displayName = 'WAVE User';
  double volume = .8;
  String inviteSecret = ''; // Ephemeral 256-bit QR invitation secret
  int maxParticipants = 10;
  bool joinApproval = false;
  AudioSource audioSource = AudioSource.music;
  WaveTrack track = localMediaPlaceholder;
  String sourceLanguage = 'English';
  String targetLanguage = 'Tamil';
  bool translatedVoice = true;
  bool liveCaptions = true;
  bool speakingRequests = false;
  SessionDraft(this.feature);
}

class WaveSession {
  final String id;
  final String name;
  final WaveFeature feature;
  final TransferMethod method;
  final SessionRole role;
  final SessionStatus status;
  final DateTime createdAt;
  final int participants;
  final int maxParticipants;
  final bool joinApproval;
  final String hostName;
  final AudioSource audioSource;
  final WaveTrack track;
  final String sourceLanguage;
  final String targetLanguage;
  final bool translatedVoice;
  final bool liveCaptions;
  final bool speakingRequests;

  const WaveSession({
    required this.id,
    required this.name,
    required this.feature,
    required this.method,
    required this.role,
    required this.status,
    required this.createdAt,
    this.participants = 0,
    this.maxParticipants = 10,
    this.joinApproval = false,
    this.hostName = 'WAVE Host',
    this.audioSource = AudioSource.music,
    this.track = localMediaPlaceholder,
    this.sourceLanguage = 'English',
    this.targetLanguage = 'Tamil',
    this.translatedVoice = true,
    this.liveCaptions = true,
    this.speakingRequests = false,
  });

  bool get isActive => status != SessionStatus.ended;

  WaveSession copyWith({
    SessionStatus? status,
    int? participants,
    SessionRole? role,
    String? name,
    AudioSource? audioSource,
    String? targetLanguage,
  }) => WaveSession(
    id: id,
    name: name ?? this.name,
    feature: feature,
    method: method,
    role: role ?? this.role,
    status: status ?? this.status,
    createdAt: createdAt,
    participants: participants ?? this.participants,
    maxParticipants: maxParticipants,
    joinApproval: joinApproval,
    hostName: hostName,
    audioSource: audioSource ?? this.audioSource,
    track: track,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    translatedVoice: translatedVoice,
    liveCaptions: liveCaptions,
    speakingRequests: speakingRequests,
  );
}
