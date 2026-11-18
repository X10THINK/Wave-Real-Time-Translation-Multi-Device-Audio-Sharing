# Wave — Markdown Documentation Pack

**Project:** Wave — Real-Time Translation & Multi-Device Audio Sharing  
**Brand:** ZAEROX  
**Source package:** `Wave_Complete_15_Documentation_Pack_v1.0(1).zip`  
**Source baseline:** 16 November 2026, version 1.0 — working draft  

This pack converts all **15 original PDF documents into Markdown**. The five requirements documents are additionally separated into **one `.md` file per numbered section**, with dedicated folders and complete-document editions. Other ten documents remain separate Markdown files. Source requirements, IDs, labels such as LOCKED/TARGET/PROPOSED/OPEN, and caveats are preserved; conversion is not a product approval or implementation audit.

## Requirements — split by section

- [BRD — Business Requirements Document](BRD/README.md) — 20 section files, [complete version](BRD/BRD_Complete.md)
- [PRD — Product Requirements Document](PRD/README.md) — 18 section files, [complete version](PRD/PRD_Complete.md)
- [SRS — Software Requirements Specification](SRS/README.md) — 9 section files, [complete version](SRS/SRS_Complete.md)
- [FRD — Functional Requirements Document](FRD/README.md) — 10 section files, [complete version](FRD/FRD_Complete.md)
- [TRD — Technical Requirements and Design Document](TRD/README.md) — 19 section files, [complete version](TRD/TRD_Complete.md)

## Design, architecture, tests and deployment — complete Markdown files

- [HLD — High Level Design](Other_Documents/HLD_High_Level_Design.md)
- [LLD — Low Level Design](Other_Documents/LLD_Low_Level_Design.md)
- [SAD — Software Architecture Document](Other_Documents/SAD_Software_Architecture_Document.md)
- [ADR — Architecture Decision Records](Other_Documents/ADR_Architecture_Decision_Records.md)
- [DB — Database Design Document](Other_Documents/DB_Database_Design_Document.md)
- [API — API Documentation](Other_Documents/API_API_Documentation.md)
- [UIUX — UI/UX Design Specification](Other_Documents/UIUX_UI-UX_Design_Specification.md)
- [STP — Software Test Plan](Other_Documents/STP_Software_Test_Plan.md)
- [TEST — Test Cases and Test Reports](Other_Documents/TEST_Test_Cases_and_Test_Reports.md)
- [DEPLOY — Deployment and Maintenance Plan](Other_Documents/DEPLOY_Deployment_and_Maintenance_Plan.md)

## Layout

```text
BRD/     00_Cover...md + numbered sections + BRD_Complete.md + README.md
PRD/     00_Cover...md + numbered sections + PRD_Complete.md + README.md
SRS/     00_Cover...md + numbered sections + SRS_Complete.md + README.md
FRD/     00_Cover...md + numbered sections + FRD_Complete.md + README.md
TRD/     00_Cover...md + numbered sections + TRD_Complete.md + README.md
Other_Documents/   HLD, LLD, SAD, ADR, DB, API, UIUX, STP, TEST, DEPLOY
```

**Conversion details:** [CONVERSION_VERIFICATION.md](CONVERSION_VERIFICATION.md). Eight original vector flow diagrams are retained as linked visual references under `assets/`.

## Source-fidelity notes

- The Markdown is derived from searchable PDF text and detected table structure. Markdown tables preserve table rows and columns where detected.
- Original PDF page layouts, decorations and any vector illustrations are not guaranteed to be pixel-identical in Markdown.
- Check the provided requirements against source PDF for formal sign-off, especially diagrams, cross-page tables and line-wrapped text.
- No new unapproved technical requirements have been added.
