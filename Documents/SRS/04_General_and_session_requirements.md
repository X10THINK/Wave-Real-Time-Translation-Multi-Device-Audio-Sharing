# Wave SRS — 04 General and session requirements

**From:** `03_SRS_Wave_Software_Requirements_Specification.pdf`  
**Pages:** 4  
**Status:** Source working draft; no claim of implemented completion.

## 04 General and session requirements

| ID | Shall requirement | Priority | BR |
| --- | --- | --- | --- |
| SRS-GEN-001 | The app shall display installed and in-app name Wave under ZAEROX brand. | Must | BR-01 |
| SRS-GEN-002 | The Home screen shall offer exactly Audio Share and Live Translation as primary feature entries. | Must | BR-01 |
| SRS-GEN-003 | The bottom navigation shall contain Audio Share, Home and Sessions; no standalone Connect or Music tab. | Must | BR-01 |
| SRS-GEN-004 | Both features shall request transport method before Host/Receiver role selection. | Must | BR-05 |
| SRS-GEN-005 | The method selector shall present Wi-Fi, Bluetooth and Mobile Hotspot as direct actions. | Must | BR-05 |
| SRS-GEN-006 | After transport selection the app shall run capability Stage A; after role selection Stage B shall validate role-specific readiness. | Must | BR-05 |
| SRS-GEN-007 | Network fix prompts shall be contextual and optional when no action is required; they shall not add mandatory success/setup pages. | Must | BR-05 |
| SRS-GEN-008 | A valid active session shall reopen from Sessions without recreating or blindly rejoining. | Must | BR-12 |
| SRS-GEN-009 | Ended session history shall not imply resume of a dead session without an explicit restart feature. | Must | BR-12 |
| SRS-GEN-010 | An admitted peer shall possess session-specific authorization; room-code/QR possession alone shall not grant access. | Must | BR-06 |
