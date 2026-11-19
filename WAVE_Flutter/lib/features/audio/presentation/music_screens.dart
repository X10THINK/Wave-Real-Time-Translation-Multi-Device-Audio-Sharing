import 'package:flutter/material.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';

class AudioSourceScreen extends StatefulWidget {
  final AudioSource initialSource;
  final WaveTrack initialTrack;
  final void Function(AudioSource, WaveTrack) onContinue;
  const AudioSourceScreen({
    super.key,
    required this.onContinue,
    this.initialSource = AudioSource.music,
    this.initialTrack = const WaveTrack(
      'Select a local file',
      'Local media',
      Duration.zero,
    ),
  });
  @override
  State<AudioSourceScreen> createState() => _AudioSourceScreenState();
}

class _AudioSourceScreenState extends State<AudioSourceScreen> {
  late AudioSource selected;
  late WaveTrack track;
  @override
  void initState() {
    super.initState();
    selected = widget.initialSource;
    track = widget.initialTrack;
  }

  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Audio Source',
    subtitle: 'Host • Choose what you want to share',
    children: [
      const SizedBox(height: 10),
      WaveOptionTile(
        title: 'Music Player',
        subtitle: 'Import a real audio file on the Host phone.',
        icon: Icons.music_note_rounded,
        selected: selected == AudioSource.music,
        onTap: () => setState(() => selected = AudioSource.music),
      ),
      WaveOptionTile(
        title: 'Video / Movie',
        subtitle: 'Host watches the video; receivers hear audio only.',
        icon: Icons.movie_rounded,
        selected: selected == AudioSource.video,
        onTap: () => setState(() => selected = AudioSource.video),
      ),
      WaveOptionTile(
        title: 'Device Audio',
        subtitle:
            'Capture permitted external app playback with Android consent.',
        icon: Icons.smartphone_rounded,
        selected: selected == AudioSource.deviceAudio,
        onTap: () => setState(() => selected = AudioSource.deviceAudio),
      ),
      const SizedBox(height: 12),
      const WaveNote(
        'After starting Host, imported WAVE Music/Movie streams audio directly. External apps such as Gallery need separate Android playback-capture permission.',
      ),
    ],
    footer: WavePrimaryButton(
      title: 'Continue',
      icon: Icons.arrow_forward_rounded,
      onPressed: () => widget.onContinue(selected, track),
    ),
  );
}
