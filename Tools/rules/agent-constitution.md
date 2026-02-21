# Agent Constitution

> **Canonical authority:** `CLAUDE.md` at the project root is the full operating guide for all agents.
> Read it at the start of every session. When behavioral questions arise, `CLAUDE.md` governs.
>
> **Fraternal Twin Notice:** This file is one of two maintained in sync.
> Its twin is `CLAUDE.md`.
> Same 10 rules. Same canonical order. Different depth, different audience.
> Any change to the rules in one file MUST be made in the other.

---

## RULE: No Destructive Operations on Pre-Existing Files

- MUST NOT delete, overwrite, or destroy any file that existed before the current session.
- This includes source files being refactored — create new versions, never delete originals.
- MAY create temporary files during a session and clean them up before the session ends.
- MAY only delete files the agent itself created in the **current session**.
- Even with explicit user instruction to delete a pre-existing file, MUST confirm and warn before proceeding.
- Structural files (`_TODO.md`, `_WISHLIST.md`, `_ROADMAP.md`, `_ACTIVE_CONTEXT.md`, `_DECISIONS_LOG.md`, `README.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `PROJECT_OVERVIEW.md`) MUST NEVER be deleted.

## RULE: Secrets Are Sacred

- MUST NOT read, output, log, persist, or display the contents of `.env` files, `secrets/`, `credentials/`, `creds/` directories, or any file containing API keys, tokens, passwords, connection strings, or private keys.
- MUST NOT commit secrets to version control.
- MUST NOT include secret values in sequenced artifacts, chat output, log files, or console output.
- When scripts need credentials, reference environment variables by name only — never by value.
- If asked to commit, persist, or output a file likely containing secrets, MUST warn and refuse.
- **Safe word override:** This rule MAY be temporarily bypassed ONLY when:
  1. The user explicitly commands access to secret material.
  2. The user supplies the project safe word in the same instruction.
  3. The safe word is verified against `.dfw/config.json` (MUST match before proceeding).
  4. The override applies to the single requested operation only — the rule re-engages immediately after.
- If the safe word is not provided or does not match, MUST refuse regardless of user instruction.

## RULE: Persist All Artifacts

- All AI-generated plans, prompts, specs, handoffs, context, research, and analysis MUST be persisted as sequenced Markdown files in the correct DFW directory.
- NEVER output a plan, analysis, or decision only in chat — it MUST also be written to disk.
- Every sequenced file MUST use the `NNN-type-slug.md` naming pattern with YAML frontmatter.

## RULE: Follow Directory Conventions and File Sequencing — No Exceptions

- ALL agents MUST route artifacts to the correct DFW directory based on type.
- ALL agents MUST follow `NNN-type-slug.md` sequencing (per-directory, 3-digit zero-padded).
- Directory names are ALWAYS lowercase.
- Before creating a file, check existing files and use `(max NNN) + 1`. Start at `001` if none exist.

## RULE: Ask Before Assuming

- When paths, destinations, tooling choices, or scope are ambiguous, MUST ask the user before proceeding.
- MUST NOT guess at file locations or default to workarounds when direct access may exist.

## RULE: Humans Steer, Agents Execute

- MUST NOT make autonomous decisions about project direction, architecture, or scope.
- When the request is unclear, ask for clarification. Propose options, but the user decides.

## RULE: Small, Composable Artifacts

- Prefer multiple small, focused files over monolithic outputs.
- Each artifact SHOULD be independently useful and reusable.
- When generating related outputs in a single session, each gets its own sequenced file, correlated by a shared `sessionId`.

## RULE: Close the Feedback Loop

- After multi-step tasks, update `context/_ACTIVE_CONTEXT.md` with current status.
- After significant decisions, append to `context/_DECISIONS_LOG.md`.
- After sessions with meaningful work, consider a journal entry (`context/NNN-journal-*.md`).

## RULE: Failure Retrospective

- When a plan, build, or debug cycle fails, MUST NOT retry blindly.
- MUST stop and determine root cause: Was it the model, the prompt, the context, or the user instruction?
- MUST persist a retrospective (`context/NNN-retro-*.md`) and create actionable TODOs for continuous improvement.
- Failures without retrospectives are wasted learning.

## RULE: Use UV for Python

- UV is the mandatory Python package manager. MUST NOT use pip/conda/poetry unless UV is unavailable and the deviation is logged.

---

## Full Reference

For the complete operating guide including the DFW Constitution (P1-P8), artifact type routing table, sequencing specification, frontmatter requirements, session correlation, and cross-agent conventions, read `CLAUDE.md` at the project root.
