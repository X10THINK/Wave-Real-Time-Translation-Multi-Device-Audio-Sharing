# Wave FRD — 03 UC-01 / UC-02: Method, role and readiness

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 3  
**Status:** Source working draft; no claim of implemented completion.

## 03 UC-01 / UC-02: Method, role and readiness

| Field | Definition |
| --- | --- |
| Actors | Audio Share Host or Receiver; Live Translation Host or Receiver |
| Precondition | Wave installed, relevant system capability query available |
| Trigger | User selects Audio Share or Live Translation |
| Main success path | Choose Wi-Fi, Bluetooth or Hotspot -> Stage A check -> role Host/Receiver -> Stage B checks -> feature branch |
| Alt A | Missing Bluetooth permission / turned off -> context fix popup -> system permission/settings -> automatic recheck |
| Alt B | Hotspot Host guided to tethering setup; Receiver guided to join existing Host network |
| Exit guarantee | No false success/ready screen and no repeated method selection later in same journey |
| Links | SRS-GEN-002 to 007; BR-05 |

- A supported automatic readiness check must not silently enable radios or hotspot on restricted Android builds.

- Role validation errors stay contextual; users can return to previous screen without losing selection.
