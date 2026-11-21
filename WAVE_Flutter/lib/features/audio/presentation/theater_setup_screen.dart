import 'package:flutter/material.dart';
import '../../../core/native/wave_native.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';

/// Theater positioning is not the channel-split DSP. Do not claim surround
/// playback until a verified multichannel distribution pipeline exists.
class TheaterPositions {
  static const names = [
    'Unassigned',
    'Front Left',
    'Front Right',
    'Center',
    'Surround Left',
    'Surround Right',
    'Sub / LFE',
    'Rear Left',
    'Rear Right',
  ];
  static const hints = [
    'Awaiting Host assignment',
    'Place at front-left of viewer',
    'Place at front-right of viewer',
    'Place in front, center of viewer',
    'Place behind-left of viewer',
    'Place behind-right of viewer',
    'Place near center/front; phone speakers have limited low bass',
    'Place far behind-left of viewer',
    'Place far behind-right of viewer',
  ];
}

class WaveTheaterSetupScreen extends StatefulWidget {
  const WaveTheaterSetupScreen({super.key});
  @override
  State<WaveTheaterSetupScreen> createState() => _WaveTheaterSetupScreenState();
}

class _WaveTheaterSetupScreenState extends State<WaveTheaterSetupScreen> {
  final Set<String> pending = {};
  Future<void> assign(String id, int role) async {
    setState(() => pending.add(id));
    try {
      await WaveNative.instance.assignSpeaker(id, role);
      if (mounted)
        waveToast(context, 'Placement sent; receiver confirmation pending');
    } catch (e) {
      if (mounted) waveToast(context, 'Could not assign speaker: $e');
    } finally {
      if (mounted) setState(() => pending.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final native = WaveNative.instance;
    return WavePage(
      title: 'WAVE Theater Positions',
      subtitle: 'Host-controlled placement guide',
      children: [
        const WaveNote(
          'Speaker position assignment works for direct LAN participants and directly verified Bluetooth peers. This build does NOT yet split or distribute discrete surround audio channels; do not use as a finished theater system.',
        ),
        const SizedBox(height: 15),
        AnimatedBuilder(
          animation: native,
          builder: (context, _) {
            final peers = native.peers;
            return Column(
              children: [
                if (peers.isEmpty)
                  const WaveNote(
                    'Invite receiver phones first, then assign their positions.',
                  ),
                for (final peer in peers) ...[
                  Builder(
                    builder: (context) {
                      final id =
                          (native.currentMode == 'bluetooth'
                                  ? peer['address']
                                  : peer['id'])
                              ?.toString() ??
                          '';
                      final role = (peer['role'] as num?)?.toInt() ?? 0;
                      return WaveGlassCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.smartphone_rounded,
                                  color: WaveColors.deepTeal,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    id,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: WaveColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              key: ValueKey((id, role)),
                              initialValue: role,
                              decoration: const InputDecoration(
                                labelText: 'Speaker position',
                              ),
                              items: [
                                for (
                                  var i = 0;
                                  i < TheaterPositions.names.length;
                                  i++
                                )
                                  DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(TheaterPositions.names[i]),
                                  ),
                              ],
                              onChanged:
                                  pending.contains(id)
                                      ? null
                                      : (v) {
                                        if (v == null) return;

                                        assign(id, v);
                                      },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 11),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 15),
        const WaveNote(
          'Network Host/Relay/Receiver roles remain independent of theater speaker positions. Phone placement cannot be measured accurately from Wi-Fi/Bluetooth alone.',
        ),
      ],
    );
  }
}

class WaveReceiverPosition extends StatelessWidget {
  const WaveReceiverPosition({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: WaveNative.instance,
    builder: (context, _) {
      final role =
          ((WaveNative.instance.state['speakerRole'] as num?)?.toInt() ?? 0)
              .clamp(0, TheaterPositions.names.length - 1)
              .toInt();
      if (role == 0) return const SizedBox.shrink();
      return WaveGlassCard(
        child: Column(
          children: [
            const Text(
              'THEATER SPEAKER POSITION',
              style: TextStyle(color: WaveColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 7),
            Text(
              TheaterPositions.names[role],
              style: const TextStyle(
                color: WaveColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.place_rounded,
              color: WaveColors.deepTeal,
              size: 38,
            ),
            Text(
              TheaterPositions.hints[role],
              textAlign: TextAlign.center,
              style: const TextStyle(color: WaveColors.muted),
            ),
            const SizedBox(height: 6),
            const Text(
              'Position assigned — discrete channel audio is not enabled in this build.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: WaveColors.warning),
            ),
          ],
        ),
      );
    },
  );
}
