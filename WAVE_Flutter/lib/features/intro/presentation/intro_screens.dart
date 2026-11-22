import 'package:flutter/material.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_background.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../core/ui/wave_legacy_intro_widgets.dart';
import '../../../core/theme/wave_legacy_intro_theme.dart';

class WaveSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const WaveSplashScreen({super.key, required this.onFinished});
  @override
  State<WaveSplashScreen> createState() => _WaveSplashScreenState();
}

class _WaveSplashScreenState extends State<WaveSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: WaveBackground(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset('assets/images/wave_icon.png', height: 190, width: 190),
            const SizedBox(height: 10),
            const Text(
              'WAVE',
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: WaveColors.deepTeal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share Audio  •  Translate Live',
              style: TextStyle(color: WaveColors.muted, fontSize: 15),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: animation,
              builder:
                  (context, child) => SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(13, (i) {
                        final phase = (i % 4) / 4.0;
                        final level =
                            (.4 +
                                    .6 *
                                        (1 - (animation.value - phase).abs())
                                            .clamp(0.0, 1.0))
                                .toDouble();
                        return Container(
                          width: 5,
                          height: 8 + level * (i % 3 == 0 ? 26 : 16),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: WaveColors.teal.withValues(
                              alpha: .45 + level * .5,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        );
                      }),
                    ),
                  ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Starting WAVE...',
              style: TextStyle(
                color: WaveColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    ),
  );
}

class WaveOnboardingScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const WaveOnboardingScreen({super.key, required this.onContinue});
  @override
  Widget build(BuildContext context) => Theme(
    data: waveLegacyOnboardingTheme(),
    child: Scaffold(
    body: WaveBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'WAVE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: WaveColors.deepTeal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(onPressed: onContinue, child: const Text('Skip')),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Share Audio &\nConnect Locally',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 29,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: WaveColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Share music, movie audio or original speech with nearby listeners.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: WaveColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              WaveLegacyGlassCard(
                colors: const [Color(0xFFB0F8F5), Color(0xFFDEFAFF)],
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/headphones.png',
                      height: 155,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Audio Share',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: WaveColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Broadcast voice & music to listeners.',
                      style: TextStyle(color: WaveColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WaveLegacyGlassCard(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/translate.png',
                      width: 83,
                      height: 75,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Translate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: WaveColors.ink,
                            ),
                          ),
                          Text(
                            'Unavailable in this no-API edition.',
                            style: TextStyle(
                              color: WaveColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              WaveLegacyPrimaryButton(
                title: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
  );
}

class WavePermissionsScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const WavePermissionsScreen({super.key, required this.onContinue});
  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Permission Setup',
    subtitle: 'Allow access only when each feature needs it.',
    back: false,
    footer: WavePrimaryButton(
      title: 'Continue to WAVE',
      icon: Icons.arrow_forward_rounded,
      onPressed: onContinue,
    ),
    children: [
      const SizedBox(height: 12),
      Row(
        children: [
          Image.asset('assets/images/wave_icon.png', width: 64, height: 64),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Permissions are requested only when needed.',
              style: TextStyle(
                color: WaveColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      WaveOptionTile(
        title: 'Microphone',
        subtitle: 'Requested when you start speaking.',
        icon: Icons.mic_rounded,
        onTap:
            () => waveToast(
              context,
              'Microphone permission is requested in the native audio integration.',
            ),
      ),
      WaveOptionTile(
        title: 'Bluetooth / Nearby',
        subtitle: 'Requested when Bluetooth is selected.',
        icon: Icons.bluetooth_rounded,
        onTap:
            () => waveToast(
              context,
              'Bluetooth access will be requested by the native connectivity service.',
            ),
      ),
      WaveOptionTile(
        title: 'Camera',
        subtitle: 'Requested when scanning a QR code.',
        icon: Icons.camera_alt_rounded,
        onTap:
            () => waveToast(
              context,
              'Camera permission is requested by the QR scanning plugin when used.',
            ),
      ),
      WaveOptionTile(
        title: 'Music Files',
        subtitle: 'Requested when you choose local music.',
        icon: Icons.library_music_rounded,
        onTap:
            () => waveToast(
              context,
              'Android file picker opens local audio and movie files when selected.',
            ),
      ),
      const SizedBox(height: 10),
      const WaveNote(
        'Android permission prompts appear only when needed. Background audio uses a visible ongoing foreground service notification.',
      ),
    ],
  );
}
