# Wave — Software Test Plan

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `13_STP_Wave_Software_Test_Plan.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> SOFTWARE TEST PLAN

> Strategy, environments, performance measures and release gates

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-STP-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Software Test Plan |
| Document ID | ZAEROX-WAVE-STP-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Purpose, entry criteria and test policy

03 Scope and exclusions

04 Environment matrix and test instrumentation

05 Test levels and types

06 Functional and scenario coverage

07 Performance metrics and non-negotiable measurement

08 Defects, severity, evidence and exit decisions

09 Roles and reporting cadence

## 02 Purpose, entry criteria and test policy

The Software Test Plan (STP) defines test strategy, responsibilities, environments, metrics and release gates for Wave. Product and engineering targets are tested without implying that passing tests already exist. Testing follows business requirement -> software requirement -> case -> evidence -> defect -> release decision traceability.

| Gate | Entry / exit condition |
| --- | --- |
| Design gate | Frozen BRD/PRD/SRS, supported Android matrix and defined performance budgets |
| Build gate | Reproducible debug/release builds, signed test artifacts, permissions manifest review |
| Functional gate | Must-priority journeys pass on required devices / no critical blocker |
| Security / billing gate | No unauthorized translation; no spending without server entitlement/grant |
| Performance gate | Actual measured and signed-off skew, latency, capacity and recovery on target matrix |
| Release gate | Owner acceptance + privacy/security/operations sign-off; explicit known limitations |

## 03 Scope and exclusions

| Category | Included tests | Excluded / separate |
| --- | --- | --- |
| Audio Share | Three sources, join approval, capacity validation, background, Host/Receiver playback | Microphone Audio Share source; receiver video |
| Networking | Wi-Fi, hotspot and Bluetooth direct/relay experiment | Claims of unlimited devices / unmeasured mesh |
| Live Translation | Mandatory auth, Host-paid, languages, caption/voice, speakers, quota | Offline cloud AI, unapproved provider claims |
| Security | Room handshake, replay, access isolation, secret handling | Third-party pen-test certificate until commissioned |
| UX | 19-screen Audio Share inventory, translation states, accessibility | Unapproved new theme/component redesign |
| Operations | Build install/update, crash recovery, backup, spend halt | No guaranteed service SLA before targets defined |

## 04 Environment matrix and test instrumentation

| Matrix axis | Required coverage | Evidence to capture |
| --- | --- | --- |
| Android OEM/version | At least representative Samsung and other Android brands + API levels selected by team | Build ID, OS, model, chipset |
| Audio output | Phone speaker, wired earbuds where available, Bluetooth earbuds/headsets | Actual eardrum-path timing/skew method |
| Network | Same-router Wi-Fi, isolated hotspot, Bluetooth direct/relay; interference scenarios | RSSI, peer count, RTT/loss, topology |
| Lifecycle | Foreground, background, screen-off, battery restrictions, process kill | Foreground-service, connectivity and playback log |
| Media | Music, imported video, permitted/blocked app playback | Source eligibility, AV sync, capture consent |
| Cloud | Normal, slow AI, outage, usage limit, concurrent speakers | Trace IDs, duration, cost counters |

## 05 Test levels and types

| Level | Objective | Owner |
| --- | --- | --- |
| Unit | Session reducer, validation, replay/epoch, offset estimator, ledger idempotency | Feature developer |
| Component | Source adapters, permission handling, local handshake, speaker authorization | Android/backend engineer |
| Integration | Multi-phone Host/Receiver, authenticated translation API and usage events | Integration QA |
| End-to-end | Classroom, group tour, imported movie and external audio | QA + product owner |
| Performance | Skew, jitter, latency, CPU, battery, dropout, capacity | Performance test lead |
| Security | Join attacks, token expiry, revoked speaker, quota bypass | Security lead |
| Accessibility | Contrast, TalkBack, text scaling, keyboard/screen readers as applicable | UX QA |
| Regression | Approved locked flows unchanged across changes | QA automation |

## 06 Functional and scenario coverage

| Test suite | Key scenarios | SRS links |
| --- | --- | --- |
| AS-HOST | Room creation, lobby, source, global control | SRS-AS-002 to 005, 009, 012 |
| AS-RECV | QR/code, approvals, local controls, leave | SRS-AS-006 to 011 |
| AS-MEDIA | Music, video and Android external-audio capture | SRS-AS-004,008,009,014 |
| NET | Readiness, hotspot setup, Bluetooth relay, reconnect | SRS-GEN-004 to 008; NFR-001/002 |
| LT-ID | All Host/Receiver sign-in; paid Host vs sponsored receiver | SRS-LT-001 to 004 |
| LT-VOICE | Speech -> voice/caption, language selection, speaker grants | SRS-LT-005 to 008 |
| BILL | Host attribution, quota, duplicate events, provider outage | SRS-LT-009 to 011 |
| SEC | Replay, stale room and unauthorized joins | SRS-GEN-010; NFR-005/006 |

## 07 Performance metrics and non-negotiable measurement

| Metric | Method | Release threshold |
| --- | --- | --- |
| Receiver-to-receiver skew | Simultaneous waveform/tone capture at physical outputs across devices | OPEN: product owner approves measured target |
| Host movie A/V mismatch | Camera/loopback with timed on-screen marker and receiver output | OPEN, must be measured |
| Capture-to-receiver delay | Host input timestamp to decoded output / acoustic measurement | OPEN by source type |
| Network recovery | Time from induced disconnect to synchronized output | OPEN by transport |
| Audio drops and buffer underrun | Count per minute across representative audio samples | OPEN |
| Relay capacity | Max sustainable hops/peers at quality threshold | OPEN, no fixed supported number |
| Translation latency | Speech boundary to caption and generated output | Initial aspiration ~1-2 s, not SLA |
| AI costs | Provider-recorded units vs Host ledger and plan | Zero unauthorized and unreconciled charges |

## 08 Defects, severity, evidence and exit decisions

| Severity | Example | Release effect |
| --- | --- | --- |
| Blocker | Unauthenticated translation, unauthorized charges, privacy leak | Stop release |
| Critical | Broken join path, data loss, Host Stop fails, reproducible mass disconnect | Stop release |
| Major | Frequent unusable sync or background failures on supported devices | Product waiver required; otherwise stop |
| Minor | Cosmetic inconsistency with workaround and no security impact | Triage with clear known issue |

- Every execution record includes build hash, date/time, device model, OS, inputs, expected vs actual, raw evidence reference and tester.

- A pass is recorded only when executed; previous chat narrative is preliminary evidence and not a test certificate.

- Retest fixed defects and affected adjacent journeys; publish unresolved known risks and scope restrictions.

## 09 Roles and reporting cadence

| Role | Ownership |
| --- | --- |
| QA lead | Maintains suite and release summary |
| Android/network tester | Physical radio and background tests; packet traces |
| Media tester | Receiver synchronization and Host movie lip-sync recordings |
| Backend/security tester | Auth/entitlement/reconciliation/injection tests |
| Product owner | Approves business acceptance budgets and design behavior |
| Release owner | Signs build, rollout, monitoring, rollback and known limitation checklist |

The historical three-member testing effort offers useful observations but is not automatically the formal sign-off team. Assign named owners and build IDs at each release candidate.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
