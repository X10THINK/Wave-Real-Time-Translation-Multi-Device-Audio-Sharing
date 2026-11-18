# Wave — Software Architecture Document

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `08_SAD_Wave_Software_Architecture_Document.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> SOFTWARE ARCHITECTURE

> DOCUMENT

> Architecture viewpoints, quality attributes and trade-offs

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-SAD-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Software Architecture Document |
| Document ID | ZAEROX-WAVE-SAD-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Architectural scope and quality drivers

03 Context and external dependencies

04 Logical, process and deployment viewpoints

05 Scenario-based architectural analysis

06 Architecture risks and mitigations

07 Interfaces, decision ownership and evolution

## 02 Architectural scope and quality drivers

This Software Architecture Document (SAD) complements the HLD with architecture viewpoints, external dependencies, trade-offs, constraints, and architecturally significant risks. It records a proposed design baseline rather than claiming the current Wave source realizes every component.

| Quality attribute | Driver / scenario | Architectural response |
| --- | --- | --- |
| Availability | Transient local disconnect must not destroy valid session | Session state and bounded reconnection |
| Latency | Movie lip-sync and receiver skew matter to user experience | Monotonic clock, timestamped frame scheduling |
| Scalability | Local peer count and relay density vary by transport | Capability probes, fanout caps and capacity tests |
| Security | QR spoofing and unauthorized billable speech must be blocked | Ephemeral room keys; server speaker and payer checks |
| Cost | Group usage can multiply AI expenses | Shared language streams, spend limits, ledger |
| Portability | Android vendors and versions differ | Native adapter capability matrix |
| Accessibility | Users need clear no-network/error states | Contextual fixes, accessible controls, contrast |

## 03 Context and external dependencies

```text
[Host/Receiver Android Devices]
|
| Local Wi-Fi / Hotspot / Bluetooth
v
[Peer Relay + Media Sync]
|
| Authenticated client -> cloud (translation only)
v
[Identity] - [Session / Speaker Authority] - [Quota Ledger]
|
[Speech AI Gateway]
|
[AI Provider: OPEN]
|
[Language outputs]
```

- The Host acts as local room authority for Audio Share; translation payer, account and spending authority live in trusted backend services.

- Device operating system supplies connectivity, audio playback/capture and system permissions.

- No dedicated ZAEROX hardware is required for the baseline software product.

## 04 Logical, process and deployment viewpoints

| View | Design contents | Not yet verified |
| --- | --- | --- |
| Logical | Presentation, session, transport, routing, media, sync, account, speech, billing | Cross-module contracts in source |
| Process | Host media producer, N peer consumers, optional relay tasks; AI gateway streams per language | Concurrency and queue bounds |
| Development | Flutter feature modules + Android platform bridge; backend API modules; schema contracts | Source repository implementation parity |
| Deployment | APK distributed to devices; local peer network; internet gateway for AI | Cloud provider/location and SLO |
| Data | Ephemeral room state, accounts, grants, billing ledger, language preferences | Retention and residency policy |

## 05 Scenario-based architectural analysis

| Scenario | Design behavior | Critical evidence |
| --- | --- | --- |
| Classroom 50+ listeners | Wi-Fi multicast/unicast architecture chosen after measurements; relay may be optional | Measured capacity and skew |
| Moving tourist group | Dynamic route changes and reconnect visualization | Mobile link-loss field test |
| One Host movie + multiple receivers | Receivers audio only; host video/audio aligned | A/V timeline instrumentation |
| Receiver pauses while forwarding | Local output off; relay queue continues | Hop topology under pause |
| Host pays for group question | Server validates speaker and payer; single ledger owner | No unauthorized usage / double charge |
| Provider quota exhausted | Throttle/stop billable streams while preserving UI safety | Reconciled provider-vs-ledger audit |

## 06 Architecture risks and mitigations

| ID | Risk | Mitigation / gate |
| --- | --- | --- |
| AR-01 | Android Bluetooth fanout and mesh infeasible at desired scale | Benchmark direct and relay fanout before promises |

| ID | Risk | Mitigation / gate |
| --- | --- | --- |
| AR-02 | Third-party source capture disallowed | Eligibility checks and source unavailable state |
| AR-03 | Audio clock drift causes audible echo | Shared playout model and skew instrumentation |
| AR-04 | Translation API latency/cost unstable | Provider experiments and budget gate |
| AR-05 | Client-side payment bypass / duplicate charge | Server-ledger authorization, idempotency |
| AR-06 | Process kill breaks resumed session | State recovery protocols, truthful history |
| AR-07 | Radio or hotspot permissions vary by OEM | Capability matrix and role-specific fix prompts |
| AR-08 | Speech privacy/retention misunderstood | Consent, minimization, retention review |

## 07 Interfaces, decision ownership and evolution

| Contract | Producer -> consumer | Owner |
| --- | --- | --- |
| Room control events | Host SessionController -> peer SessionController | Local session team |
| Media frames | Source manager -> local transport -> sync receiver | Audio/network team |
| Join/auth challenge | Discovery -> admission authority | Security/network team |
| Translation commands | Signed-in client -> backend service | Backend/identity team |
| Speech segments | Authorized source -> gateway -> language subscribers | AI/backend team |
| Usage events | Provider adapter -> immutable ledger -> Host summary | Billing/backend team |

Architecture governance: PRD defines customer-facing behavior, SAD documents system-wide rationale, HLD shows components, LLD specifies algorithms, ADR records trade-offs, API and DB docs define external/data contracts, STP validates outcomes. Any architectural change must propagate across these artifacts.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
