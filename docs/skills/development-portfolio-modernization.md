# PROXTEL Development Skill Portfolio Modernization

## Area 1.7 M2

Three legacy Development Skills are being modernized as canonical candidates:

- auditor-web
- estratega-seo
- maestro-frontend

## Legacy preservation

The original files under skills/base remain byte-exact and are retained as immutable provenance.

Each canonical candidate contains:

- SKILL.md
- skill.json
- references/legacy-baseline.md
- references/modernization-notes.md

## Governance state

Candidate lifecycle:

candidate

Registry governance state:

under-audit

Candidate creation is not approval.

## Distribution bridge

Existing project bundles continue to use the same Skill IDs.

The distribution scripts use scripts/skill-source-resolver.ps1.

Routing rule:

- Registry state approved -> canonical Registry source_path
- any other state -> legacy skills/base fallback

Therefore an under-audit candidate cannot silently replace an installed trusted baseline.

## Promotion

Independent Auditor approval is required.

Only after a final APPROVED decision may Registry state transition to approved and the resolver begin selecting the canonical source automatically.

## Rollback

Area 1.7 M2 preserves exact backups of the Registry and the two modified distribution scripts during execution.

No Git commit or push is created automatically.