# Wave TRD — 10 Billing, metering and spend-safety architecture

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 12, 13  
**Status:** Source working draft; no claim of implemented completion.

## 10 Billing, metering and spend-safety architecture

### Source of financial truth

The backend, not a Flutter screen or Host packet, must decide whether AI work can be initiated and how usage is charged. Sponsor ownership is bound to a signed-in Host session. All authorized Receiver speaking costs belong to that Host under the locked Host-paid model.

### Proposed usage event/ledger design

| Field | Purpose |
| --- | --- |
| usage_event_id | Unique idempotency key from provider/job/event lifecycle. |
| session_id / sponsor_user_id | Immutable attribution to Host-sponsored session and payer. |
| speaker_user_id / target_language | Auditable authorized speaker and target stream. |
| unit_type / units | Provider-aligned measure (seconds, tokens, requests or credits); exact policy open. |
| estimated_cost / actual_cost | Reconcile preauthorization with provider-reported final billable units. |
| reserved / committed / voided | Reservation state so concurrent requests cannot overdraw budget. |
| provider_reference / occurred_at | Reference for reconciliation and dispute/audit with privacy minimization. |

### Billing control flow

- Before dispatch: verify Host active entitlement, session active, speaker authorized and available spend; reserve an estimated bounded budget atomically.

- During stream: enforce time/usage ceilings and limits per session, host, speaker and language; stop or deny new provider work before overrun.

- After billable work: reconcile actual provider usage, commit ledger once and release unused reservation; retry/failure must not double-charge.

- For exhaustion/provider failure: stop chargeable translation cleanly, notify Host/Receivers and preserve local non-billable session control as applicable.

- Never hardcode speculative per-minute rates in client UI. Use server-configured pricing/credits after business/legal approval.

### Financial observability

Track sponsor quota/balance, reserved spend, actual provider cost, minutes per source/target language, cost per successful translation minute, unusual concurrency and reconciliation delta. Billing must remain auditable without retaining unnecessary raw speech/audio.
