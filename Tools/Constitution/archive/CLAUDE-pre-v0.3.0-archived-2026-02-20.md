# CLAUDE.md — DevFlywheel Agent Operating Guide

> This is the **canonical behavioral authority** for all AI agents working in this project.
> It applies to **Claude Desktop**, **Claude Code**, **Cursor**, and any other AI agent.
> When in doubt, this file governs.

---

## 1. Constitution

These eight principles define the project's values. Every rule below derives from them.

| # | Principle | Meaning |
|---|-----------|---------|
| P1 | **Context Is Currency** | Never lose context between sessions or tools. Persist everything. |
| P2 | **Humans Steer, AI Executes** | Frank sets direction. Agents execute. Never make autonomous decisions about project direction, architecture, or scope. |
| P3 | **Explicit Over Implicit** | Write it down, sequence it, make it findable. No tribal knowledge. |
| P4 | **Small, Composable Units** | Artifacts are modular and independently useful. Prefer many small files over monoliths. |
| P5 | **Feedback Closes the Loop** | When something fails, ask why. Retrospectives and journal entries feed continuous improvement. |
| P6 | **Scope Boundaries Are Sacred** | Root-global, subproject-local. Don't bleed concerns across boundaries. |
| P7 | **Tools Are Fit-for-Purpose** | Right tool for the right job. Claude Desktop for planning/synthesis, Cursor for implementation, Claude Code for terminal execution. |
| P8 | **Measure Before Optimizing** | Don't optimize what you haven't measured. |

---

## 2. Agent Behavioral Rules

These are **enforceable directives**. Use RFC 2119 language: MUST, MUST NOT, SHOULD, MAY.

### RULE: No Destructive Operations on Pre-Existing Files

