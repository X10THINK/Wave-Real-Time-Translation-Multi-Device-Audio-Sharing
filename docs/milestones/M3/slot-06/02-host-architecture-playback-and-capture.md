# Slot 06 — Host architecture, playback synchronization, and device audio capture

**Milestone:** M3 — Audio and Media  
**Feature:** Live Audio — Host  
**Source file:** `WAVE_Flutter/lib/features/audio/presentation/audio_live_screens.dart`  
**Source lines:** 1–73 (on `milestone/M3-audio-and-media`)  
**Integration policy:** Documentation only. Do not modify or reformat the original Flutter source.

## 1. Imports and responsibilities (lines 1–10)

The Host screen imports Flutter Material; `WaveNative` (native/session commands); `WaveMediaPlayback` (local media playback controller); Theater Setup, WAVE theme and shared UI widgets; session models and `WaveScope`; the media player screen; and live network widgets. These are dependencies/references, not proof that every imported feature is executed in lines 1–73.

## 2. Widget interface (lines 12–25)

`LiveAudioHostScreen` is a `StatefulWidget`. Its constructor requires:

- `sessionId` — string identifying the expected active room.
- `onEnd` — parent-owned end-session callback.
- `onParticipants` — parent-owned participants/controls navigation callback.
- `onDetails` — parent-owned session-details callback.
- `onRecovery` — parent-owned recovery callback.

`createState()` constructs `_LiveAudioHostScreenState`. The callback declarations describe the screen's interface; the code in this section does not itself execute those navigation callbacks.

## 3. Host-local state and playback guard (lines 27–40)

- `String? error` stores a capture error for later display in the Host UI.
- `bool playbackBusy = false` prevents `setRoomPlaying` from starting again while a prior invocation remains in progress.
- `setRoomPlaying(bool play)` is asynchronous and returns `Future<void>`.
- It first returns if `playbackBusy` is already true.
- It rejects control when the native layer is not hosting, is not running, or reports a `currentRoom` different from `sessionId`. A toast says the Host room is no longer active.
- It calls `setState(() => playbackBusy = true)` before issuing the control request; the later cleanup resets this flag.

The guard is a UI-level safeguard. It should not be described as proof of complete distributed synchronization across receivers.

## 4. Internal media branch (lines 41–50)

When `native.captureSource == 'internalMedia'`, code obtains `WaveMediaPlayback.instance`.

1. It checks `media.player?.value.isInitialized == true`. Otherwise, it throws `StateError('Open a music or video file first')`.
2. If `play` is true, it awaits `media.play()`; otherwise, it awaits `media.pause()`.
3. It then awaits `native.refresh()`, with a source comment about allowing the native Media3 service state to propagate.

The source's intent is to keep local playback and shared-room state consistent. This UI method does not measure inter-device timing or prove sample-accurate synchronization.

## 5. Device audio branch and invalid sources (lines 51–55)

- If `native.captureSource == 'deviceAudio'`, the method awaits `native.roomPlayback(play)`. As the source comment notes, this controls room delivery without claiming it pauses the external Android app itself.
- When neither supported capture source is selected, it throws `StateError('Select a playable audio source first')`.

These are separate code paths: internal app media calls `WaveMediaPlayback`; device audio calls `WaveNative.roomPlayback`.

## 6. Completion, errors, and cleanup (lines 56–62)

- After the awaited operation, the screen shows either “Shared playback resumed” or “Shared playback paused” when `mounted`.
- `catch (e)` displays “Playback control unavailable: …” when `mounted`.
- `finally` clears `playbackBusy` through `setState` when `mounted`, whether success or an exception occurs.
- `mounted` guards avoid attempting these UI updates after the widget is disposed.

The toast is a request/operation result, not a verified per-receiver playback acknowledgment.

## 7. Enable supported device audio (lines 64–72)

`enableCapture()` is another asynchronous method:

1. Await `WaveNative.instance.captureDeviceAudio()`.
2. Await `WaveNative.instance.refresh()`.
3. If still mounted, clear the Host screen's local `error` state.
4. On an exception, save `e.toString()` into local `error`, if mounted.

Android MediaProjection consent and capture compatibility are not implemented by this UI method itself; their behavior depends on the native implementation, device, and app capture policy. No successful device test is claimed here.

## 8. Practical code-reading map

| Question | Source |
| --- | --- |
| What are the inputs of the Host screen? | lines 12–22 |
| Why is this a StatefulWidget? | lines 12, 23–29 |
| How are repeated playback commands guarded? | lines 33–40 and 59–60 |
| What happens with app-local music/video? | lines 42–50 |
| What happens with supported external app audio? | lines 51–52 |
| How are invalid source and errors handled? | lines 53–60 |
| How is device capture requested? | lines 64–72 |

## 9. Tanglish viva answers

**Q: `playbackBusy` ethukku?**  
A: “Sir, Host playback request already ongoing-na repeated pause/resume call avoid panna bool guard use panrom. `finally`-la reset panrom.”

**Q: Internal media-um device audio-vum difference?**  
A: “Sir, internal media case-la `WaveMediaPlayback` play/pause call pannuvom; device audio case-la `WaveNative.roomPlayback` moolama shared-room delivery control pannuvom.”

**Q: `enableCapture()` enna pannum?**  
A: “Sir, native device audio capture request send panni state refresh pannum. Exception vandha Host screen error state-la save pannuvom.”

**Q: Exact synchronized playback guarantee irukka?**  
A: “Illa sir, indha UI code timing measure pannala, receiver acknowledgement-um verify pannala. Native implementation and real-device tests separate.”

## 10. Handoff and limits

This document reviews only lines 1–73 of the original `audio_live_screens.dart` file. Later Slot 06 documentation should cover Host session display and controls, invitations and session ending, then Receiver states and controls. No Dart code, existing behavior, dependencies, or Android build settings are changed by this documentation commit.
