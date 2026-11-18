# Wave TRD — 04 Session protocol, lifecycle and membership

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 6, 7  
**Status:** Source working draft; no claim of implemented completion.

## 04 Session protocol, lifecycle and membership

### Canonical session state machine

| State | Entry / possible transitions | Required invariant |
| --- | --- | --- |
| CREATING | Local room setup -> LOBBY or ERROR. | Session ID generated once; no media playback before valid setup. |
| LOBBY | Accept new members -> READY/ENDED. | Invite valid; approval and capacity enforcement. |
| READY | Start complete, source not selected -> LIVE/PAUSED/ENDED. | Session alive; no false Sharing status. |
| LIVE | Source available -> PAUSED/RECONNECTING/ENDED. | Host timeline authoritative; audio routed to admitted members. |
| PAUSED | Host pause or movie view exit -> LIVE/ENDED. | Connections/room remain active; no movie audio sent. |
| RECONNECTING | Transport lost -> prior state/ERROR/ENDED. | Same session identity and replay protection. |
| ENDED | Host end or expiry -> History. | No automatic resume; tokens revoked and media stopped. |

### Membership and role invariants

- Host owns session configuration, room approval, media control and global End. A Receiver can change only their own output state and may be promoted to an authorized translation speaker.

- Relay status is a dynamically assigned transport responsibility; never assign it as a separate UI registration role.

- Room codes and QR payloads identify/locate the session but cannot grant access alone. Host-only approval setting is distinct from cryptographic/admission validation.

- Use unique session_id, member_id, device_instance_id, participant role and membership version/epoch to reject stale memberships and duplicate joins.

- Define idempotent join and command IDs; retries should not create duplicate participants, sessions, ledger entries or playback actions.

### Proposed session message envelope

| Field | Semantics |
| --- | --- |
| protocol_version | Semantic major/minor; reject incompatible major with helpful response. |
| session_id / member_id | Cryptographically unpredictable session identifier and current authorized sender identity. |
| epoch / sequence | Monotonic room generation and sender sequence to detect replay/reordering. |
| message_type | JOIN_REQUEST, JOIN_ACCEPT, APPROVAL, SYNC, PLAY, PAUSE, SEEK, SOURCE, LEAVE, END, etc. |
| issued_at / expires_at | Clock/context-aware expiry; never rely on remote wall-clock alone for media playout. |
| payload / auth_tag | Typed encoded body and integrity protection using session keys. |
