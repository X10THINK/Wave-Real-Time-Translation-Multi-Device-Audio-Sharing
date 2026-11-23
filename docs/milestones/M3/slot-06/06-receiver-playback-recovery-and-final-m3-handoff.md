# Slot 06 — Receiver playback, recovery, and final M3 handoff

**Milestone:** M3 — Audio and Media  
**Final documentation commit:** 25th commit attributed to Umesha-0929 in the M3 sequence  
**Original source file:** `WAVE_Flutter/lib/features/audio/presentation/audio_live_screens.dart`  
**Reviewed range:** lines **424–560** on `milestone/M3-audio-and-media`  
**Policy:** This document explains existing source. It does **not** modify Flutter/Android source, tests, behavior, or other contributors' milestones.

## 1. Receiver audio controls and state priority (lines 424–454)

An `AnimatedBuilder(animation: native)` renders the audio controls from current native state:

- `hostPaused`: `state['hostStreamPaused'] == true` — Host has paused room playback.
- `hostMuted`: `state['hostPlaybackEnabled'] == false` — Host has disabled playback for this receiver.
- `effectivePause`: `hostPaused || hostMuted || localPaused` — any of these makes the receiver UI show the play/resume icon.

When `hostPaused`, the panel shows **Host paused playback**. Otherwise, when `hostMuted`, it shows **Host paused this receiver**. The UI precedence is explicit. `localPaused` is a getter defined earlier in the same class (line 345), not a new state declared here.

**Scope:** This is a UI interpretation of reported flags, not proof that remote playback is actually stopped or resumed on every device.

## 2. Receiver local pause/resume button (lines 454–471)

The filled tonal icon button:

- Disables its `onPressed` callback when `hostPaused || hostMuted`.
- Otherwise invokes `togglePause`, defined earlier in the Receiver screen.
- Uses priority-sensitive tooltips: **Host has paused**, **Paused by Host**, **Resume audio**, or **Pause audio**.
- Displays a play icon when `effectivePause` is true; otherwise, a pause icon.

This separates Host authority from an individual receiver's local playback control.

## 3. Mute / unmute and volume slider (lines 472–497)

A second `IconButton.filledTonal` calls `mute`, with an icon/tooltip selected by the `muted` getter:

- Muted: `volume_off_rounded`, tooltip **Unmute**.
- Not muted: `volume_up_rounded`, tooltip **Mute**.

The `Slider` reads `volume` and delegates changes to `setVolume`. The percentage is displayed as `(muted ? 0 : volume * 100).round()`.

A note states: **Your local pause and volume do not affect anyone else or relay forwarding.** This is the intended user-facing behavior stated by the source; actual transport isolation/forwarding requires native implementation and device-level verification.

Earlier Receiver methods (lines 341–371) provide `lastVolume`, `volume`, `muted`, `localPaused`, `togglePause`, `setVolume`, and `mute`. These controls are wired to those methods; this section does not introduce a new volume engine.

## 4. Receiver-to-Host role transition UI (lines 503–537)

Another `AnimatedBuilder` checks `native.hosting`:

- If true, it renders a card titled **You are now Session Host**.
- It explains that this phone became Host and asks the user to choose a new media source.
- **Open Movie / Music Player** navigates to `WaveMediaScreen(movie: true)` using `Navigator.push`.
- If `native.hosting` is false, the builder returns `SizedBox.shrink()` and renders no transition card.

Important distinction: The presence of this card shows the UI reacting to `native.hosting`. It does **not** itself implement or prove host-election, network failover, or migration of an ongoing stream. Although the tile says “Movie / Music Player,” the actual navigation argument here is `movie: true`.

## 5. Shared Receiver widgets and network UI (lines 538–540)

- `WaveReceiverPosition()` shows the assigned theater placement when a role is available; see Slot 05's Theater documentation.
- `LiveNetworkPanel()` embeds the existing live network information widget.

These are component integrations. This file alone does not demonstrate that physical speaker placement can be measured, or that Bluetooth multi-hop forwarding is working.

## 6. Connection recovery (lines 541–546)

`WaveOptionTile` with title **Connection Recovery** and subtitle **Review actual network state** invokes the parent callback `widget.onRecovery`.

The screen delegates to the parent; the callback implementation is **not** defined within these lines. We cannot infer which troubleshooting operations occur after navigation merely from this widget.

