# Wave BRD — 13 Technical constraints and dependencies - business impact

**From:** `01_BRD_Wave_Business_Requirements_Document_BRD_v1.0.pdf`  
**Pages:** 16, 17  
**Status:** Source working draft; no claim of implemented completion.

## 13 Technical constraints and dependencies - business impact

| Dependency / constraint | Why it matters | Required response |
| --- | --- | --- |
| Android app/platform permissions | Bluetooth, nearby device discovery, hotspot, camera, microphone, background processes and media capture vary by OS/OEM. | Contextual permission workflow; tested compatibility matrix. |
| Wi-Fi / hotspot topology | Available bandwidth, interference, AP client limits and local discovery affect group size. | Measured limits and capacity-aware messaging. |
| Bluetooth multi-hop | Classic Bluetooth, BLE and OEM restrictions affect fanout and concurrent audio operations. | Feasibility test, routing limits and alternatives; no automatic-mesh claim. |
| Media synchronization | Clock drift, jitter, buffering and output-route latency cause echo/lip-sync problems. | Playback Sync Engine benchmark and fallback paths. |
| External-app playback capture | Source applications may opt out of capture; platform consent is mandatory. | Eligible-app feedback and supported-case tests. |
| AI cloud provider | Streaming language support, latency, pricing, quotas and data terms vary. | Provider evaluation with accuracy, privacy and unit economics. |

| Dependency / constraint | Why it matters | Required response |
| --- | --- | --- |
| Internet gateway | Even local Receiver access requires a route to cloud AI for translation. | Define gateway availability/connection requirements and outage behavior. |
