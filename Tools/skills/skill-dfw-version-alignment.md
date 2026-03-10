# Skill: DFW Version Alignment

**Situation trigger**: When a project extends DFW conventions (adds phases, renames
steps, splits concepts) rather than following them exactly.

**Pattern**: Document the extension explicitly in the project's `CLAUDE.md` under a
`DFW Version Alignment` section. Required fields:
- What DFW says
- What this project does instead
- Why the extension exists (rationale, not just description)
- Whether this is a strict superset or a genuine divergence

**Table format**:
| Extension | DFW | This Project | Rationale |
|-----------|-----|--------------|-----------|

**Anti-pattern**: Silently deviating from DFW conventions without documentation.
When an agent reads the project `CLAUDE.md` and finds no alignment section, it assumes
DFW conventions apply exactly. Silent deviations cause agent errors and broken handoffs.

**Source**: GitCollabPlaybook `CLAUDE.md` — DFW Version Alignment section (S20260222).
Validated across multiple GitCollab sessions where the extra planning split needed explicit anchoring.

## Registration

- Index entry required: `DFW/Tools/skills/README.md`
- Update this skill if DFW lifecycle naming or the project alignment contract changes.
