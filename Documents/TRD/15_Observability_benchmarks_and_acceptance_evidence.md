# Wave TRD — 15 Observability, benchmarks and acceptance evidence

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 15, 16, 17  
**Status:** Source working draft; no claim of implemented completion.

## 15 Observability, benchmarks and acceptance evidence

### Proposed metrics

| Domain | Metrics to collect | Method |
| --- | --- | --- |
| Local transport | Peer count, reconnects, throughput, RSSI where available, jitter/loss, route/hops. | Device log and captured test metrics. |
| Audio sync | Receiver audible skew, Host video lip-sync offset, drift, underruns, late frames. | Multichannel recording / synced reference. |
| Live Translation | Speech onset -> caption partial/final, speech onset -> voice, accuracy and interruption. | Timed bilingual corpus and user studies. |
| Billing | Reserved/committed provider units, Host credit spend, quota denial, duplicate-charge rate. | Ledger/provider reconciliations. |
| Android lifecycle | Background starts/stops, permission errors, service lifetime, battery drain. | OEM/OS matrix, profiler, logcat. |
| UX/accessibility | Successful joins, denied/timeout recovery, screen reader, scaling/contrast. | Scripted UI and device tests. |

### Scenario-based test matrix

| ID | Required test | Expected proof |
| --- | --- | --- |
| T-01 | Guest Audio Share Wi-Fi and hotspot joins, Host approval ON/OFF. | Successful validated join and independent leave. |
| T-02 | Bluetooth direct and multi-hop at increasing relay depth. | Actual topology, loss, delay and fallback logs; no hard capacity promise. |
| T-03 | Music/video sync across different device models and output routes. | Documented offset distribution and drift/resync results. |
| T-04 | Host video lock/exits; Receiver pause/resume while acting as relay. | Movie audio stops; independent local pause with forwarding sustained. |
| T-05 | External playback capture allowed vs opted-out source. | Consent and policy compliance; truthful error states. |
| T-06 | All translation users must sign in, even with Host sponsor. | Rejected unauthenticated requests at UI AND backend. |
| T-07 | Translation with 2+ target languages and authorized Receiver speaking. | Correct separate voice/caption streams and attribution. |
| T-08 | Provider timeout, loss of gateway internet, quota exhaustion. | Safe halt, no unauthorized spend, clear user messaging. |
| T-09 | Simultaneous billable work, retries, duplicate callback events. | Exactly-once ledger commit semantics from idempotent events. |
| T-10 | Foreground/background/Doze/OEM battery policies and Android accessibility. | Measured compatibility matrix and unresolved exceptions. |

### What does NOT constitute sufficient evidence

A working prototype demo alone does not establish transport coverage, fanout scale, AI correctness, secure billing, compatibility or a production-grade Sync Engine. Release claims require repeatable tests, actual device identifiers, test setup and thresholds approved in advance.
