# Wave TRD — 05 Transport layer and discovery constraints

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 7  
**Status:** Source working draft; no claim of implemented completion.

## 05 Transport layer and discovery constraints

| Transport | Proposed technical path | Critical limitations / checks |
| --- | --- | --- |
| Shared Wi-Fi | Authenticated LAN discovery, secure client-server or peer forwarding; scalable fanout based on measured capacity. | AP isolation, multicast/UDP availability, latency, network change and router policies. |
| Host hotspot | Host guides Android tethering configuration; receivers join network via system UI; local sockets. | OEM device limits, hotspot+mobile-data behavior, Android hotspot control restrictions. |
| Bluetooth Classic | App-level RFCOMM/socket channels for negotiated audio/control framing; direct and relay experiments. | Practical throughput, simultaneous link limits, codec overhead, discovery and connection stability. |
| Wi-Fi Direct | Candidate low-level future adapter, not a user-facing fourth network choice. | Group ownership, coexistence, versions and hardware availability. |
| Cross-network cloud | Deliberately excluded from core room discovery/media requirement. | Do not make public-internet remote rooms an implicit dependency of local Audio Share. |

### TransportAdapter proposal

Define an interface with scan/discover, connect, authenticateLink, sendControl, sendMedia, subscribeEvents, getMetrics and close. Each adapter declares media MTU/frame size, estimated throughput, link latency, peer count, congestion signals and whether reliable/unreliable delivery is available.

### Topology and local route planning

- Maintain a route graph keyed by device/session IDs, with link quality, hop count, freshness and selected route. Distinguish direct Receiver from Receiver-with-relay-function.

- Use bounded time-to-live/hop-limit and deduplication (session_id + source_stream_id + sequence) to prevent loops and re-broadcast storms.

- Prefer stable routes over constant topology churn; route updates require authentication and monotonic epoch/version.

- On relay loss, attempt bounded alternative routing with jitter-buffer protection; if unavailable, mark Reconnecting and ask for relevant user action.

- Never assume Bluetooth mesh can scale unboundedly or that relay forwarding is possible under background restrictions.
