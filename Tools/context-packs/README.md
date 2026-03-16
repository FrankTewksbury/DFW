# DFW Context Packs — Index and Routing Rules

> **What this is:** The global library of context packs for the DFW methodology.
> A context pack is a concise, declarative document that tells an agent what to
> know about a domain before working in it.
>
> **How this differs from Skills:** Skills are procedural — they describe how to
> perform a specific DFW task (write a handoff, run a pre-flight check). Context
> packs are declarative — they describe domain knowledge that should inform how
> any task is performed in that domain. A skill says "do this." A context pack
> says "know this."
>
> **Scope:** Global packs only. Project-local packs live in the project's own
> `context-packs/` directory and are not indexed here.

---

## The Switchboard Model

Context packs are loaded on demand, not all at once. The agent loads only the
packs relevant to the current task. Handoffs specify which packs to load using
a `## Context Packs` section (see HANDOFF-TEMPLATE.md).

**Loading rules:**
1. Read the `## Context Packs` section of the incoming handoff
2. Locate each named pack in this directory (global) or the project's
   `context-packs/` directory (local)
3. Read each pack before starting work
4. Project-local packs take precedence over global packs with the same name

**Selection guidance:** When no handoff specifies packs, agents select packs
based on the task type:

| Task type | Suggested packs |
|-----------|----------------|
| Python async code | `pack-python-async.md` |
| Python test writing | `pack-testing-python.md` |
| Graph algorithm implementation | `pack-graph-algorithms.md` |
| Cloud infrastructure config | `pack-cloud-config.md` *(not yet written)* |
| Planning / spec writing | `pack-planning.md` *(not yet written)* |

---

## Active Packs

| Pack | Domain | Situation trigger | File |
|------|--------|-------------------|------|
| Python Async | Python | Writing or reviewing async Python code using asyncio, aiohttp, or websockets | `pack-python-async.md` |
| Python Testing | Python | Writing pytest tests, designing fixtures, or reviewing test coverage | `pack-testing-python.md` |
| Graph Algorithms | Algorithms | Implementing or reviewing weighted graph construction or cycle detection | `pack-graph-algorithms.md` |

---

## Writing a New Pack

A context pack must:
- Be concise — an agent should be able to read it in under 2 minutes
- Be declarative — "know this", not "do this"
- Be validated — content must come from real project experience, not theory
- Include a `## Source` section naming the project(s) that validated it
- Include a `## Registration` section listing this README as a downstream obligation

**File naming:** `pack-<domain>-<topic>.md`
**Examples:** `pack-python-async.md`, `pack-cloud-aws-iam.md`, `pack-testing-contracts.md`

---

## Deprecated Packs

*None yet.*

---

**Updated**: 2026-03-16
**Maintained by**: DFW methodology team