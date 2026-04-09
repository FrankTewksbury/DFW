# Handoff Template

**Version**: 1.1  
**Created**: 2026-02-15  
**Session**: S20260215_1900  
**Last Updated**: 2026-02-19 (Session S20260219 — R17: added Issue State and Author Available fields)

---

## Purpose

Handoffs are the single most important artifact in the DevFlywheel. They are how context survives tool boundaries and session boundaries. Every tool transition and every session end should produce a handoff document.

**Reusable Architectural State**: A handoff is not a disposable note — it is a persistent context artifact that compounds. A well-written handoff becomes a reusable template for the next similar transition. The handoff stack (all handoffs for a project) is the story an AI tool reads to get up to speed with zero clarifying questions. This is how Claude Code can execute autonomously: it reads the full handoff stack and knows everything the author knew.

---

## Standard Handoff Format

Use this template for all handoffs:

```markdown
# Handoff: [Brief Description]

**From**: [Source Tool/Session]  
**To**: [Destination Tool/Session]  
**Date**: YYYY-MM-DD  
**Session**: S<YYYYMMDD>_<HHMM>  
**Project**: [Project Name]  
**Issue State**: [CONTINUING | DECOMPOSED | COMPLETE → PR #N | N/A — tool transition]  
**Author Available**: [Yes | Limited (hours/timezone) | No]

---

## Context

### What Was Done
- [Describe completed work]
- [Key accomplishments]
- [Current state]

### Decisions Made
- [Decision 1 with rationale]
- [Decision 2 with rationale]

### Current State
- [Where are we now?]
- [What's the state of the system?]

---

## Intent

### What Needs to Happen Next
- [Primary objective]
- [Secondary objectives]

### Why This Matters
- [Business/technical rationale]
- [Dependencies on this work]

### Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

## Constraints

### What Must Not Change
- [Immutable aspects]
- [Protected interfaces]

### Boundaries and Limitations
- [Scope boundaries]
- [Technical constraints]
- [Time constraints]

### Dependencies
- [What this depends on]
- [What depends on this]

---

## Context Packs

> List the context packs the receiving agent should load before starting work.
> Omit this section if no domain-specific context packs are relevant.
> Global packs: `DFW/Tools/context-packs/`. Project-local packs: project's own
> `context-packs/` directory. Project-local packs take precedence on name conflict.

- `pack-name.md` — [one-line reason this pack is relevant to the task]

---

## Files and Artifacts

### Files Involved
- `path/to/file1.ext` - [Purpose]
- `path/to/file2.ext` - [Purpose]

### Artifacts Created
- [Document 1]
- [Code artifact 2]

### References
- [Link to related docs]
- [Link to decisions]

---

## Open Questions

### Unresolved Issues
1. [Question 1]
2. [Question 2]

### Needs Clarification
- [Item requiring decision]
- [Item requiring research]

### Next Phase Should Address
- [Topic for next phase]
- [Investigation needed]

---

## Notes

[Any additional context, warnings, or information that doesn't fit above categories]
```

---

## Handoff Types

### 1. Tool Transition Handoff
Used when moving from one tool to another (e.g., Claude Desktop → Cursor).

**Key Sections**: Context, Intent, Files, Constraints

**Example**: Planning → Implementation

### 2. Session End Handoff
Created at the end of each development session for the next session.

**Key Sections**: Context, What Was Done, What's Next, Open Questions

**Example**: Daily session close

### 3. Phase Transition Handoff
Used when moving between development phases (e.g., Research → Implementation).

**Key Sections**: All sections, particularly Success Criteria

**Example**: Phase 0 Research → Phase 1 Implementation

### 4. Collaboration Handoff
Used when passing work between team members.

**Key Sections**: Context, Intent, Constraints, Files  
**Required Fields**: `Issue State`, `Author Available`

**Example**: Developer A → Developer B

> For a full cross-developer handoff, use the extended template in
> `DFW/Tools/templates/PROTOCOL-cross-dev-handoff.md`.
> This base template is sufficient for solo session and tool-transition handoffs.

---

## Best Practices

### DO
- ✅ Create handoffs for every tool transition
- ✅ Be specific about file paths and locations
- ✅ Include session IDs for traceability
- ✅ List open questions explicitly
- ✅ Define clear success criteria
- ✅ Link to related documentation

### DON'T
- ❌ Assume the reader has your context
- ❌ Skip handoffs for "quick" transitions
- ❌ Use vague descriptions ("fix the bug")
- ❌ Leave questions buried in paragraphs
- ❌ Omit rationale for decisions

---

## Storage Locations

### Project-Specific Handoffs
Store in: `prompts/handoffs/`

**Naming**: `YYYY-MM-DD-handoff-description.md`

**Example**: `2026-02-15-handoff-planning-to-implementation.md`

### Cross-Project Handoffs
Store alongside other project handoffs in `prompts/handoffs/`

**Shared patterns**: keep reusable handoff conventions in `DFW/Tools/templates/`

---

## Integration with Journal System

Handoffs should be referenced in journal entries:

```markdown
## Handoffs Created
- [Planning → Implementation](../prompts/handoffs/2026-02-15-handoff-planning-to-implementation.md)

## Handoffs Consumed
- [Previous Session](../prompts/handoffs/2026-02-14-handoff-session-end.md)
```

---

## Validation Checklist

Before considering a handoff complete:

- [ ] All six standard sections present (Context, Intent, Constraints, Success Criteria, Files, Questions)
- [ ] Session ID included for traceability
- [ ] `Issue State` field filled — is the work continuing, decomposed, complete, or N/A?
- [ ] `Author Available` field filled — can the recipient reach you if questions arise?
- [ ] File paths are absolute or clearly relative
- [ ] Success criteria are measurable
- [ ] Open questions explicitly listed
- [ ] Next phase knows what to do without asking

---

## Examples

See active project `prompts/handoffs/` directories for reference implementations.

---

## Amendment History

| Version | Date | Session | Change | Rationale |
|---------|------|---------|--------|-----------|
| 1.0 | 2026-02-15 | S20260215_1900 | Initial creation | Establishing DevFlywheel structure |
| 1.1 | 2026-02-19 | S20260219 | Added `Issue State` and `Author Available` fields | R17 — fields designed in GitCollabPlaybook, used in every handoff since S20260217. Base template was behind actual practice (P3 violation). |
| 1.2 | 2026-03-16 | S20260316 | Added `## Context Packs` section | Context switchboard — agents load only domain-relevant packs specified by sender. Packs live in `DFW/Tools/context-packs/` (global) or project `context-packs/` (local). |

---

## Related Documents

- [DFW Constitution](/constitution/principles) - P1: Context Is Currency
- [Tools and Integrations](/operating-manual/tools-and-integrations) - When to use which tools
- `DFW/Tools/templates/PROTOCOL-cross-dev-handoff.md` - Extended template for developer-to-developer handoffs

---

**Status**: Active  
**Maintained by**: Paul Githens  
**Based on**: Frank Nazzaro's DevFlywheel design


## Registration

- Related template: `DFW/Tools/templates/PROTOCOL-cross-dev-handoff.md`
- Related docs: `/git-collaboration/session-end-workflow`, `/git-collaboration/scenario-c-async-handoffs`
- Update this template if handoff required fields or storage conventions change.
