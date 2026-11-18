# Wave PRD — 14 Risks, dependencies and open decisions

**From:** `02_PRD_Wave_Product_Requirements_Document_PRD_v1.0.pdf`  
**Pages:** 15  
**Status:** Source working draft; no claim of implemented completion.

## 14 Risks, dependencies and open decisions

| Risk / dependency | Impact | Mitigation / decision |
| --- | --- | --- |
| Bluetooth fanout / mesh | Variable hardware limits; multi-hop latency and topology fragility. | Proof-of-capability on devices before claiming scale. |
| Android media capture policy | Third-party app audio may be inaccessible. | Respect capture eligibility and inform users. |
| Foreground/background limitations | Music, mic or forwarding may stop under OS power rules. | Foreground-service compliance and device matrix. |
| Internet-only AI path | Offline local links cannot translate without reachable cloud gateway. | Honest network prerequisites and fallback messaging. |
| All-participant translation sign-in | No-data listener authentication is unresolved. | Define host-gateway mediated sign-in or require listener internet; do not silently permit guests. |
| Host-paid financial exposure | Unexpected overage or abuse could damage trust. | Server-enforced budgets, authoritative ledgers, alerts and abuse prevention. |
| Unverified sync / lip-sync | Echo/lag degrades movie and music experience. | Recorded device sync calibration and regression tests. |

### Open product decisions register

| ID | Decision needed |
| --- | --- |
| OD-01 | Launch markets, segments and official supported Android/OEM/device versions. |
| OD-02 | Production target languages and provider service regions; first pair is prototype English <-> Tamil. |
| OD-03 | Subscription/credits, currency, prices, renewals, taxes, refunds, top-ups and max spend. |
| OD-04 | Required sign-in fields/provider and exact placement within approved translation branches. |
| OD-05 | Private data retention/deletion, transcription/recording policy and consent notices. |
| OD-06 | Exact measured sync, audio quality, latency, participant cap and relay-depth release thresholds. |
| OD-07 | Host outage/transfer, app restart, stale rooms and Wi-Fi/hotspot/Bluetooth migration semantics. |
| OD-08 | How all participants sign in when only Host has internet; gateway auth eligibility and constraints. |
| OD-09 | Translation simultaneous-speaker policy, parallel channels and final language rollout. |
| OD-10 | Provider integrations, API reliability/cost budgets and fallback service plan. |
