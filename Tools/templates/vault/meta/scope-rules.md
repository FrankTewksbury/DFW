---
type: rule
created: 2026-02-11
status: active
tags: [meta, scope, rules, enforcement]
---

# Scope Rules — Global vs Local

> **This is an enforceable rule. Claude must follow this in every session.**

---

## The Rule

**Obsidian vault = GLOBAL scope only.**
**Project directories = LOCAL scope — all project work product.**

If a file is about a specific project's deliverable, it does NOT go in Obsidian. Period.

---

## What Goes in Obsidian (Global)

| Directory | Content | Example |
|-----------|---------|---------|
| `ideas/` | Pre-project ideas, not yet assigned | "What if we built X?" |
| `meta/` | Cross-project rules, conventions, routing | This file, tag taxonomy |
| `journal/` | Daily journals spanning all projects | "Today I worked on RGR and K4X..." |
| `projects/<name>/` | **Lightweight stub ONLY** | Status, link to project dir, last session date |

## What Goes in the Project Directory (Local)

| Directory | Content | Tool Access |
|-----------|---------|-------------|
| `docs/` | Specs, architecture, ADRs, overview | Cursor, Claude Code, git |
| `plans/` | TODO, wishlist, roadmap | Cursor, Claude Code |
| `prompts/` | System prompts, handoffs, templates | Claude Desktop, Claude Code |
| `context/` | Active context, decisions, retros | All tools |
| `research/` | Research artifacts | Claude Desktop |
| `scripts/` | Automation, hooks | CI, terminal |
| `src/`, `tests/` | Code | Cursor, Claude Code |

---

## Violation Check

Before writing ANY file, Claude must ask:
1. Is this about a specific project? -> Write to project directory
2. Is this a journal, methodology doc, or cross-project reference? -> Obsidian is OK
3. Am I unsure? -> Ask the user, don't default to Obsidian
