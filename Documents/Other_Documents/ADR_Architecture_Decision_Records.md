# Wave — Architecture Decision Records

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `09_ADR_Wave_Architecture_Decision_Records.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> ARCHITECTURE DECISION

> RECORDS

> Decisions, trade-offs, assumptions and reversibility

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-ADR-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Architecture Decision Records |
| Document ID | ZAEROX-WAVE-ADR-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Record conventions and decision precedence

03 Architecture decision register

04 Decision details and consequences

05 Open ADR evaluations and rollback triggers

06 Review and ownership register

## 02 Record conventions and decision precedence

An Architecture Decision Record (ADR) documents context, decision, alternatives, status, consequences, and reversal trigger. Accepted product decisions are authoritative over older proposals; implementation designs marked PROPOSED remain reviewable.

| Status | Meaning |
| --- | --- |
| ACCEPTED - locked | Product/UX policy approved; implementation may still be incomplete |
| TARGET | Desired behavior without adequate device/production evidence |
| PROPOSED | Recommended architecture not ratified |
| OPEN | Owner must evaluate and decide before production freeze |

## 03 Architecture decision register

| ID | Decision | Status |
| --- | --- | --- |
| ADR-001 | Split Audio Share local plane from paid cloud Translation plane | ACCEPTED - product boundary |
| ADR-002 | All Live Translation participants use authenticated accounts | ACCEPTED - locked |
| ADR-003 | Host-paid group translation metered to Host account | ACCEPTED - locked |
| ADR-004 | Method selection before Host/Receiver role | ACCEPTED - locked |
| ADR-005 | Audio Share source selection from Live Host after Lobby/Start | ACCEPTED - locked |
| ADR-006 | Audio Share sources: Music, Host Video audio, Supported External App Audio | ACCEPTED - locked |
| ADR-007 | Host-only movie video; receivers hear audio-only | ACCEPTED - locked |
| ADR-008 | Pause Host movie video and audio on leaving player | ACCEPTED - locked |
| ADR-009 | Receiver local pause does not affect others or forwarding | ACCEPTED - locked |
| ADR-010 | Bluetooth adaptive multi-hop forwarding | TARGET - not certified |
| ADR-011 | Timestamp-driven sync engine with monotonic clocks | PROPOSED |
| ADR-012 | Server-authoritative translation usage ledger and quota | PROPOSED implementation / locked rule |
| ADR-013 | Language-scoped shared translation output streams | PROPOSED |
| ADR-014 | Wi-Fi Direct as internal experiment, not 4th method tile | PROPOSED internal option |
| ADR-015 | Future Theater Mode isolated from Audio Share baseline | ACCEPTED future scope |
| ADR-016 | Auth provider, AI provider, hosting and pricing | OPEN |

## 04 Decision details and consequences

ADR-001 | Split Audio Share local plane from paid cloud Translation plane Status: ACCEPTED - product boundary. Rationale: Keeps offline local Audio Share independent of cloud billing. Consequence / trade-off: Cloud translation still requires internet.

ADR-002 | All Live Translation participants use authenticated accounts Status: ACCEPTED - locked. Rationale: Enables identity, authorized speakers and accountable usage. Consequence / trade-off: No translation guest path.

ADR-003 | Host-paid group translation metered to Host account Status: ACCEPTED - locked. Rationale: Simplifies sponsored class/tour group business model. Consequence / trade-off: Need spend controls and shared usage budget.

ADR-004 | Method selection before Host/Receiver role Status: ACCEPTED - locked. Rationale: Consistent flows across features. Consequence / trade-off: Stage A and role-specific Stage B.

ADR-005 | Audio Share source selection from Live Host after Lobby/Start Status: ACCEPTED - locked. Rationale: Removes source gating and redundant setup. Consequence / trade-off: Ready state before media start.

ADR-006 | Audio Share sources: Music, Host Video audio, Supported External App Audio Status: ACCEPTED - locked. Rationale: Distinct, bounded source model. Consequence / trade-off: No mic source; Android capture limits.

ADR-007 | Host-only movie video; receivers hear audio-only Status: ACCEPTED - locked. Rationale: Avoids receiver video distribution expense. Consequence / trade-off: Strict synchronization and timing expectations.

ADR-008 | Pause Host movie video and audio on leaving player Status: ACCEPTED - locked. Rationale: Predictable session semantics. Consequence / trade-off: Room and invites remain alive.

ADR-009 | Receiver local pause does not affect others or forwarding Status: ACCEPTED - locked. Rationale: Independent personal listening. Consequence / trade-off: Fast live-timeline rejoin TARGET.

ADR-010 | Bluetooth adaptive multi-hop forwarding Status: TARGET - not certified. Rationale: Extend local reach through eligible listening peers. Consequence / trade-off: Android hardware fanout and delay feasibility risk.

ADR-011 | Timestamp-driven sync engine with monotonic clocks Status: PROPOSED. Rationale: Better skew/drift management than arrival-time playback. Consequence / trade-off: Must benchmark end-to-end.

ADR-012 | Server-authoritative translation usage ledger and quota Status: PROPOSED implementation / locked rule. Rationale: Prevents client-side spend manipulation. Consequence / trade-off: Ledger, reserve, reconciliation design.

ADR-013 | Language-scoped shared translation output streams Status: PROPOSED. Rationale: Avoid duplicate AI work for same source/target. Consequence / trade-off: Provider licensing and latency review.

ADR-014 | Wi-Fi Direct as internal experiment, not 4th method tile Status: PROPOSED internal option. Rationale: Preserve approved UI while exploring peer connections. Consequence / trade-off: OEM support and discovery limits.

ADR-015 | Future Theater Mode isolated from Audio Share baseline Status: ACCEPTED future scope. Rationale: Prevents surround-channel requirements changing baseline. Consequence / trade-off: Separate release and validation.

ADR-016 | Auth provider, AI provider, hosting and pricing Status: OPEN. Rationale: Requires benchmark, procurement and approval. Consequence / trade-off: Never embed secrets or fabricate cost.

## 05 Open ADR evaluations and rollback triggers

| Decision to resolve | Candidate options | Evidence before acceptance |
| --- | --- | --- |
| AI translation provider | Managed speech-to-speech; STT+MT+TTS composition; supported on-device subpipeline | English/Tamil accuracy, latency, privacy, real usage cost |
| Bluetooth media data plane | Bluetooth Classic / BLE-supported peer channels / mixed local transport | Measured throughput, fanout, Android background behavior |
| Local media protocol | Timestamped unicast; multicast where available; reliable control channel | Clock skew, packet loss and security tests |
| Cloud storage/identity | Managed service versus self-hosted | Cost, access controls, retention, region, backup |
| Theater Mode release | Standalone feature branch or later milestone | Multichannel decoding and calibration tests |

- Revisit ADR-010 if four-device tests cannot reproduce useful throughput/latency or peer routing.

- Revisit ADR-011 if synchronization measurements reveal unacceptable drift on supported output devices.

- Revisit ADR-012/013 if actual provider billing, language support or contracts contradict assumptions.

## 06 Review and ownership register

| Role | Approval responsibility |
| --- | --- |
| Product Owner | Locks user journeys, access/billing behavior and out-of-scope |
| Technical Lead | Protocol, architecture and system-level trade-offs |
| Android/Audio Lead | Media capture, transport and synchronization feasibility |
| Backend/Security Lead | Auth, entitlement, spending control and privacy |
| QA Lead | Reproducible device / negative / performance acceptance evidence |
| Operations Owner | Hosting, release, monitoring, restore and spend limits |

Each record should be assigned a concrete owner and dated decision at implementation review. Current document contains no fabricated stakeholder signatures.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
