# Wave — API Documentation

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `11_API_Wave_API_Documentation.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> API DOCUMENTATION

> Proposed backend endpoints, local protocols and event schemas

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-API-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | API Documentation |
| Document ID | ZAEROX-WAVE-API-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 API scope, security and versioning

03 Identity, entitlement and room APIs

04 REST request and response examples

05 Streaming events and sequencing

06 Local peer control frame schema

07 Errors, rate controls and observability

08 Contract testing and release checklist

## 02 API scope, security and versioning

The API Documentation defines candidate backend REST and streaming contracts for account-required Live Translation. These are illustrative v1 interfaces, not deployed endpoints. Local Audio Share peer control is a separate transport-independent protocol and generally requires no public cloud API.

| Rule | Contract expectation |
| --- | --- |
| Base path | /v1/ is version prefix; deployment host remains OPEN |
| Authentication | Bearer token validated by backend for every translation endpoint |
| Authorization | Session membership, payer entitlement and speaker grants independently enforced |
| Content | application/json for control; binary encoded stream frames over chosen secure media channel |
| Idempotency | Idempotency-Key for chargeable creation / settle / session transitions |
| Errors | Stable code, message, correlation_id, retryable, details; never provider secrets |
| Network security | HTTPS / WSS or equivalent secure channel; tokens never in URL / QR |

## 03 Identity, entitlement and room APIs

| Method + endpoint | Input / auth | Response / rule |
| --- | --- | --- |
| POST /v1/identity/session | Provider identity proof; server validates subject | Short-lived access token / renewal policy |
| GET /v1/entitlements/me | Bearer Host account | Effective plan, validity, remaining allowance if approved |
| POST /v1/translation/sessions | Host bearer; name/approval/transport; Idempotency-Key | 201 sessionId; entitlement check required |
| GET /v1/translation/sessions/{id} | Authenticated admitted user | Allowed room info; do not leak private membership |
| POST /v1/translation/sessions/{id}/join | Receiver bearer; valid invite proof | Admitted / Pending / Denied |
| POST /v1/translation/sessions/{id}/leave | Member bearer | Removes member only |
| POST /v1/translation/sessions/{id}/end | Host bearer | Terminal; cancel billable stream |

| Method + endpoint | Input / auth | Response / rule |
| --- | --- | --- |
| PATCH /v1/translation/sessions/{id}/ speakers | Host bearer; actor/grant action | Grant, revoke, expiresAt |
| GET /v1/translation/sessions/{id}/usage | Host bearer only | Ledger-based spent/remaining data |

## 04 REST request and response examples

```text
POST /v1/translation/sessions
Authorization: Bearer <redacted-token>
Idempotency-Key: 9f0c-unique-request
Content-Type: application/json
{ "roomName": "Classroom A", "transport": "wifi",
"joinApproval": true, "requestedMaxParticipants": 20 }
201 Created
{ "sessionId": "uuid", "state": "LOBBY", "payer": "HOST",
"entitlement": { "eligible": true },
"sessionEpoch": 1 }
POST /v1/translation/sessions/{id}/join
Authorization: Bearer <receiver-token>
{ "inviteProof": "proof-value", "desiredLanguage": "ta" }
202 Accepted
{ "membershipId": "uuid", "state": "PENDING_APPROVAL",
"roomState": "LOBBY" }
# On approved join: state=ADMITTED; personal paid plan NOT required.
```

Example identifiers, request values and endpoint spellings are illustrative only; freeze schemas and authorization policies before SDK or client implementation.

## 05 Streaming events and sequencing

| Event | Direction | Important fields / rule |
| --- | --- | --- |
| stream.open | Client -> gateway | sessionId, membershipId, language, speakerGrantId |
| audio.chunk | Authorized speaker -> gateway | streamId, seq, tsMono, codec, encryptedAudio |
| caption.partial/final | Gateway -> language subscribers | sourceSeq, lang, text, isFinal, timing |
| voice.segment | Gateway -> language subscribers | lang, segmentId, startTime, codec, audio |

| Event | Direction | Important fields / rule |
| --- | --- | --- |
| speaker.revoked | Server -> client | targetAccount, effectiveAt; stop uploads |
| quota.warning / exceeded | Server -> clients | payer state, usage remaining; stop processing |
| stream.closed / error | Bidirectional | reasonCode, correlationId, retryable |

```text
{
"type": "caption.final", "sessionId": "uuid",
"streamId": "uuid", "sequence": 148,
"language": "ta", "sourceTimestampUs": 35240000,
"text": "<translated caption>",
"correlationId": "uuid"
}
```

## 06 Local peer control frame schema

| Type | Required fields | Receiver rule |
| --- | --- | --- |
| HELLO / CHALLENGE / JOIN | roomId, epoch, nonce, protocolVersion, proof | Verify authority before admission |
| MEMBER_ADMITTED / REVOKED | memberId, epoch, capabilities, keyRef | Update permissions and keys |
| SYNC_SAMPLE | tHostSend, tRecv, tHostAck, epoch | Estimate monotonic offset/jitter |
| PLAY / PAUSE / SEEK | streamId, sequence, effectivePtsUs, epoch | Apply only if newer authorized Host event |
| SOURCE_CHANGE | old/new streamId, codec, timelineZero | Discard stale source frames |
| MEDIA_FRAME | streamId, seq, pts, duration, TTL, auth | Verify/dedupe/schedule and optional relay |
| LEAVE / END | member/session ID, epoch, messageId | Leave is local; Host End terminal |

## 07 Errors, rate controls and observability

| Code | Client meaning | Security / retry expectation |
| --- | --- | --- |
| UNAUTHENTICATED | Sign in required | 401; no protected data |
| NOT_ENTITLED | Host plan invalid | 403; do not start AI |
| NOT_ADMITTED | Membership not approved | 403; no stream data |
| NOT_SPEAKER | Speaking right revoked/missing | 403; no upload accepted |
| QUOTA_EXCEEDED | Host budget/limit depleted | Stop new AI work; explicit upgrade UX |
| SESSION_ENDED | Host ended session | 410; do not auto-recreate |

| Code | Client meaning | Security / retry expectation |
| --- | --- | --- |
| UNSUPPORTED_LANGUAGE | Selection not currently supported | 422 with supported alternatives |
| TRANSPORT_UNAVAILABLE | Local network/radio unusable | Contextual system fix |
| RATE_LIMITED | Too many requests | 429 with Retry-After |

- Enforce per-account, per-session and per-stream limits independently.

- Never record bearer tokens, microphone frames, invite proofs or payment secrets in general logs.

- Correlate client errors and server traces using privacy-safe correlation IDs; record billing adjustments as separate events.

## 08 Contract testing and release checklist

| Area | Required test |
| --- | --- |
| Authentication | Anonymous Receiver denied translation; signed-in sponsored Receiver permitted |
| Authorizations | Non-Host cannot grant speaker; revoked speaker blocked immediately |
| Entitlement | Unpaid Host cannot create paid stream; client falsified paid flag ignored |
| Idempotency | Repeated creates/usage events do not duplicate rooms or charges |
| Schema evolution | Old client receives versioned error and upgrade instructions |
| Stream recovery | Duplicate/out-of-order captions and segments reconciled |
| Privacy | URLs, logs and caches contain no provider secrets |
| Quota | Stress test simultaneous speakers and just-in-time stop budget |

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
