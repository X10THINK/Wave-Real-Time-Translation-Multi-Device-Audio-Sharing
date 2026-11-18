# Wave BRD — 05 Stakeholders, customer groups and product roles

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 7  
**Status:** Source working draft; no claim of implemented completion.

## 05 Stakeholders, customer groups and product roles

### Stakeholders

| Stakeholder | Interest / responsibility |
| --- | --- |
| ZAEROX product ownership | Business outcomes, requirement approval, scope, pricing, go/no-go and priorities. |
| Product design / UX | Consistent screens and accessibility without altering approved Wave component language. |
| Flutter / Android engineering | Client workflows, native permissions, transport integration, media and sync behavior. |
| AI / cloud engineering | Translation gateway, streaming, cost usage and language/provider support. |
| Security / privacy / operations | Identity, protected rooms, retention, payments, monitoring and incident response. |
| Quality assurance / real users | Functional acceptance, device compatibility, network/recovery testing and usability. |

### Personas and role permissions

| Role | Meaning | Key rights / limits |
| --- | --- | --- |
| Audio Share Host | Starts and manages a local audio session. | Create room, configure approvals, invite, select source, global playback controls, remove participants and end session; guest mode is permitted. |
| Audio Share Receiver | Joins a local audio session. | Listen, local pause/mute/volume/output/leave; cannot end or globally control other devices; guest mode is permitted. |
| Translation Host | Authenticated creator/payer of a translation room. | Create and manage paid session, select relevant options, manage speaker rights and usage; must have valid payer entitlement. |
| Translation Receiver | Authenticated participant in a translation room. | Join, select language, receive voice/captions, speak only if authorized; no separate charge in Host-sponsored model. |
| Relay device | Automatic network responsibility, not a signup role. | May listen and forward within supported connectivity and session permissions; user still selects Host or Receiver. |
