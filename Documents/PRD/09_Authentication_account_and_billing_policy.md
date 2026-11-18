# Wave PRD — 09 Authentication, account and billing policy

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 11, 12  
**Status:** Source working draft; no claim of implemented completion.

## 09 Authentication, account and billing policy

### Mandatory Live Translation accounts

A signed-in account is required for every Live Translation participant, regardless of whether the individual is paying. Guest Audio Share access remains available. Registration fields, identity provider, verification requirements and the precise sign-in screen placement are still open decisions. Minimize required personal information and never store payment card data in app-owned tables.

### Host-paid sponsorship and usage ownership

- Before spending begins, the backend checks sponsoring Host identity, active subscription/credits, permitted session scope and remaining budget.

- Each authorized speech/translation event is attributed to the sponsoring Host account, even when an authorized Receiver is the speaker.

- Receivers can join funded sessions without purchasing individual subscriptions; this does not remove their mandatory sign-in requirement.

- Cost/credit and quota indicators should be clear. Warnings, enforcement at the spend limit, and safe session behavior on exhaustion are required.

- Exact currency prices, tiers, included minutes, top-up behavior, translation unit calculation and refunds are not approved. Do not invent them in UI or billing logic.

| ID | Requirement | State |
| --- | --- | --- |
| PR-BI-01 | Authenticate every participant before entering Live Translation sessions. | LOCKED |
| PR-BI-02 | Authorize sponsorship server-side and prevent receivers from self-authorizing Host spending. | LOCKED + TARGET |

| ID | Requirement | State |
| --- | --- | --- |
| PR-BI-03 | Meter authorized speech/translation processing to sponsoring Host. | LOCKED |
| PR-BI-04 | Display quota/budget state, warnings and blocked-exhausted conditions. | LOCKED + TARGET |
| PR-BI-05 | Allow subscription/credit accounting without committing to unapproved prices. | OPEN |
| PR-BI-06 | Protect account privacy, deletion rights and consent; retention policy is pending. | OPEN + TARGET |
