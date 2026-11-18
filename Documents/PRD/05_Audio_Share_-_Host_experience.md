# Wave PRD — 05 Audio Share - Host experience

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 6, 7  
**Status:** Source working draft; no claim of implemented completion.

## 05 Audio Share - Host experience

### Host journey: Create -> Lobby -> Start -> Source -> Live

- Create Session: enter a room name; set maximum participants subject to real support constraints; choose Join Approval ON or OFF; validate inputs inline.

- Host Lobby: show session name, method/status, QR and room code, joined users, pending requests, approvals and Start Session. Choosing audio source is not a prerequisite for reaching Lobby.

- Start Session: open Live Host in Ready state even if no source has been selected; never show Sharing when no source is available.

- Choose Source: select Music, Video or supported External App Audio; allow switching sources without destroying the existing room.

- Live Host: show status (Ready, Sharing, Paused, Reconnecting, Source Unavailable, Ending), session elapsed time, participants and quick invite; offer Pause/Resume, source change and End.

- Host End is global: invalidate the room, stop playback for everyone and mark the session ended. Confirm destructive actions.

### Host media source specifics

| Source | Expected behavior | Special rules |
| --- | --- | --- |
| Music | Import/select local playable audio; inspect metadata; Host controls play/pause/seek. | Music continues in supported background sessions; keep room identity and sync timeline. |
| Video | Host imports compatible movie, sees video and hears audio. Receivers get audio only. | Leaving the video player or locking Host phone pauses local video AND shared audio; room remains alive. |
| External app | Explain Android playback-capture consent; start only if source and device permit. | Unsupported media/capture denial must be explicit; never imply all third-party apps work. |

### Audio Share Host requirement register

| ID | Requirement | State |
| --- | --- | --- |
| PR-AS-01 | Host room creation retains identity, settings, selected method and approval rules. | LOCKED |
| PR-AS-02 | Host Lobby always permits inviting and managing participants; source setup cannot gate Lobby. | LOCKED |
| PR-AS-03 | Host live screen remains the central place for session, source and participant controls. | LOCKED |
| PR-AS-04 | Provide Music, Video and External App Audio only; remove microphone source tile. | LOCKED |
| PR-AS-05 | Host movie is visible only locally; all Receivers get movie audio only. | LOCKED |
| PR-AS-06 | Host movie view exit/lock pauses video and audio; connections survive in Paused state. | LOCKED |
| PR-AS-07 | Music background playback and timeline alignment must be implemented and validated. | TARGET |
| PR-AS-08 | Unsupported external-app capture must show truthful error/retry/permission states. | LOCKED |
| PR-AS-09 | Source change keeps room and membership; cleanly releases previous source. | LOCKED |
| PR-AS-10 | Host global stop/end affects all members, subject to visible confirmation. | LOCKED |