## 7. Relay and media limitations (lines 547–549)

The source displays an informational `WaveNote` explaining:

- Relay forwarding **can continue** when supported peers are linked and WAVE's foreground service remains active.
- Receiver phones **do not receive movie video** in this interface; the feature is audio-focused.

The statement is conditional and aspirational where it depends on transport and Android service behavior. No real-device relay-performance pass is claimed by this documentation.

## 8. Leave-session flow (lines 550–560)

The **Leave Session** destructive `WavePrimaryButton` calls `widget.onLeave`. The parent owns the actual leave implementation. This code does not itself call a native leave method, clear session storage, or promise cleanup; it wires the action to its parent callback.

## 9. Receiver UI data flow for viva

1. `WaveScope.of(context).getSession(sessionId)` (earlier lines 373–381) validates the session.
2. `WaveNative.instance` exposes joined status, native state flags, and volume values.
3. `AnimatedBuilder` updates the displayed connection and playback statuses.
4. The Receiver controls delegate local pause/mute/volume to `togglePause`, `mute`, and `setVolume`.
5. Host-controlled pause/disable flags take precedence in the pause button.
6. Optional Host-transition card appears only when `native.hosting` is true.
7. Recovery and Leave actions delegate to the parent callbacks `onRecovery` and `onLeave`.

## 10. Tanglish viva questions and concise answers

**Q1. `effectivePause` ethukku?**  
A: “Sir, Host full pause, Host individual receiver pause, local pause — indha moonu-la edhaavadhu true-na receiver UI paused state kaattum. `||` OR operator use pannirukkom.”

**Q2. Host pause irukkumbodhu local Pause button enna aagum?**  
A: “Sir, `onPressed` null aagum; Host control override panna local listener-ku allow pannaadhu.”

**Q3. Receiver volume change mattha receivers-a affect pannuma?**  
A: “UI source note padi local volume and local pause mattha listeners-a affect panna koodadhu. Aana forwarding separation native side-la test panni confirm pannanum.”

**Q4. `native.hosting` true-na enna?**  
A: “Sir, intha receiver screen Host status-a observe panni 'You are now Session Host' card kaattum. Host-election engine indha UI-la implement pannala.”

**Q5. Recovery and Leave callbacks enga execute aagum?**  
A: “Sir, indha widget-la `widget.onRecovery` and `widget.onLeave` parent-kku delegate pannirukkom. Actual implementations parent navigation/session layer-la irukkum.”

**Q6. Real-time relay or synchronized playback proven-ah?**  
A: “Illa sir, indha source section UI states, controls, and callbacks-a prove pannudhu; mesh performance and sync latency native integration/testing dependent.”

## 11. Final M3 handoff — original source import map

| Slot | Original module and scope |
| --- | --- |
| 01 | `lib/features/audio/presentation/music_screens.dart` — audio source selection UI |
| 02 | `lib/core/media/wave_media_playback.dart` — media playback controller |
| 03 | `lib/features/media/presentation/wave_media_screen.dart` — music/video player UI |
| 04 | `lib/features/audio/presentation/audio_dashboard_screen.dart` + `assets/images/headphones.png` and `assets/images/music.png` — dashboard and existing assets |
| 05 | `lib/features/audio/presentation/theater_setup_screen.dart` — position assignment UI |
| 06 | `lib/features/audio/presentation/audio_live_screens.dart` — live Host and Receiver UI |

All above paths are beneath `WAVE_Flutter/` in the repository. Git history and blob integrity must be checked independently; this handoff document makes no test-pass or completion claims about Android builds, external-audio capture, relay routing, latency, or network failover.

## 12. Engineering review boundaries

- The M3 branch is a source-integration and learning branch. It is **not** a request to merge into `MAIN`.
- Original pre-existing Flutter code is retained; code quality/refactoring decisions belong to a separate team-approved workflow.
- Any future integration needs dependency-aware branch comparison and conflict review with the team's chosen base.
- Speaker position labels do not mean true discrete multichannel audio.
- User-facing statuses are based on reported state, not independent end-to-end measurements.
- Keep source code attribution and technical documentation factually accurate; commits document the files reviewed and actually imported, not fabricated intermediate implementations.

**Handoff status:** Slot 06's original source and documentation topics are covered. Git verification, review, and merge approval remain separate steps.
