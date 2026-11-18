# Wave PRD — 06 Audio Share - Receiver experience

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 7, 8  
**Status:** Source working draft; no claim of implemented completion.

## 06 Audio Share - Receiver experience

### Receiver join and admission

- User chooses supported Join by room code, QR scan or Nearby Rooms (only where discovery is actually supported).

- Short codes act as discovery references, not standalone authentication. Verify identity/session token, host availability, network reachability and room capacity before admission.

- Join Approval ON: send request, show Pending, allow Cancel; present accepted, denied and timed-out results; Host can accept/reject.

- Join Approval OFF: skip waiting screen after normal session/security/capacity validation; no bypass of admission checks.

### Receiver listening behavior

- Receiver controls own mute, volume, available audio output and local pause/resume without changing other users.

- Local pause suspends only local output; if the phone is forwarding audio as a relay, its forwarding path should continue where feasible and authorized.

- On local resume, sync to the Host current live timeline; do not play queued old audio or restart from the beginning.

- Host global pause/end overrides all Receivers. Receiver Leave removes only that participant.

- Reconnect within the same live screen where possible, with actionable Retry/Fix controls only if automatic recovery fails.

### Receiver requirement register

| ID | Requirement | State |
| --- | --- | --- |
| PR-AR-01 | Support valid room code and QR joining; Nearby only when transport discovery is supported. | LOCKED |
| PR-AR-02 | Respect Host Join Approval ON/OFF, denial, timeout, cancel and room-full states. | LOCKED |
| PR-AR-03 | Receiver has independent volume, mute, output, local pause and leave. | LOCKED |
| PR-AR-04 | Local pause does not stop peer listening or necessary relay forwarding. | LOCKED + TARGET |
| PR-AR-05 | Local resume returns to current Host playback timeline, dropping stale buffers. | LOCKED + TARGET |
| PR-AR-06 | Receiver shows audio only for Host video source; no remote video player. | LOCKED |
| PR-AR-07 | On recoverable loss, use in-place reconnecting and honest output status. | LOCKED + TARGET |
