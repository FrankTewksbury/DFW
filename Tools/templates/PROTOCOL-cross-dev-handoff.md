## Rule Precedence

This handoff gives task-level context. If anything in it conflicts with the project `CLAUDE.md` or the DFW Constitution, the higher-level document wins. Flag the conflict instead of silently following the lower-level instruction.

---

## Purpose

This protocol extends the standard DFW handoff template for the case where work crosses a developer boundary — Developer A passes an issue to Developer B, who is a different person with a different local environment, different mental model, and no access to A's session journals.

The standard handoff template was designed for tool transitions and session boundaries within a single developer's workflow. When the recipient is a different human being, several of its implicit assumptions break. This protocol fills those gaps without replacing the existing template.

---

## When to Use This Protocol

Use the cross-developer handoff when any of the following are true:

- The work on a branch is being handed to a **different developer** to continue
- The work is SCOPE CHANGED and child issues will be picked up by a **different developer**
- A developer is going to be **unavailable** and the branch may need to be taken over
- The work touches a critical area and requires **explicit knowledge transfer** before review

Do not use for:
- Solo session-to-session handoffs (use the standard `DFW/Tools/templates/HANDOFF-TEMPLATE.md`)
- PR descriptions (those have their own template in [PR Conventions](/git-collaboration/pr-conventions))
- Phase transition handoffs within a single developer's workflow

---

## The Cross-Developer Handoff Template

```markdown
# Cross-Dev Handoff: [Brief Description]

**From Developer**: [Name — @github-username — contact method]
**To Developer**: [Name — @github-username, or "Any team member"]
**Author Available**: [Yes | Limited (hours/timezone) | No]
**Date**: YYYY-MM-DD
**Session**: S<YYYYMMDD>_<HHMM>
**Project**: [Project Name]

---

## Issue State

**Status**: [CONTINUING | DECOMPOSED | COMPLETE → PR #N]

### If CONTINUING
- **Branch**: `feature/42-auth-module` (fork: github.com/devA/rori)
- **Resume from**: [Specific file, function name, or task — be precise]
- **Do not touch**: [Anything the recipient should explicitly avoid changing]
- **Worktree path** (if applicable): `../rori-42-auth`

### If DECOMPOSED
- **Original branch**: `feature/42-auth-module` (closed / leave open — specify)
- **New issues created**: #49 Refresh token rotation, #50 Token revocation
- **Start with**: #49 — #50 depends on #49's interface
- **Context carried forward**: [What from the original work is still relevant]

### If COMPLETE → PR open
- **PR**: #[N] — [PR title] — [URL]
- **Action needed**: Review and approve / merge when ready

---

## Team Context

**Project**: [One sentence — what this project is and does]
**This issue's role**: [How issue #N fits into the larger project]
**Area of codebase**: [Module, service, or layer being worked on]
**Key docs to read first**:
- `CLAUDE.md` — team conventions and known gotchas
- [Any relevant spec, ADR, or design doc]
**Who owns this area**: [@username — available for questions]

---

## Environment Setup

**Central repo**: `github.com/team/rori`
**Fork to use**: `github.com/devA/rori` (or create your own fork of central)
**Branch**: `feature/42-auth-module`

```bash
# Set up and check out the branch
git fetch devA   # add devA's fork as remote if not already: git remote add devA [url]
git worktree add ../rori-42-auth devA/feature/42-auth-module
cd ../rori-42-auth
./scripts/worktree-setup.sh

# Verify environment
npm test -- --grep "auth"   # should show X passing, Y pending
```

**Environment variables needed**: `.env.local` required — copy from `.env.example`, update:
- `JWT_SECRET`: any string locally, team secret for staging
- `REDIS_URL`: `redis://localhost:6379` for local

**Known environment issues**: [Any gotchas specific to the local setup]

---

## Context

### What Was Done
- [Completed item with enough detail for a stranger to understand]
- [Key accomplishments]
- [Current state of the system]

### Decisions Made
For each significant decision:

**Decision**: [What was decided]
**Rationale**: [Why this option over the alternatives — include what was rejected]
**Alternatives considered**: [What was tried or evaluated and why it was not chosen]
**Status**: [Final — do not revisit | Tentative — open to discussion]

