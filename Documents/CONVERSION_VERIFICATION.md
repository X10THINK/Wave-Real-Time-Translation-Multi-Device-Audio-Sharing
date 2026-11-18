# Markdown conversion and verification

- Source: 15 searchable PDF documents from the uploaded Wave documentation ZIP.
- Conversion: 15 complete-document `.md` files; 76 separate numbered-section `.md` files across BRD, PRD, SRS, FRD and TRD.
- Plus 5 source-cover documents, folder indexes and root navigation.
- Eight vector flow diagrams are provided as cropped PNG visual references and linked in the matching Markdown sections and complete documents.
- The material is a **source-preserving conversion**, not a rewritten or reapproved set of requirements.

## Per-document extraction summary

| Document | Source pages | Numbered sections | PDF text-token coverage (before decorative header exclusions) |
| --- | ---: | ---: | ---: |
| BRD | 20 | 20 | 99.54% |
| PRD | 17 | 18 | 98.94% |
| SRS | 7 | 9 | 100.00% |
| FRD | 6 | 10 | 100.00% |
| TRD | 19 | 19 | 98.76% |
| HLD | 6 | 9 | 100.00% |
| LLD | 6 | 10 | 100.00% |
| SAD | 5 | 8 | 100.00% |
| ADR | 6 | 7 | 100.00% |
| DB | 6 | 9 | 100.00% |
| API | 6 | 9 | 100.00% |
| UIUX | 6 | 9 | 100.00% |
| STP | 6 | 10 | 100.00% |
| TEST | 8 | 7 | 100.00% |
| DEPLOY | 6 | 10 | 100.00% |

**Coverage notes:** The token-level check compares visible source text (excluding repeated PDF headers and footers) with the reconstructed Markdown. Source PDFs use the literal token `bullet` in some bullet glyph encodings; those markers are normalized into Markdown `-` list markers. This normalization explains the small apparent differences in BRD, PRD and TRD. Not a semantic omission. Table text and headings are captured in the result.

**Formatting notes:** Markdown tables reflow content and will not reproduce PDF line breaks and colors. For vector flow diagrams, follow the image reference near the relevant heading. Consult the original source PDF if formal pixel-fidelity or approval evidence is required.
