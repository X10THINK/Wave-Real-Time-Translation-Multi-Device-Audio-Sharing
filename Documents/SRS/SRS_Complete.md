# Wave — Software Requirements Specification

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> SOFTWARE REQUIREMENTS

> SPECIFICATION

> Functional and non-functional software requirements

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-SRS-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Software Requirements Specification |
| Document ID | ZAEROX-WAVE-SRS-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Purpose, scope and system boundary

03 Actors, assumptions and operating environment

04 General and session requirements

05 Audio Share functional requirements

06 Live Translation and identity requirements

07 Quality, security and performance requirements

08 External interfaces and requirement traceability

## 02 Purpose, scope and system boundary

The Software Requirements Specification (SRS) defines verifiable system behaviors for the Wave Android app, local transport and media engine, and proposed identity, translation and billing services. It complements the BRD business outcomes, PRD user needs, and TRD technical approach.

| Boundary | Included | Excluded or gated |
| --- | --- | --- |
| Client | Flutter Android UI, native audio, local transports, session and playback state | iOS and desktop clients (future) |
| Audio Share | Wi-Fi, hotspot and Bluetooth selection; Music, Host Video audio and permitted External App Audio | Microphone as Audio Share source; receiver-side video |
| Live Translation | Signed-in Host/Receiver, hosted paid sessions, audio/captions and optional speaker grants | Unauthenticated translation guests; fully offline AI translation |
| Infrastructure | Proposed authorization, entitlement, usage accounting, stream routing | Provider choices and deployment platform are not finalized |

Requirement status convention: LOCKED = approved behavior; TARGET = performance/deployment objective to verify; PROPOSED = candidate solution; OPEN = needs product/engineering approval. Release priority does not certify completion.

## 03 Actors, assumptions and operating environment

| Actor | Responsibilities | Constraints |
| --- | --- | --- |
| Audio Share Host | Creates room, invites, selects source, controls shared timeline, ends session | May be guest; device capability governs sources |
| Audio Share Receiver | Discovers/joins, listens, locally controls output, can relay internally | Admission handshake and network checks required |
| Translation Host | Signs in, proves entitlement, pays for authorized group usage, controls speaker rights | Must use server-authorized billing controls |
| Translation Receiver | Signs in, joins valid room, selects language, receives translated output | No independent paid entitlement in Host-funded session |
| Cloud operations | Operates authenticated AI gateway, usage ledger, key rotation, observability | Provider and pricing remain OPEN |

- Target OS is Android; test versions, OEM builds and audio outputs must be documented in compatibility matrix.

- Cloud AI cannot be assumed offline; the translation gateway requires internet connectivity.

- Capturing third-party app playback is constrained by Android and source-app policy.

- Transport availability and participant limits must be measured, not promised universally.

## 04 General and session requirements

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-GEN-001 | The app shall display installed and in-app name Wave under ZAEROX brand. | Must | BR-01 |
| SRS-GEN-002 | The Home screen shall offer exactly Audio Share and Live Translation as primary feature entries. | Must | BR-01 |
| SRS-GEN-003 | The bottom navigation shall contain Audio Share, Home and Sessions; no standalone Connect or Music tab. | Must | BR-01 |
| SRS-GEN-004 | Both features shall request transport method before Host/Receiver role selection. | Must | BR-05 |
| SRS-GEN-005 | The method selector shall present Wi-Fi, Bluetooth and Mobile Hotspot as direct actions. | Must | BR-05 |
| SRS-GEN-006 | After transport selection the app shall run capability Stage A; after role selection Stage B shall validate role-specific readiness. | Must | BR-05 |
| SRS-GEN-007 | Network fix prompts shall be contextual and optional when no action is required; they shall not add mandatory success/setup pages. | Must | BR-05 |
| SRS-GEN-008 | A valid active session shall reopen from Sessions without recreating or blindly rejoining. | Must | BR-12 |
| SRS-GEN-009 | Ended session history shall not imply resume of a dead session without an explicit restart feature. | Must | BR-12 |
| SRS-GEN-010 | An admitted peer shall possess session-specific authorization; room-code/QR possession alone shall not grant access. | Must | BR-06 |

