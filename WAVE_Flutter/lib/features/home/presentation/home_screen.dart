import 'package:flutter/material.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';
import '../../../state/wave_scope.dart';

class WaveHomeScreen extends StatelessWidget {
  final VoidCallback onAudio;
  final VoidCallback onTranslate;
  final VoidCallback onMusic;
  final VoidCallback onSessions;
  final VoidCallback onCreate;
  final VoidCallback onProfile;
  const WaveHomeScreen({
    super.key,
    required this.onAudio,
    required this.onTranslate,
    required this.onMusic,
    required this.onSessions,
    required this.onCreate,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final state = WaveScope.of(context);
    final active = state.activeSessions;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
      children: [
        WaveTopBar(showProfile: true, onProfile: onProfile),
        const SizedBox(height: 26),
        Text(
          DateTime.now().hour < 12
              ? 'Good morning,'
              : DateTime.now().hour < 18
              ? 'Good afternoon,'
              : 'Good evening,',
          style: const TextStyle(color: WaveColors.muted, fontSize: 19),
        ),
        Text(
          '${state.displayName} 👋',
          style: const TextStyle(
            color: WaveColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Share audio and original speech\nwith nearby listeners.',
          style: TextStyle(color: WaveColors.muted, fontSize: 14, height: 1.35),
        ),
        const SizedBox(height: 23),
        _FeatureCard(
          title: 'Audio Share',
          caption: 'Broadcast your voice or\nmusic to multiple devices.',
          art: 'assets/images/headphones.png',
          colors: const [Color(0xFFFFFFFF), Color(0xFFDAF9F5)],
          onTap: onAudio,
        ),
        const SizedBox(height: 14),
        _FeatureCard(
          title: 'Live Translate',
          caption:
              'Tamil ↔ English speech translation.\nRequires configured cloud gateway.',
          art: 'assets/images/translate.png',
          colors: const [Color(0xFFFFFFFF), Color(0xFFE3FBF7)],
          onTap: onTranslate,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                'Music Player',
                'Play and share\nmusic in sessions.',
                'assets/images/music.png',
                const [Color(0xFFFFFFFF), Color(0xFFE8FAF7)],
                onMusic,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                'Sessions',
                'Create, join, and\nmanage sessions.',
                'assets/images/sessions.png',
                const [Color(0xFFFFFFFF), Color(0xFFE8FAF7)],
                onSessions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        WaveGlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const WaveIconTile(icon: Icons.sensors_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.isEmpty
                          ? 'No Active Session'
                          : '${active.length} Active Session${active.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: WaveColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      active.isEmpty
                          ? 'Create or join a session to get started.'
                          : '${active.first.feature.label} • ${active.first.status.label}',
                      maxLines: 2,
                      style: const TextStyle(
                        color: WaveColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: active.isEmpty ? onCreate : onSessions,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [WaveColors.deepTeal, const Color(0xFF007C78)],
                    ),
                  ),
                  child: Text(
                    active.isEmpty ? 'Create Session +' : 'View',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title, caption, art;
  final List<Color> colors;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.title,
    required this.caption,
    required this.art,
    required this.colors,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => WaveGlassCard(
    onTap: onTap,
    colors: colors,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    child: Row(
      children: [
        Image.asset(art, width: 128, height: 116, fit: BoxFit.contain),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: WaveColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                caption,
                style: const TextStyle(
                  color: WaveColors.muted,
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        const WavePearlIcon(
          icon: Icons.arrow_forward_rounded,
          size: 39,
        ),
      ],
    ),
  );
}

class _MiniCard extends StatelessWidget {
  final String title, caption, art;
  final List<Color> colors;
  final VoidCallback onTap;
  const _MiniCard(this.title, this.caption, this.art, this.colors, this.onTap);
  @override
  Widget build(BuildContext context) => WaveGlassCard(
    colors: colors,
    padding: const EdgeInsets.all(12),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(art, width: 45, height: 45, fit: BoxFit.contain),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: WaveColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: Text(
                caption,
                style: const TextStyle(
                  color: WaveColors.muted,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
            const WavePearlIcon(
              icon: Icons.arrow_forward_rounded,
              size: 35,
            ),
          ],
        ),
      ],
    ),
  );
}
