# Wave TRD — 12 Candidate network and backend interfaces

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 14  
**Status:** Source working draft; no claim of implemented completion.

## 12 Candidate network and backend interfaces

### API surface (illustrative; not deployed endpoints)

| Interface | Method / event | Responsibility |
| --- | --- | --- |
| /v1/identity/session | POST | Create or refresh authenticated account/session token via chosen identity service. |
| /v1/translation/sessions | POST | Create sponsored translation session after entitlement authorization. |
| /v1/translation/sessions/{id}/join | POST | Join authenticated account; validate room and approval policy. |
| /v1/translation/sessions/{id}/speakers | PATCH | Grant/revoke speaker rights with Host-bound authorization. |
| /v1/translation/sessions/{id}/usage | GET | Read server-calculated Host budget/usage summary. |
| /v1/translation/stream | WebSocket / WebRTC candidate | Send authorized speech audio; deliver language-scoped voice/caption events. |
| Local PeerChannel | Encrypted local socket | Transport-independent JOIN, SYNC, PLAY, PAUSE, SEEK, SOURCE, MEDIA, LEAVE, END. |

### Contract requirements

- Every sensitive backend method requires server-verifiable identity, session-scoped authorization and idempotency where applicable.

- Use versioned payload schemas and explicit error codes: UNAUTHENTICATED, NOT_ENTITLED, NOT_ADMITTED, NOT_SPEAKER, QUOTA_EXCEEDED, SESSION_ENDED, UNSUPPORTED_LANGUAGE, TRANSPORT_UNAVAILABLE.

- Never expose AI provider secrets or payment credentials in Flutter code, QR payloads or logs.

- Choose transport technology (streaming WebSocket/WebRTC/UDP/local sockets) after comparing delay, reconnect semantics, security and resource cost on target devices.
