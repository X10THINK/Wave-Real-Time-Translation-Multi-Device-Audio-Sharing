# Wave FRD — 09 Functional rules and traceability

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 6  
**Status:** Source working draft; no claim of implemented completion.

## 09 Functional rules and traceability

| Business rule | Verification case | SRS links |
| --- | --- | --- |
| Join Approval ON means Host accept required | TC-AS-009 / TC-AS-010 | SRS-AS-007 |
| No Audio Share mic source | TC-AS-018 | SRS-AS-004/005 |
| Host movie minimize pauses movie audio | TC-AS-024 | SRS-AS-009 |
| Receiver local pause does not change others | TC-SYNC-005 | SRS-AS-010/011 |
| Translation requires all signed in | TC-LT-001 / TC-LT-003 | SRS-LT-001 |
| Paid Host funds all authorized participants | TC-BILL-002 | SRS-LT-009 |
| API quota enforced server side | TC-BILL-005 | SRS-LT-010/011 |

FRD acceptance requires primary flows, exception paths, access enforcement and traceability to automated/manual tests. UI-only walkthroughs are not sufficient to accept network and billing behaviors.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
