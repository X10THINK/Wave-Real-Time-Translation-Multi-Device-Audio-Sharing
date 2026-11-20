import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/native/wave_native.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';
import 'live_network_widgets.dart';

bool validInvite(String value) =>
    RegExp(r'^(W6:|WAVE4:)[A-Za-z0-9-]{4,12}(@[0-9.]+)?#[A-Za-z0-9_-]{22,43}$')
        .hasMatch(value);

/// Approved V3.1: each transport tile is a direct action; no extra Continue.
class TransferMethodScreen extends StatefulWidget {
  final WaveFeature feature;
  final ValueChanged<TransferMethod> onContinue;
  const TransferMethodScreen({
    super.key,
    required this.feature,
    required this.onContinue,
  });
  @override
  State<TransferMethodScreen> createState() => _TransferMethodScreenState();
}

class _TransferMethodScreenState extends State<TransferMethodScreen> {
  TransferMethod? selected;
  void choose(TransferMethod method) {
    if (widget.feature == WaveFeature.audio) {
      if (method == TransferMethod.hotspot) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hotspot device capacity is phone-dependent; WAVE prioritizes stable audio and sync over admitting more receivers.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
      widget.onContinue(method);
    } else
      setState(() => selected = method); // preserve Live Translation navigation
  }

  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Transfer Method',
    subtitle: '${widget.feature.label} • Choose local connectivity',
    children: [
      const SizedBox(height: 14),
      WaveOptionTile(
        title: 'Wi-Fi',
        subtitle: 'Share on a reachable Wi-Fi network.',
        icon: Icons.wifi_rounded,
        selected: selected == TransferMethod.wifi,
        onTap: () => choose(TransferMethod.wifi),
      ),
      WaveOptionTile(
        title: 'Bluetooth',
        subtitle: 'Direct Bluetooth with available paired relay links.',
        icon: Icons.bluetooth_rounded,
        selected: selected == TransferMethod.bluetooth,
        onTap: () => choose(TransferMethod.bluetooth),
      ),
      WaveOptionTile(
        title: 'Mobile Hotspot',
        subtitle:
            'No internet required for local audio. Capacity varies by device.',
        icon: Icons.settings_input_antenna_rounded,
        selected: selected == TransferMethod.hotspot,
        onTap: () => choose(TransferMethod.hotspot),
      ),
      const WaveNote(
        'Audio Share: tap a method to advance. Physical connection limits and audio quality depend on device capabilities.',
      ),
    ],
    footer: widget.feature == WaveFeature.translation
        ? WavePrimaryButton(
            title: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: selected == null
                ? null
                : () => widget.onContinue(selected!),
          )
        : null,
  );
}

