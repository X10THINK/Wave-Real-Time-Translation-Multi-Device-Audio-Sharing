# Wave — Low Level Design

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `07_LLD_Wave_Low_Level_Design.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> LOW LEVEL DESIGN

> Proposed state machines, algorithms and module contracts

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-LLD-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | Low Level Design |
| Document ID | ZAEROX-WAVE-LLD-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Module contracts and state machine policy

03 Room state machine

04 Peer join, approval and replay defense

05 Timed audio delivery and receiver-local pause

06 Adaptive relay topology and backpressure

07 Media source adapter lifecycle

08 Translation streaming, usage commits and error model

09 Persistence, diagnostics and negative tests

## 02 Module contracts and state machine policy

The Low-Level Design (LLD) proposes internal responsibilities and algorithm boundaries for a Flutter Android application with native audio/transport adapters and optional secured cloud services. All implementation details below remain design proposals until reviewed and mapped to actual source files.

| Module | Key methods / events | Thread / lifecycle notes |
| --- | --- | --- |
| SessionController | create, join, admit, start, stop, reconnect; onState | Serialized event reducer; persisted epoch |
| ConnectivityFacade | probe(method,role), discover, connect, switch | Android permission and radio lifecycle |
| PeerRouter | registerPeer, findRoute, forward, dropPeer | Bounded queues; TTL/hop defense |
| AudioSourceManager | prepareMusic, prepareVideo, startCapture, stop | MediaProjection consent and audio focus |
| SyncClock | sampleClock, estimateOffset, playoutAt, correctDrift | Use monotonic time; no wall-clock scheduling |
| TranslationClient | authenticate, join, publishAuthorizedSpeech, subscribeLang | Never hold provider secrets |
| UsageAuthority | authorizeHost, reserve, commitUsage, enforceLimit | Server-side, atomic and idempotent |

## 03 Room state machine

```text
CREATED -> LOBBY -> READY -> SHARING <-> PAUSED
| |
| v
+-----> RECONNECTING
|
RECOVERED -> prior authoritative state
|
TIMEOUT / EXPLICIT END
v
ENDED
```

| Invariant | Expected behavior |
| --- | --- |
| Session epoch increases on reset/recreation | Old packets and membership proofs cannot mutate new session |
| Only Host controls global playback | Receiver action cannot alter global state |
| End is terminal for current session ID | A history card cannot resume terminated transport |
| Role-sensitive network repair | No duplicate room creation due to network checks |

## 04 Peer join, approval and replay defense

```text
function joinPeer(invite, identity):
assert invite.notExpired and networkReachable(invite.host)
challenge = freshRandomNonce()
peerProof = validateHandshake(invite.roomId, challenge)
assert room.active and capacity.available and peerProof.valid
if room.joinApproval:
request = createPendingJoin(peer, expiresAt)
wait for Host.accept / reject / timeout / cancel
assert peer.authorized and room.epoch == expectedEpoch
return issueEphemeralSessionKeysAndMembership(peer)
```

- QR / room code is discovery material, not a bearer credential giving universal admission.

- Add nonce, expiry, epoch and unique message IDs; reject replays and stale approvals.

- Reconnect is permitted only with valid membership proof and current session policy.

- Receivers on Audio Share can use a validated local display name without cloud login; translation requires account identity.

## 05 Timed audio delivery and receiver-local pause

```text
MediaFrame { roomId, epoch, streamId, seq, hostTimeNs,
ptsUs, durationUs, codec, payload, authTag }
OnReceiverFrame(frame):
if staleEpoch(frame) or replayedSequence(frame): discard
verify(frame.authTag)
if routeForwardingEnabled: forwardOnceWithTtl(frame)
if localPlaybackPaused: discardLocalFrameOnly
else:
playoutAt = mapHostClock(frame.ptsUs) + targetBuffer
if playoutAt < now - lateTolerance: discard
else: schedule(frame, playoutAt)
OnReceiverResume():
clearLocalStaleBuffers(); requestCurrentHostTimeline()
reacquireClockEstimate(); beginAtNextSafeBoundary()
```

The transfer of already-buffered music segments is a viable optimization only if memory, permission, storage and content rights permit it. It does not automatically synchronize playback: pause/resume and seek remain timestamped session control events.

The system shall not guarantee 60 ms, <500 ms, or 10-20 ms skew based on a single device pair or nominal codec timing. Measure source-to-ear timing, skew, drift and relay-hop effect separately.

## 06 Adaptive relay topology and backpressure

```text
every routingWindow:
neighbors = discoverAuthorizedNeighbors()
score = latencyWeight*rtt + lossWeight*loss + loadWeight*queue
routes = shortestViableRoutes(neighbors, maxHops, fanoutLimit)
for packet:
if seen(roomId, epoch, streamId, seq): drop
if ttl <= 0 or unauthorizedPeer: drop
enqueueBounded(nextHops, packet with ttl-1)
on linkFailure: invalidateRoute; requestReplacementRoute
```

- Bluetooth bandwidth, concurrent links and Android vendor restrictions are first-class feasibility limits.

- Use backpressure, queue limits and hop caps; never fan out indefinitely.

- Peer eligibility to relay must not automatically force microphone use, speaker output or system permissions not required for normal listening.

- Transport mixing and mid-session handover are separate unverified research tasks.

## 07 Media source adapter lifecycle

| Adapter | Create / update | Stop / error |
| --- | --- | --- |
| Music | URI permission -> decode -> timestamp -> stream | Release decoder; continue allowed background service |
| Host video | Video player media timeline and shared audio source | Leaving video view/locking pauses both; session remains |
| External app | User consent -> MediaProjection/AudioPlaybackCapture eligible audio | Permission denied, opt-out or revocation -> Source Unavailable |
| Receiver output | Decode, buffer, audio focus, route device | Local pause affects output only; forwarding keeps running |

Source changes must safely release old capture/decoder state without destroying the room. Host Ready is distinct from media genuinely active; UI must reflect actual emitted stream availability.

## 08 Translation streaming, usage commits and error model

```text
StartSponsoredStream(user, session, language):
require isAuthenticated(user)
require session.active && user.admitted && user.isSpeaker
require hostEntitlementValid(session.hostAccountId)
token = reserveBudgetAtomic(session.id, estimatedUnits)
stream = provider.open(language, serverCredential)
for chunk in stream:
if !token.valid or quotaExceeded(): terminateChargeableWork()
emitCaptionsAndAudioToAuthorizedLanguageSubscribers(chunk)
usageLedger.commitIdempotent(chunk.usageId, session.hostId)
reconcileWithProviderUsage(); closeStream()
```

| Error code | HTTP / local handling | Product response |
| --- | --- | --- |
| UNAUTHENTICATED | 401 | Sign in; do not admit to translation |
| NOT_ENTITLED | 403 | Host purchase/renewal gateway |
| NOT_ADMITTED / NOT_SPEAKER | 403 | Show access reason; do not process audio |
| QUOTA_EXCEEDED | 402/409 policy proposed | Stop paid stream; show Host quota action |
| SESSION_ENDED | 410 | Return to history; cannot resume dead room |
| TRANSPORT_UNAVAILABLE | Local error | Contextual network fix/retry |
| UNSUPPORTED_LANGUAGE | 422 | Choose supported language |

## 09 Persistence, diagnostics and negative tests

| Component | Persist | Do not persist by default |
| --- | --- | --- |
| Audio Share Session | Session id/epoch, local display name, allowed invite metadata | Unbounded raw audio |
| Translation | Signed-in account refs, language choice, consent and session linkage | AI provider secret or microphone samples |
| Billing | Immutable usage id, payer ref, provider counter, adjustments | Client-calculated financial truth |
| Diagnostics | Anonymized state, latency histograms, error codes | QR bearer secrets, raw captions in general logs |

- Unit tests: state reducer, admission races, packet dedupe, sequence/epoch checks, timestamp mapping, quota idempotency.

- Integration tests: Android capture eligibility, network transitions, signed-in Receiver joining Host-funded session.

- Device tests: real Host video vs Receiver ear latency and receiver-to-receiver drift across supported outputs.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
