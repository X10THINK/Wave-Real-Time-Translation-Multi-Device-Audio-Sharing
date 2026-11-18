# Wave BRD — 10 Non-functional business requirements

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 14  
**Status:** Source working draft; no claim of implemented completion.

## 10 Non-functional business requirements

Values below are product expectations and testing directions. Where no baseline or thresholds have been approved, acceptance thresholds must be agreed after representative device and service benchmarking.

| ID | Quality area | Business expectation |
| --- | --- | --- |
| NFR-01 | Availability | Recover gracefully from recoverable network/service interruption; show true status and actions. |
| NFR-02 | Audio synchronization | Measure receiver-to-receiver and Host-video alignment by transport/device; earlier 10-20 ms figure is a research target, not a guarantee. |
| NFR-03 | Translation latency | Work toward approximately 1-2 s perceived continuous translated speech in early stages; sub-500 ms is a later research ambition only. |
| NFR-04 | Scalability | Verify capacity separately for Wi-Fi, hotspot, direct Bluetooth and relay; no universal max count. |
| NFR-05 | Security | Protect identity, session membership, speaking permissions and billing access; document cryptography and key handling. |
| NFR-06 | Privacy | Apply data minimization, consent/notice for microphone and cloud processing, and defined retention/deletion policies. |
| NFR-07 | Reliability | Handle packet loss, buffering, clock drift, host exit, screen lock, device sleep, reconnect and audio-route changes. |
| NFR-08 | Accessibility | Follow approved contrast corrections and test Android touch targets, font scaling, screen readers and reduced motion. |
| NFR-09 | Compatibility | Maintain a tested Android OS and device/OEM support matrix before public support claims. |
| NFR-10 | Cost efficiency | Track cost per translation minute/target language/session and implement usage caps/alerts. |
| NFR-11 | Observability | Provide useful diagnostics and redacted network/error logs without unnecessary personal content. |
| NFR-12 | Media quality | Use appropriate codec/quality settings; tune against measured conditions rather than marketing targets. |
