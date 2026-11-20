import 'dart:math';

import '../../core/native/wave_native.dart';
import '../media/presentation/wave_media_screen.dart';
import 'presentation/live_network_widgets.dart';

import 'package:flutter/material.dart';

import '../../core/theme/wave_theme.dart';
import '../../core/ui/wave_widgets.dart';
import '../../domain/models/wave_session.dart';
import '../../state/wave_scope.dart';
import '../audio/presentation/audio_live_screens.dart';
import '../sessions/presentation/session_management_screens.dart';
import '../translation/presentation/translation_screens.dart';
import 'presentation/setup_screens.dart';

/// Audio Share V3.1: method → automatic capability check → role → create/join.
/// Host creates room and opens Lobby/Live first, then chooses audio source.
/// No extra Network Setup page or pre-Lobby source selection.
abstract final class WaveFlow {
  static Future<T?> _push<T>(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push<T>(MaterialPageRoute<T>(builder: (_) => screen));

  static void fromHome(
    BuildContext context,
    WaveFeature feature, {
    required VoidCallback onExisting,
  }) {
    final active = WaveScope.of(context).activeFor(feature);
    if (active != null) {
      onExisting();
      return;
    }
    start(context, feature);
  }

  static void chooseFeature(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFEAFEFF),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a Feature',
                style: TextStyle(
                  fontSize: 20,
                  color: WaveColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              WaveOptionTile(
                title: 'Audio Share',
                subtitle: 'Music, movies and supported app audio',
                icon: Icons.headphones_rounded,
                onTap: () {
                  Navigator.pop(sheetContext);
                  start(context, WaveFeature.audio);
                },
              ),
              WaveOptionTile(
                title: 'Live Translate',
                subtitle: 'Tamil ↔ English · Gateway required',
                icon: Icons.translate_rounded,
                onTap: () {
                  Navigator.pop(sheetContext);
                  start(context, WaveFeature.translation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A UI route is not authoritative: the native foreground engine may survive
  /// navigation, an Activity recreation or a process/UI restart.
  static Future<bool> _ensureNativeAvailable(BuildContext context) async {
    await WaveNative.instance.refresh();
    if (!context.mounted) return false;
    if (!WaveNative.instance.running) return true;
    final currentId = WaveNative.instance.currentRoom;
    final controller = WaveScope.of(context);
    WaveSession? existing;
    for (final s in controller.activeSessions) {
      if (s.id == currentId) {
        existing = s;
        break;
      }
    }
    if (existing != null) {
      waveToast(context, 'Session already active — opening the existing room');
      resume(context, existing);
      return false;
    }
    final shouldReplace = await confirmWaveAction(
      context,
      title: 'Another WAVE session is active',
      message:
          'Room $currentId is still running on this phone. To create/join another room, the current session must stop. Stop it and continue?',
      confirmLabel: 'Stop & Start New',
    );
    if (!shouldReplace || !context.mounted) return false;
    await WaveNative.instance.stop();
    for (final item in controller.activeSessions.toList()) {
      controller.endSession(item.id);
    }
    return true;
  }

  static Future<void> start(
    BuildContext context,
    WaveFeature feature, {
    WaveTrack? selectedTrack,
    bool forceNew = false,
  }) async {
    try {
      await WaveNative.instance.refresh();
      if (!context.mounted) return;
      if (WaveNative.instance.running) {
        final controller = WaveScope.of(context);
        final currentId = WaveNative.instance.currentRoom;
        WaveSession? matching;
        for (final s in controller.activeSessions) {
          if (s.id == currentId) {
            matching = s;
            break;
          }
        }
        if (matching != null && matching.feature == feature && !forceNew) {
          resume(context, matching);
          return;
        }
        final replace = await confirmWaveAction(
          context,
          title: 'Another WAVE session is running',
          message: 'You can only run one native WAVE room at a time. Stop the current room to start a new one?',
          confirmLabel: 'Stop & Start New',
        );
        if (!replace || !context.mounted) return;
        await WaveNative.instance.stop();
        for (final s in controller.activeSessions.toList()) {
          controller.endSession(s.id);
        }
      } else {
        final controller = WaveScope.of(context);
        for (final old in controller.activeSessions.toList()) {
          controller.endSession(old.id); // OS service stopped externally.
        }
      }
      if (!context.mounted) return;
      final draft = WaveScope.of(context).draft(feature);
      if (selectedTrack != null) {
        draft.audioSource = AudioSource.music;
        draft.track = selectedTrack;
      }
      _push<void>(
        context,
        TransferMethodScreen(
          feature: feature,
          onContinue: (method) {
            draft.method = method;
            if (feature == WaveFeature.audio) {
              _preflight(context, draft);
            } else {
              _chooseRole(context, draft);
            }
          },
        ),
      );
    } catch (error) {
      if (context.mounted)
        waveToast(context, 'Unable to read current session: $error');
    }
  }

  /// Stage A: transport-wide capabilities only. Host/Receiver-specific setup
  /// stays in the native start/join path so a Receiver is never told to enable
  /// its own hotspot. Android permissions are requested contextually there.
  static Future<void> _preflight(
    BuildContext context,
    SessionDraft draft,
  ) async {
    if (draft.method == TransferMethod.bluetooth) {
      try {
        final granted = await WaveNative.instance.permissions(
          method: TransferMethod.bluetooth,
          host: false,
        );
        if (!context.mounted) return;
        if (!granted) {
          await WaveNative.instance.openAppSettings();
          return;
        }
        final enabled = await WaveNative.instance.bluetoothReady();
        if (!context.mounted) return;
        if (!enabled) {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Turn on Bluetooth'),
              content: const Text(
                'Enable Bluetooth in Android Settings, then return to WAVE.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Not now'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    WaveNative.instance.openNetworkSettings(
                      TransferMethod.bluetooth,
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          return;
        }
      } catch (e) {
        if (context.mounted) waveToast(context, 'Bluetooth check: $e');
        return;
      }
    }
    if (!context.mounted) return;
    _chooseRole(context, draft);
  }

  static void _chooseRole(BuildContext context, SessionDraft draft) {
    _push<void>(
      context,
      RoleSelectionScreen(
        method: draft.method!,
        onSelected: (role) {
          draft.role = role;
          if (role == SessionRole.host) {
            _create(context, draft);
          } else {
            _join(context, draft);
          }
        },
      ),
    );
  }

  static void _create(BuildContext context, SessionDraft draft) {
    _push<void>(
      context,
      CreateSessionScreen(
        method: draft.method!,
        onContinue: (name, maxUsers, approval) async {
          draft.roomName = name;
          draft.maxParticipants = maxUsers;
          draft.joinApproval = approval;
          await _activateHost(context, draft);
        },
      ),
    );
  }

  static void _join(BuildContext context, SessionDraft draft) {
    _push<void>(
      context,
      JoinSessionScreen(
        method: draft.method!,
        onContinue: (code) async {
          draft.roomCode = code;
          await _activateReceiver(context, draft);
        },
        onQr: () => _push<void>(
          context,
          QrScannerScreen(
            onManualCode: (code) async {
              draft.roomCode = code;
              await _activateReceiver(context, draft);
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _showNetworkProblem(
    BuildContext context,
    SessionDraft draft,
    Object error,
  ) async {
    if (!context.mounted) return;
    final message = error.toString().contains('permission')
        ? 'Allow the requested permission in Android Settings, then try again.'
        : error.toString().contains('invite')
        ? 'Check the complete invitation with the host and try again.'
        : 'Could not connect. Check that the host is running and both devices use the selected network, then retry.';
    final networkIssue = RegExp(
      r'(Wi-Fi|hotspot|Bluetooth|network|permission|connect)',
      caseSensitive: false,
    ).hasMatch(message);
    if (!networkIssue) {
      waveToast(context, message);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${draft.method?.label ?? 'Network'} needs attention'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (draft.method != null)
                WaveNative.instance.openNetworkSettings(draft.method!);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<void> _activateHost(
    BuildContext context,
    SessionDraft draft,
  ) async {
    final code = 'WAVE${1000 + Random.secure().nextInt(9000)}';
    try {
      if (!await _ensureNativeAvailable(context)) return;
      if (!context.mounted) return;
      await WaveNative.instance.start(draft: draft, code: code);
      if (!context.mounted) return;
      final session = WaveScope.of(context)
          .createSession(draft, roomCode: code);
      _openLobby(context, session);
    } catch (e) {
      if (context.mounted) await _showNetworkProblem(context, draft, e);
    }
  }

  static Future<void> _activateReceiver(
    BuildContext context,
    SessionDraft draft,
  ) async {
    final raw = draft.roomCode.trim();
    // A room ID alone must never become an AES key. Both forms contain a
    // cryptographically random secret. W6 omits the IP and discovers LAN Host.
    final hasCompact = raw.toUpperCase().startsWith('W6:');
    final hasLegacy = raw.toUpperCase().startsWith('WAVE4:');
    if ((!hasCompact && !hasLegacy) || !raw.contains('#')) {
      waveToast(
        context,
        'Enter the Secure Join Code from Host, or scan its QR',
      );
      return;
    }
    final body = raw.substring(hasCompact ? 3 : 6);
    final invitation = body.split('#');
    if (invitation.length != 2 || invitation[1].isEmpty) {
      waveToast(context, 'Invalid secure invitation');
      return;
    }
    draft.inviteSecret = invitation[1];
    final parts = invitation[0].split('@');
    final code = parts.first.toUpperCase();
    final hostIp = parts.length > 1 ? parts[1].trim() : null;
    if (!RegExp(r'^[A-Z0-9-]{4,12}$').hasMatch(code)) {
      waveToast(context, 'Enter a valid WAVE room code');
      return;
    }
    draft.roomCode = code;
    try {
      if (!await _ensureNativeAvailable(context)) return;
      if (!context.mounted) return;
      await WaveNative.instance.start(draft: draft, code: code);
      try {
        if (draft.method != TransferMethod.bluetooth)
          await WaveNative.instance.join(hostIp: hostIp);
      } catch (_) {
        await WaveNative.instance
            .stop(); // Leave no orphaned receiver service after failure.
        rethrow;
      }
      if (!context.mounted) return;
      _push<void>(
        context,
        WaitingForNativeConnection(
          bluetooth: draft.method == TransferMethod.bluetooth,
          onRetry: draft.method == TransferMethod.bluetooth
              ? null
              : () => WaveNative.instance.join(hostIp: hostIp),
          onReady: () {
            _finishReceiver(context, draft);
          },
        ),
      );
    } catch (e) {
      if (context.mounted) await _showNetworkProblem(context, draft, e);
    }
  }

  static void _finishReceiver(BuildContext context, SessionDraft draft) {
    final session = WaveScope.of(context).joinSession(draft);
    _openReceiver(context, session);
  }

  static void _room(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (route) => route.isFirst,
    );
  }

  static void _openLobby(BuildContext origin, WaveSession session) {
    final context = Navigator.of(origin, rootNavigator: true).context;
    _room(
      context,
      HostLobbyScreen(
        session: session,
        onStart: () {
          WaveScope.of(context).changeStatus(session.id, SessionStatus.live);
          _openHost(context, session);
        },
      ),
    );
  }

  static void resume(BuildContext context, WaveSession session) {
    final s = WaveScope.of(context).getSession(session.id);
    if (s == null) return;
    if (!s.isActive) {
      details(context, s);
      return;
    }
    if (s.status == SessionStatus.reconnecting) {
      _recovery(context, s);
      return;
    }
    if (s.status == SessionStatus.lobby && s.role == SessionRole.host) {
      _openLobby(context, s);
      return;
    }
    if (s.role == SessionRole.host) {
      _openHost(context, s);
    } else {
      _openReceiver(context, s);
    }
  }

  static void _openHost(BuildContext origin, WaveSession s) {
    final context = Navigator.of(origin, rootNavigator: true).context;
    if (s.feature == WaveFeature.audio) {
      _room(
        context,
        LiveAudioHostScreen(
          sessionId: s.id,
          onEnd: () => _exit(context, s),
          onParticipants: () => participants(context, s),
          onDetails: () => details(context, s),
          onRecovery: () => _recovery(context, s),
        ),
      );
    } else {
      _room(
        context,
        LiveTranslationHostScreen(
          sessionId: s.id,
          onEnd: () => _exit(context, s),
          onParticipants: () => participants(context, s),
          onDetails: () => details(context, s),
        ),
      );
    }
  }

  static void _openReceiver(BuildContext origin, WaveSession s) {
    final context = Navigator.of(origin, rootNavigator: true).context;
    if (s.feature == WaveFeature.audio) {
      _room(
        context,
        LiveAudioReceiverScreen(
          sessionId: s.id,
          onLeave: () => _exit(context, s),
          onDetails: () => details(context, s),
          onRecovery: () => _recovery(context, s),
        ),
      );
    } else {
      _room(
        context,
        LiveTranslationReceiverScreen(
          sessionId: s.id,
          onLeave: () => _exit(context, s),
          onDetails: () => details(context, s),
          onSpeak: () => _push<void>(
            context,
            AuthorizedSpeakerScreen(onStop: () => Navigator.pop(context)),
          ),
        ),
      );
    }
  }

  static void details(BuildContext context, WaveSession s) {
    _push<void>(
      context,
      SessionDetailsScreen(
        sessionId: s.id,
        onResume: () => resume(context, s),
        onParticipants: () => participants(context, s),
        onExit: () => _exit(context, s),
      ),
    );
  }

  static void participants(BuildContext context, WaveSession s) {
    if (!s.isActive || WaveNative.instance.currentRoom != s.id) {
      waveToast(context, 'This session has ended.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFEAFEFF),
      builder: (_) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .80,
          child: ParticipantControlsSheet(sessionId: s.id),
        ),
      ),
    );
  }

  static void history(BuildContext context) {
    _push<void>(
      context,
      SessionHistoryScreen(onDetails: (s) => details(context, s)),
    );
  }

  static void _recovery(BuildContext context, WaveSession s) {
    _push<void>(
      context,
      ConnectionRecoveryScreen(
        sessionId: s.id,
        onRetry: () {
          WaveNative.instance.refresh().then((_) async {
            if (WaveNative.instance.running &&
                !WaveNative.instance.hosting &&
                !WaveNative.instance.joined &&
                s.method != TransferMethod.bluetooth)
              await WaveNative.instance.join();
            if (!context.mounted) return;
            if (WaveNative.instance.running &&
                (s.role == SessionRole.host || WaveNative.instance.joined)) {
              WaveScope.of(context).changeStatus(s.id, SessionStatus.live);
              Navigator.pop(context);
            } else {
              waveToast(
                context,
                'Still reconnecting — check network or peer links',
              );
            }
          });
        },
        onLeave: () => _exit(context, s),
      ),
    );
  }

  static Future<void> _exit(BuildContext context, WaveSession s) async {
    final confirmed = await confirmWaveAction(
      context,
      title: s.role == SessionRole.host ? 'End Session?' : 'Leave Session?',
      message: 'This will disconnect WAVE from ${s.name}.',
      confirmLabel: s.role == SessionRole.host ? 'End' : 'Leave',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await WaveNative.instance.stop();
    } catch (e) {
      if (context.mounted) waveToast(context, 'Could not stop session: $e');
      return;
    }
    if (!context.mounted) return;
    WaveScope.of(context).endSession(s.id);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void musicLibrary(BuildContext context) {
    _push<void>(context, const WaveMediaScreen(movie: false));
  }
}
