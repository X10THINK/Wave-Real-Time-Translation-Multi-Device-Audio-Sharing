# M3 Slot 06 — Host session, peers, and playback UI

**Commit 22 scope:** Documentation of `WAVE_Flutter/lib/features/audio/presentation/audio_live_screens.dart`, lines **74–243**, on `milestone/M3-audio-and-media`.

**Preservation rule:** This is a source-reading guide only. Do not change the original Dart code, behavior, or project dependencies.

## 1. Active session validation (lines 74–82)

`build(BuildContext context)` obtains the session with `WaveScope.of(context).getSession(widget.sessionId)`. If the session is absent or `!s.isActive`, the widget returns a `WavePage` titled **Session Ended**, with a note to return Home and start or join another room. This is a local UI fallback, not a command to terminate a native session.

## 2. Host page and room identity (lines 82–112)

The screen stores `WaveNative.instance` in `native` and renders a `WavePage` with title **Live Audio • Host** and subtitle **Real Android audio sharing session**. Its first `WaveGlassCard` displays a sensors icon, the session's `s.name`, and the room ID `s.id`. The card uses the project's `WaveColors` styling. These labels describe the session already retrieved from `WaveScope`; this section does not create a new room.

## 3. Reactive role, method, and peers metrics (lines 113–138)

An `AnimatedBuilder(animation: native)` rebuilds a `WaveGlassCard` containing three `WaveMetric` widgets:

| Metric | Displayed value | Source |
| --- | --- | --- |
| Role | `Host` | fixed label |
| Method | `s.method.label` | retrieved session |
| Peers | `${native.connected}` | native connected count |

The builder listens to the `WaveNative` notifier. The displayed peer count is a status value, not proof that all receivers are playing at the same timestamp. The screen does not measure latency or receiver synchronization.

## 4. Host playback status and safety guards (lines 139–184)

A second `AnimatedBuilder` reads `native.captureSource` and `native.state['hostStreamPaused'] == true`.

- `playable` is true only when the source is `internalMedia` or `deviceAudio`.
- When no playable source is selected, the status says **Select a source below to begin sharing**.
- When the native state reports a paused host stream, the status says **Room audio paused · connection stays active**.
- Otherwise, the status says **Room audio ready / sharing**.

The **Pause All** button calls `setRoomPlaying(false)`; **Resume All** calls `setRoomPlaying(true)`. Both are disabled when `!playable` or `playbackBusy`. Their underlying method is documented in the previous Slot 06 Host architecture guide (lines 33–62).

The text **For one listener, open Participants & Controls below** points users to a separate control area. Lines 139–184 do not implement a per-listener action. The paused status is based on the native state value; it should not be represented as verified acknowledgments from every receiver.

## 5. Choose audio source: music and video (lines 185–210)

The **Choose Audio Source** section offers two `WaveOptionTile` navigation entries:

| Tile | Destination | Flag |
| --- | --- | --- |
| Music Player | `WaveMediaScreen` | `movie: false` |
| Video Player | `WaveMediaScreen` | `movie: true` |

Both use `Navigator.push` with `MaterialPageRoute<void>`. The video tile says the Host sees video while receivers hear audio only. This is the UI's stated intended experience; these lines alone do not demonstrate a verified audio-only receiver playback test. The tiles open the media screen rather than directly starting playback in the current method.

## 6. Supported external-app audio capture (lines 211–243)

An **External App Audio Share** `WaveGlassCard` has two reactive native-state views:

1. A text label shows **Device audio capture active** when `native.captureSource == 'deviceAudio'`; otherwise it states **Android MediaProjection consent is required**.
2. A `WavePrimaryButton` shows **Capture Active** and is disabled when `deviceAudio` is selected. Otherwise it shows **Enable Supported Device Audio** and calls `enableCapture` from lines 64–72.

This prevents requesting capture again from that button while the UI reports an active device-audio source. It does not bypass Android MediaProjection consent or guarantee that a particular external app permits playback capture.

## 7. Dependencies and limitations

- `WaveScope` supplies the room model and active flag; `WaveNative` supplies connected count, capture source, paused flag, and change notifications.
- `setRoomPlaying` and `enableCapture` are defined earlier in the same state class. Their asynchronous success and failure paths are separate from the button wiring in this range.
- `WaveMediaScreen` is a destination for the media options; the full media player logic lives outside these lines.
- This section does **not** establish maximum receiver capacity, multi-device synchronized start times, background capture compatibility, end-to-end latency, or test PASS status.
- UI strings and cards are described as they exist in the original source, not as newly approved UX decisions. Any future UX redesign should be handled separately, without changing the preserved M3 source in this commit.

## 8. Tanglish viva preparation

**Q: Session end aana screen enna pannum?**  
A: “`WaveScope`-la session check pannuvom. Session illena illa inactive-na ‘Session Ended’ page kaattum. Indha UI check native room-a stop panna command illa.”

**Q: Peers number epdi update aagum?**  
A: “`AnimatedBuilder` `WaveNative`-a listen pannum. `native.connected` value change aana displayed peers metric rebuild aagum.”

**Q: Pause All / Resume All eppadi work aagum?**  
A: “Playable source irundha, previous command busy illa-na buttons enabled. Pause `setRoomPlaying(false)`, Resume `setRoomPlaying(true)` call pannum. Exact receiver sync guarantee-nu solla mudiyadhu.”

**Q: Music Player, Video Player difference?**  
A: “Rendum `WaveMediaScreen`-ku navigate pannum. Music-ku `movie: false`, video-ku `movie: true` pass pannuvom.”

**Q: Device audio capture button eppo disabled?**  
A: “`captureSource` ‘deviceAudio’ aana ‘Capture Active’ show aagi button disabled. Illena ‘Enable Supported Device Audio’ click panna `enableCapture()` call aagum. Android consent still required.”

## 9. Handoff

Commit 22 covers lines 74–243 only. Next planned Slot 06 documentation covers later Host controls and session ending, followed by Receiver architecture and recovery. This commit must add only this Markdown file; no original Flutter source edits.
