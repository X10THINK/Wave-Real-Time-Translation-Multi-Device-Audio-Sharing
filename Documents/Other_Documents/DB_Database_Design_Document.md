# Wave — Database Design Document

**Brand:** ZAEROX  
**Product:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Source:** `10_DB_Wave_DB_Design_Document.pdf`  
**Source version:** 1.0 (Working Draft, 16 November 2026)  
**Conversion:** Markdown transcription of source PDF; source status and unresolved decisions unchanged.

## Original cover details

> ZAEROX / WAVE / PRODUCT & ENGINEERING

> DB DESIGN DOCUMENT

> Proposed logical schema, data integrity and retention

> DOCUMENT ID

> VERSION

> ISSUED

> ZAEROX-WAVE-DB-001

> 1.0 / DRAFT

> 16 NOV 2026

> Prepared for product, design, Flutter/Android, backend, QA, security and operations review.

> Status: working draft. Requirements are not evidence of completed implementation or real-device certification.

## 00 Document control

| Field | Value |
| --- | --- |
| Product | Wave - Real-Time Translation & Multi-Device Audio Sharing |
| Application label / brand | Wave / ZAEROX |
| Document | DB Design Document |
| Document ID | ZAEROX-WAVE-DB-001 |
| Revision / issue | 1.0 / 16 November 2026 |
| Status | Working draft for review; not final implementation evidence |
| Baseline | Approved Wave discussions through 16 Nov 2026; Audio Share UX V3.1; BRD/PRD/TRD v1.0 |

Decision precedence: Every Live Translation participant, Host and Receiver, must sign in. Host-funded Receivers do not need individual paid entitlements. Basic Audio Share remains guest-accessible. Audio Share source selection follows Lobby / Start Session, and Bluetooth adaptive relay is a development target, not certified capability.

## 01 Contents

This document contains the following sections. Section numbers are stable identifiers; page positions may vary with layout.

02 Data ownership, storage layers and privacy

03 Logical entity model and relationships

04 Core entities and field dictionary

05 Invariants, foreign keys and indexes

06 Illustrative relational DDL (proposed)

07 Retention, encryption, migration and restore

08 DB validation test matrix

## 02 Data ownership, storage layers and privacy

The Database Design Document specifies a PROPOSED logical model for paid Live Translation and supporting metadata. Basic Audio Share can remain local/ephemeral without cloud registration. A particular RDBMS is not selected; names, keys and retention windows are illustrative until implementation and privacy approval.

| Data class | Location / source of truth | Policy |
| --- | --- | --- |
| Audio Share room state | Host/peer memory + minimal local snapshot | Ephemeral, scoped by session epoch |
| Translation account | Authenticated cloud identity authority | Every translation participant must sign in |
| Sponsored room / grants | Trusted session backend | Only authorized speakers generate chargeable usage |
| Usage and credit ledger | Trusted server, append-only accounting semantics | Host bears sponsored session costs |
| Speech / caption content | Streaming memory by default; storage only if approved | No raw recording retention by default |
| Device analytics | Privacy-filtered telemetry | No secrets, raw audio or transcripts in normal logs |

## 03 Logical entity model and relationships

```text
ACCOUNT (1) -------- (N) MEMBERSHIP (N) ------- (1) SESSION
| | |
| +-- (N) SPEAKER_GRANT +-- (N) LANGUAGE_SUB
| |
+-- (N) ENTITLEMENT +-- (N) USAGE_EVENT
|
(N) LEDGER_ENTRY
SESSION.host_account_id -> ACCOUNT.id
USAGE_EVENT.payer_account_id -> SESSION.host_account_id
Only admitted signed-in MEMBERSHIP rows participate in Translation.
```

Logical relation sketch, not a physical migration or proof of an existing backend database.

## 04 Core entities and field dictionary

| Entity | Fields (type / key) | Purpose / constraints |
| --- | --- | --- |
| accounts | id UUID PK; auth_subject TEXT UNIQUE; display_name TEXT; created_at TIMESTAMPTZ; status ENUM | Server-validated identity, no stored plaintext passwords |

