# Wave TRD — 09 Identity, account access and speaker authorization

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 11, 12  
**Status:** Source working draft; no claim of implemented completion.

## 09 Identity, account access and speaker authorization

### Authentication rules

| Flow | Enforced by | Technical requirement |
| --- | --- | --- |
| Basic Audio Share | Local session coordinator | No mandatory account. Still require secure local room admission and revocable membership. |
| Translation Host | Identity and entitlement backend | Verified account before creating/starting billable session. |
| Translation Receiver | Identity backend + session gateway | Verified account before join, including Host-paid sponsored access. |
| Authorized speaker | Session owner policy + backend | Host permits microphone upload; server rejects unauthorized speaker frames. |

### Proposed auth/token lifecycle

- Use a supported authentication provider and server-verifiable access tokens; exact provider and required registration fields are open product decisions.

- Use short-lived, session-scoped join credentials with audience, session, user, membership, role, expiry and revocation semantics.

- Refresh/re-authenticate according to provider policy without implicitly admitting signed-out users. Host transfer/owner election is out of scope until formally designed.

- Do not use room code, QR content, nickname or Bluetooth pairing alone as translation account authentication.

- Credential/device compromise and banned/removed participants must revoke access to media, speaker controls and paid AI processing.

### Threat model highlights

| Threat | Required defense |
| --- | --- |
| Forged room/speaker | Authenticated membership and Host-authorized speaker grants. |
| Replay/old packets | Session key, epoch, nonce/counter, replay window and command version. |
| Unauthorized host billing | Backend entitlement, sponsor-bound claims and per-event rate checks. |
| Guest translation bypass | Server rejects unauthenticated Receiver even when Host sponsors. |
| Session/link eavesdropping | Encryption of audio/control packets and secure handshake; keys scoped to session. |
| Room-code guessing | Rate limiting, expiry and handshake beyond short code. |
