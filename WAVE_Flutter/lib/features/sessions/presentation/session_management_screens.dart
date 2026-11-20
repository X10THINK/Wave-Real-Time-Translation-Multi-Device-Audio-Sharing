import '../../../core/native/wave_native.dart';
import '../../session_flow/presentation/live_network_widgets.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';
import '../../../state/wave_scope.dart';

class SessionDetailsScreen extends StatelessWidget {
  final String sessionId;
  final VoidCallback onResume, onParticipants, onExit;
  const SessionDetailsScreen({
    super.key,
    required this.sessionId,
    required this.onResume,
    required this.onParticipants,
    required this.onExit,
  });
  @override
  Widget build(BuildContext context) {
    final s = WaveScope.of(context).getSession(sessionId);
    if (s == null) return const WavePage(title: 'Session Unavailable');
    return WavePage(
      title: 'Session Details',
      subtitle: s.feature.label,
      children: [
        WaveGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  WaveIconTile(
                    icon: s.feature == WaveFeature.audio
                        ? Icons.headphones
                        : Icons.translate,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        color: WaveColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  WaveStatusBadge(
                    s.status.label,
                    color: s.status == SessionStatus.ended
                        ? WaveColors.muted
                        : WaveColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _row('Room Code', s.id),
              _row('Role', s.role.label),
              _row('Transfer Method', s.method.label),
              _row('Status', s.status.label),
              _row(
                'Connected devices',
                '${s.isActive ? WaveNative.instance.connected : s.participants}',
              ),
              _row('Started', _stamp(s.createdAt)),
              if (s.feature == WaveFeature.audio)
                _row('Audio Source', s.audioSource.label),
              if (s.feature == WaveFeature.translation) ...[
                _row('Source Language', s.sourceLanguage),
                _row('Listening Language', s.targetLanguage),
              ],
            ],
          ),
        ),
        const SizedBox(height: 17),
        if (s.isActive)
          WaveOptionTile(
            title: 'Participants',
            subtitle: 'People and join requests',
            icon: Icons.group_rounded,
            onTap: onParticipants,
          ),
        if (s.isActive) ...[
          WavePrimaryButton(
            title: 'Resume Session',
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
          ),
          const SizedBox(height: 12),
          WavePrimaryButton(
            title: s.role == SessionRole.host ? 'End Session' : 'Leave Session',
            destructive: true,
            onPressed: onExit,
          ),
        ],
        const SizedBox(height: 13),
        const WaveNote(
          'Connection state is reported by Android native transport. Live Translation API is not configured in this build.',
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: WaveColors.muted, fontSize: 13),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: WaveColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  String _stamp(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class ParticipantsScreen extends StatelessWidget {
  final String sessionId;
  const ParticipantsScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) {
    final s = WaveScope.of(context).getSession(sessionId);
    return WavePage(
      title: 'Participants',
      subtitle: s?.name ?? 'Session',
      children: [
        const LiveNetworkPanel(showApproval: true),
        const SizedBox(height: 13),
        const WaveNote(
          'Join Approval requests are actionable in Wi-Fi/Hotspot mode; Bluetooth pairs are authorized through Android pairing and room-code checks.',
        ),
      ],
    );
  }
}

class SessionHistoryScreen extends StatelessWidget {
  final ValueChanged<WaveSession> onDetails;
  const SessionHistoryScreen({super.key, required this.onDetails});
  @override
  Widget build(BuildContext context) {
    final past = WaveScope.of(context).pastSessions;
    return WavePage(
      title: 'Session History',
      subtitle: 'Previously ended sessions',
      children: [
        if (past.isEmpty)
          const WaveEmptyState(
            icon: Icons.history_rounded,
            title: 'No Session History',
            subtitle: 'Your ended sessions will appear here.',
          ),
        for (final item in past)
          WaveOptionTile(
            title: item.name,
            subtitle: '${item.feature.label} • ${item.role.label} • ${item.id}',
            icon: item.feature == WaveFeature.audio
                ? Icons.headphones_rounded
                : Icons.translate_rounded,
            onTap: () => onDetails(item),
          ),
        const WaveNote(
          'Your most recent 100 sessions are stored only on this device.',
        ),
      ],
    );
  }
}

class ConnectionRecoveryScreen extends StatelessWidget {
  final String sessionId;
  final VoidCallback onRetry, onLeave;
  const ConnectionRecoveryScreen({
    super.key,
    required this.sessionId,
    required this.onRetry,
    required this.onLeave,
  });
  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Connection Recovery',
    subtitle: 'Network connection recovery',
    children: [
      const SizedBox(height: 35),
      const WaveGlassCard(
        colors: [Color(0xFFECFEFF), Color(0xFFA5EDEE)],
        child: Column(
          children: [
            SizedBox(height: 25),
            Icon(
              Icons.sensors_off_rounded,
              size: 86,
              color: WaveColors.deepTeal,
            ),
            SizedBox(height: 15),
            Text(
              'Connection Status',
              style: TextStyle(
                color: WaveColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'WAVE is checking its native transport and available peers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaveColors.muted),
            ),
            SizedBox(height: 23),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const LiveNetworkPanel(),
    ],
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WavePrimaryButton(
          title: 'Refresh Connection',
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
        const SizedBox(height: 11),
        WavePrimaryButton(
          title: 'Leave Session',
          outlined: true,
          onPressed: onLeave,
        ),
      ],
    ),
  );
}
