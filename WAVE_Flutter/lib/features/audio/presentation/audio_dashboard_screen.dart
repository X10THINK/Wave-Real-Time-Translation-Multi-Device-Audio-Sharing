import 'package:flutter/material.dart';
import '../../../core/native/wave_native.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';
import '../../../state/wave_scope.dart';

class AudioDashboardScreen extends StatelessWidget {
  final VoidCallback onStart;
  final ValueChanged<WaveSession> onResume;
  final ValueChanged<WaveSession> onDetails;
  const AudioDashboardScreen({
    super.key,
    required this.onStart,
    required this.onResume,
    required this.onDetails,
  });
  @override
  Widget build(BuildContext context) {
    final state = WaveScope.of(context);
    final item = state.activeFor(WaveFeature.audio);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
      children: [
        const WaveTopBar(),
        const SizedBox(height: 20),
        const Text(
          'Audio Share',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w900,
            color: WaveColors.ink,
          ),
        ),
        const Text(
          'Manage your audio sharing sessions.',
          style: TextStyle(color: WaveColors.muted),
        ),
        const SizedBox(height: 22),
        if (item == null) ...[
          WaveGlassCard(
            colors: const [Color(0xFFFFFFFF), Color(0xFFE0F9F5)],
            child: Column(
              children: [
                Image.asset(
                  'assets/images/headphones.png',
                  width: 195,
                  height: 154,
                  fit: BoxFit.contain,
                ),
                const Text(
                  'No Active Audio Session',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: WaveColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start sharing or join an existing room.',
                  style: TextStyle(color: WaveColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          WavePrimaryButton(
            title: 'Start Audio Share',
            icon: Icons.add_rounded,
            onPressed: onStart,
          ),
          const SizedBox(height: 20),
          const WaveNote(
            'Choose Wi-Fi, Bluetooth or Hotspot first. Then select Host or Receiver.',
          ),
        ] else ...[
          WaveGlassCard(
            colors: const [Color(0xFFFFFFFF), Color(0xFFE3FAF7)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/headphones.png',
                      width: 90,
                      height: 90,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WaveStatusBadge(item.status.label),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: WaveColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            item.id,
                            style: const TextStyle(
                              color: WaveColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 36,
                  alignment: Alignment.center,
                  child: const _DecorativeWaveform(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          WaveGlassCard(
            child: Row(
              children: [
                WaveMetric(
                  label: 'Role',
                  value: item.role.label,
                  icon: Icons.person_rounded,
                ),
                WaveMetric(
                  label: 'Method',
                  value: item.method.label,
                  icon: Icons.wifi_rounded,
                ),
                WaveMetric(
                  label: 'Listeners',
                  value: '${WaveNative.instance.connected}',
                  icon: Icons.group_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const WaveLabel('Quick Actions'),
          WavePrimaryButton(
            title: 'Resume Session',
            icon: Icons.play_arrow_rounded,
            onPressed: () => onResume(item),
          ),
          const SizedBox(height: 10),
          WavePrimaryButton(
            title: 'End & Start New Room',
            icon: Icons.add_rounded,
            outlined: true,
            onPressed: onStart,
          ),
          const SizedBox(height: 16),
          WaveOptionTile(
            title: 'Session Details',
            subtitle: 'Room info, connection and participants',
            icon: Icons.info_outline_rounded,
            onTap: () => onDetails(item),
          ),
          const WaveNote(
            'Session statistics come from native Android transport. Performance and multi-device sync depend on the phone and radio links.',
          ),
        ],
      ],
    );
  }
}

class _DecorativeWaveform extends StatelessWidget {
  const _DecorativeWaveform();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      27,
      (i) => Container(
        width: 3,
        height: 7 + (i * 17 % 23).toDouble(),
        margin: const EdgeInsets.symmetric(horizontal: 2.4),
        decoration: BoxDecoration(
          color: WaveColors.deepTeal.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    ),
  );
}
