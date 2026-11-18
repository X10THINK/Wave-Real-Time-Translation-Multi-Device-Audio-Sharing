# Wave FRD — 05 UC-05 / UC-06: Audio Share Receiver

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 4  
**Status:** Source working draft; no claim of implemented completion.

## 05 UC-05 / UC-06: Audio Share Receiver

| Stage | Rule / branch | Expected behavior |
| --- | --- | --- |
| Join discovery | Code, QR or Nearby if supported | Verify room/transport/session token/capacity |
| Approval ON | Host decides | Pending -> accepted, denied, timeout or cancel |
| Approval OFF | Admission succeeds after security checks | Join Live Receiver automatically |
| Waiting | No Host media yet | Connected/waiting state; no invented audio |
| Listening | Receive permitted media stream | Local output volume/mute/device choice |
| Local pause | Pause only this Receiver output | No effect on other receivers; forwarding still permitted |
| Local resume | Host timeline is ahead | Drop stale frames, realign current timeline (TARGET) |
| Leave | User exits Receiver | Remove this peer only; Host and others stay active |

Receiver names and device identity must not require a general Audio Share login. Display name validation and uniqueness within the room should be implemented as a local session identity scheme; exact identity field policy remains OPEN.
