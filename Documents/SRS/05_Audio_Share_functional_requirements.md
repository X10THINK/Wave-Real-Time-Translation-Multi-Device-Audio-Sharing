# Wave SRS — 05 Audio Share functional requirements

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 4, 5  
**Status:** Source working draft; no claim of implemented completion.

## 05 Audio Share functional requirements

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-AS-001 | Audio Share shall allow Host and Receiver access without mandatory sign-in. | Must | BR-02 |
| SRS-AS-002 | Host Create Session shall accept room name, maximum participants and Join Approval ON/OFF. | Must | BR-03 |
| SRS-AS-003 | Host shall enter Lobby and start session before choosing source from Live Host. | Must | BR-03 |
| SRS-AS-004 | Host source selector shall offer only Music Player, Video Player and Supported External App Audio. | Must | BR-04 |
| SRS-AS-005 | The system shall not expose Microphone as an Audio Share source. | Must | BR-04 |
| SRS-AS-006 | Receivers shall join via validated room code, QR, and Nearby only when technically supported. | Must | BR-06 |

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-AS-007 | With approval ON, admission shall await Host acceptance; with OFF, eligible peers shall join after validation. | Must | BR-06 |
| SRS-AS-008 | Receiver view shall play audio only; no receiver video stream or player shall be required. | Must | BR-04 |
| SRS-AS-009 | Host movie view minimize or screen lock shall pause movie video and shared movie audio but preserve the session. | Must | BR-03 |
| SRS-AS-010 | Receiver-local mute, volume, pause, output choice and leave shall not stop other receivers or necessary relay forwarding. | Must | BR-03 |
| SRS-AS-011 | Receiver resume shall realign to current Host media timeline and discard obsolete buffered frames. | Target | BR-13 |
| SRS-AS-012 | A Host global end shall invalidate the session and notify connected participants. | Must | BR-03 |
| SRS-AS-013 | Supported local sources shall be distributable without internet where a viable local transport exists. | Must | BR-02 |
| SRS-AS-014 | External App Audio shall activate only after supported Android capture consent and eligibility checks. | Must | BR-14 |
| SRS-AS-015 | Audio Share shall expose truthful Ready, Live, Paused, Reconnecting and Source-Unavailable states. | Must | BR-12 |
