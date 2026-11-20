import 'package:flutter/material.dart';

import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';
import '../../../state/wave_scope.dart';

class SessionsDashboardScreen extends StatefulWidget {
  final ValueChanged<WaveSession> onResume;
  final ValueChanged<WaveSession> onDetails;
  final VoidCallback onHistory;
  const SessionsDashboardScreen({
    super.key,
    required this.onResume,
    required this.onDetails,
    required this.onHistory,
  });
  @override
  State<SessionsDashboardScreen> createState() =>
      _SessionsDashboardScreenState();
}

class _SessionsDashboardScreenState extends State<SessionsDashboardScreen> {
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final state = WaveScope.of(context);
    final all = state.activeSessions;
    final visible = all
        .where(
          (e) =>
              filter == 0 ||
              (filter == 1
                  ? e.role == SessionRole.host
                  : e.role == SessionRole.receiver),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
      children: [
        const WaveTopBar(),
        const SizedBox(height: 18),
        const Text(
          'Sessions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: WaveColors.ink,
          ),
        ),
        const Text(
          'Your ongoing, hosted and joined rooms.',
          style: TextStyle(color: WaveColors.muted),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            for (final (index, name) in [
              (0, 'All'),
              (1, 'Hosted'),
              (2, 'Joined'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: filter == index,
                    label: Text(name),
                    onSelected: (_) => setState(() => filter = index),
                    selectedColor: const Color(0xFFB7F6F3),
                    showCheckmark: false,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const WaveLabel('Ongoing Sessions'),
        if (visible.isEmpty)
          const WaveEmptyState(
            icon: Icons.sensors_off_rounded,
            title: 'No Ongoing Sessions',
            subtitle: 'Hosted and joined sessions will appear here.',
          ),
        for (final s in visible) ...[
          _SessionCard(
            s,
            onResume: () => widget.onResume(s),
            onDetails: () => widget.onDetails(s),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 15),
        WaveOptionTile(
          title: 'Session History',
          subtitle: 'Previously ended sessions',
          icon: Icons.history_rounded,
          onTap: widget.onHistory,
        ),
        const WaveNote(
          'Active Android audio streams run in a foreground service. Ending a session closes transport links.',
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WaveSession session;
  final VoidCallback onResume, onDetails;
  const _SessionCard(
    this.session, {
    required this.onResume,
    required this.onDetails,
  });
  @override
  Widget build(BuildContext context) => WaveGlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            WaveIconTile(
              icon: session.feature == WaveFeature.audio
                  ? Icons.headphones_rounded
                  : Icons.translate_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: const TextStyle(
                      color: WaveColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${session.feature.label} • ${session.role.label}',
                    style: const TextStyle(
                      color: WaveColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            WaveStatusBadge(
              session.status.label,
              color: session.status == SessionStatus.reconnecting
                  ? WaveColors.warning
                  : WaveColors.success,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${session.method.label}   •   Room ${session.id}',
          style: const TextStyle(color: WaveColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDetails,
                child: const Text('Details'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onResume,
                child: const Text('Resume'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
