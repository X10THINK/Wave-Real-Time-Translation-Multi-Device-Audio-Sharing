# Wave FRD — 02 Functional decomposition and scenario policy

**From:** `04_FRD_Wave_Functional_Requirements_Document.pdf`  
**Pages:** 3  
**Status:** Source working draft; no claim of implemented completion.

## 02 Functional decomposition and scenario policy

FRD captures end-to-end functional behaviors, actors, preconditions, triggers, postconditions, exception paths and input/output rules. Use-case IDs map to SRS and BRD. Flows below are the current approved behavior unless explicitly labeled PROPOSED or TARGET.

| Functional group | Use cases | Core owner |
| --- | --- | --- |
| Entry and readiness | UC-01 Transport selection; UC-02 Select role and capability checks | Flutter + Android adapters |
| Audio Share Host | UC-03 Create/Lobby/Start; UC-04 Source and global playback | Host session controller |
| Audio Share Receiver | UC-05 Join/Approval/Listen; UC-06 Local controls | Peer session engine |
| Session lifecycle | UC-07 Resume/Leave/End/Recover | Shared session manager |
| Live Translation | UC-08 Auth/Host billable room; UC-09 Receiver/Language; UC-10 Speaker/Usage | Identity and translation gateway |
