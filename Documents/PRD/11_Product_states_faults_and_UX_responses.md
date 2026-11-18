# Wave PRD — 11 Product states, faults and UX responses

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 13  
**Status:** Source working draft; no claim of implemented completion.

## 11 Product states, faults and UX responses

| Situation | User-visible response | Must not happen |
| --- | --- | --- |
| No supported network | Show role-aware compact Network Fix action; recheck after Android settings. | Repeated mandatory setup/success screens. |
| Room invalid/full/offline | Explain reason; permit retry, new code or safe exit. | Auto-admit without validation. |
| Approval denied/timed out | Show final status and cancel/retry options as policy allows. | Remain in an endless spinner. |
| No playable source | Remain in Ready/Waiting with source selection. | Show Live/Sharing falsely. |
| External capture denied | Explain that capture is unsupported or consent missing. | Use unsupported capture workarounds. |
| Receiver local pause | Local silence while peers and relay keep working. | Broadcast Host pause. |
| Host movie exit/lock | Pause movie/video + shared movie audio; room stays connected. | Continue movie audio while video is paused. |
| Disconnect | In-place recovery with clear status / Retry/Fix when required. | Duplicate room creation or lost participants by default. |
| AI provider outage | Clearly stop/mark unavailable voice and captions; allow safe session exit. | Fabricate translated speech/status. |
| No entitlement/quota | Prevent unauthorized paid processing; show budget action. | Continue accruing unapproved charges. |
