# Wave TRD — 11 Data model and retention boundaries

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 13  
**Status:** Source working draft; no claim of implemented completion.

## 11 Data model and retention boundaries

| Logical entity | Key fields (proposed) | Retention / control |
| --- | --- | --- |
| Account | user_id, verified identity provider, language preference, account state. | Mandatory for translation; fields/retention pending. |
| Session | session_id, type, Host ID, method, lifecycle state, created/ended time, approval policy. | Active + permitted limited history. |
| Membership | member_id, session_id, verified account ID when translation, role, state, authorization epoch. | Revocable; guest temporary ID for Audio Share. |
| Audio source | source_id/epoch, media type, duration/metadata, capture eligibility status. | Avoid storing private media by default. |
| Translation turn | turn_id, speaker, target groups, language and status. | Metadata only by default; transcript policy open. |
| Entitlement | sponsor_user_id, plan/quota, valid period, billing rules. | Backend only; immutable financial events. |
| Usage ledger | usage_event_id, sponsor, unit, provider ref, reservation/commit state. | Auditable financial retention, policy pending. |
| Diagnostics | timing, loss, OS/device versions, redacted error codes. | Time-limited and privacy-minimized. |

### Data protection constraints

- Prefer ephemeral handling of raw audio and speech segments. Do not store recordings or transcripts unless policy, notice, consent and explicit use cases require it.

- Encrypt transport and backend data; minimize logs, remove room codes/tokens/PII; ensure account controls and consent flows can be audited.

- Protect financial/event integrity with append-only ledger semantics, role-based admin rights and controlled retention.

- Define subject-data deletion, backups, retention periods, region compliance and consent wording before production release.
