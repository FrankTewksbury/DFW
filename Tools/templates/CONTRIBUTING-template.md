# Contributing

This project uses the [DevFlywheel (DFW)](https://github.com/FrankTewksbury/DFW) methodology.
This guide explains how to contribute using DFW conventions. Read it before opening your
first branch.

---

## Prerequisites

- DFW workspace set up (see [DFW README](https://github.com/FrankTewksbury/DFW))
- `git dfwsync-start`, `dfwsync-complete`, and `dfwsync-resume` aliases installed
- This repo cloned into `02-Projects/[ProjectName]/` in your workspace
- `CLAUDE.md` read — team conventions and known gotchas live there

---

## The Short Version

Every contribution follows the same four-step cycle:

1. **Start**: Sync, branch, set up worktree
2. **Build**: Follow the DFW session lifecycle and close-state workflow
3. **Finish**: Squash wip commits, open PR
4. **Close**: Merge, sync, clean up

The sections below expand each step.

---

## Starting Work on an Issue

Every piece of work ties to an issue. No branch without an issue.

```bash
# From inside your project directory (02-Projects/[ProjectName]/)
git dfwsync-start feature/42-short-description project-name-42

# Set up your worktree environment
cd ../project-name-42
./scripts/worktree-setup.sh
```

**Branch naming:**
```
feature/[issue-id]-[short-description]   ← new functionality
fix/[issue-id]-[short-description]       ← bug fixes
docs/[issue-id]-[short-description]      ← documentation only
research/[issue-id]-[short-description]  ← investigation, no code change
```

**First commit** (immediately after worktree setup):
```
feat(scope): initialize issue #42

Session: S20260218_0900
Issue: #42
Phase: 1 - Research
```

---

## Commit Conventions

All commits follow [Conventional Commits](https://www.conventionalcommits.org/) with DFW extensions.

**Format:**
```
[type](scope): short description

[optional body]

Session: S<YYYYMMDD>_<HHMM>
Issue: #N
Phase: [Research | Planning | Implementation | Close]
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `wip`

**`wip` commits** are for mid-session saves only. They are squashed before opening a PR —
their content is preserved in the PR's Session History section.

```bash
# Mid-session save (wip commit):
git add -A
git commit -m "wip: auth handler stubbed, writing tests next

Session: S20260218_1100
Issue: #42
Phase: 3 - Implementation"
```

**Resume commits** are required when returning to a continuable branch:
```
chore: resume session S20260218 on issue #42

Resuming from: [specific file/function or handoff doc reference]
Current state: [what is working, what is not]

Session: S20260218_1400
Issue: #42
Phase: 1 - Research
```

---

## Ending a Session (CLOSE)

At the end of every session, ask: **is this issue done?**

### COMPLETE — Issue is done, ready for PR

```bash
# Squash wip commits into logical commits
git rebase -i main

# Push and open PR
git push origin feature/42-short-description
# Open PR on GitHub/GitLab — use the PR template
```

### CONTINUABLE — More work needed, you'll pick it up

```bash
# Save state with a wip commit
git add -A
git commit -m "wip: end session S20260218 — [current state summary]"
git push origin feature/42-short-description
# Write a session handoff (see DFW/Tools/templates/HANDOFF-TEMPLATE.md)
```

### SCOPE CHANGED — Issue is larger than expected

```bash
# Save current state
git add -A
git commit -m "wip: end session S20260218 — scope changed, decomposing"
git push origin feature/42-short-description
# Create new child issues for remaining work
# Write a handoff referencing the new issues
```

---

## Pull Requests

Use the PR template (`.github/pull_request_template.md`). The key sections are:

- **Summary**: What this PR does and why
- **Session History**: One row per session, preserving context from wip commits
- **Decisions Made**: Significant choices made during implementation
- **Testing**: How to verify the changes work

**Review norms:**
- Aim to review within 48 hours
- +1 from one team member required to merge (Tier 2 change)
- Changes to `CLAUDE.md` require +1 — no direct commits ever
- Changes affecting the global DFW meta follow Tier 1 process (see the shared DFW repo)

**Squash wip commits before opening a PR.** Reviewers see clean logical commits.
Session context from wip commits goes into the Session History section of the PR description.

---

## Keeping Your Fork Current

The `dfwsync-start` alias handles this automatically at the start of each new issue.
For continuable branches, use `dfwsync-resume`:

```bash
git dfwsync-resume feature/42-short-description
# Then write your resume commit
```

After your PR merges:
```bash
git dfwsync-complete feature/42-short-description
```

---

## Handing Off to Another Developer

If your branch needs to be picked up by someone else, use the cross-developer handoff protocol:

```
DFW/Tools/templates/PROTOCOL-cross-dev-handoff.md
```

Store the completed handoff document in `prompts/handoffs/` on your branch before pushing.

---

## Updating CLAUDE.md

`CLAUDE.md` is the team's shared AI memory for this project. Update it when you:

- Make a significant architectural decision
- Discover a gotcha or non-obvious constraint
- Find a pattern worth repeating
- Identify a mistake worth avoiding

**Process:** Always via PR. Never a direct commit. Reviewers should confirm the entry
is accurate and clearly written before approving.

---

## Getting Help

- **DFW conventions:** [Git Collaboration docs](https://github.com/FrankTewksbury/DFW/tree/main/docs/git-collaboration) — playbook documents cover every scenario
- **This project's conventions:** `CLAUDE.md` in this repo
- **Onboarding:** [DFW onboarding guide](https://github.com/FrankTewksbury/DFW/blob/main/docs/git-collaboration/onboarding.mdx)
- **Questions:** Open an issue or ask in the team channel
