# Wave FRD — 06 UC-07: Recovery and Sessions Hub

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 5  
**Status:** Source working draft; no claim of implemented completion.

## 06 UC-07: Recovery and Sessions Hub

| Condition | User-visible action | System response |
| --- | --- | --- |
| Live active Host session | Tap Sessions > Active Hosted | Reopen same Live Host state |
| Live active Receiver session | Tap Sessions > Active Joined | Reopen same Live Receiver state |
| Transient link loss | Show Reconnecting in place | Attempt bounded reconnect; preserve authorized state |
| Permission or network loss | Show relevant fix prompt | Return/recheck rather than re-create room |
| Host ends session | Show Ended and history | Invalidate room and connected peer tokens |
| App process termination | No false live claim | Restore only if authoritative active session and keys remain valid |

Persistence across process death, Host re-election, cross-network migration and stale-room cleanup are engineering research topics, not certified behavior.
