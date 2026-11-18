# Wave SRS — 02 Purpose, scope and system boundary

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 3  
**Status:** Source working draft; no claim of implemented completion.

## 02 Purpose, scope and system boundary

The Software Requirements Specification (SRS) defines verifiable system behaviors for the Wave Android app, local transport and media engine, and proposed identity, translation and billing services. It complements the BRD business outcomes, PRD user needs, and TRD technical approach.

| Boundary | Included | Excluded or gated |
| --- | --- | --- |
| Client | Flutter Android UI, native audio, local transports, session and playback state | iOS and desktop clients (future) |
| Audio Share | Wi-Fi, hotspot and Bluetooth selection; Music, Host Video audio and permitted External App Audio | Microphone as Audio Share source; receiver-side video |
| Live Translation | Signed-in Host/Receiver, hosted paid sessions, audio/captions and optional speaker grants | Unauthenticated translation guests; fully offline AI translation |
| Infrastructure | Proposed authorization, entitlement, usage accounting, stream routing | Provider choices and deployment platform are not finalized |

Requirement status convention: LOCKED = approved behavior; TARGET = performance/deployment objective to verify; PROPOSED = candidate solution; OPEN = needs product/engineering approval. Release priority does not certify completion.
