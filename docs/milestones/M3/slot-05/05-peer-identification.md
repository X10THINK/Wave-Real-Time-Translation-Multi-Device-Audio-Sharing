# Peer Identification in Theater Setup

Source: `theater_setup_screen.dart`, lines 65–85 and 88–103.

## UI source
`AnimatedBuilder` rebuilds from `WaveNative.instance`. It reads `native.peers`; each `peer` is treated as a key-value structure.

The per-peer ID expression is:

```dart
final id =
    (native.currentMode == 'bluetooth'
            ? peer['address']
            : peer['id'])
        ?.toString() ??
    '';
```

## What this means
- In Bluetooth mode, this screen prefers the peer's `address`.
- In other modes, it prefers the peer's `id`.
- The value is stringified if present and otherwise becomes an empty string.
- That derived ID is shown as the device heading and passed to `assign(id, v)` when a new position is chosen.

## Assumptions to review
- The UI does not validate that IDs are nonempty or unique.
- It does not prove that all modes return the expected peer fields.
- A transport-specific ID may be sensitive metadata; do not expose it in unnecessary consumer UI.

## Viva distinction
This file **reads** an existing peer list; it does not discover nearby devices or establish the transport connection.