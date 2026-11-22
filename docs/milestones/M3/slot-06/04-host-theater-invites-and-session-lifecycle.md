# Slot 06 — Host theater placement, invitations, and session lifecycle

**Milestone:** M3 — Audio and Media  
**Source:** `WAVE_Flutter/lib/features/audio/presentation/audio_live_screens.dart`  
**Source range:** lines 244–324 on `milestone/M3-audio-and-media`  
**Change policy:** Documentation only. The original Flutter source, dependencies, assets, and runtime behavior remain unchanged.

## Scope

This section completes the live Host UI. It connects to a theater-placement screen, a network panel, capture feedback, a session invitation sheet, parent-managed participant/details navigation, and two different ending actions: stop shared audio **without ending the room**, and end the session through a parent callback.

## 1. Theater speaker placement (lines 244–258)

- A `WaveOptionTile` displays **Theater Speaker Placement** with a speaker-group icon.
- Its subtitle explicitly says front/surround positions can be assigned but the **multichannel engine is not yet enabled**.
- The `onTap` handler calls `Navigator.push` with a `MaterialPageRoute<void>` to `const WaveTheaterSetupScreen()`.
- This is UI navigation to the Slot 05 placement workflow, not implementation or verification of separate 5.1/7.1 audio channels.
- Two adjacent `SizedBox(height: 12)` widgets occur immediately before the tile in the original file; this document records the original layout without changing it.

## 2. Network panel and capture errors (lines 259–261)

- The Host embeds `const LiveNetworkPanel(showApproval: true)`.
- This passes a flag to the reusable network widget; it does **not**, by itself, show the implementation of peer approval or prove its behavior.
- `if (error != null) WaveNote('Capture error: $error')` conditionally displays the local Host capture error recorded earlier in the screen.
- No network-discovery or error-recovery implementation should be inferred from these UI calls alone.

## 3. Invite / QR Code for the existing session (lines 262–281)

- An `Invite / QR Code` option describes sharing the **existing** session without restarting it.
- Tap opens a `showModalBottomSheet<void>` with a drag handle, scrollable layout, and light background.
- The sheet creates a `SafeArea` containing a shrink-wrapped, padded `ListView`.
- Its content is `HostInviteCard(session: s)`, where `s` is the current session object selected by the Host build method.
- The session invitation UI is delegated to `HostInviteCard`. This section does not prove QR generation, scanning success, nearby discovery reliability, or connection capacity.

## 4. Participants & Controls and Session Details (lines 282–293)

- The **Participants & Controls** tile invokes `widget.onParticipants`, a callback provided by the parent screen.
- The **Session Details** tile invokes `widget.onDetails`, another parent-supplied callback.
- The Host widget does not implement these destination screens in lines 282–293. Do not claim their internal workflows are defined here.

## 5. Playback/video information (lines 294–298)

The `WaveNote` says music and movies share audio automatically while playing, and only the Host sees video. This is the UI's intended feature message. It is **not** a measured guarantee of compatible source capture, playback latency, synchronized receivers, or device performance.

## 6. Stop Shared Playback (Keep Room) — not End Session (lines 299–313)

The outlined `WavePrimaryButton` labeled **Stop Shared Playback (Keep Room)** has an asynchronous handler:

1. It awaits `WaveNative.instance.stopSharedAudio()`.
2. It then awaits `WaveMediaPlayback.instance.stop()`.
3. When `context.mounted` is true, it shows `Audio stopped; session remains active`.
4. On an exception, it shows `Cannot stop audio: $e` when `context.mounted`.

Important distinctions:

- This action is intended to stop shared playback while **keeping the session/room active**; it does not call `widget.onEnd`.
- The two stop calls are sequential. If the first throws, the second is not reached inside this handler.
- There is no transaction rollback in this UI handler. Therefore partial failure outcomes depend on the native and media implementations.
- `context.mounted` protects use of `context` for post-`await` toasts after the widget may have been disposed.

## 7. End Session (lines 314–320)

- A separate destructive `WavePrimaryButton`, labeled **End Session**, uses a stop-circle icon.
- Its `onPressed` directly references `widget.onEnd`.
- **Ending the session** is delegated to the parent callback; these lines alone do not specify all cleanup, leave, or network shutdown operations.
- This button must not be confused with **Stop Shared Playback (Keep Room)**.

## 8. Flow at a glance

| Host selection | Code path | Intended outcome |
| --- | --- | --- |
| Theater Speaker Placement | `Navigator.push(...WaveTheaterSetupScreen())` | Open speaker placement UI |
| Invite / QR Code | `showModalBottomSheet(...HostInviteCard(session: s))` | Present invite UI for current room |
| Participants & Controls | `widget.onParticipants` | Delegate navigation/control flow to parent |
| Session Details | `widget.onDetails` | Delegate details flow to parent |
| Stop Shared Playback (Keep Room) | `stopSharedAudio()` then `WaveMediaPlayback.stop()` | Stop audio without intentionally ending room |
| End Session | `widget.onEnd` | Ask parent to end session |

## 9. Tanglish viva preparation

**Q1. Host Theater button enna pannudhu?**  
“Sir, Theater placement screen-ku navigate pannudhu. Speaker position assign panna UI irukku; discrete surround sound distribution implement aagala.”

**Q2. QR button click panna enna nadakkum?**  
“Sir, existing session object `s`-a `HostInviteCard`-ku pass panni modal bottom sheet open pannuvom; session restart panna vendam.”

**Q3. Participants screen logic enga irukku?**  
“Sir, Host screen `widget.onParticipants` callback-a call pannudhu. Actual participants flow parent or destination component-la irukku.”

**Q4. Stop Shared Playback-um End Session-um difference?**  
“Sir, stop button native shared audio and local media playback-a stop panna try pannum, room active-ah keep pannuradhukku. End Session button `onEnd` parent callback-ku control pass pannum.”

**Q5. Two audio-stop operations-la error vandha?**  
“Sir, try/catch error-a toast-la display pannum. First call fail aana next await execute aagadhu; partial failure state indha UI-la rollback pannala.”

**Q6. What does `context.mounted` do?**  
“Sir, async work mudinja appuram context still mounted-aa irukkaa-nu check panni toast show panrom.”

## 10. Verified versus not proven

**Directly documented in source:** Host widget labels and routes; the network panel parameter; error note; invitation bottom sheet; parent callbacks; ordered stop operations; and End Session callback.

**Not proven by this file:** Real surround sound; QR scanning or peer joining; exact receiver synchronization; capture compatibility across external apps; full background/relay reliability; completeness of session termination.

**Next Slot 06 documentation:** Receiver local controls and connection state, then receiver playback, volume, recovery, and leave-session handoff.

**Integrity:** This commit adds Markdown documentation only. No original Dart source is edited, no APK test is asserted, and no merge to `MAIN` is performed.
