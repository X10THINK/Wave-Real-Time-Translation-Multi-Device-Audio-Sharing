# Wave PRD — 07 Audio Share - session lifecycle and screen inventory

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 8, 9, 10  
**Status:** Source working draft; no claim of implemented completion.

## 07 Audio Share - session lifecycle and screen inventory

### Nineteen logical screens (approved V3.1)

| ID | Screen | Usage |
| --- | --- | --- |
| S01 | Wave Home | Two feature cards plus genuine active-session resume |
| S02 | Transfer Method | Three tap-to-choose local networks, Stage A automatic check |
| S03 | Select Role | Host or Receiver, Stage B role checks |
| H01 | Create Session | Name, participant limit, approval ON/OFF |
| H02 | Host Lobby | Invite QR/code, participant approvals, Start |
| H03 | Live Audio Host | Ready/Live/Paused/Recovering and control hub |
| H04 | Audio Source Selection | Three approved source options only |
| H05 | Music Library / Import | File picker, tracks, eligibility/error |
| H06 | Music Player | Shared music controls and timeline |
| H07 | Video Import / Selection | File picker and supported-media feedback |
| H08 | Video Player (Host) | Video local + receiver audio only |
| R01 | Join Session | Code/QR/Nearby entry |
| R02 | Enter Room Code | Short code validation and room lookup |
| R03 | QR Scanner | Secure invite scan; camera permissions in context |
| R04 | Nearby Sessions | Conditional on supported discovery |
| R05 | Waiting for Approval | Only Join Approval ON |
| R06 | Live Audio Receiver | Listening + independent local controls |
| X01 | Sessions Hub | All/Hosted/Joined, Active/Reconnecting/Recent |
| X02 | Session History / Details | Ended metadata; no false Resume action |

### Overlays and states - not additional mandatory pages

Contextual Network Fix Popup; QR/Invite; Participant Management; Remove/End/Leave confirmations; connection recovery; join validation; approval outcomes; Android permissions; capture/source status; audio output selector; session-resume shortcut. Global permission/setup pages and duplicate Audio Share dashboards should not be inserted as routine navigation.

### Session lifecycle requirements

| ID | Required behavior | State |
| --- | --- | --- |
| PR-SE-01 | Valid active session in Sessions Hub opens existing Host/Receiver live view without recreating room. | LOCKED |
| PR-SE-02 | Ended sessions show history/details; no Resume unless an explicit restart product is built. | LOCKED |
| PR-SE-03 | Room and membership remain alive during Host movie Paused state. | LOCKED |
| PR-SE-04 | Host loss, app process death and owner handover policies must be designed and tested. | OPEN |
| PR-SE-05 | Method migration Wi-Fi <-> hotspot <-> Bluetooth should protect session continuity where feasible. | TARGET |
