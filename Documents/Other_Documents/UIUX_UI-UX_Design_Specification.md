# Wave — UI/UX Design Specification

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `12_UIUX_Wave_UI_UX_Design_Specification.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> UI UX DESIGN

> SPECIFICATION

> Approved screens, flows, visual system and accessibility

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-UIUX-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | UI UX Design Specification |
| Document ID | ZAEROX-WAVE-UIUX-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Design baseline and navigation identity

03 Audio Share 19 logical screens

04 Navigation and interaction flows

05 Live Translation experience and sign-in

06 Component and visual design references

07 Overlays, status states and empty/error UI

08 Screen acceptance and usability checks

## 02 Design baseline and navigation identity

This UI/UX Design Specification translates approved Wave UX V3.1 decisions into handoff-ready page behavior. Product branding is ZAEROX; installed/in-app name is Wave. Follow approved White + Turquoise visual identity and preserve previously finalized component family rather than introducing a new theme.

| Constraint | Required outcome |
| --- | --- |
| Bottom navigation | Audio Share \| Home \| Sessions; no standalone Music or Connect tabs |
| Entry order | Feature -> method (Wi-Fi/Bluetooth/Hotspot) -> Stage A check -> Host/Receiver -> Stage B check |
| Connectivity UI | Role-specific fix popup only when necessary; avoid extra setup success screens |
| Relay selection | No third Relay role; internal forwarding responsibility only |
| Permissions | Contextual Android platform permissions for microphone in Translation, camera QR, Bluetooth and allowed playback capture |
| Live Translation entry | Both Host and Receiver must sign in contextually in their branches before paid/joined translation operation |

## 03 Audio Share 19 logical screens

| ID | Screen | Required content / constraint |
| --- | --- | --- |
| S01 | Wave Home | Audio Share + Live Translation cards; active-session resume shortcut when actually valid |
| S02 | Transfer Method | Wi-Fi / Bluetooth / Hotspot direct tap; automatic Stage A probe |
| S03 | Select Role | Host / Receiver only; silent role-aware Stage B check |
| H01 | Create Session | Room name, max participants, join approval; inline validation |
| H02 | Host Lobby | QR/code, members, approval queue, Start Session; no source prerequisite |
| H03 | Live Audio Host | Ready/Live/Paused/Reconnecting; QR, participants, source, end |
| H04 | Audio Source Selection | Music / Video / External App Audio only; contextual subpage |
| H05 | Music Library / Import | Tracks, file selection, eligibility and empty/error states |
| H06 | Music Player | Artwork, title, position, control, sharing state, background requirement |
| H07 | Video Import / Selection | Local supported movie selection and eligibility feedback |
| H08 | Video Player (Host) | Host video + sound, receiver audio only, leave-player pause rule |
| R01 | Join Session | Room Code / QR / supported Nearby |

| ID | Screen | Required content / constraint |
| --- | --- | --- |
| R02 | Enter Room Code | Code is discovery only, not authorization |
| R03 | QR Scanner | Camera permission on demand; verify invite and room |
| R04 | Nearby Sessions | Conditional; hide when unsupported |
| R05 | Waiting for Approval | Conditional on approval ON; timeout, deny and cancel |
| R06 | Live Audio Receiver | Audio-only, local pause/mute/volume/output and recovery |
| X01 | Sessions Hub | All / Hosted / Joined; Active / Reconnecting / Recent |
| X02 | Session History / Details | Ended details; no misleading dead-session Resume |

The 19 inventory items include conditional screens and contextual subpages. Loading, status changes, approvals, network fixes and confirmations generally appear as overlays or states, not new mandatory pages.

## 04 Navigation and interaction flows

```text
Wave Home -> Audio Share -> Method -> Stage A -> Role -> Stage B
Host: Create Room -> Lobby -> Start -> Live Host Ready
-> Source -> Music / Video / Supported App Audio
Receiver: Join -> Code/QR/Nearby -> Validate
-> Approval ON? Wait/Accept : Admit -> Live Audio
Sessions Hub -> Active/Reconnecting same live view
-> Ended session history only
```

The Host Room QR and participant management are reachable from Lobby and Live Host, including Ready, Paused and Reconnecting where the underlying room exists. Source changes do not recreate the room. Receiver-local actions do not mutate other receivers.

## 05 Live Translation experience and sign-in

| Flow stage | Host experience | Receiver experience |
| --- | --- | --- |
| Feature / method / role | Live Translation -> transport -> Host | Live Translation -> transport -> Receiver |
| Sign-in gate | Mandatory account sign-in before paid session creation | Mandatory account sign-in before joining translation |
| Financial gate | Host entitlement verified by server | No individual paid plan required in Host-funded room |
| Room workflow | Create, invite, approve, control speakers | Join by code/QR, approval when ON |
| Language UI | Source and supported output channels as available | Choose preferred supported language |

| Flow stage | Host experience | Receiver experience |
| --- | --- | --- |
| Live UX | Capture mic when authorized, captions, costs/status | Translated voice and live captions; speaker request/grant |
| Error UI | Not Entitled / Quota Exceeded / Provider Unavailable | Unauthorized / Not Admitted / Unsupported Language |

The exact number of Live Translation screens and placement of each identity form were not fixed in the Audio Share V3.1 handoff; this section specifies functional states rather than inventing a locked screen count.

## 06 Component and visual design references

| Family | Approved direction | Implementation rule |
| --- | --- | --- |
| Color | White + Turquoise with contrast-only corrections | Use accessible dark turquoise text/essential icons where needed; no broad palette redesign |
| Buttons | Soft Turquoise Neumorphic Pill | Preserve shape and approved gradient/depth family |
| Cards | Halo / soft white raised surfaces | Consistent elevations and section spacing |
| Inputs | Pearl Capsule fields | Room Name, Code and Name must follow shared style |
| Dialogs | Pearl Halo dialogs and sheets | Compact role-aware network fixes and approvals |
| Status indicators | Liquid Signal / restrained motion | States must communicate by text+shape, not color alone |
| Navigation | Approved Audio Share \| Home \| Sessions | Preserve existing bottom navigation visual family |
| Accessibility | WCAG AA appropriate contrast, Android touch targets | TalkBack labels, font scaling, safe areas, reduced motion, text focus |

## 07 Overlays, status states and empty/error UI

| Overlay / state | Trigger | Required behavior |
| --- | --- | --- |
| Network fix | Missing permissions, Wi-Fi, Bluetooth or hotspot join | Action-specific fix and recheck |
| QR / Invite | Host Lobby or Live | Code copy / share; valid room scope |
| Participant management | Host Lobby/Live | Names/status, requests, remove confirmation |

| Overlay / state | Trigger | Required behavior |
| --- | --- | --- |
| Waiting for approval | Receiver with approval ON | Cancel/accepted/rejected/timed out |
| Audio output | Receiver live | Speaker vs available audio route, mute/volume |
| Source unavailable | Source denied, no eligible external audio | Do not claim active playback |
| Reconnecting | Network error, Host absent temporarily | In-place progress and real Retry/Fix when possible |
| End/Leave | Host End vs Receiver Leave | Host end affects all; Receiver leave independent |
| No account / plan | Translation entry | Sign-in for all; paid entitlement on Host only |

## 08 Screen acceptance and usability checks

| Test case | UX acceptance condition |
| --- | --- |
| UX-01 | Method tap advances without extra Continue; Stage A and B only prompt when needed |
| UX-02 | Host reaches Lobby before selecting music, video or external source |
| UX-03 | Receiver video player does not exist; Host movie minimize pauses movie and shared audio |
| UX-04 | Joining with approval OFF validates session; ON shows waiting state |
| UX-05 | Receiver local pause/mute does not imply Host pause |
| UX-06 | Sessions Hub opens current valid live session, never outdated ended room |
| UX-07 | Live Translation Receiver cannot bypass contextual sign-in |
| UX-08 | All critical touch targets accessible and labeled; scaled text does not clip |
| UX-09 | White/Turquoise contrast patches do not change previously approved visual family |

Final UX approval requires design handoff comparison, Android screen-size snapshots, accessibility walkthrough, and corresponding functional tests; visual mockup approval is not system certification.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
