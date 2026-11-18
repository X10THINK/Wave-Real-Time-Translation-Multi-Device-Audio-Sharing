# Wave TRD — 02 System objectives, boundaries and design principles

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 4  
**Status:** Source working draft; no claim of implemented completion.

## 02 System objectives, boundaries and design principles

Wave is a Flutter Android application with native Android responsibilities for connectivity, media capture/playback and foreground services. The system supports two distinct data paths: an offline-capable local Audio Share plane, and an internet-dependent AI translation plane. A shared session/core routing layer governs both services, but authentication and billing rules differ.

### Architecture principles

- Preserve product navigation and all latest locked UI decisions; build modules behind stable product contracts rather than replacing screens.

- Explicitly distinguish control plane (join, permissions, session states, commands) from media/data plane (encoded audio frames, translation voice segments, captions).

- All transport-specific operations must be behind interchangeable interfaces; do not assume Wi-Fi, hotspot and Bluetooth have equal capacity/latency.

- Use authoritative server-side enforcement for paid translation access and usage; never trust client-side balances or role assertions.

- Use monotonic clocks and timestamps for sync, independent of wall-clock changes; recognize output-device latency.

- Make recovery idempotent: reconnecting must not create duplicate billable sessions, double-charge or replay stale media.

- Fail visibly and securely when an Android restriction, cloud dependency or hardware limit cannot be satisfied.

Source-of-truth precedence: 16 Nov 2026 Live Translation all-account sign-in supersedes earlier guest-translation proposals. Audio Share remains guest-accessible. All users still select transport first, role second, and then Create/Join; sign-in occurs in context of translation branches.

### Technical non-goals

No fabricated guarantee of unlimited Bluetooth hops or peers; no Receiver video streaming; no microphone Audio Share source; no bypass of Android content-capture policy; no full offline AI translation; no production claim for a selected AI vendor, billing provider, storage backend or exact codec until verified.