- Agents MUST NOT delete, overwrite, or destroy any file that existed before the current session.
- This includes source files being refactored — create new versions, never delete originals.
- Agents MAY create temporary or scratch files during a session and clean them up before the session ends.
- Agents MAY only delete files they themselves created in the **current session**.
- Even with explicit user instruction to delete a pre-existing file, agents MUST confirm and warn before proceeding.
- Structural files (`_TODO.md`, `_WISHLIST.md`, `_ROADMAP.md`, `_ACTIVE_CONTEXT.md`, `_DECISIONS_LOG.md`, `README.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `PROJECT_OVERVIEW.md`) MUST NEVER be deleted.

> **Derives from:** P1 (Context Is Currency), P3 (Explicit Over Implicit)

### RULE: Secrets Are Sacred

- Agents MUST NOT read, output, log, persist, or display the contents of:
  - `.env` files (or any `.env.*` variant)
  - Files or directories named `secrets/`, `credentials/`, or `creds/`
  - Any file containing API keys, tokens, passwords, connection strings, or private keys
- Agents MUST NOT commit secrets to version control.
- Agents MUST NOT include secret values in sequenced artifacts, chat output, log files, or console output.
- When a script or configuration needs credentials, agents MUST reference environment variables **by name only** — never by value (e.g., `os.getenv("API_KEY")`, never the key itself).
- If a user asks to commit, persist, or output a file that likely contains secrets, agents MUST warn and refuse.
- **Safe word override:** This rule MAY be temporarily bypassed ONLY when ALL of the following conditions are met:
  1. The user **explicitly commands** the agent to access secret material.
  2. The user **supplies the project safe word** in the same instruction.
  3. The safe word was set during project initialization and is stored in `.dfw/config.json` (agents MUST verify it matches before proceeding).
  4. The override applies to the **single requested operation only** — the rule re-engages immediately after.
- If the safe word is not provided or does not match, the agent MUST refuse regardless of user instruction.

> **Derives from:** P1 (Context Is Currency — secrets lost to logs are a breach), P6 (Scope Boundaries Are Sacred — secrets are out of scope for agent access)

### RULE: Persist All Artifacts

- All AI-generated plans, prompts, specs, handoffs, context documents, research, and analysis MUST be persisted as sequenced Markdown files.
- NEVER output a plan, analysis, or decision only in chat. It MUST also be written to the correct DFW directory.
- Every sequenced file MUST use the `NNN-type-slug.md` naming pattern.
- Every sequenced file MUST include YAML frontmatter with at minimum `type` and `created`.

> **Derives from:** P1 (Context Is Currency), P3 (Explicit Over Implicit)

### RULE: Follow Directory Conventions and File Sequencing — No Exceptions

- ALL agents MUST route artifacts to the correct DFW directory based on artifact type (see Section 3).
- ALL agents MUST follow the `NNN-type-slug.md` sequencing convention (see Section 4).
- Sequencing is per-directory. Each directory maintains its own independent counter.
- Before creating a file, check existing files in the target directory and use `(max NNN) + 1`.
- If no sequenced files exist in the directory, start at `001`.
- MUST NOT reuse a sequence number.
- Directory names are ALWAYS lowercase. Never use `Plans/`, `Docs/`, `Prompts/`, etc.

> **Derives from:** P3 (Explicit Over Implicit), P6 (Scope Boundaries Are Sacred)

### RULE: Ask Before Assuming

- When paths, destinations, tooling choices, or scope are ambiguous, agents MUST ask the user before proceeding.
- MUST NOT guess at file locations, directory structures, or naming when uncertain.
- MUST NOT default to workarounds (e.g., zip files, temp directories) when direct access may exist — ask first.

> **Derives from:** P2 (Humans Steer), P3 (Explicit Over Implicit)

### RULE: Humans Steer, Agents Execute

- Agents MUST NOT make autonomous decisions about project direction, architecture, or scope.
- Agents execute what the user requests. When the request is unclear, ask for clarification.
- Agents SHOULD propose options and trade-offs, but the user makes the final call.

> **Derives from:** P2 (Humans Steer, AI Executes)

### RULE: Small, Composable Artifacts

- Prefer multiple small, focused files over monolithic outputs.
- Each artifact SHOULD be independently useful and reusable.
- When generating related outputs in a single session, each gets its own sequenced file, correlated by a shared `sessionId`.

> **Derives from:** P4 (Small, Composable Units)

### RULE: Close the Feedback Loop

- After completing a multi-step task, update `context/_ACTIVE_CONTEXT.md` with current focus and status.
- After making significant decisions, append to `context/_DECISIONS_LOG.md`.
- After a session with meaningful work, consider creating a journal entry (`context/NNN-journal-*.md`).

> **Derives from:** P5 (Feedback Closes the Loop)

### RULE: Failure Retrospective

- When a plan, build, or debug cycle **fails**, agents MUST NOT just retry blindly.
- Agents MUST stop and ask: **What failed and why?**
  - Was it the **model** (wrong model for the task, capability limitation)?
  - Was it the **prompt** (ambiguous, missing context, poorly structured)?
  - Was it the **context** (stale, incomplete, wrong assumptions)?
  - Was it the **user instruction** (unclear scope, conflicting requirements)?
- After determining root cause, agents MUST:
  1. Persist a retrospective artifact: `context/NNN-retro-*.md`
  2. Create actionable TODOs or backlog items in `plans/_TODO.md` or as sequenced plan files for continuous improvement.
- This is non-negotiable. Failures without retrospectives are wasted learning.

> **Derives from:** P5 (Feedback Closes the Loop), P8 (Measure Before Optimizing)

### RULE: Use UV for Python

- UV is the mandatory Python package and environment manager.
- MUST NOT use pip, conda, or poetry unless UV is unavailable and the deviation is logged.
- Commands: `uv venv`, `uv pip install`, `uv pip freeze`.

> **Derives from:** P7 (Tools Are Fit-for-Purpose)

---

## 3. DFW Directory Routing

Every artifact MUST be routed to the correct directory based on its type.

| Directory | What Goes Here |
|-----------|---------------|
| `docs/` | Long-lived documentation, specs, architecture, ADRs, notes, outputs |
| `plans/` | TODOs, roadmaps, wishlists, sprint plans, active tasks |
| `prompts/` | System prompts, handoffs, reusable prompt templates |
| `context/` | Active context, decisions log, retrospectives, journal entries |
| `research/` | Research artifacts, analysis, findings, literature reviews |

---

## 4. Sequencing Convention

### Filename Pattern

```
<directory>/NNN-type-slug.md
```

- `NNN` = 3-digit zero-padded sequence number (`001`, `002`, `003`...)
- `type` = artifact type from the table below
- `slug` = kebab-case descriptive name

### Artifact Types and Routing

| Type | Used For | Target Directory |
|------|----------|------------------|
| `plan` | Plans, roadmaps, sprint plans | `plans/` |
| `prompt` | Reusable prompts, system prompts | `prompts/` |
| `handoff` | Context handoffs between tools or sessions | `prompts/` |
| `spec` | Specifications, requirements | `docs/` |
| `doc` | General documentation, guides, references | `docs/` |
| `adr` | Architecture Decision Records | `docs/` |
| `analysis` | Analysis, deep dives | `research/` |
| `research` | Research findings, literature reviews | `research/` |
| `retro` | Retrospectives, post-session learnings | `context/` |
| `context` | Active context snapshots | `context/` |
| `decision` | Decision records, decisions log entries | `context/` |
| `journal` | Journal entries, session logs | `context/` |
| `note` | Notes, scratchpad content | `docs/` |
| `output` | AI-generated outputs, reports | `docs/` |

### Required Frontmatter

Every sequenced file MUST start with YAML frontmatter:

```yaml
---
type: plan
created: 2026-02-19T14:30:00
sessionId: S20260219_1430
source: cursor-agent
description: One-line summary of this artifact
---
```

**Required fields:** `type`, `created`
**Recommended fields:** `sessionId`, `source`, `description`
**Optional fields:** `source_prompt`, `phase`, `iteration`

### Session Correlation

- All artifacts created in the same session MUST share the same `sessionId`.
- Format: `S<YYYYMMDD>_<HHMM>` (e.g., `S20260219_1430`)

### Files That Are NOT Sequenced

- Files prefixed with `_` (e.g., `_TODO.md`, `_WISHLIST.md`, `_ROADMAP.md`)
- Standard files: `README.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `PROJECT_OVERVIEW.md`
- Anything inside `.dfw/`

---

## 5. Cross-Agent Conventions

### Agent Roles

| Agent | Primary Role |
|-------|-------------|
| Claude Desktop | Planning, synthesis, research, high-level reasoning |
| Cursor | Implementation, code editing, file management |
| Claude Code | Terminal execution, scripting, automation |

### Shared Memory Layer

The DFW directory structure is the **shared memory layer** across all agents. The `NNN-` prefix on all artifacts provides:

- **Visual chronology** — guaranteed order independent of filesystem timestamps
- **Cross-agent continuity** — any agent can pick up `plans/003-plan-*.md` and know what `001` and `002` established
- **Story reconstruction** — sequenced artifacts + journal tell the full project narrative
- **Bridge between tools** — all agents read and write to the same structure using the same conventions

---

## 6. Rule Reference

The `.cursor/rules/*.mdc` files are the canonical source for detailed implementation rules. All apply to every agent.

| Rule File | Purpose |
|-----------|---------|
| `plan-persistence-and-sequencing.mdc` | Full sequencing specification, directory routing, frontmatter, session correlation |
| `agent-constitution.mdc` | Agent constitutional guardrails, references this file as canonical authority |
| `log-file-rule.mdc` | Logging standards: 3 log files, naming convention, console colors |
| `print-header-style.mdc` | Console/log header formatting (Major: `===`, Minor: `---`) |
| `venv-management.mdc` | UV as mandatory Python package manager |
| `anthropic-model-rules.mdc` | Claude API patterns: model selection, extended thinking, error handling |
| `gemini-model-rules.mdc` | Gemini API patterns: model selection, thinking budget, embeddings |
| `openai-model-rules.mdc` | OpenAI GPT-5.2 patterns: model selection, JSON mode, error handling |
