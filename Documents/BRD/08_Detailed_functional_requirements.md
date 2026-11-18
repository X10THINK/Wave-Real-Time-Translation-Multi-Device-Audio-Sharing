# Wave BRD — 08 Detailed functional requirements

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 10, 11, 12, 13  
**Status:** Source working draft; no claim of implemented completion.

## 08 Detailed functional requirements

This section captures what the Wave product must do, while avoiding hard-coded assumptions about transport, API provider or exact capacity. Each entry is a requirement/target, not a claim of present implementation.

### 8.1 Shared app and session management

| ID | Priority | Requirement |
| --- | --- | --- |
| FR-C01 | Must | Show Wave Home with Audio Share, Live Translation and genuine active-session resume entry. |
| FR-C02 | Must | Provide method selection in this order: Wi-Fi, Bluetooth, Mobile Hotspot (UI presentation may follow locked design). |
| FR-C03 | Must | Run automatic method capability checks and role-specific checks; show compact fix prompt only if required. |
| FR-C04 | Must | Provide Host and Receiver roles; do not expose Relay as a third role tile. |
| FR-C05 | Must | Provide Sessions Hub with Hosted / Joined, Active / Reconnecting / Recent states. |
| FR-C06 | Must | Reopen a valid active session without forcing a new create/join operation. |
| FR-C07 | Must | Represent Ready, Active, Paused, Reconnecting, Unavailable and Ended states honestly. |
| FR-C08 | Must | Handle Android permission denial, retry, limited hardware support and settings return. |
| FR-C09 | Should | Provide clear connection diagnostics, error messages and recovery/leave paths. |

### 8.2 Audio Share - Host and Receiver

| ID | Priority | Requirement |
| --- | --- | --- |
| FR-A01 | Must | Allow a Host to define room name, supported participant capacity and Join Approval setting. |
| FR-A02 | Must | Provide an invite mechanism with QR and room code; Nearby only when actually supported. |
| FR-A03 | Must | Validate room reachability, identity/authorization, session state and capacity before admitting a Receiver. |
| FR-A04 | Must | When approval is ON, support request, waiting, accept, reject, timeout and cancel; OFF bypasses manual approval but not security checks. |
| FR-A05 | Must | Let Host start from Lobby into Live Host Ready before choosing an audio source. |
| FR-A06 | Must | Provide exactly Music, Video, External App Audio source selections; exclude Microphone. |
| FR-A07 | Must | Enable local music import/playback and Host global play/pause/seek controls when supported. |
| FR-A08 | Must | Let Host import and view video locally while distributing its audio only to Receivers. |
| FR-A09 | Must | On Host leaving video player or locking screen, pause local video and shared movie audio but preserve the session. |
| FR-A10 | Must | For supported sources only, obtain platform consent to capture external-app playback audio and report capture states. |
| FR-A11 | Must | Let Receiver choose local audio output, adjust volume/mute, pause/resume output and leave independently. |
| FR-A12 | Must | Receiver-local pause shall not stop others or required relay forwarding; resume should rejoin current Host timeline. |
| FR-A13 | Must | Host global pause/end shall update the shared session; Host End terminates the room for all participants. |
| FR-A14 | Should | Keep eligible shared music active during supported minimized/screen-off conditions. |
| FR-A15 | Should | Provide source switching without destroying session identity and safely release old source resources. |
| FR-A16 | Target | Implement timestamped synchronized playback, drift correction and fast rejoin across supported transports. |
| FR-A17 | Target | Support adaptive direct / multi-hop / branching local forwarding and route repair where technically feasible. |
| FR-A18 | Target | Investigate transport transitions without unnecessary session loss; treat reachability and capability as conditional. |

### 8.3 Live Translation and language experience

| ID | Priority | Requirement |
| --- | --- | --- |
| FR-T01 | Must | Preserve transfer method selection -> role selection before Live Translation Host/Receiver actions. |
| FR-T02 | Must | Require successful account sign-in for all Live Translation participants before creating or joining rooms. |
| FR-T03 | Must | Permit authenticated Host to create and manage an eligible translation session after entitlement validation. |
| FR-T04 | Must | Permit authenticated Receivers to join authorized Host-sponsored sessions without individual payment. |
| FR-T05 | Must | Allow each participant to select a supported listening/translation language. |
| FR-T06 | Must | Capture authorized speaker microphone audio with appropriate permissions and send it to a valid translation gateway. |
| FR-T07 | Must | Provide translated synthesized voice and live captions for eligible target languages. |
| FR-T08 | Must | Keep translation output updated during ongoing speech, including interruption and reconnect scenarios. |
| FR-T09 | Should | Allow Host to approve/manage which participants can speak during multilingual discussion. |
| FR-T10 | Should | Support bidirectional discussion and avoid uncontrolled overlapping-speaker usage. |
| FR-T11 | Target | Explore grouping repeated translation computation per language/stream where possible to control cost. |
| FR-T12 | Target | Explore multiple parallel multilingual sessions/channels as a scaling capability. |
| FR-T13 | Must | Show internet/service outage, unavailable language or denied microphone states accurately. |
| FR-T14 | Future | Support consent-based own-voice output only after separate review of privacy, quality and cost. |

### 8.4 Identity, payment, usage and governance

| ID | Priority | Requirement |
| --- | --- | --- |
| FR-I01 | Must | Allow guest-style access to basic Audio Share independent of Live Translation account requirement. |
| FR-I02 | Must | Require Live Translation account identity for Host and Receiver, including Host-paid invitees. |
| FR-I03 | Must | Ensure Receiver sign-in does not imply they need their own paid subscription in a sponsored session. |
| FR-I04 | Must | Validate Host subscription/credits/entitlement before beginning billable operations. |
| FR-I05 | Must | Attribute authorized speaker/session translation usage to the sponsoring Host in Host-paid mode. |
| FR-I06 | Must | Meter usage according to the chosen AI provider charging units and agreed billable policy. |
| FR-I07 | Must | Block unauthorized chargeable actions and enforce configurable limits and session budgets. |
| FR-I08 | Should | Provide Host-visible usage estimates, consumption status, warnings and stop/renewal state. |
| FR-I09 | Must | Keep payment-sensitive card or account credentials out of Wave application records; use approved processors. |
| FR-I10 | Open | Specify registration fields, exact checkout screens, local currency, subscription duration, refund and tax rules. |
