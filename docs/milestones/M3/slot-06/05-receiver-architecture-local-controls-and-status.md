# Slot 06 — Receiver architecture, local audio controls, and connection status

**Milestone:** M3 — Audio and Media  
**Commit scope:** 24th Umesha-0929 commit / Slot 06 documentation #4  
**Source:** `WAVE_Flutter/lib/features/audio/presentation/audio_live_screens.dart`  
**Exact source section reviewed:** lines **326–423** on `milestone/M3-audio-and-media`  
**Policy:** Documentation only. Original Dart source remains unchanged.

## 1. Receiver widget interface (lines 326–339)

`LiveAudioReceiverScreen` is a `StatefulWidget` that accepts:

- `sessionId`: identifier of the expected active listening session.
- `onLeave`: parent-provided callback for leaving the session.
- `onDetails`: parent-provided callback for details.
- `onRecovery`: parent-provided callback for connection recovery.

The constructor requires each parameter. `createState()` constructs `_LiveAudioReceiverScreenState`. Declaring a callback here does **not** mean this particular line range invokes it.

## 2. Receiver-local state and getters (lines 341–346)

| Source member | Behavior |
| --- | --- |
| `double lastVolume = .8` | Keeps a local remembered volume (initially 80%) for unmute behavior. |
| `volume` getter | Reads numeric native state key `volume`, converts it to `double`, or defaults to `0.8` if null. |
| `localPaused` getter | True only when native state key `playbackEnabled` is exactly `false`. |
| `muted` getter | True when current `volume == 0`. |

These getters consume the state reported by `WaveNative.instance`. They do not prove actual speaker output or audio packet delivery.

## 3. Local pause/resume toggle (lines 347–354)

`togglePause()` is asynchronous:

1. Calls `WaveNative.instance.volume(volume, enabled: localPaused)`.
2. Calls `WaveNative.instance.refresh()` after awaiting the native request.
3. On exception, displays a toast (“Could not change playback. Try again.”) only if `mounted`.

The `enabled` argument is intentionally `localPaused`: when local playback is currently paused, this asks the native layer to enable it; otherwise it asks to disable it. Actual native effects depend on the native implementation.

## 4. Change local listening volume (lines 356–363)

`setVolume(double next)` calls `WaveNative.instance.volume(next, enabled: !localPaused)`, then refreshes state.

- `next` is the requested volume value.
- The method preserves whether local playback is paused using `enabled: !localPaused`.
- On exception, it reports “Could not change volume.” if `mounted`.
- This section shows no clamping in `setVolume`; input validation / effective range should not be assumed from this method alone.

## 5. Mute / unmute and previous volume (lines 365–371)

`mute()` checks the computed `muted` getter:

- If not muted, save `lastVolume = volume`, then call `setVolume(0)`.
- If muted, call `setVolume(lastVolume)` to restore the remembered value.

`mute()` is `void` and calls asynchronous `setVolume` without awaiting it. This is a factual description of the source, not a claim about error-free instant switching. The remembered volume belongs to this widget's state, rather than a separate persistent settings store.

## 6. Session validation and Receiver page (lines 373–395)

The Receiver's `build()` reads `WaveScope.of(context).getSession(widget.sessionId)`.

- If the session is missing or `!s.isActive`, the widget returns a `WavePage` titled `Session Ended` and a note to return Home.
- Otherwise, it obtains `WaveNative.instance` and constructs the `Live Audio • Receiver` page, subtitled `Audio listening + adaptive relay`.
- The introductory `WaveGlassCard` displays a headphones icon. This UI is not proof of completed mesh relay transport.

## 7. Receiver connection and playback status priority (lines 396–423)

An `AnimatedBuilder(animation: native)` rebuilds the status text when its listenable notifies. The nested conditional chooses the **first matching** status:

| Priority | State condition | Text shown |
| --- | --- | --- |
| 1 | `!native.joined` | `Reconnecting…` |
| 2 | `state['hostStreamPaused'] == true` | `Host paused` |
| 3 | `state['playbackEnabled'] == false` | `Paused on this phone` |
| 4 | `state['volume'] == 0` | `Muted` |
| 5 | `(state['received'] as num? ?? 0) == 0` | `Waiting for host audio` |
| 6 | None of the preceding | `Connected — Playing` |

**Priority matters:** for example, a disconnected peer shows `Reconnecting…` even when `playbackEnabled` is false. Host pause precedes local pause, which precedes muted.

The card also displays `s.name`, the existing session name.

**Interpretation warning:** `Connected — Playing` is derived from reported native flags/counters, not direct verification that a person can hear synchronized audio. Likewise, `received` is simply a native-reported value used by the UI; this code section does not prove the type or meaning of a network packet by itself.

## 8. Relevant API / state dependencies

- `WaveNative.instance.state`: maps named keys to native-reported values.
- `WaveNative.instance.volume(...)`: issues a local playback/volume request.
- `WaveNative.instance.refresh()`: requests updated native state.
- `WaveScope`: looks up the session.
- `AnimatedBuilder`: rebuilds UI on native notifications.

Exact native implementations and Android platform behavior are outside this 326–423 source-section review.

## 9. Constraints and risks to report accurately

- This section does not establish end-to-end Bluetooth mesh reliability, synchronized multi-receiver playback, or background survivability.
- The getters use casts such as `as num?`; incompatible non-numeric native state could still throw a cast error.
- `lastVolume` is initialized to 0.8 and updated by `mute()`, but this segment does not persist it across widget reconstruction.
- Exception handlers show UI feedback but do not independently verify remote state convergence.
- Host-level pause and receiver-local pause are separately represented in the UI.

## 10. Tanglish viva notes

**Q: Receiver StatefulWidget ethukku?**  
A: “Sir, local `lastVolume` maari state maintain pannrom. Native audio state-a read panni UI update panna `AnimatedBuilder` use pannrom.”

**Q: Local Pause Toggle epdi?**  
A: “Sir, `playbackEnabled` false-na `localPaused` true. Toggle click pannumbodhu `volume(volume, enabled: localPaused)` call panni, refresh panrom.”

**Q: Mute / Unmute logic?**  
A: “Sir, mute panna previous volume `lastVolume`-la save panrom; 0 set panrom. Unmute panna saved volume restore panna request anupprom.”

**Q: `Reconnecting…` eppodhu?**  
A: “Sir, `native.joined` false-na first priority-la Reconnecting status kaattrom, other flags irundhaalum.”

**Q: `Connected — Playing` label actual output test proof-ah?**  
A: “Illa sir, reported native state base panni UI label show pannrom; receiver real-a hear panraana nu hardware test separate.”

## 11. Next handoff

Commit 25 should review lines 424–560: the remaining Receiver playback controls and volume slider, Host-controlled pause indications, Host role transition UI, Theater/Network widgets, connection recovery, relay note, leave-session callback, and final M3 handoff. This document makes no edits to those source sections.
