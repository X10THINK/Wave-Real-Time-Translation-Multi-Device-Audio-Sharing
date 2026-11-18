# Wave — Functional Requirements Document

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> FUNCTIONAL

> REQUIREMENTS DOCUMENT

> Detailed workflows, use cases and functional rules

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-FRD-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Functional Requirements Document |
| Document ID | ZAEROX-WAVE-FRD-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Functional decomposition and scenario policy

03 UC-01 / UC-02: Method, role and readiness

04 UC-03 / UC-04: Audio Share Host

05 UC-05 / UC-06: Audio Share Receiver

06 UC-07: Recovery and Sessions Hub

07 UC-08 / UC-09: Paid Live Translation

08 UC-10: Authorized questions and spending rules

09 Functional rules and traceability

## 02 Functional decomposition and scenario policy

FRD captures end-to-end functional behaviors, actors, preconditions, triggers, postconditions, exception paths and input/output rules. Use-case IDs map to SRS and BRD. Flows below are the current approved behavior unless explicitly labeled PROPOSED or TARGET.

| Functional group | Use cases | Core owner |
| --- | --- | --- |
| Entry and readiness | UC-01 Transport selection; UC-02 Select role and capability checks | Flutter + Android adapters |
| Audio Share Host | UC-03 Create/Lobby/Start; UC-04 Source and global playback | Host session controller |
| Audio Share Receiver | UC-05 Join/Approval/Listen; UC-06 Local controls | Peer session engine |
| Session lifecycle | UC-07 Resume/Leave/End/Recover | Shared session manager |
| Live Translation | UC-08 Auth/Host billable room; UC-09 Receiver/Language; UC-10 Speaker/Usage | Identity and translation gateway |

## 03 UC-01 / UC-02: Method, role and readiness

| Field | Definition |
| --- | --- |
| Actors | Audio Share Host or Receiver; Live Translation Host or Receiver |
| Precondition | Wave installed, relevant system capability query available |
| Trigger | User selects Audio Share or Live Translation |
| Main success path | Choose Wi-Fi, Bluetooth or Hotspot -> Stage A check -> role Host/Receiver -> Stage B checks -> feature branch |
| Alt A | Missing Bluetooth permission / turned off -> context fix popup -> system permission/settings -> automatic recheck |
| Alt B | Hotspot Host guided to tethering setup; Receiver guided to join existing Host network |
| Exit guarantee | No false success/ready screen and no repeated method selection later in same journey |
| Links | SRS-GEN-002 to 007; BR-05 |

- A supported automatic readiness check must not silently enable radios or hotspot on restricted Android builds.

- Role validation errors stay contextual; users can return to previous screen without losing selection.

## 04 UC-03 / UC-04: Audio Share Host

| Stage | Inputs / behavior | Success / failure |
| --- | --- | --- |
| Create | Room name; maximum participants; approval switch | Room created within supported bounds; invalid values handled inline |
| Lobby | Invites via QR/code; members; pending requests; Start Session | Approvals apply; no mandatory source setup before lobby |
| Live Ready | Start Session enters Live Host with no source | Room remains connected; Ready not mislabeled Live |
| Choose source | Music / Video / Supported External App Audio | Capture consent and eligibility only when needed |
| Control | Host play/pause/seek/source change/end | Sequence control to peers; release replaced source safely |
| Video minimize | Host leaves player or locks screen | Pause video + shared movie audio; preserve room until resume |
| Failure | Source unavailable, capture denied, network lost | Show truthful source/transport state and recovery action |

Audio Share has no standalone microphone source; Live Translation owns microphone input.

## 05 UC-05 / UC-06: Audio Share Receiver

| Stage | Rule / branch | Expected behavior |
| --- | --- | --- |
| Join discovery | Code, QR or Nearby if supported | Verify room/transport/session token/capacity |
| Approval ON | Host decides | Pending -> accepted, denied, timeout or cancel |
| Approval OFF | Admission succeeds after security checks | Join Live Receiver automatically |
| Waiting | No Host media yet | Connected/waiting state; no invented audio |
| Listening | Receive permitted media stream | Local output volume/mute/device choice |
| Local pause | Pause only this Receiver output | No effect on other receivers; forwarding still permitted |
| Local resume | Host timeline is ahead | Drop stale frames, realign current timeline (TARGET) |
| Leave | User exits Receiver | Remove this peer only; Host and others stay active |

