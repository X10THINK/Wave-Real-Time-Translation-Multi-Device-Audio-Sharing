import 'package:flutter/material.dart';
import '../../../core/native/wave_native.dart';
import '../../../core/media/wave_media_playback.dart';
import 'theater_setup_screen.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';
import '../../../state/wave_scope.dart';
import '../../media/presentation/wave_media_screen.dart';
import '../../session_flow/presentation/live_network_widgets.dart';

class LiveAudioHostScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback onEnd, onParticipants, onDetails, onRecovery;
  const LiveAudioHostScreen({
    super.key,
    required this.sessionId,
    required this.onEnd,
    required this.onParticipants,
    required this.onDetails,
    required this.onRecovery,
  });
  @override
  State<LiveAudioHostScreen> createState() => _LiveAudioHostScreenState();
}

class _LiveAudioHostScreenState extends State<LiveAudioHostScreen> {
  String? error;
  bool playbackBusy = false;

  /// Media3 and shared room state must change together. The host can pause
  /// external capture delivery without pretending to pause the external app.
  Future<void> setRoomPlaying(bool play) async {
    if (playbackBusy) return;
    final native = WaveNative.instance;
    if (!native.hosting || !native.running || native.currentRoom != widget.sessionId) {
      waveToast(context, 'Host room is no longer active');
      return;
    }
    setState(() => playbackBusy = true);
    try {
      if (native.captureSource == 'internalMedia') {
        final media = WaveMediaPlayback.instance;
        if (media.player?.value.isInitialized != true) {
          throw StateError('Open a music or video file first');
        }
        if (play) await media.play();
        else await media.pause();
        // Wait until the native Media3 service has propagated its state.
        await native.refresh();
      } else if (native.captureSource == 'deviceAudio') {
        await native.roomPlayback(play);
      } else {
        throw StateError('Select a playable audio source first');
      }
      if (mounted) waveToast(context, play ? 'Shared playback resumed' : 'Shared playback paused');
    } catch (e) {
      if (mounted) waveToast(context, 'Playback control unavailable: $e');
    } finally {
      if (mounted) setState(() => playbackBusy = false);
    }
  }

