# Slot 05 — Module Scope and Ownership

## Basis
Source: `WAVE_Flutter/lib/features/audio/presentation/theater_setup_screen.dart` (203 lines). This is a source review, not a test or release certification.

## Responsibilities
- `TheaterPositions` provides nine position names and their matching placement hints (lines 8–31).
- `WaveTheaterSetupScreen` offers host-controlled speaker position selection, using `WaveNative.instance.peers` (lines 33–152).
- `WaveReceiverPosition` renders the assigned position from native state (lines 154–203).
- The file composes existing Wave widgets and theme values. It does not implement a playback engine.

## Outside this module
- Discrete multichannel surround sound, DSP, or individual audio-channel distribution. Source comments and warnings explicitly say this is not implemented.
- Radio-based measurement of a phone's precise physical position.
- Peer discovery or transport connection setup; this UI consumes the peer list.
- Proof of speaker synchronization, routing, or real-device performance.

## Native boundary
The UI delegates assignments through `WaveNative.instance.assignSpeaker(id, role)` (line 44). A returned request is not proof of remote confirmation.

## Integration rule
Keep imported Dart source unchanged. This documentation should be revised only if the source or verified behavior subsequently changes.