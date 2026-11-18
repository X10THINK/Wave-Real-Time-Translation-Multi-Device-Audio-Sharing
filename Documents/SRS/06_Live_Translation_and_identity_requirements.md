# Wave SRS — 06 Live Translation and identity requirements

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 5, 6  
**Status:** Source working draft; no claim of implemented completion.

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
