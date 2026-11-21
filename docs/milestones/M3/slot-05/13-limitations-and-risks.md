# Theater Setup Limitations and Review Risks

**Basis:** `theater_setup_screen.dart` entire source. These are source-based findings, not executed tests.

| Component | Seen in source | Limitation |
|---|---|---|
| Position tables | Nine names and hints, indices 0–8 | No measured physical coordinates |
| Host peer cards | `native.peers` | Peer discovery and completeness are elsewhere |
| Peer identity | Bluetooth `address`, other-mode `id` | Missing/duplicate identifiers not validated here |
| Assignment | Async `assignSpeaker(id, role)` | Remote acknowledgement not demonstrated |
| Pending state | Local `Set<String>` | No persisted queue or explicit retry mechanism |
| Role values | Receiver clamps numeric role | Host dropdown lacks local range clamp |
| Receiver presentation | Shows assigned label and hint | No proof of actual audio-channel routing |
| Surround audio | Source explicitly warns discrete splitting is not enabled | Cannot claim finished 5.1/7.1 theater |

**Engineering and presentation rule:** Describe implemented interface behavior precisely and keep unverified transport, DSP and synchronization performance separate. Working Dart source remains untouched.