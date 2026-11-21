# Native Speaker Assignment Call Path

Source: `theater_setup_screen.dart`, lines 39–52 and 125–133.

## Initiation
The host changes a `DropdownButtonFormField<int>`. Its `onChanged` callback ignores `null` and calls `assign(id, v)` when the target ID is not pending.

## Async command
`assign(String id, int role)`:
1. Adds the peer identifier to the local `pending` set using `setState`.
2. Awaits `WaveNative.instance.assignSpeaker(id, role)`.
3. Displays a success-stage toast if the widget remains mounted.
4. Displays an error toast when an exception is thrown and the widget is mounted.
5. Removes the identifier from `pending` in `finally`, if mounted.

## Critical semantics
The toast says `Placement sent; receiver confirmation pending`. Resolving the awaited call is **not proof** that a receiver adopted the role, that its speaker is audible, or that multichannel audio is distributed.

## Dependency boundary
The native implementation of `assignSpeaker` is defined elsewhere. Its protocol, acknowledgement guarantees, and persistence cannot be proven from this UI file alone.

## Review question
What device/network conditions can make `assignSpeaker` fail, and how does the native implementation surface those failures to the UI?