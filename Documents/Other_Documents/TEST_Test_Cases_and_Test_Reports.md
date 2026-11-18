# Wave — Test Cases and Test Reports

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `14_TEST_Wave_Test_Cases_and_Test_Reports.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> TEST CASES AND TEST

> REPORTS

> Test inventory, historical observations and report templates

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-TEST-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Test Cases and Test Reports |
| Document ID | ZAEROX-WAVE-TEST-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Execution status and evidence discipline

03 Detailed planned test-case register

04 Reusable execution record templates

05 Historical prototype observations (not release certification)

06 Defect log and release readiness report template

## 02 Execution status and evidence discipline

This document contains a prepared manual/automation test-case inventory and a historical test-observation summary. It does NOT present invented passes. All cases below are NOT EXECUTED IN THIS DOCUMENT until a tester records real build/device evidence and signs a release result.

| Result code | Meaning |
| --- | --- |
| NOT RUN | Not executed against a specific build in this report |
| PASS | Expected and actual match, reproducible evidence attached |
| FAIL | Behavior deviates; defect and reproducer linked |
| BLOCKED | Cannot run due to device, permission, provider, or prerequisite |
| NEEDS RETEST | Previous observation exists but no signed verified current-build run |

The current supplied conversation contains prototype observations, but not a complete, signed, build-specific STP run. No summary percentage or certification is claimed.

## 03 Detailed planned test-case register

| Case ID | Action / condition | Expected outcome | SRS ref |
| --- | --- | --- | --- |
| TC-ENTRY-001 | Launch Wave as guest | Home visible; Audio Share available; translation triggers sign-in when needed | GEN-001 |
| TC-ENTRY-002 | Open either feature and tap Wi-Fi method | Stage A checks then Host/Receiver; no Continue page | GEN-004/006 |
| TC-ENTRY-003 | Bluetooth disabled at method stage | Contextual permission/enable prompt; recheck on return | GEN-006/007 |
| TC-ENTRY-004 | Hotspot Receiver with no Host network | Guide joining Host hotspot; do not enable own hotspot | GEN-006/007 |
| TC-AS-001 | Create room with valid name/capacity/approval | Lobby created; QR and members visible | AS-002/003 |
| TC-AS-002 | Create room with invalid name/capacity | Inline validation; room not created | AS-002 |
| TC-AS-003 | Start from Lobby with no source | Live Host Ready; room persists | AS-003/015 |
| TC-AS-004 | Choose Music after Start | Music selected and playable after eligibility checks | AS-004 |
| TC-AS-005 | Choose Host Video after Start | Host plays video/audio; Receiver sees audio only | AS-004/008 |
| TC-AS-006 | Choose Supported External App Audio | Android consent requested; supported playback captured only | AS-014 |

| Case ID | Action / condition | Expected outcome | SRS ref |
| --- | --- | --- | --- |
| TC-AS-007 | External app opt-out or consent denied | Source unavailable; app does not falsely show Live | AS-014/015 |
| TC-AS-008 | Join valid room code | Handshake, capacity and approval policy validated | AS-006/007 |
| TC-AS-009 | Approval ON / Host accepts | Receiver admitted; media begins only after admission | AS-007 |
| TC-AS-010 | Approval ON / Host rejects | Receiver denied; no media/key leaked | AS-007 |
| TC-AS-011 | Approval ON / timeout / cancel | Waiting state ends; request cleaned up | AS-007 |
| TC-AS-012 | Approval OFF / valid peer | Direct admit only after security/capacity validation | AS-007 |
| TC-AS-013 | QR expired / malformed / reused | Join rejected; no session key | GEN-010 |
| TC-AS-014 | Room full / Host offline | Correct error; no phantom admission | AS-006 |
| TC-AS-015 | Use Nearby on unsupported device | Feature hidden or explicit unsupported state | AS-006 |
| TC-AS-016 | Receiver changes volume/output/mute | Others unchanged | AS-010 |
| TC-AS-017 | Receiver leaves | Only receiver removed; others unaffected | AS-010 |
| TC-AS-018 | Inspect Audio Share source picker | Exactly Music, Video, External App; no Microphone | AS-004/005 |
| TC-AS-019 | Host changes source during session | Session persists, old decoder/capture released | AS-003/004 |
| TC-AS-020 | Host global pause/resume | All active Receivers reflect shared state | AS-012 |
| TC-AS-021 | Host ends session | Peers notified; keys invalidated; history not active | AS-012 |
| TC-AS-022 | Return via Sessions Hub during live session | Same current live view; no new room | GEN-008 |
| TC-AS-023 | Open ended room history | No false Resume action | GEN-009 |
| TC-AS-024 | Minimize Host movie / lock screen | Host movie video + shared audio pause; room remains | AS-009 |
| TC-AS-025 | Background music with screen off | Continues only on validated supported Android matrix | NFR-003 |
| TC-SYNC-001 | Three receivers start same track | Record physical receiver skew and source-to-ear latency | NFR-002 |
| TC-SYNC-002 | Host movie vs receiver output | Record lip-sync offset at physical output | NFR-002 |
| TC-SYNC-003 | Force jitter / packet loss | Bounded buffer, no stale packet replay, eventual recovery | NFR-001/002 |

| Case ID | Action / condition | Expected outcome | SRS ref |
| --- | --- | --- | --- |
| TC-SYNC-004 | Relay peer exits mid-stream | Reroute/recover or honest error; no infinite loop | NFR-001 |
| TC-SYNC-005 | Pause Receiver that is a relay | Local output stops; downstream forwarding continues | AS-010/011 |
| TC-SYNC-006 | Receiver resumes after Host advanced | Discard stale audio; rejoin current Host timeline | AS-011 |
| TC-NET-001 | 4 Android devices with Bluetooth relay topology | Measure fanout, hops, throughput, dropout, delay | NFR-002 |
| TC-NET-002 | Hotspot max-connection exhaustion | Correct capacity guidance; no unverified promises | NFR-004 |
| TC-NET-003 | Host/Receiver process kill | No unauthorized phantom session; recover or end honestly | NFR-001 |
| TC-LT-001 | Anonymous Host tries translation room create | Sign-in required; no paid processing starts | LT-001/003 |
| TC-LT-002 | Signed-in Host with no valid plan | No billable stream; entitlement error | LT-003 |
| TC-LT-003 | Anonymous Receiver enters sponsored code | Must sign in before joining | LT-001/004 |
| TC-LT-004 | Signed-in Receiver with no own paid plan joins sponsored room | Allowed after admission when Host entitlement valid | LT-004 |
| TC-LT-005 | Receiver selects supported target language | Correct authorized audio/captions delivered | LT-005/006 |
| TC-LT-006 | Unapproved student uploads speech | Upload denied; no charge | LT-007/008 |
| TC-LT-007 | Host grants/revokes speaker right | Grant works; revoked speech immediately rejected | LT-007/008 |
| TC-LT-008 | Unsupported language selected | Clear error/available languages; no charge | LT-012 |
| TC-BILL-001 | Paid Host creates translation room | Host server entitlement checked | LT-003 |
| TC-BILL-002 | Authorized Receiver speaks in Host-paid session | Charge attributed to Host, not Receiver | LT-009 |
| TC-BILL-003 | Replay provider usage event | Single posted charge with idempotency | LT-010 |
| TC-BILL-004 | Client tampers with payer / entitlements | Server rejects change; no unauthorized provider work | LT-010 |
| TC-BILL-005 | Quota exhausted during streaming | Billable work halted, clear error, reconcile ledger | LT-011 |
| TC-SEC-001 | Use stale invite, revoked membership or wrong epoch | Reject access and media | GEN-010 |
| TC-SEC-002 | Cross-account usage query | Unauthorized requester denied | LT-010 |

| Case ID | Action / condition | Expected outcome | SRS ref |
| --- | --- | --- | --- |
| TC-UX-001 | TalkBack + large text + small device | Meaningful labels, no hidden controls or clipped text | NFR-007 |

Every case inherits test-record fields: Tester, build hash, Android make/model/version, physical topology, source content, precondition, steps, expected result, actual result, status, date/time, artifact path, defect reference, and retest version.

## 04 Reusable execution record templates

| Field | Example content to fill (not executed) |
| --- | --- |
| Test case / build | TC-AS-024 / <actual-git-hash> |
| Tester / date | <name> / <timestamp> |
| Device matrix | <Host/Receiver Android models, OS/API, output types> |
| Topology | <Router / hotspot / Bluetooth hops> |
| Precondition | Session and source eligibility verified |
| Action | Minimize Host movie or lock screen |
| Expected | Video + shared movie audio pause; room remains connected |
| Actual result | [Tester to enter after execution] |
| Status / attachments | NOT RUN / [recording + logs + measurement] |
| Defect and retest | [Issue ID and retest build] |

| Metrics record | Suggested columns |
| --- | --- |
| Audio synchronization | Build; devices; topology; sample rate; output; 95th skew; maximum skew; source-to-ear latency; underruns |
| Translation | Provider; model; language pair; speaker count; caption latency; audio latency; WER/quality review; usage units |
| Relay | Link type; hop count; concurrent peers; bitrate; drop%; recovery seconds; battery drain |
| Cost integrity | Session ID; payer ID; authorized speakers; provider usage units; ledger units; adjustment refs |

## 05 Historical prototype observations (not release certification)

| Area | Earlier user-reported observation | Follow-up status |
| --- | --- | --- |
| Wi-Fi / hotspot | Host-to-Receiver streaming was observed in prototypes | NEEDS RETEST against final build |
| Background | Minimized playback / other-app sharing was reported to work in selected tests | OEM/version matrix not supplied |
| Latency | Low Latency v0.1 build was preferred; delay decreased but was still noticeable | No calibrated millisecond guarantee |
| Echo | Echo reduced with earphones / low-delay mode | Need acoustic measurements |
| Multi-receiver sync | Receiver 1 and Receiver 2 arrived at differing times; three-device buffers differed | Sync Engine validation outstanding |
| Source isolation | Media-only testing still included microphone in an earlier build | Locked spec removes Audio Share microphone |
| Bluetooth relay | 4-phone relay source/prototypes exist | Adaptive multipath mesh not verified |
| Live translation | English-to-Tamil vendor-side proof of concept was observed | Wave integrated AI gateway remains unverified |
| Auth/billing | Approved account / sponsored billing rules documented | No production completion claim |

Historical observations come from prior project conversation, not independently reviewed raw test logs. They are useful hypotheses and regression targets, not formal PASS evidence.

## 06 Defect log and release readiness report template

| Defect field | Required value |
| --- | --- |
| Issue ID / owner | Trackable issue and assigned resolver |
| Severity / priority | Blocker / Critical / Major / Minor |
| Steps / prerequisites | Deterministic case, device and environment |
| Expected vs actual | With log trace, media recording or network packet evidence |
| Root cause and fix | Code revision and change impact |
| Verification | Retest result and regression suite links |

| Release gate | Current report status | Required evidence before approval |
| --- | --- | --- |
| Must features / flows | NOT ASSESSED | Signed case executions on nominated release build |
| Cross-device sync & relay | NOT ASSESSED | Calibrated physical timing and topology matrix |

| Release gate | Current report status | Required evidence before approval |
| --- | --- | --- |
| Translation login and sponsored billing | NOT ASSESSED | Backend auth/ledger negative + positive tests |
| Security & privacy | NOT ASSESSED | Security sign-off + data handling review |
| Accessibility and release operations | NOT ASSESSED | Device review + deployment drill |

Overall result for this prepared report: NO RELEASE PASS/FAIL DECISION. This pack is a usable test specification and reporting template pending real execution.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