| Entity | Fields (type / key) | Purpose / constraints |
| --- | --- | --- |
| entitlements | id UUID PK; account_id FK; plan_id TEXT; valid_from/to TIME; status ENUM; version INT | Host paid permission; never inferred from client |
| sessions | id UUID PK; owner_id FK; kind ENUM; transport ENUM; join_approval BOOL; state ENUM; epoch INT; created/ended_at | Translation Host authoritative; Audio Share local model analogous |
| memberships | id UUID PK; session_id FK; account_id FK NULL for local guest; status ENUM; joined_at | Unique active member per session/account or local peer |
| speaker_grants | id UUID PK; session_id FK; account_id FK; granted_by FK; status; expires_at | Host authorizes and revokes speech |
| language_subscription s | id UUID PK; session_id FK; member_id FK; language_tag TEXT; status | Only supported language selections |
| usage_events | id UUID PK; session_id FK; payer_account_id FK; provider_event_id UNIQUE; amount_units DECIMAL; event_time | Idempotent metered usage with trustworthy provider basis |
| ledger_entries | id UUID PK; payer_account_id FK; usage_event_id FK; debit/credit DECIMAL; currency/unit; posted_at | Append-only financial accounting, adjustment records |
| session_invites | id UUID PK; session_id FK; token_hash; expires_at; revoked_at | Never store raw QR secret in log |
| audit_events | id UUID PK; actor_id; session_id; action; target_id; created_at; redacted_meta JSON | Security/consent and administrative audit |

## 05 Invariants, foreign keys and indexes

| Constraint | Definition / design intent |
| --- | --- |
| Membership uniqueness | At most one active membership per account per translation session; local guest key is session-scoped |
| Sponsored billing | usage_events.payer_account_id equals Host owner of session at charge time |
| Immutable posted usage | Do not update/delete posted ledger rows; issue corrective reversal entries |
| Idempotent provider events | Unique provider_event_id + provider/version; reject duplicates |
| Speaker rights | Only Host or authorized moderator can grant; grant belongs to active session membership |
| Language validation | BCP 47-like language tag normalized and checked against provider-supported list |
| Indexes | sessions(owner_id,state); memberships(session_id,status); usage_events(payer,event_time); ledger_entries(payer,posted_at) |

| Constraint | Definition / design intent |
| --- | --- |
| Invite safety | Store invite hash and expiry; rotate on end/recreation |

## 06 Illustrative relational DDL (proposed)

```text
CREATE TABLE sessions (
id UUID PRIMARY KEY,
owner_account_id UUID NOT NULL REFERENCES accounts(id),
kind VARCHAR(24) NOT NULL CHECK (kind IN ('translation')),
state VARCHAR(20) NOT NULL,
epoch INTEGER NOT NULL DEFAULT 1,
join_approval BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMPTZ NOT NULL,
ended_at TIMESTAMPTZ
);
CREATE TABLE usage_events (
id UUID PRIMARY KEY,
session_id UUID NOT NULL REFERENCES sessions(id),
payer_account_id UUID NOT NULL REFERENCES accounts(id),
provider_event_id TEXT NOT NULL UNIQUE,
amount_units NUMERIC(20,6) NOT NULL CHECK(amount_units >= 0),
occurred_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_usage_payer_time
ON usage_events(payer_account_id,occurred_at);
```

This example is not an executable complete migration: accounts, keys, provider mapping, policy tables, triggers and access policies must be defined before deployment.

## 07 Retention, encryption, migration and restore

| Control | Proposed policy | Approval needed |
| --- | --- | --- |
| Sensitive PII | Minimize, encrypt at rest, limit access by need | Privacy counsel / data owner |
| Speech buffers | Transient streaming only by default | Consent and provider contract |
| Usage/audit records | Retention follows business, tax and legal requirements | Jurisdiction and finance review |
| Encryption keys | Managed secure store; rotation and separation of duties | Security sign-off |
| Schema migrations | Versioned forward/backward compatible; backup before destructive change | Operations sign-off |
| Restore tests | Periodic restore into isolated environment; reconcile ledger counts | RPO/RTO targets OPEN |

| Control | Proposed policy | Approval needed |
| --- | --- | --- |
| Data deletion | Remove account-linked nonmandatory personal data; preserve legally required records only | Policy/region OPEN |

## 08 DB validation test matrix

| ID | Test | Pass condition |
| --- | --- | --- |
| DB-01 | Two concurrent join attempts for same account | Single active membership |
| DB-02 | Duplicated provider usage webhook/event | One usage posting / no double debit |
| DB-03 | Receiver spends without Host grant | No usage event accepted |
| DB-04 | Room ended while streaming event posts | Correct terminal state and ledger reconciliation |
| DB-05 | Invite revoked / expired | No valid admission issued |
| DB-06 | Backup / restore ledger | Row counts and balance checks reconcile |
| DB-07 | Access control cross-account | Cannot read other Host usage or participants |
| DB-08 | Account deletion request | Policy-compliant removal with audit and legally required exception |

Production implementation must additionally define row-level authorization, database transaction isolation, encryption key ownership and secure provider webhook validation.

Document governance: Items marked LOCKED describe approved product/UX expectations, not finished software. PROPOSED marks designs needing implementation approval. TARGET marks performance or capacity that must be measured. OPEN marks decisions requiring owner sign-off.