class RoleSelectionScreen extends StatelessWidget {
  final TransferMethod method;
  final ValueChanged<SessionRole> onSelected;
  const RoleSelectionScreen({
    super.key,
    required this.method,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Select Your Role',
    subtitle: 'Selected: ${method.label}',
    children: [
      const SizedBox(height: 23),
      WaveOptionTile(
        title: 'Host',
        subtitle:
            'Create a session, invite listeners, then select the media source.',
        icon: Icons.cell_tower_rounded,
        onTap: () => onSelected(SessionRole.host),
      ),
      WaveOptionTile(
        title: 'Receiver',
        subtitle: 'Join an existing session and listen; relay when linked.',
        icon: Icons.headphones_rounded,
        onTap: () => onSelected(SessionRole.receiver),
      ),
      const WaveNote(
        'Relay runs automatically on a connected receiver where a forwarding route is available.',
      ),
    ],
  );
}

class CreateSessionScreen extends StatefulWidget {
  final TransferMethod method;
  final Future<void> Function(String, int, bool) onContinue;
  const CreateSessionScreen({
    super.key,
    required this.method,
    required this.onContinue,
  });
  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final room = TextEditingController(text: 'My WAVE Room');
  int maxUsers = 10;
  bool approval = false;
  bool busy = false;
  String? error;
  Future<void> submit() async {
    if (busy) return;
    if (room.text.trim().isEmpty || room.text.trim().length > 70) {
      setState(() => error = 'Use a room name between 1 and 70 characters.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onContinue(room.text.trim(), maxUsers, approval);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Create Session',
    subtitle: 'Host • ${widget.method.label}',
    children: [
      WaveGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaveField(
              controller: room,
              label: 'Room Name',
              hint: 'Enter session name',
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const WaveLabel('Maximum Participants'),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Fewer participants',
                  onPressed: () => setState(
                    () => maxUsers = (maxUsers - 1).clamp(1, 100).toInt(),
                  ),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$maxUsers',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WaveColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'More participants',
                  onPressed: () => setState(
                    () => maxUsers = (maxUsers + 1).clamp(1, 100).toInt(),
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              title: const Text('Join Approval'),
              subtitle: const Text(
                'Review join requests before allowing receivers.',
              ),
              value: approval,
              onChanged: (b) => setState(() => approval = b),
              activeThumbColor: WaveColors.teal,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      const WaveNote(
        'Your room opens first. Choose Music, Video or External App Audio from the Live Host screen. WAVE requests connection permissions when needed.',
      ),
    ],
    footer: WavePrimaryButton(
      title: busy ? 'Creating room…' : 'Create Room',
      icon: Icons.arrow_forward_rounded,
      onPressed: busy ? null : submit,
    ),
  );
}

class JoinSessionScreen extends StatefulWidget {
  final TransferMethod method;
  final Future<void> Function(String) onContinue;
  final VoidCallback onQr;
  const JoinSessionScreen({
    super.key,
    required this.method,
    required this.onContinue,
    required this.onQr,
  });
  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  bool busy = false;
  String? error;
  Future<void> join() async {
    if (busy) return;
    if (!validInvite(code.text.trim())) {
      setState(
        () => error = 'Paste the complete secure invitation from the host.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onContinue(code.text.trim());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Join Session',
    subtitle: 'Receiver • ${widget.method.label}',
    children: [
      WaveGlassCard(
        child: Column(
          children: [
            WaveField(
              controller: code,
              label: 'Secure Join Code',
              hint: 'W6:ROOM#secure-code',
            ),
            const SizedBox(height: 10),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            WavePrimaryButton(
              title: busy ? 'Joining…' : 'Join Room',
              icon: Icons.login_rounded,
              onPressed: busy ? null : join,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      WaveOptionTile(
        title: 'Scan QR Code',
        subtitle: 'Scan Host invitation to get code and IP address.',
        icon: Icons.qr_code_scanner_rounded,
        onTap: widget.onQr,
      ),
      const WaveNote(
        'Enter the compact Secure Join Code shown on Host, or scan its QR. Room ID by itself is not a secure invitation; Bluetooth also needs pairing.',
      ),
    ],
  );
}

class QrScannerScreen extends StatefulWidget {
  final ValueChanged<String> onManualCode;
  const QrScannerScreen({super.key, required this.onManualCode});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final code = TextEditingController();
  bool scanned = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void found(String raw) {
    if (scanned) return;
    if (!validInvite(raw)) {
      waveToast(context, 'Use the complete WAVE invitation from the host.');
      return;
    }
    scanned = true;
    Navigator.pop(context);
    widget.onManualCode(raw);
  }

  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Scan Host QR',
    subtitle: 'Scan the secure invitation',
    children: [
      SizedBox(
        height: 265,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final text = barcode.rawValue;
                if (text != null &&
                    (text.startsWith('W6:') || text.startsWith('WAVE4:'))) {
                  found(text);
                  break;
                }
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      WaveField(
        controller: code,
        label: 'Secure Join Code or Invitation',
        hint: 'W6:ROOM#secure-code',
      ),
      const SizedBox(height: 12),
      WavePrimaryButton(
        title: 'Use Code',
        onPressed: () {
          if (code.text.trim().isNotEmpty) found(code.text.trim());
        },
      ),
    ],
  );
}

class NetworkSetupScreen extends StatefulWidget {
  final TransferMethod method;
  final SessionRole role;
  final Future<void> Function() onContinue;
  const NetworkSetupScreen({
    super.key,
    required this.method,
    required this.role,
    required this.onContinue,
  });
  @override
  State<NetworkSetupScreen> createState() => _NetworkSetupScreenState();
}

class _NetworkSetupScreenState extends State<NetworkSetupScreen> {
  bool starting = false;
  Future<void> _startOnce() async {
    if (starting)
      return; // Rapid double taps must not start two native sessions.
    setState(() => starting = true);
    try {
      await widget.onContinue();
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    final role = widget.role;
    final icon = method == TransferMethod.wifi
        ? Icons.wifi_rounded
        : method == TransferMethod.hotspot
        ? Icons.settings_input_antenna_rounded
        : Icons.bluetooth_rounded;
    final instruction = method == TransferMethod.wifi
        ? 'Connect all phones to the same reachable Wi-Fi LAN.'
        : method == TransferMethod.hotspot
        ? (role == SessionRole.host
              ? 'Enable Hotspot in Android Settings first.'
              : 'Join the Host phone hotspot in Android Settings first.')
        : 'Turn Bluetooth on, pair phones in Android Settings and connect a peer.';
    return WavePage(
      title: 'Network Setup',
      subtitle: '${method.label} • ${role.label}',
      children: [
        const SizedBox(height: 20),
        WaveGlassCard(
          colors: const [Color(0xFFE1FFFF), Color(0xFFACF5EE)],
          child: Column(
            children: [
              Icon(icon, size: 78, color: WaveColors.deepTeal),
              const SizedBox(height: 12),
              Text(
                method.label,
                style: const TextStyle(
                  color: WaveColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: WaveColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WaveOptionTile(
          title: 'Open Android Network Settings',
          subtitle: 'Enable your selected connection method.',
          icon: Icons.settings_rounded,
          onTap: () => WaveNative.instance.openNetworkSettings(method),
        ),
        const WaveNote(
          'Continue starts the native network once. Existing sessions can be resumed or explicitly stopped.',
        ),
      ],
      footer: WavePrimaryButton(
        title: starting ? 'Starting Network…' : 'Start Network',
        icon: starting
            ? Icons.hourglass_top_rounded
            : Icons.arrow_forward_rounded,
        onPressed: starting ? null : _startOnce,
      ),
    );
  }
}

class ConnectingScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const ConnectingScreen({super.key, required this.onContinue});
  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Connecting',
    subtitle: 'Native session verification',
    children: [
      const LiveNetworkPanel(),
      const SizedBox(height: 12),
      WavePrimaryButton(
        title: 'Continue When Connected',
        onPressed: WaveNative.instance.joined ? onContinue : null,
      ),
    ],
  );
}

class HostLobbyScreen extends StatelessWidget {
  final WaveSession session;
  final VoidCallback onStart;
  const HostLobbyScreen({
    super.key,
    required this.session,
    required this.onStart,
  });
  @override
  Widget build(BuildContext context) => WavePage(
    title: 'Host Session Lobby',
    subtitle: '${session.name} • ${session.method.label}',
    children: [
      HostInviteCard(session: session),
      const SizedBox(height: 15),
      TextButton.icon(
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copy Secure Join Code'),
        onPressed: () async {
          try {
            final invite = await WaveNative.instance.invite(
              room: session.id,
              ip: session.method == TransferMethod.bluetooth
                  ? null
                  : WaveNative.instance.localIp,
            );
            await Clipboard.setData(ClipboardData(text: invite));
            if (context.mounted) waveToast(context, 'Secure Join Code copied');
          } catch (e) {
            if (context.mounted) waveToast(context, 'Invite: $e');
          }
        },
      ),
      const SizedBox(height: 10),
      const LiveNetworkPanel(showApproval: true),
    ],
    footer: WavePrimaryButton(
      title: 'Start Live Sharing',
      icon: Icons.play_arrow_rounded,
      onPressed: onStart,
    ),
  );
}
