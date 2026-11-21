# Pending Assignment State

Source: `theater_setup_screen.dart`, lines 39–52, 108–133.

## Local state
`final Set<String> pending = {};` tracks peer identifiers for which the host has an in-progress `assignSpeaker` request.

On request start, `setState(() => pending.add(id))` schedules a rebuild. While `pending.contains(id)` is true, the corresponding dropdown's `onChanged` is `null`, disabling selection. The `finally` block removes the ID when the screen remains mounted.

## Why a Set
A set has unique string members, so the pending check is per identifier rather than a global loading flag. Other peer dropdowns are not explicitly disabled by this guard.

## Lifecycle
The code checks `mounted` before toasts and state cleanup following the await. This avoids calling `setState` or accessing UI context from an unmounted state.

## Limits
- The pending guard is screen-local and not a persisted assignment queue.
- It does not establish a remote acknowledgement or retry policy.
- An empty/duplicate peer identifier may cause collisions in pending-state behavior.
- The native module may update its peer-role list separately; that should be verified in its own source.

No changes to the running app are made here.