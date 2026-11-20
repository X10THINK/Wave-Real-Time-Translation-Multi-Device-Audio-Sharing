import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/native/wave_native.dart';
import '../../../core/media/wave_media_playback.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../session_flow/flow_coordinator.dart';
import '../../../domain/models/wave_session.dart';

class WaveMediaScreen extends StatefulWidget {
  final bool movie;
  const WaveMediaScreen({super.key, this.movie = true});
  @override
  State<WaveMediaScreen> createState() => _WaveMediaScreenState();
}

class _WaveMediaScreenState extends State<WaveMediaScreen>
    with WidgetsBindingObserver {
  final media = WaveMediaPlayback.instance;
  String search = '', fit = 'fit';
  double? seeking;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    media.addListener(refresh);
    WaveNative.instance.addListener(refresh);
    media.refresh();
    if (!widget.movie)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) media.loadMusicLibrary();
      });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void pauseOwnVideo() {
    if (widget.movie && media.movie) media.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden)
      pauseOwnVideo();
    if (state == AppLifecycleState.resumed) media.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    media.removeListener(refresh);
    WaveNative.instance.removeListener(refresh);
    pauseOwnVideo();
    super.dispose();
  }

  String time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    final value = media.player?.value;
    final ready = value?.isInitialized == true && media.movie == widget.movie;
    final pos = ready ? value!.position : Duration.zero;
    final duration = ready ? value!.duration : Duration.zero;
    final max =
        duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final n = WaveNative.instance;
    final tracks =
        media.musicLibrary
            .where(
              (t) => '${t.title} ${t.artist}'.toLowerCase().contains(
                search.toLowerCase(),
              ),
            )
            .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie ? 'Video Player' : 'Music Player'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                WaveNote(
                  n.running && n.hosting
                      ? 'Sharing audio with your room. Video stays on this device.'
                      : n.running
                      ? 'Local playback only. The host controls shared audio.'
                      : 'Local playback only. Start a room to share audio.',
                ),
                if (!n.running)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: WavePrimaryButton(
                      title: 'Start Audio Sharing',
                      onPressed:
                          () => WaveFlow.start(context, WaveFeature.audio),
                    ),
                  ),
                const SizedBox(height: 16),
                if (widget.movie && ready) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: Colors.black,
                      child: AspectRatio(
                        aspectRatio: value!.aspectRatio.clamp(0.6, 2.5).toDouble(),
                        child: const AndroidView(viewType: 'wave/native_video'),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final mode in ['fit', 'fill', 'zoom'])
                        ChoiceChip(
                          label: Text(mode),
                          selected: fit == mode,
                          onSelected: (_) async {
                            await const MethodChannel(
                              'wave.native/commands',
                            ).invokeMethod('mediaFit', {'mode': mode});
                            if (mounted) setState(() => fit = mode);
                          },
                        ),
                      IconButton(
                        tooltip: 'Fullscreen',
                        icon: const Icon(Icons.fullscreen),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const _FullScreenWaveVideo(),
                              ),
                            ),
                      ),
                    ],
                  ),
                ] else
                  Icon(
                    widget.movie ? Icons.movie : Icons.library_music,
                    size: 72,
                  ),
                Text(
                  ready
                      ? media.fileName ?? 'Selected media'
                      : 'Choose ${widget.movie ? 'a video' : 'a track'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                WavePrimaryButton(
                  title: widget.movie ? 'Open Video' : 'Choose Audio File',
                  icon: Icons.folder_open,
                  onPressed:
                      media.loading
                          ? null
                          : () => media.pick(asMovie: widget.movie),
                ),
                if (media.loading || media.buffering)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(
                      semanticsLabel: 'Loading media',
                    ),
                  ),
                Slider(
                  label: '${time(pos)} of ${time(duration)}',
                  value: (seeking ?? pos.inMilliseconds.toDouble()).clamp(
                    0.0,
                    max,
                  ),
                  max: max,
                  onChanged: ready ? (v) => setState(() => seeking = v) : null,
                  onChangeEnd:
                      ready
                          ? (v) async {
                            setState(() => seeking = null);
                            await media.seek(Duration(milliseconds: v.round()));
                          }
                          : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(time(pos)), Text(time(duration))],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    IconButton(
                      tooltip: 'Back 10 seconds',
                      icon: const Icon(Icons.replay_10),
                      onPressed:
                          ready
                              ? () => media.seek(
                                Duration(
                                  milliseconds: (pos.inMilliseconds - 10000)
                                      .clamp(0, duration.inMilliseconds),
                                ),
                              )
                              : null,
                    ),
                    IconButton.filled(
                      tooltip: value?.isPlaying == true ? 'Pause' : 'Play',
                      icon: Icon(
                        value?.isPlaying == true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: ready ? media.toggle : null,
                    ),
                    IconButton(
                      tooltip: 'Forward 10 seconds',
                      icon: const Icon(Icons.forward_10),
                      onPressed:
                          ready
                              ? () => media.seek(
                                Duration(
                                  milliseconds: (pos.inMilliseconds + 10000)
                                      .clamp(0, duration.inMilliseconds),
                                ),
                              )
                              : null,
                    ),
                    PopupMenuButton<double>(
                      tooltip: 'Playback speed',
                      enabled: ready,
                      onSelected: media.setSpeed,
                      itemBuilder:
                          (_) => [
                            for (final v in [.5, .75, 1.0, 1.25, 1.5, 2.0])
                              PopupMenuItem(value: v, child: Text('$v×')),
                          ],
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text('${media.speed}×'),
                      ),
                    ),
                  ],
                ),
                if (media.error != null) WaveNote(media.error!),
                if (!widget.movie) ...[
                  const SizedBox(height: 20),
                  const WaveLabel('My Music'),
                  if (media.libraryLoading) const LinearProgressIndicator(),
                  if (!media.musicAccessGranted) ...[
                    const Text(
                      'Allow music access, or choose an individual file above.',
                    ),
                    WavePrimaryButton(
                      title: 'Allow Music Access',
                      onPressed:
                          media.libraryLoading
                              ? null
                              : () => media.loadMusicLibrary(),
                    ),
                    TextButton(
                      onPressed: n.openAppSettings,
                      child: const Text('Open App Permission Settings'),
                    ),
                  ] else ...[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search songs or artists',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => search = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${tracks.length} of ${media.musicLibrary.length} tracks',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh music',
                          onPressed: () => media.loadMusicLibrary(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    if (tracks.isEmpty && !media.libraryLoading)
                      const Text(
                        'No matching music. Try another search or choose a file.',
                      ),
                  ],
                ],
              ],
            ),
          ),
          if (!widget.movie && media.musicAccessGranted)
            SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final t = tracks[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(t.title),
                  subtitle: Text(t.artist),
                  trailing: const Icon(Icons.play_arrow),
                  enabled: !media.loading,
                  onTap: () async {
                    if (await media.openDeviceTrack(t)) await media.play();
                  },
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

/// Immersive media controls. The native surface is transferred (not duplicated)
/// when this route opens and returns to the inline player when it closes.
class _FullScreenWaveVideo extends StatefulWidget {
  const _FullScreenWaveVideo();
  @override
  State<_FullScreenWaveVideo> createState() => _FullScreenWaveVideoState();
}

class _FullScreenWaveVideoState extends State<_FullScreenWaveVideo> {
  double? _seekingMs;
  bool _controlsVisible = true;
  String _fit = 'fit';
  final _api = const MethodChannel('wave.native/commands');

  String _timestamp(Duration d) {
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    final min = (d.inMinutes % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$min:$sec' : '${d.inMinutes}:$sec';
  }

  Future<void> _setFit(String mode) async {
    try {
      await _api.invokeMethod<void>('mediaFit', {'mode': mode});
      if (mounted) setState(() => _fit = mode);
    } catch (e) {
      if (mounted) waveToast(context, 'Cannot change video fit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = WaveMediaPlayback.instance;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(
            color: Colors.black,
            child: AndroidView(viewType: 'wave/native_video'),
          )),
          // Touching the picture reveals or hides the playback chrome.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _controlsVisible = !_controlsVisible),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: media,
              builder: (context, _) {
                final current = media.player?.value;
                final ready = current?.isInitialized == true && media.movie;
                final duration = current?.duration ?? Duration.zero;
                final position = current?.position ?? Duration.zero;
                final maxMs = duration.inMilliseconds > 0
                    ? duration.inMilliseconds.toDouble() : 1.0;
                return IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _controlsVisible ? 1 : 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xD9000000), Color(0x00000000)],
                            ),
                          ),
                          child: Row(children: [
                            IconButton(
                              tooltip: 'Exit fullscreen',
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(
                              media.fileName ?? 'Now Playing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            )),
                            PopupMenuButton<String>(
                              tooltip: 'Video scaling',
                              icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
                              onSelected: _setFit,
                              itemBuilder: (_) => [
                                for (final mode in ['fit', 'fill', 'zoom'])
                                  PopupMenuItem(value: mode,
                                    child: Text('${mode == _fit ? '✓  ' : ''}${mode[0].toUpperCase()}${mode.substring(1)}')),
                              ],
                            ),
                          ]),
                        ),
                        const Spacer(),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xE8172932),
                            border: Border.all(color: const Color(0x556EDCD7)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF43E2D0),
                                inactiveTrackColor: const Color(0xFF6B8590),
                                thumbColor: const Color(0xFF78F1E3),
                              ),
                              child: Slider(
                                min: 0, max: maxMs,
                                value: (_seekingMs ?? position.inMilliseconds.toDouble()).clamp(0.0, maxMs),
                                onChanged: ready ? (v) => setState(() => _seekingMs = v) : null,
                                onChangeEnd: ready ? (v) async {
                                  setState(() => _seekingMs = null);
                                  await media.seek(Duration(milliseconds: v.round()));
                                } : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(_timestamp(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(_timestamp(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ]),
                            ),
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              IconButton(
                                color: Colors.white,
                                tooltip: 'Rewind 10 seconds',
                                icon: const Icon(Icons.replay_10_rounded),
                                onPressed: ready ? () => media.seek(Duration(
                                  milliseconds: (position.inMilliseconds - 10000).clamp(0, duration.inMilliseconds),
                                )) : null,
                              ),
                              IconButton.filled(
                                tooltip: current?.isPlaying == true ? 'Pause' : 'Play',
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF57DDCF),
                                  foregroundColor: const Color(0xFF12383F),
                                  minimumSize: const Size(54, 54),
                                ),
                                icon: Icon(current?.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                onPressed: ready ? media.toggle : null,
                              ),
                              IconButton(
                                color: Colors.white,
                                tooltip: 'Forward 10 seconds',
                                icon: const Icon(Icons.forward_10_rounded),
                                onPressed: ready ? () => media.seek(Duration(
                                  milliseconds: (position.inMilliseconds + 10000).clamp(0, duration.inMilliseconds),
                                )) : null,
                              ),
                              PopupMenuButton<double>(
                                tooltip: 'Playback speed',
                                enabled: ready,
                                icon: const Icon(Icons.speed_rounded, color: Colors.white),
                                onSelected: media.setSpeed,
                                itemBuilder: (_) => [
                                  for (final speed in [.5, .75, 1.0, 1.25, 1.5, 2.0])
                                    PopupMenuItem(value: speed, child: Text('${speed}×')),
                                ],
                              ),
                            ]),
                            if (media.buffering) const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
