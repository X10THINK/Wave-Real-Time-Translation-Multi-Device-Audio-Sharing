# Wave BRD — 12 Data, identity, privacy and trust

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 15, 16  
**Status:** Source working draft; no claim of implemented completion.

## 12 Data, identity, privacy and trust

### Proposed minimal business data categories

| Category | Purpose | Status |
| --- | --- | --- |
| Account identity / credentials | Authenticate every Live Translation Host and Receiver; perform recovery and abuse prevention. | Specific fields and identity provider open. |
| Session metadata | Identify room, host, membership, method, status, invite and role. | Needed for approved journeys. |
| Authorization state | Manage join approval, speaker permission, removal and sponsored-session entitlement. | Required rule. |
| Usage and commerce metadata | Associate billable AI consumption and entitlement with sponsoring Host. | Required; detailed schema open. |
| Diagnostics | Support reliability/security troubleshooting with privacy safeguards. | Scope and retention open. |
| Speech and captions | Process authorized live translation streams. | Retention and recording policy open. |

### Privacy constraints

Wave must explain when audio is captured locally, when speech or text is transmitted to a cloud AI provider, and who can hear output within a session. Define retention and deletion periods, geographic handling, consent for any optional recording or voice cloning, and participant rights. No always-on recording or archival of translated speech should be assumed as part of the baseline requirement.

Password storage, account recovery, account deletion, processor-hosted payments, and regulatory/legal review need detailed requirements before production release. Do not store users' card numbers, CVV or banking PIN in Wave.
