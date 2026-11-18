# Wave SRS — 03 Actors, assumptions and operating environment

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 3  
**Status:** Source working draft; no claim of implemented completion.

## 03 Actors, assumptions and operating environment

| Actor | Responsibilities | Constraints |
| --- | --- | --- |
| Audio Share Host | Creates room, invites, selects source, controls shared timeline, ends session | May be guest; device capability governs sources |
| Audio Share Receiver | Discovers/joins, listens, locally controls output, can relay internally | Admission handshake and network checks required |
| Translation Host | Signs in, proves entitlement, pays for authorized group usage, controls speaker rights | Must use server-authorized billing controls |
| Translation Receiver | Signs in, joins valid room, selects language, receives translated output | No independent paid entitlement in Host-funded session |
| Cloud operations | Operates authenticated AI gateway, usage ledger, key rotation, observability | Provider and pricing remain OPEN |

- Target OS is Android; test versions, OEM builds and audio outputs must be documented in compatibility matrix.

- Cloud AI cannot be assumed offline; the translation gateway requires internet connectivity.

- Capturing third-party app playback is constrained by Android and source-app policy.

- Transport availability and participant limits must be measured, not promised universally.
