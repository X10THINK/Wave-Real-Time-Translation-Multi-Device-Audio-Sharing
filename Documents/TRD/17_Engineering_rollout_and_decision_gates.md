# Wave TRD — 17 Engineering rollout and decision gates

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 17, 18  
**Status:** Source working draft; no claim of implemented completion.

## 17 Engineering rollout and decision gates

| Gate | Deliverables / check | Approval owner |
| --- | --- | --- |
| G0 - Design review | Spec-to-code map, security/dataflow threat model, API/provider decision options. | Engineering + product |
| G1 - Local transport proof | Wi-Fi/hotspot/BT direct test reports; initial route and auth proof. | Engineering + QA |
| G2 - Sync qualification | Clock/drift tests, music/movie/receiver pause behavior, output routes. | Audio engineering + QA |
| G3 - Account / AI beta | All participant sign-in, Host-funded verification, live translated voice/captions. | Product + AI + backend |
| G4 - Billing safety | Server metering/quotas, consent, ledger reconciliation, concurrency/race tests. | Backend + security + finance |
| G5 - Release readiness | App lifecycle/OEM compatibility, privacy policy, accessible UX, capacity and SLA claims based on tests. | Product owner + QA |

### Open technical decisions

| ID | Unresolved specification |
| --- | --- |
| TD-01 | Minimum/target Android SDK versions, device/OEM compatibility and Bluetooth coexistence matrix. |
| TD-02 | Media codec(s), framing interval, discovery scheme and secure link key exchange per transport. |
| TD-03 | Relay graph protocol, routing metric, allowed fanout/hops, self-healing and method migration policy. |
| TD-04 | Sync playout latency budgets, output-route calibration and measured skew percentiles. |
| TD-05 | Selected AI provider/API, language support, latency, failover, cloud hosting and geographic processing regions. |
| TD-06 | Identity provider, account fields, authenticated joining over Host-only internet connection. |
| TD-07 | Pricing/credit unit specification, provider usage reconciliation, quotas and payment provider. |
| TD-08 | Session host loss, explicit handover rules, app restart and persistent history semantics. |
| TD-09 | Data retention, recordings/transcript policy, privacy notices, deletion/backup. |
| TD-10 | Release targets and QA coverage for battery, network quality, accessibility, sync and fanout. |
