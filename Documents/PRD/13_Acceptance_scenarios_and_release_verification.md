# Wave PRD — 13 Acceptance scenarios and release verification

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 14  
**Status:** Source working draft; no claim of implemented completion.

## 13 Acceptance scenarios and release verification

| ID | End-to-end acceptance scenario | Evidence |
| --- | --- | --- |
| AC-01 | Guest Audio Share Host selects method -> Host -> Create -> Lobby -> Start -> Source; valid session persists. | Multi-device manual/automated flow test. |
| AC-02 | Receiver joins by QR/code, with approvals ON and OFF, including denied/full/offline paths. | Session admission test matrix. |
| AC-03 | Host shares music; multiple Receivers align playback and Host commands are globally applied. | Recorded multi-phone timeline sample. |
| AC-04 | Host video is local only; receivers hear audio only; video player exit pauses video and shared audio. | Host/receiver simultaneous recording. |
| AC-05 | Receiver pauses locally, resumes live timeline; no peer interruption or old-buffer playback. | Timestamped pause/rejoin test. |
| AC-06 | External source refused by Android/source app reports unsupported; no silent/fake output. | Capture permission/device test. |
| AC-07 | Valid existing session returns from Hub; ended session does not present fake Resume. | Lifecycle/restart UI test. |
| AC-08 | Live Translation Host AND sponsored Receiver cannot create/join until authenticated. | Auth access-control test. |
| AC-09 | Authorized voice produces correct chosen-language speech/captions; unsupported language is handled. | Audio/caption bilingual evaluation. |
| AC-10 | All translation usage from authorized speakers is billed to Host, not sponsored Receiver. | Reconciled usage-ledger test. |
| AC-11 | At budget exhaustion new chargeable AI work stops without unexpected overage. | Concurrency/quota race test. |
| AC-12 | Demonstrate recovery, sync, relay and participant limits on representative Android OEM devices. | Signed field-test report. |

### Measurement guidance

Each acceptance record should log build version, device model/OS, transport, room size, scenario, recorded measurements, pass criteria and observed results. Performance thresholds are deliberately not pre-approved; choose and ratify them before formal release certification.
