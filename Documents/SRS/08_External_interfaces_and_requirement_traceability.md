# Wave SRS — 08 External interfaces and requirement traceability

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 6, 7  
**Status:** Source working draft; no claim of implemented completion.

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
