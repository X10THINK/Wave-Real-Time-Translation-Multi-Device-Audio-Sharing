# Wave FRD — 08 UC-10: Authorized questions and spending rules

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 5, 6  
**Status:** Source working draft; no claim of implemented completion.

## 08 UC-10: Authorized questions and spending rules

| Scenario | Expected flow | Negative branch |
| --- | --- | --- |
| One-to-many lecture | Host speaks; Receivers listen in selected supported languages | Unsupported language -> explicit selectable alternative or error |
| Student question (cost-aware Option A) | Host authorizes student; translate question only into Host language; Host answers to all | Revoked/unapproved student cannot upload chargeable speech |
| Open group / tourist discussion | Host grants speakers per session rules; usage metered to Host | No uncontrolled all-to-all expansion without caps |
| Quota/entitlement reached | End/disable paid processing with clear reason; preserve non-billable states | Client cannot continue charging after limit |
| New languages / provider failure | Use only approved provider capability; explicit degraded/failure mode | Do not promise 4 or unlimited languages without benchmarks |

The student-question Option A discussion is a preferred cost-control pattern. Its final deployment behavior, moderation UX and eligibility rules need product approval and test coverage.
