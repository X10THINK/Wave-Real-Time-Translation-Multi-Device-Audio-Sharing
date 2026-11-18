# Wave TRD — 13 Error handling, recovery and resilience design

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 14, 15  
**Status:** Source working draft; no claim of implemented completion.

## 13 Error handling, recovery and resilience design

| Failure | Recovery / invariant | Verification |
| --- | --- | --- |
| Receiver network loss | Try existing room credentials and route recovery; preserve session ID, revalidate membership. | Forced disconnect per method. |
| Relay offline | Recompute alternate path with TTL/deduplication; avoid packet loop. | Kill relay mid-stream. |
| Host paused movie | Send pause/epoch control; connections alive, no stale audio. | Lock Host during video. |
| Host process killed | Do not claim automatic continuation; apply approved ownership policy when defined. | OEM background / process death. |
| Source file unavailable | Pause/stop relevant media; preserve room state and report source missing. | Revoke document permission. |

| Failure | Recovery / invariant | Verification |
| --- | --- | --- |
| Cloud/provider unreachable | Stop fresh chargeable work; retain verified last states, retry safely. | Server connection drop. |
| Billing reservation race | Atomic reserve/commit; enforce budget under concurrent speakers. | Simultaneous speech load. |
| Auth token expires | Refresh as permitted; block unauthorized voice/paid work on expiry. | Forced token invalidation. |
| Playback clock drift | Correct gradual drift or resync at current live PTS without replaying old frames. | Long-running two/three-device test. |
