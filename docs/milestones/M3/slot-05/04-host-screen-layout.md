# Theater Host Screen Layout

Source: `WAVE_Flutter/lib/features/audio/presentation/theater_setup_screen.dart`, lines 33–152. This is source review, not execution evidence.

## Top-level screen
`WaveTheaterSetupScreen` is a `StatefulWidget` and its state builds a `WavePage` titled `WAVE Theater Positions` with subtitle `Host-controlled placement guide`.

The page contains:
1. An opening `WaveNote` warning that assignment is not finished discrete surround-channel playback.
2. An `AnimatedBuilder` subscribing to `WaveNative.instance`.
3. Either an empty-peer note or a sequence of `WaveGlassCard` entries.
4. A concluding `WaveNote` distinguishing network roles from speaker positions.

## Peer card layout
Each card contains a phone icon; an ellipsized peer identifier inside `Expanded`; a small vertical gap; and `DropdownButtonFormField<int>` labeled `Speaker position`. Cards have 11 logical pixels of separation.

## Empty state
When `native.peers` is empty, the UI says `Invite receiver phones first, then assign their positions.` This screen does not perform the invitation itself.

## Boundaries
`WavePage`, `WaveGlassCard`, `WaveNote`, and the theme come from shared modules. Their internal implementation is not established here. No source files have been modified by this document.