  Future<void> enableCapture() async {
    try {
      await WaveNative.instance.captureDeviceAudio();
      await WaveNative.instance.refresh();
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WaveScope.of(context).getSession(widget.sessionId);
    if (s == null || !s.isActive)
      return const WavePage(
        title: 'Session Ended',
        children: [WaveNote('Return Home to start or join another room.')],
      );
    final native = WaveNative.instance;
    return WavePage(
      title: 'Live Audio • Host',
      subtitle: 'Real Android audio sharing session',
      children: [
        WaveGlassCard(
          colors: const [Color(0xFFFFFFFF), Color(0xFFE0F9F5)],
          child: Column(
            children: [
              const Icon(
                Icons.sensors_rounded,
                color: WaveColors.deepTeal,
                size: 60,
              ),
              const SizedBox(height: 8),
              Text(
                s.name,
                style: const TextStyle(
                  color: WaveColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Room: ${s.id}',
                style: const TextStyle(color: WaveColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: native,
          builder:
              (context, _) => WaveGlassCard(
                child: Row(
                  children: [
                    const WaveMetric(
                      label: 'Role',
                      value: 'Host',
                      icon: Icons.person_rounded,
                    ),
                    WaveMetric(
                      label: 'Method',
                      value: s.method.label,
                      icon: Icons.wifi_rounded,
                    ),
                    WaveMetric(
                      label: 'Peers',
                      value: '${native.connected}',
                      icon: Icons.group_rounded,
                    ),
                  ],
                ),
              ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: native,
          builder: (context, _) {
            final source = native.captureSource;
            final playable = source == 'internalMedia' || source == 'deviceAudio';
            final paused = native.state['hostStreamPaused'] == true;
            return WaveGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WaveLabel('Host Playback Controls'),
                  const SizedBox(height: 6),
                  Text(
                    !playable ? 'Select a source below to begin sharing' :
                    paused ? 'Room audio paused · connection stays active' :
                    'Room audio ready / sharing',
                    style: const TextStyle(color: WaveColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: playable && !playbackBusy ? () => setRoomPlaying(false) : null,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pause All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: playable && !playbackBusy ? () => setRoomPlaying(true) : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Resume All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('For one listener, open Participants & Controls below.',
                    style: TextStyle(color: WaveColors.muted, fontSize: 12)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        const WaveLabel('Choose Audio Source'),
        WaveOptionTile(
          title: 'Music Player',
          subtitle: 'Import local music and broadcast its audio',
          icon: Icons.library_music_rounded,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const WaveMediaScreen(movie: false),
                ),
              ),
        ),
        WaveOptionTile(
          title: 'Video Player',
          subtitle: 'Host sees video; receivers hear audio only',
          icon: Icons.movie_rounded,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const WaveMediaScreen(movie: true),
                ),
              ),
        ),
        WaveGlassCard(
          child: Column(
            children: [
              const WaveLabel('External App Audio Share'),
              AnimatedBuilder(
                animation: native,
                builder:
                    (context, _) => Text(
                      native.captureSource == 'deviceAudio'
                          ? 'Device audio capture active'
                          : 'Android MediaProjection consent is required',
                      style: const TextStyle(color: WaveColors.muted),
                    ),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: native,
                builder:
                    (context, _) => WavePrimaryButton(
                      title:
                          native.captureSource == 'deviceAudio'
                              ? 'Capture Active'
                              : 'Enable Supported Device Audio',
                      icon: Icons.cast_rounded,
                      onPressed:
                          native.captureSource == 'deviceAudio'
                              ? null
                              : enableCapture,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        WaveOptionTile(
          title: 'Theater Speaker Placement',
          subtitle:
              'Assign front/surround positions (multichannel engine not yet enabled)',
          icon: Icons.speaker_group_rounded,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const WaveTheaterSetupScreen(),
                ),
              ),
        ),
        const LiveNetworkPanel(showApproval: true),
        if (error != null) WaveNote('Capture error: $error'),
        const SizedBox(height: 12),
        WaveOptionTile(
          title: 'Invite / QR Code',
          subtitle: 'Share this existing session without restarting',
          icon: Icons.qr_code_2_rounded,
          onTap:
              () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                backgroundColor: const Color(0xFFEAFEFF),
                builder:
                    (_) => SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        children: [HostInviteCard(session: s)],
                      ),
                    ),
              ),
        ),
        WaveOptionTile(
          title: 'Participants & Controls',
          subtitle: 'Manage listeners, individual playback and join requests',
          icon: Icons.group_rounded,
          onTap: widget.onParticipants,
        ),
        WaveOptionTile(
          title: 'Session Details',
          subtitle: 'Room and network settings',
          icon: Icons.info_outline_rounded,
          onTap: widget.onDetails,
        ),
        const SizedBox(height: 14),
        const WaveNote(
          'Music and movies share audio automatically when playing. Only the Host sees the video.',
        ),
        const SizedBox(height: 12),
        WavePrimaryButton(
          title: 'Stop Shared Playback (Keep Room)',
          outlined: true,
          icon: Icons.stop_rounded,
          onPressed: () async {
            try {
              await WaveNative.instance.stopSharedAudio();
              await WaveMediaPlayback.instance.stop();
              if (context.mounted)
                waveToast(context, 'Audio stopped; session remains active');
            } catch (e) {
              if (context.mounted) waveToast(context, 'Cannot stop audio: $e');
            }
          },
        ),
        const SizedBox(height: 15),
        WavePrimaryButton(
          title: 'End Session',
          destructive: true,
          icon: Icons.stop_circle_rounded,
          onPressed: widget.onEnd,
        ),
      ],
    );
  }
}

class LiveAudioReceiverScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback onLeave, onDetails, onRecovery;
  const LiveAudioReceiverScreen({
    super.key,
    required this.sessionId,
    required this.onLeave,
    required this.onDetails,
    required this.onRecovery,
  });
  @override
  State<LiveAudioReceiverScreen> createState() =>
      _LiveAudioReceiverScreenState();
}

class _LiveAudioReceiverScreenState extends State<LiveAudioReceiverScreen> {
  double lastVolume = .8;
  double get volume =>
      (WaveNative.instance.state['volume'] as num?)?.toDouble() ?? .8;
  bool get localPaused => WaveNative.instance.state['playbackEnabled'] == false;
  bool get muted => volume == 0;
  Future<void> togglePause() async {
    try {
      await WaveNative.instance.volume(volume, enabled: localPaused);
      await WaveNative.instance.refresh();
    } catch (e) {
      if (mounted) waveToast(context, 'Could not change playback. Try again.');
    }
  }

  Future<void> setVolume(double next) async {
    try {
      await WaveNative.instance.volume(next, enabled: !localPaused);
      await WaveNative.instance.refresh();
    } catch (e) {
      if (mounted) waveToast(context, 'Could not change volume.');
    }
  }

  void mute() {
    if (!muted) {
      lastVolume = volume;
      setVolume(0);
    } else
      setVolume(lastVolume);
  }

  @override
  Widget build(BuildContext context) {
    final s = WaveScope.of(context).getSession(widget.sessionId);
    if (s == null || !s.isActive)
      return const WavePage(
        title: 'Session Ended',
        children: [WaveNote('Return Home to start or join another room.')],
      );
    final native = WaveNative.instance;
    return WavePage(
      title: 'Live Audio • Receiver',
      subtitle: 'Audio listening + adaptive relay',
      children: [
        WaveGlassCard(
          colors: const [Color(0xFFFFFFFF), Color(0xFFE3FAF7)],
          child: Column(
            children: [
              const Icon(
                Icons.headphones_rounded,
                color: WaveColors.deepTeal,
                size: 67,
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: native,
                builder:
                    (context, _) => Text(
                      !native.joined
                          ? 'Reconnecting…'
                          : native.state['hostStreamPaused'] == true
                          ? 'Host paused'
                          : native.state['playbackEnabled'] == false
                          ? 'Paused on this phone'
                          : native.state['volume'] == 0
                          ? 'Muted'
                          : (native.state['received'] as num? ?? 0) == 0
                          ? 'Waiting for host audio'
                          : 'Connected — Playing',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: WaveColors.ink,
                        fontSize: 21,
                      ),
                    ),
              ),
              const SizedBox(height: 5),
              Text(s.name, style: const TextStyle(color: WaveColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: native,
          builder: (context, _) {
            final hostPaused = native.state['hostStreamPaused'] == true;
            final hostMuted = native.state['hostPlaybackEnabled'] == false;
            final effectivePause = hostPaused || hostMuted || localPaused;
            return WaveGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WaveLabel('Audio Controls'),
                  if (hostPaused)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Host paused playback',
                        style: TextStyle(
                          color: WaveColors.deepTeal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (hostMuted && !hostPaused)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Host paused this receiver',
                        style: TextStyle(color: WaveColors.deepTeal),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: hostPaused || hostMuted ? null : togglePause,
                        tooltip:
                            hostPaused
                                ? 'Host has paused'
                                : hostMuted
                                ? 'Paused by Host'
                                : localPaused
                                ? 'Resume audio'
                                : 'Pause audio',
                        icon: Icon(
                          effectivePause
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: muted ? 'Unmute' : 'Mute',
                        onPressed: mute,
                        icon: Icon(
                          muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: volume,
                          activeColor: WaveColors.deepTeal,
                          onChanged: setVolume,
                        ),
                      ),
                      Text(
                        '${(muted ? 0 : volume * 100).round()}%',
                        style: const TextStyle(color: WaveColors.ink),
                      ),
                    ],
                  ),
                  const Text(
                    'Your local pause and volume do not affect anyone else or relay forwarding.',
                    style: TextStyle(color: WaveColors.muted, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 13),
        AnimatedBuilder(
          animation: native,
          builder:
              (context, _) =>
                  native.hosting
                      ? WaveGlassCard(
                        child: Column(
                          children: [
                            const WaveLabel('You are now Session Host'),
                            const Text(
                              'This phone became Host. Select a new media source to continue sharing.',
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 6),
                            WaveOptionTile(
                              title: 'Open Movie / Music Player',
                              subtitle: 'Choose a new local media source',
                              icon: Icons.movie,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => const WaveMediaScreen(
                                            movie: true,
                                          ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
        ),
        const WaveReceiverPosition(),
        const LiveNetworkPanel(),
        const SizedBox(height: 12),
        WaveOptionTile(
          title: 'Connection Recovery',
          subtitle: 'Review actual network state',
          icon: Icons.sync_problem_rounded,
          onTap: widget.onRecovery,
        ),
        const WaveNote(
          'Relay forwarding can continue when supported peers are linked and WAVE foreground service remains active. Receiver phones do not receive movie video.',
        ),
        const SizedBox(height: 15),
        WavePrimaryButton(
          title: 'Leave Session',
          destructive: true,
          icon: Icons.logout_rounded,
          onPressed: widget.onLeave,
        ),
      ],
    );
  }
}
