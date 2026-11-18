# Wave BRD — 04 Project scope and boundaries

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 6  
**Status:** Source working draft; no claim of implemented completion.

## 04 Project scope and boundaries

### Baseline product scope - included

| Area | In-scope business capability |
| --- | --- |
| Core application | Android Wave application, Home, Audio Share, Live Translation, Sessions, contextual permissions and settings necessary to operate. |
| Audio Share | Host/Receiver group sessions; Music, Host Video audio only, eligible External App Audio; receiver output controls and session lifecycle. |
| Connectivity | User selection of Wi-Fi, Mobile Hotspot or Bluetooth; discovery/joining via supported code, QR and Nearby methods; readiness/recovery. |
| Relay & sync | Dynamic forwarding and synchronized delivery as engineering targets; not a capacity or performance guarantee. |
| Live Translation | Authenticated participants; voice + captions; continuous one-to-many use case; authorized group discussion as a product goal. |
| Commercial | Host-paid session entitlement, billable AI usage controls, quotas, subscription/credit modeling and payment integration requirements. |
| Trust | Consent, identity verification, protected sessions, participant moderation, basic privacy and audit/diagnostic needs. |

### Not in baseline scope

- Manufacture, sale, or operation of proprietary ZAEROX earbuds or physical BT SHARE hardware as a dependency.

- Receiver-side movie/video streaming or a Watch Together video screen: receivers listen to Host movie audio only.

- A separate microphone audio source under Audio Share; microphones belong to Live Translation.

- Guaranteed capture from every third-party media app; Android and source-app policies govern eligibility.

- Fully offline AI speech translation; the approved approach relies on internet-accessible AI processing.

- General cloud-hosted cross-network room discovery/participation as a default local-session capability.

- Guaranteed unlimited recipients, seamless all-device mesh operation, zero latency, or universal Android support.

### Future / independently scoped options

Theater Mode with channel-specific surround roles, placement, calibration and fallback is a separate approved future concept and is not inserted into the baseline Audio Share screen count. Consented personal voice cloning, broader language coverage, advanced multi-session translation and other expansion ideas require their own product prioritization.