Example:
**Decision**: Use RS256 for JWT signing  
**Rationale**: Public key can be distributed to third-party consumers without exposing signing capability. HS256 would require sharing the secret with every consumer.  
**Alternatives considered**: HS256 (simpler, rejected — see rationale); EdDSA (considered, deferred to future issue #60)  
**Status**: Final — auth interface is already in use downstream

### Current State
[Logical state: what is working, what is not, where in the implementation the work stopped]

**Environment state**:
- Tests: [X passing / Y failing — list failing tests if any]
- Build: [clean / known warnings — describe if any]
- Known broken: [anything intentionally incomplete that should not be run yet]

---

## Intent

### Priority
**Must complete** (blocks others or closes the issue):
- [Most critical item]

**Should complete** (important but not blocking):
- [Secondary item]

**Could complete** (nice-to-have if time allows):
- [Optional item]

**Minimum viable** (what constitutes "done enough to PR" if time is constrained):
- [The bare minimum — what absolutely must work before a PR can be opened]

### What Needs to Happen Next
1. [Primary next action — specific enough to start without asking]
2. [Secondary action]

### Success Criteria
- [ ] [Criterion]
  **Verify**: [Exact command or check — POST /api/login → response includes access_token]
- [ ] [Criterion]
  **Verify**: [How to check this]

---

## Constraints

### Hard Constraints (architectural — do not override without team discussion)
- [Constraint]: [Why it's fixed — e.g., "auth interface signature: 3 downstream consumers depend on it"]

### Soft Constraints (author preference — can be discussed)
- [Preference]: [Why the author made this choice, and that alternatives are acceptable]

### Dependencies
**This work depends on**:
- [What must be true / available for this work to proceed]

**Other work depends on this**:
- [What is blocked waiting for this issue — gives recipient a sense of urgency]

---

## Files and Artifacts

### Key Files (repo-relative paths)
- `src/auth/auth.service.ts` — main implementation, safe to modify
- `src/auth/auth.interface.ts` — **shared interface — coordinate before changing**
- `src/auth/__tests__/auth.service.spec.ts` — test suite, safe to modify

### Artifacts Created This Work
- [Any docs, diagrams, or research produced that the recipient should read]

### References
- [Issue #42 in tracker](link)
- [Any relevant PR, design doc, or ADR]

---

## Open Questions

### Unresolved Issues
1. [Question]
   **Blocking**: Yes / No
   **Ask**: [@username or "team sync"]
   **Deadline**: [Before starting X / Low urgency]

### Needs Clarification
- [Item]: [@who to ask]

---

## Contact & Escalation

**For questions about this work**: @[from-developer] via [Slack/WhatsApp/email]
**Author available until**: [Date/time, or "ongoing"]
**If author unavailable**: [Who else knows this area / where to look]
**Team sync**: [Next scheduled sync where this can be discussed if async is insufficient]

---

## Notes

[Any additional context, warnings, gotchas, or information that doesn't fit above]
```

---


---

## Storage Location

Store completed cross-developer handoffs in `prompts/handoffs/` on the branch they describe.
This keeps them alongside other persisted session artifacts while still making the handoff easy to reference from commits and future sessions.

## Handoff Types and Which Sections Are Required

Not every section is required for every cross-developer handoff. Use judgment:

| Handoff Type | Required Sections | Often Skippable |
|-------------|-------------------|----------------|
| CONTINUING (same project, known developer) | Issue State, Context, Intent, Environment Setup | Team Context, Contact |
| CONTINUING (new developer or new to area) | All sections | Nothing |
| DECOMPOSED | Issue State, Context (decisions made), Intent (priority), Notes | Environment Setup (new branch) |
| COMPLETE → PR | Issue State only | Most sections |

**Minimum viable handoff**: Issue State + What Was Done + What Needs to Happen Next + Environment Setup. Everything else adds value but this minimum ensures the recipient can start.

---

## Dependency Branch Handoffs

When the handoff involves a dependency branch (B's branch is based on A's unmerged branch), add this to the Issue State section:

```markdown
### Dependency Branch Info
**This branch depends on**: `feature/42-auth-module` (@devA fork)
**Dependency status**: UNMERGED — waiting on PR #42
**Interface stability**: [Stable — safe to build on | In flux — check with @devA before building further]
**After #42 merges**: Rebase this branch onto central main
  ```bash
  git fetch upstream
  git checkout main && git merge upstream/main --ff-only
  git checkout feature/43-user-profile
  git rebase main
  git push origin feature/43-user-profile --force-with-lease
  git commit --allow-empty -m "chore: post-rebase checkpoint — #42 now in main"
  ```
```

---

## Flywheel Connection

The cross-developer handoff is where one developer's accumulated session context becomes another developer's starting point. Without it, knowledge resets at every developer boundary — the new developer rediscovers decisions, hits the same edge cases, makes the same mistakes. With it, the flywheel doesn't just spin within one developer's sessions — it spins across the team. Every decision rationale documented here, every "do not touch" constraint, every known environment gotcha is hours of future session time returned to the team. P1 (Context Is Currency) at team scale.

---

## Related Documents
- `DFW/Tools/templates/HANDOFF-TEMPLATE.md` — the base template this extends
- [Session-End Workflow](/git-collaboration/session-end-workflow) — when this handoff is created (session CLOSE CONTINUABLE, cross-dev)
- [Scenario C: Async Handoffs](/git-collaboration/scenario-c-async-handoffs) — full walkthrough using this protocol
- Dependency Branches research note — dependency branch handoff detail

---

## Registration

- Related artifact: `DFW/Tools/templates/HANDOFF-TEMPLATE.md`
- Related docs: `/git-collaboration/scenario-c-async-handoffs`, `/git-collaboration/session-end-workflow`
- Update this protocol if the base handoff fields or cross-dev handoff flow change.