Receiver names and device identity must not require a general Audio Share login. Display name validation and uniqueness within the room should be implemented as a local session identity scheme; exact identity field policy remains OPEN.

## 06 UC-07: Recovery and Sessions Hub

| Condition | User-visible action | System response |
| --- | --- | --- |
| Live active Host session | Tap Sessions > Active Hosted | Reopen same Live Host state |
| Live active Receiver session | Tap Sessions > Active Joined | Reopen same Live Receiver state |
| Transient link loss | Show Reconnecting in place | Attempt bounded reconnect; preserve authorized state |
| Permission or network loss | Show relevant fix prompt | Return/recheck rather than re-create room |
| Host ends session | Show Ended and history | Invalidate room and connected peer tokens |
| App process termination | No false live claim | Restore only if authoritative active session and keys remain valid |

Persistence across process death, Host re-election, cross-network migration and stale-room cleanup are engineering research topics, not certified behavior.

## 07 UC-08 / UC-09: Paid Live Translation

| Stage | Host path | Receiver path |
| --- | --- | --- |
| Method and role | Transport -> Host | Transport -> Receiver |
| Identity gate | Sign in; verify paid Host entitlement | Sign in before joining a Translation room |
| Session entry | Create sponsored session with policies | Enter/scan room and pass validation |
| Admission | Approve if ON; maintain speaker controls | Await approval or join if OFF |
| Language | Choose source/available languages as supported | Choose preferred output language |
| Media path | Authorized mic -> AI processing | Receive translated voice and captions |
| Charging | Host pays usage generated by authorized speakers | No separate paid subscription for this Host-funded room |

- Never start billable provider work based solely on a client-side paid badge or QR code.

- Speaker grants and usage attribution must be enforced on server and remain valid across reconnects.

- Translate the same source/language result once for a group when possible; this is a cost-optimization design, not a locked provider architecture.

## 08 UC-10: Authorized questions and spending rules

| Scenario | Expected flow | Negative branch |
| --- | --- | --- |
| One-to-many lecture | Host speaks; Receivers listen in selected supported languages | Unsupported language -> explicit selectable alternative or error |
| Student question (cost-aware Option A) | Host authorizes student; translate question only into Host language; Host answers to all | Revoked/unapproved student cannot upload chargeable speech |
| Open group / tourist discussion | Host grants speakers per session rules; usage metered to Host | No uncontrolled all-to-all expansion without caps |
| Quota/entitlement reached | End/disable paid processing with clear reason; preserve non-billable states | Client cannot continue charging after limit |
| New languages / provider failure | Use only approved provider capability; explicit degraded/failure mode | Do not promise 4 or unlimited languages without benchmarks |

The student-question Option A discussion is a preferred cost-control pattern. Its final deployment behavior, moderation UX and eligibility rules need product approval and test coverage.

## 09 Functional rules and traceability

| Business rule | Verification case | SRS links |
| --- | --- | --- |
| Join Approval ON means Host accept required | TC-AS-009 / TC-AS-010 | SRS-AS-007 |
| No Audio Share mic source | TC-AS-018 | SRS-AS-004/005 |
| Host movie minimize pauses movie audio | TC-AS-024 | SRS-AS-009 |
| Receiver local pause does not change others | TC-SYNC-005 | SRS-AS-010/011 |
| Translation requires all signed in | TC-LT-001 / TC-LT-003 | SRS-LT-001 |
| Paid Host funds all authorized participants | TC-BILL-002 | SRS-LT-009 |
| API quota enforced server side | TC-BILL-005 | SRS-LT-010/011 |

FRD acceptance requires primary flows, exception paths, access enforcement and traceability to automated/manual tests. UI-only walkthroughs are not sufficient to accept network and billing behaviors.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
