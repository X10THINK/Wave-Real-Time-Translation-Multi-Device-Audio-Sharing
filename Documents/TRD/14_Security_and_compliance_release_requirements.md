# Wave TRD — 14 Security and compliance release requirements

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 15  
**Status:** Source working draft; no claim of implemented completion.

## 14 Security and compliance release requirements

### Security baseline

- Authenticated host/session and all-user translation membership, signed/expiring invites, admission control and revocation.

- Secure authenticated encryption for local media/control where feasible, key rotation/rekey on membership change and cryptographic design review prior to launch.

- HTTPS/TLS to cloud services; store tokens in platform-appropriate secure storage; never distribute private API keys in apps.

- Host actions and speaker permissions authorized server-side for paid sessions; no client-supplied charge ownership override.

- API rate limiting, safe error disclosures, replay protection, invite brute-force controls and privacy-safe security logs.

- Media rights/compliance review for importing and transmitting locally accessed content; third-party protected playback capture remains subject to source-app/system policy.

### Privacy and user transparency

The final policy must specify microphone use, speech transfer to cloud AI, participants who may hear voice/captions, whether transcripts or recordings persist, account deletion and billing records retention. Jurisdiction-specific legal evaluation remains a release gate, not something assumed satisfied by this draft.
