# Wave SRS — 07 Quality, security and performance requirements

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 6  
**Status:** Source working draft; no claim of implemented completion.

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
