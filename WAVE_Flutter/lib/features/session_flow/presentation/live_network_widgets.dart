import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/native/wave_native.dart';
import '../../../core/theme/wave_theme.dart';
import '../../../core/ui/wave_widgets.dart';
import '../../../domain/models/wave_session.dart';

class LiveNetworkPanel extends StatelessWidget {
  final bool showApproval;
  const LiveNetworkPanel({super.key, this.showApproval = false});
  @override
  Widget build(BuildContext context) {
    final native = WaveNative.instance;
    return AnimatedBuilder(
      animation: native,
      builder: (context, _) {
        final state = native.state;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaveCapsulePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        color: WaveColors.deepTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          native.running
                              ? 'Native audio network active'
                              : 'Audio network stopped',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: WaveColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Peers: ${native.connected}  •  ${native.joined ? 'Joined' : 'Waiting / Hosting'}',
                    style: const TextStyle(color: WaveColors.muted),
                  ),
                  if (native.currentMode == 'bluetooth' &&
                      state['wifiRadioOn'] == true &&
                      ((state['underruns'] as num?)?.toInt() ?? 0) > 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Bluetooth audio is stuttering with Wi-Fi active. Both may compete for 2.4 GHz airtime. If possible, use 5 GHz Wi-Fi and avoid heavy downloads; exact behaviour depends on your phone.',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (state['networkMigrating'] == true)
                    const Text(
                      'Network changed — reconnecting…',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  if ((state['lastDisconnectReason'] ?? '')
                      .toString()
                      .isNotEmpty)
                    const Text(
                      'Bluetooth connection changed; check status below.',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    initiallyExpanded: false,
                    title: const Text(
                      'Connection details',
                      style: TextStyle(
                        fontSize: 13,
                        color: WaveColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Text(
                        'Device IP: ${native.localIp.isEmpty ? 'Not available' : native.localIp}',
                        style: const TextStyle(color: WaveColors.muted),
                      ),
                      Text(
                        'Audio capture: ${native.captureSource}',
                        style: const TextStyle(color: WaveColors.muted),
                      ),
                      Text(
                        'Packets sent/received: ${state['sent'] ?? 0} / ${state['received'] ?? 0} • relayed: ${state['forwarded'] ?? 0}',
                        style: const TextStyle(
                          color: WaveColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Glitches: ${state['underruns'] ?? 0} • late/dropped: ${state['audioDrops'] ?? 0} • sender drops: ${state['senderDrops'] ?? 0}',
                        style: const TextStyle(
                          color: WaveColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Send queue: ${state['senderQueue'] ?? 0} • tap frames: ${state['mediaPcmFrames'] ?? 0}',
                        style: const TextStyle(
                          color: WaveColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (state['clockRttMs'] != null)
                        Text(
                          'Clock RTT: ${state['clockRttMs']} ms • playout goal: ${state['targetDelayMs'] ?? '?'} ms',
                          style: const TextStyle(
                            color: WaveColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        'Clock sync: ${state['clockSynced'] == true ? 'Ready' : 'Waiting'}',
                        style: const TextStyle(color: WaveColors.muted),
                      ),
                      const Text(
                        'Encrypted group session • WAVE6 / WAVE4',
                        style: TextStyle(color: WaveColors.muted),
                      ),
                      if ((state['lastDisconnectReason'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(
                          'Bluetooth last link event: ${state['lastDisconnectReason']}',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                          ),
                        ),
                      if (state['networkMigrating'] == true)
                        const Text(
                          'Network changed: reconnecting…',
                          style: TextStyle(color: Colors.orange),
                        ),
                      if (state['hostElectionStatus'] == 'seeking_quorum')
                        const Text(
                          'Host lost: seeking quorum…',
                          style: TextStyle(color: Colors.orange),
                        ),
                      if (state['hostTerm'] != null)
                        Text(
                          'Host term: ${state['hostTerm']} • Voters: ${state['voterCount'] ?? 0}',
                          style: const TextStyle(color: WaveColors.muted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (native.peers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const WaveLabel('Connected Devices'),
              for (final peer in native.peers)
                WaveOptionTile(
                  title:
                      (peer['name'] ??
                              peer['id'] ??
                              peer['address'] ??
                              'Device')
                          .toString(),
                  subtitle: (peer['ip'] ?? peer['address'] ?? 'Wireless peer')
                      .toString(),
                  icon: Icons.smartphone_rounded,
                  onTap: null,
                ),
            ],
            if (showApproval && native.pending.isNotEmpty) ...[
              const SizedBox(height: 12),
              const WaveLabel('Join Requests'),
              for (final request in native.pending)
                WaveGlassCard(
                  child: Column(
                    children: [
                      Text(
                        "${request['name'] ?? 'Listener'} (${request['id']})",
                        style: const TextStyle(color: WaveColors.ink),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => native.approve(
                                request['id'].toString(),
                                false,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => native.approve(
                                request['id'].toString(),
                                true,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class HostInviteCard extends StatelessWidget {
  final WaveSession session;
  const HostInviteCard({super.key, required this.session});
  @override
  Widget build(BuildContext context) {
    final native = WaveNative.instance;
    return AnimatedBuilder(
      animation: native,
      builder: (context, _) {
        final ip = native.localIp;
        return FutureBuilder<String>(
          future: native.invite(
            room: session.id,
            ip: session.method == TransferMethod.bluetooth ? null : ip,
          ),
          builder: (context, snapshot) {
            final invite = snapshot.data ?? '';
            return FutureBuilder<String>(
              future: native.compactInvite(room: session.id),
              builder: (context, compactSnap) {
                final compact = compactSnap.data ?? '';
                return WaveCapsulePanel(
                  child: Column(
                    children: [
                      const Text(
                        'Secure Join Code',
                        style: TextStyle(color: WaveColors.muted),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        compact.isEmpty ? 'Preparing…' : compact,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: WaveColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Room ID: ${session.id}',
                        style: const TextStyle(
                          color: WaveColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFD6EFEB)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: invite.isEmpty
                            ? const SizedBox(
                                width: 175,
                                height: 175,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : QrImageView(
                                data: invite,
                                size: 175,
                                version: QrVersions.auto,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ip.isEmpty
                            ? 'Nearby discovery / Bluetooth pairing'
                            : 'Host network: $ip',
                        style: const TextStyle(
                          color: WaveColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: compact.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: compact));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Secure Join Code copied'),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy Join Code'),
                      ),
                      TextButton.icon(
                        onPressed: invite.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: invite));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('QR invitation copied'),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.qr_code_rounded),
                        label: const Text('Copy QR invitation'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class BluetoothPeerPicker extends StatefulWidget {
  const BluetoothPeerPicker({super.key});
  @override
  State<BluetoothPeerPicker> createState() => _BluetoothPeerPickerState();
}

class _BluetoothPeerPickerState extends State<BluetoothPeerPicker> {
  List<Map<String, String>> peers = [];
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      peers = await WaveNative.instance.pairedBluetoothDevices();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      WaveLabel(
        WaveNative.instance.hosting
            ? 'Paired Bluetooth devices'
            : 'Select your paired host phone',
      ),
      if (loading) const LinearProgressIndicator(),
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
      for (final p in peers)
        WaveOptionTile(
          title: p['name'] ?? 'Android phone',
          subtitle: p['address'] ?? '',
          icon: Icons.bluetooth_rounded,
          onTap: () async {
            try {
              await WaveNative.instance.connectBluetooth(p['address']!);
              if (context.mounted) waveToast(context, 'Connecting…');
            } catch (e) {
              if (context.mounted) waveToast(context, 'Bluetooth: $e');
            }
          },
        ),
      TextButton.icon(
        onPressed: refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh paired devices'),
      ),
      const WaveNote(
        'Pair each listener with the host in Android Bluetooth settings, then connect directly to the host.',
      ),
    ],
  );
}

class WaitingForNativeConnection extends StatefulWidget {
  final bool bluetooth;
  final VoidCallback onReady;
  final Future<void> Function()? onRetry;
  const WaitingForNativeConnection({
    super.key,
    required this.bluetooth,
    required this.onReady,
    this.onRetry,
  });
  @override
  State<WaitingForNativeConnection> createState() =>
      _WaitingForNativeConnectionState();
}

class _WaitingForNativeConnectionState
    extends State<WaitingForNativeConnection> {
  bool advanced = false, stopping = false, timedOut = false;
  Timer? timeout;
  @override
  void initState() {
    super.initState();
    WaveNative.instance.addListener(check);
    timeout = Timer(const Duration(seconds: 25), () {
      if (mounted) setState(() => timedOut = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      check();
    });
  }

  void check() {
    if (!mounted || advanced || stopping) return;
    if (WaveNative.instance.joined) {
      advanced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady();
      });
    } else
      setState(() {});
  }

  Future<void> cancel() async {
    if (stopping) return;
    setState(() => stopping = true);
    try {
      await WaveNative.instance.stop();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => stopping = false);
        waveToast(context, 'Unable to stop. Please retry.');
      }
    }
  }

  @override
  void dispose() {
    timeout?.cancel();
    WaveNative.instance.removeListener(check);
    if (!advanced && !stopping) unawaited(WaveNative.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: advanced || stopping,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) cancel();
    },
    child: WavePage(
      title: 'Connecting',
      subtitle: 'Connecting to the host',
      children: [
        const WaveLiquidSignal(label: 'Connecting to host'),
        const SizedBox(height: 20),
        Text(
          WaveNative.instance.state['joinDenied'] == true
              ? 'The host declined your request or the room is full.'
              : timedOut
              ? 'Connection is taking longer than expected. Check the invitation and network with the host.'
              : 'Waiting for the host connection or approval.',
        ),
        const SizedBox(height: 16),
        const LiveNetworkPanel(),
        if (widget.bluetooth) const BluetoothPeerPicker(),
        if (widget.onRetry != null)
          WavePrimaryButton(
            title: 'Retry Connection',
            onPressed: stopping
                ? null
                : () async {
                    try {
                      await widget.onRetry!();
                      if (mounted) setState(() => timedOut = false);
                    } catch (e) {
                      if (mounted)
                        waveToast(
                          context,
                          'Connection failed. Check the host and try again.',
                        );
                    }
                  },
          ),
        const SizedBox(height: 12),
        WavePrimaryButton(
          title: stopping ? 'Stopping…' : 'Cancel & Edit Code',
          outlined: true,
          onPressed: stopping ? null : cancel,
        ),
      ],
    ),
  );
}

/// V3.1 participant sheet: one place for requests, peers, and individual
/// playback commands. Commands are not treated as acknowledged until an
/// explicit receiver feedback protocol exists.
class ParticipantControlsSheet extends StatefulWidget {
  final String sessionId;
  const ParticipantControlsSheet({super.key, required this.sessionId});
  @override
  State<ParticipantControlsSheet> createState() =>
      _ParticipantControlsSheetState();
}

class _ParticipantControlsSheetState extends State<ParticipantControlsSheet> {
  final Map<String, double> gains = {};
  final Set<String> busy = {};
  Future<void> send(String id, String action, int value) async {
    if (!WaveNative.instance.hosting ||
        WaveNative.instance.currentRoom != widget.sessionId)
      return;
    if (busy.contains(id)) return;
    setState(() => busy.add(id));
    try {
      await WaveNative.instance.controlReceiver(
        peerId: id,
        action: action,
        value: value,
      );
      if (mounted)
        waveToast(
          context,
          'Playback setting sent. It will be repeated until the receiver reconnects.',
        );
    } catch (e) {
      if (mounted) waveToast(context, 'Receiver control failed: $e');
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final native = WaveNative.instance;
    return AnimatedBuilder(
      animation: native,
      builder: (context, _) {
        if (!native.running || native.currentRoom != widget.sessionId)
          return const Center(child: Text('This session has ended.'));
        final devices = native.peers;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          children: [
            if (native.hosting)
              TextButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('End this room'),
                onPressed: () async {
                  final ok = await confirmWaveAction(
                    context,
                    title: 'End this room?',
                    message: 'This ends the room for everyone. Create a new room to invite only the people you trust.',
                    confirmLabel: 'End room',
                  );
                  if (ok && context.mounted) {
                    await native.stop();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            const Text(
              'Participants & Playback',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
                color: WaveColors.ink,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Host controls change WAVE app audio, never system volume. A relay keeps forwarding when its local speaker is paused.',
              style: TextStyle(color: WaveColors.muted),
            ),
            const SizedBox(height: 18),
            if (devices.isEmpty)
              const WaveNote(
                'No connected receivers yet. Share the secure invitation from the Host room.',
              ),
            for (final peer in devices) ...[
              Builder(
                builder: (context) {
                  final id =
                      (native.currentMode == 'bluetooth'
                              ? peer['address']
                              : peer['id'])
                          ?.toString() ??
                      '';
                  final valid =
                      native.hosting &&
                      id.isNotEmpty &&
                      (native.currentMode != 'bluetooth' ||
                          peer['verified'] == true);
                  final gain =
                      gains[id] ?? (peer['gain'] as num?)?.toDouble() ?? 100.0;
                  return WaveGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.smartphone_rounded,
                              color: WaveColors.deepTeal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (peer['name'] ?? id).toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: WaveColors.ink,
                                    ),
                                  ),
                                  Text(
                                    (peer['ip'] ??
                                            peer['address'] ??
                                            'Connected device')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: WaveColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: valid && !busy.contains(id)
                                    ? () => send(id, 'PAUSE', 100)
                                    : null,
                                icon: const Icon(Icons.pause_rounded),
                                label: const Text('Pause'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: valid && !busy.contains(id)
                                    ? () => send(id, 'PLAY', 100)
                                    : null,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Play'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.volume_down_rounded,
                              color: WaveColors.deepTeal,
                            ),
                            Expanded(
                              child: Slider(
                                value: gain,
                                min: 0,
                                max: 100,
                                divisions: 20,
                                onChanged: valid
                                    ? (v) => setState(() => gains[id] = v)
                                    : null,
                                onChangeEnd: valid
                                    ? (v) => send(id, 'GAIN', v.round())
                                    : null,
                              ),
                            ),
                            Text(
                              '${gain.round()}%',
                              style: const TextStyle(color: WaveColors.ink),
                            ),
                          ],
                        ),
                        if (valid)
                          TextButton.icon(
                            icon: const Icon(Icons.person_remove_outlined),
                            label: Text(
                              native.currentMode == 'bluetooth'
                                  ? 'Block this paired device'
                                  : 'Disconnect listener',
                            ),
                            onPressed: () async {
                              final confirmed = await confirmWaveAction(
                                context,
                                title: 'Remove this listener?',
                                message: native.currentMode == 'bluetooth'
                                    ? 'This paired device will be blocked for this room.'
                                    : 'The listener will disconnect. A shared invitation can still be used to request access.',
                                confirmLabel: 'Remove',
                              );
                              if (!confirmed || !context.mounted) return;
                              try {
                                await native.removePeer(id, widget.sessionId);
                              } catch (e) {
                                if (context.mounted)
                                  waveToast(
                                    context,
                                    'Could not remove listener: ${e.toString()}',
                                  );
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 9),
            ],
            const WaveLabel('Join Approval & Network Status'),
            const LiveNetworkPanel(showApproval: true),
          ],
        );
      },
    );
  }
}