## 05 Audio Share functional requirements

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-AS-001 | Audio Share shall allow Host and Receiver access without mandatory sign-in. | Must | BR-02 |
| SRS-AS-002 | Host Create Session shall accept room name, maximum participants and Join Approval ON/OFF. | Must | BR-03 |
| SRS-AS-003 | Host shall enter Lobby and start session before choosing source from Live Host. | Must | BR-03 |
| SRS-AS-004 | Host source selector shall offer only Music Player, Video Player and Supported External App Audio. | Must | BR-04 |
| SRS-AS-005 | The system shall not expose Microphone as an Audio Share source. | Must | BR-04 |
| SRS-AS-006 | Receivers shall join via validated room code, QR, and Nearby only when technically supported. | Must | BR-06 |

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-AS-007 | With approval ON, admission shall await Host acceptance; with OFF, eligible peers shall join after validation. | Must | BR-06 |
| SRS-AS-008 | Receiver view shall play audio only; no receiver video stream or player shall be required. | Must | BR-04 |
| SRS-AS-009 | Host movie view minimize or screen lock shall pause movie video and shared movie audio but preserve the session. | Must | BR-03 |
| SRS-AS-010 | Receiver-local mute, volume, pause, output choice and leave shall not stop other receivers or necessary relay forwarding. | Must | BR-03 |
| SRS-AS-011 | Receiver resume shall realign to current Host media timeline and discard obsolete buffered frames. | Target | BR-13 |
| SRS-AS-012 | A Host global end shall invalidate the session and notify connected participants. | Must | BR-03 |
| SRS-AS-013 | Supported local sources shall be distributable without internet where a viable local transport exists. | Must | BR-02 |
| SRS-AS-014 | External App Audio shall activate only after supported Android capture consent and eligibility checks. | Must | BR-14 |
| SRS-AS-015 | Audio Share shall expose truthful Ready, Live, Paused, Reconnecting and Source-Unavailable states. | Must | BR-12 |

## 06 Live Translation and identity requirements

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-LT-001 | Every Live Translation participant shall authenticate before joining or creating a chargeable room. | Must | BR-07 |
| SRS-LT-002 | Translation method selection shall precede Host/Receiver role selection; sign-in shall be contextual within branch. | Must | BR-05 |
| SRS-LT-003 | Host shall obtain valid server-side paid entitlement before creating billable translation processing. | Must | BR-08 |
| SRS-LT-004 | An authenticated sponsored Receiver shall not need a separate paid entitlement for the Host-funded session. | Must | BR-08 |
| SRS-LT-005 | Receiver shall choose supported language for translated voice and captions. | Must | BR-09 |
| SRS-LT-006 | System shall support continuous authorized speaker capture with translation and voice/caption delivery. | Target | BR-09 |
| SRS-LT-007 | Only an authorized speaker shall be able to submit chargeable speech to the gateway. | Must | BR-11 |
| SRS-LT-008 | Host shall approve and revoke speaker privileges and be able to end sponsored usage. | Must | BR-11 |

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-LT-009 | Usage for all authorized speakers in sponsored rooms shall be charged to Host account. | Must | BR-08 |
| SRS-LT-010 | Provider tokens, payer authorization and usage limits shall be enforced by trusted backend controls. | Must | BR-10 |
| SRS-LT-011 | Quota exhaustion or entitlement expiry shall stop new billable work and return clear state. | Must | BR-10 |
| SRS-LT-012 | Supported language list, model provider and billable unit definition shall be config-driven / OPEN until approved. | Open | BR-09 |

## 07 Quality, security and performance requirements

| ID | Quality requirement and verification expectation | Status |
| --- | --- | --- |
| SRS-NFR-001 | Audio Share sessions must recover from transient disconnection without unauthorized membership reuse; measure interruption and state integrity. | TARGET |
| SRS-NFR-002 | Receiver-to-receiver audio skew, Host movie lip-sync, jitter and drift shall be measured in real hardware test matrix. | TARGET |
| SRS-NFR-003 | Background music and allowed capture shall be tested across Android versions, vendors, battery policies and headset profiles. | TARGET |
| SRS-NFR-004 | The app shall not claim a participant capacity or Bluetooth mesh range without reproducible test evidence. | LOCKED |
| SRS-NFR-005 | Sensitive remote APIs shall use authenticated transport, scoped authorization, server-side billing and secrets isolation. | MUST |
| SRS-NFR-006 | Join workflows shall resist expired invites, replay and unauthorized room access. | MUST |
| SRS-NFR-007 | User journeys shall support Android back navigation, text scaling, sufficient contrast and appropriate touch targets. | MUST |
| SRS-NFR-008 | Telemetry shall exclude raw audio, account secrets and unnecessary personally identifying data by default. | PROPOSED |
| SRS-NFR-009 | Availability, capacity and cost targets require a benchmark and business sign-off before SLA commitment. | OPEN |

Previous discussions included ~1-2 second translation aspiration, sub-500 ms exploratory ambition and 10-20 ms sync aspirational skew. None is a release SLA. Establish budgets from measured device and provider results.

## 08 External interfaces and requirement traceability

| Interface | SRS dependencies | Evidence |
| --- | --- | --- |
| Android media capture / output | SRS-AS-004, 008, 009, 014 | Permission and capture-eligibility tests |
| Local session handshake | SRS-GEN-006, 010; SRS-AS-006, 007 | Admission and replay tests |
| Host synchronized playback | SRS-AS-010, 011; SRS-NFR-002 | Multi-device synchronized playback captures |
| Auth and entitlement API | SRS-LT-001 to 004, 009 to 011 | Security and ledger tests |
| Streaming speech / captions | SRS-LT-005 to 008 | Multilingual continuity + interruption test |
| Sessions UI persistence | SRS-GEN-008, 009; SRS-NFR-001 | Restart/reconnect acceptance tests |

Change control: When a requirement changes, update its linked BR/PRD rule, API schema or state diagram, specific test-case IDs and release gate. Do not declare conformance solely because a UI screen exists.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
