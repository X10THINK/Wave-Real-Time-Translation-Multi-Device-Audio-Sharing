# Wave BRD — 14 Acceptance criteria and validation plan

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 17  
**Status:** Source working draft; no claim of implemented completion.

## 14 Acceptance criteria and validation plan

Final release gates require recorded test environments, pass/fail evidence and stakeholder-approved thresholds. Suggested UAT cases below are suitable for conversion into executable QA scenarios; they are not completed test results.

| ID | Area | Acceptance scenario |
| --- | --- | --- |
| UAT-01 | Audio Share | Host starts valid room on supported local method and Receiver joins with correct approvals; no internet required for local media. |
| UAT-02 | Audio Share | Host selects local music; multiple phones play shared audio; pause/seek behavior matches global/local rule. |
| UAT-03 | Audio Share | Host plays imported video and receivers hear audio only; leave player pauses movie video and audio while keeping room alive. |
| UAT-04 | Audio Share | Receiver pauses locally and resumes at current timeline without interrupting other listeners/necessary forwarding. |
| UAT-05 | Audio Share | Denied Bluetooth/camera/capture permission shows relevant action, does not falsely report ready. |
| UAT-06 | Audio Share | Unsupported third-party audio capture reports eligibility/permission state instead of promising playback. |
| UAT-07 | Session | Active session resume returns to live view; ended session displays historical details, not misleading Resume. |
| UAT-08 | Translation | Host and Receiver are both blocked from create/join until signed in, including sponsored receiver. |
| UAT-09 | Translation | Eligible Host can begin a funded session; Receiver can join without personal charge. |
| UAT-10 | Translation | Authorized speech produces selected language voice and captions; failed/unavailable language reported. |
| UAT-11 | Billing | Authorized usage is attributed to sponsoring Host; quota exhaustion prevents unexpected charge. |
| UAT-12 | Resilience | Measure transport-specific latency, audio drift, capacity, recovery and background behavior on defined devices. |

### Minimum evidence for release sign-off

- Approved requirements-to-test traceability and defect log with severity and owner.

- Device/OS matrix and test conditions for every published network/capacity/performance claim.

- Security, privacy, payments and entitlement controls reviewed before paid translation release.

- End-to-end bilingual translation samples with target-language and speaker-rights coverage.

- User acceptance of approved Wave visual identity, navigation and accessible interaction behavior.
