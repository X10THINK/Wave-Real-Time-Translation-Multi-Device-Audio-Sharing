# Wave PRD — 03 Scope, release strategy and exclusions

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 5  
**Status:** Source working draft; no claim of implemented completion.

## 03 Scope, release strategy and exclusions

### Functional scope

- Audio Share: Host/Receiver sessions, lobby, invites, joining approval, Wi-Fi/hotspot/Bluetooth transport selection, three host audio sources, music/movie controls, local receiver controls, Sessions Hub and honest recovery states.

- Live Translation: all-user authentication, Host-paid entitlement checking, local-room joining, microphone speech, authorized speakers, language selection, translated voice and captions, usage metering and cost/quota protection.

- Shared foundation: transport-aware session lifecycle, participant records, verified admission, role-based permission checks, status, accessibility and compatibility reporting.

### Explicit exclusions / non-guarantees

- Microphone or generic Live Audio as an Audio Share source: removed from Audio Share; microphone is used for translation.

- Video streamed to Receiver phones: not part of the approved movie experience. Only the Host sees imported video.

- Universal capture of audio from arbitrary third-party apps: not possible under Android playback-capture rules.

- Cross-network cloud rooms and fully offline AI translation: outside the approved core local-session model.

- Unlimited Bluetooth mesh, a fixed 50-100 participant capacity, zero audio delay and sub-500-ms translation: not guaranteed or validated.

- Theater Mode, speaker spatial calibration, personal voice cloning and separate ZAEROX earbuds/accessory hardware: future or separate projects.

### Recommended phased delivery (proposal, not locked)

| Phase | Scope | Go/no-go evidence |
| --- | --- | --- |
| P0 - Foundation | Identity/session states, network readiness UX, source import and basic local transport. | Repeatable Host/Receiver connectivity and recovery tests. |
| P1 - Audio Share | Music/movie/audio capture eligibility, output control, shared sync and sessions lifecycle. | Multi-phone timing and background test results. |
| P2 - Translation beta | Signed-in translation, authorized speakers, AI provider, captions/voice, Host sponsorship and metering. | Cost reconciliation, privacy checks and latency samples. |
| P3 - Resilience/scale | Adaptive relay, network handover, large-group tuning, international language expansion. | Device matrix and multi-hop / load validation. |
