# Wave FRD — 04 UC-03 / UC-04: Audio Share Host

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 3, 4  
**Status:** Source working draft; no claim of implemented completion.

## 04 UC-03 / UC-04: Audio Share Host

| Stage | Inputs / behavior | Success / failure |
| --- | --- | --- |
| Create | Room name; maximum participants; approval switch | Room created within supported bounds; invalid values handled inline |
| Lobby | Invites via QR/code; members; pending requests; Start Session | Approvals apply; no mandatory source setup before lobby |
| Live Ready | Start Session enters Live Host with no source | Room remains connected; Ready not mislabeled Live |
| Choose source | Music / Video / Supported External App Audio | Capture consent and eligibility only when needed |
| Control | Host play/pause/seek/source change/end | Sequence control to peers; release replaced source safely |
| Video minimize | Host leaves player or locks screen | Pause video + shared movie audio; preserve room until resume |
| Failure | Source unavailable, capture denied, network lost | Show truthful source/transport state and recovery action |

Audio Share has no standalone microphone source; Live Translation owns microphone input.
