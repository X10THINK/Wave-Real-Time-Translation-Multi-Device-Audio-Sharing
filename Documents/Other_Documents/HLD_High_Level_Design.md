# Wave — High Level Design

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `06_HLD_Wave_High_Level_Design.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> HIGH LEVEL DESIGN

> System components, boundaries and end-to-end flows

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-HLD-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | High Level Design |
| Document ID | ZAEROX-WAVE-HLD-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Architectural drivers and top-level view

03 Subsystems and ownership

04 Control-plane and media-plane boundaries

05 Host and Receiver sequence at high level

06 Translation processing overview

07 Deployment and trust boundary overview

08 Non-functional scaling and failure modes

## 02 Architectural drivers and top-level view

The High-Level Design (HLD) defines a modular target architecture separating the local, sometimes-offline Audio Share data plane from the internet-dependent Live Translation and account/billing control plane. Components are logical boundaries, not assertions that deployed services exist.

```text
ANDROID WAVE CLIENT CLOUD SERVICES (PROPOSED)
+---------------------------+ +------------------------------+
| Flutter UI + Session Hub | | Identity + Entitlements |
| Host / Receiver |<--------->| Translation Session API |
+-------------+-------------+ TLS | Usage Ledger / Quota |
| | AI Streaming Gateway |
+-------------v-------------+ +--------------+---------------+
| Session + Membership Core | |
| Join / Approvals / Rejoin | v
+-------------+-------------+ AI Provider (OPEN)
|
+-------------v-------------+
| Local Connectivity Engine |
| Wi-Fi / Hotspot / BT |
| Relay discovery & routing |
+-------------+-------------+
|
+-------------v-------------+
| Media + Sync Engine |
| timestamp, clock, buffer |
| source adapters + output |
+---------------------------+
```

The exact cloud topology, Bluetooth protocol mix and streaming provider are candidate implementation choices subject to architectural decision records and device tests.

## 03 Subsystems and ownership

| Subsystem | Responsibility | Key interfaces / status |
| --- | --- | --- |
| Presentation | Home, method, role, host/receiver, sessions, translation UX | Flutter widgets; LOCKED UX |
| Session coordinator | Room identity, role, join approval, lifecycle, rejoin | Local PeerChannel; PROPOSED |
| Transport adapters | Capability checks, discovery, Wi-Fi/Hotspot/Bluetooth sockets | Android native plugins; TARGET |
| Relay controller | Dynamic forwarding eligible peers, route repair, loop defense | Internal only; TARGET |
| Media source adapters | Music file, local Host video audio, supported playback capture | Android MediaProjection eligibility; TARGET |
| Sync engine | Time samples, scheduled playout, drift, discontinuities | Media timeline events; TARGET |

| Subsystem | Responsibility | Key interfaces / status |
| --- | --- | --- |
| Translation coordinator | Speaker authorization, target language streams, caption/voice fanout | Authenticated gateway; PROPOSED |
| Account/billing | Identity, entitlement, hosted payer, quota, immutable ledger | Trusted server; LOCKED policy / PROPOSED design |
| Observability | Crash, health, latency, provider spend and security events | Privacy-filtered telemetry; PROPOSED |

## 04 Control-plane and media-plane boundaries

| Operation | Control flow | Media / billing effect |
| --- | --- | --- |
| Create Audio Share | Host creates local session; room tokens generated | No cloud billing |
| Join | Peer discovers/validates room; optional approval | Media key issued only after admission |
| Play/Pause/Seek | Host sends sequenced state change with timeline | Receivers schedule matching behavior |
| Receiver local pause | Receiver output state only | Forwarding unaffected if relay eligible |
| Translation create | Account -> entitlement -> sponsored session | Payer context bound server side |
| Speaker stream | Authenticated speaker grant checked | Metered AI processing and language output |
| Quota stop | Backend threshold and atomic usage enforcement | Reject further billable work, notify clients |

No module may treat a room code, a payment indicator in local storage, or a connection-level Bluetooth pairing as equivalent to an authenticated and authorized session.

## 05 Host and Receiver sequence at high level

```text
Host Session Core Network Receiver
| Create | | |
|----------------->| New session | |
| Lobby / invite | | |
| |<---- JOIN + proof ---------------|
|<--- Approval? ---| | |
| ACCEPT --------->|--- admission+key -------------->|
| Start ---------->| | |
| Choose source -->| | |
| PLAY(seq, time)->|--- timed MEDIA ---------------->|
| Pause ---------->|--- control -------------------->|
| End ------------>|--- invalidate ----------------->|
```

Recovery retains authoritative sequence/epoch information, checks peer membership again, and discards stale media and duplicate control events. Specific protocol fields are detailed in the LLD and API docs.

## 06 Translation processing overview

```text
Signed-in Host -- entitlement validated -- sponsored session
|
Admitted signed-in Receiver -- selected language
|
Authorized Speaker -> audio ingress -> AI gateway -> STT/translation/TTS
|
shared language streams
|
translated voice + captions
|
metering -> Host usage ledger
```

- The initial supported prototype language pair is Tamil and English; broader language matrix is OPEN.

- Reuse translated results per target language where consent, correctness, latency and provider policy permit.

- Keep provider API keys and payment credentials entirely server-side.

- Degraded state must distinguish unavailable provider, unsupported language, insufficient quota and lost stream.

## 07 Deployment and trust boundary overview

| Boundary | Trust properties | Release gate |
| --- | --- | --- |
| Device local session | Authenticated local handshake and rotating ephemeral keys | Join, replay, spoofing and peer-removal tests |
| Device to cloud | TLS, access token, per-session authorization | Security review and negative tests |
| Billing gateway | Atomic limits, idempotent usage recording, reconciled provider cost | Usage audit, double-charge test |
| Provider integration | Server-held secrets, redaction, opt-in disclosure | Vendor review, privacy approval |
| Data at rest | Minimal identities and metadata; encryption/retention controls | Deletion and backup recovery tests |

Hosting location, regional compliance requirements, retention periods, backups and SLOs are business/operations OPEN decisions.

## 08 Non-functional scaling and failure modes

| Risk | Architecture response | Verification |
| --- | --- | --- |
| Hotspot peer cap | Capability-based limits and UX guidance, never fixed unsupported number | Device matrix by model |
| Bluetooth relay throughput | Controlled fanout, hop budget, bandwidth accounting | 4-phone and escalating topology tests |
| Clock drift | Monotonic clock estimates, scheduled playout, drift correction | Loopback skew measurements |
| Host process death | Fail safe Ended/Reconnecting until authority proven | Force-stop / OS kill tests |
| AI provider outage | Backoff; stop/limit billable streams; clear fallback | Failure injection |
| Cloud partial failure | Idempotent session and usage transitions | Retry / replay ledger tests |

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
