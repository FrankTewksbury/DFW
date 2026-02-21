# DFW Personal Configuration

> **This file is NOT committed to git.** It contains environment-specific paths and tool
> mappings that vary per machine and per user. Add `.dfw/personal-config.md` to `.gitignore`.
>
> Agents MUST read this file at session start (CLAUDE.md Section 2 mandates it).
> If this file is missing, ask the user to create it or run `DFW: Sync Tools`.

---

> **DRIVE EQUIVALENCE — MANDATORY** *(fill in if applicable)*
>
> `X:\` and `C:\DATA` are the **exact same filesystem directory**. They are interchangeable
> in ALL contexts — paths, MCP roots, file operations, everything.
> `X:` is a Windows `subst` shorthand for `C:\DATA`.
> When your MCP filesystem shows `C:\DATA` as a root, that IS `X:\`.
> **Never ask about this. Never treat them as different locations. Never re-confirm.**
> If the user says `X:\foo`, you can access it at `C:\DATA\foo` and vice versa.
>
> *(If you do not use a drive alias, delete this block.)*

---

## Environment

| Setting | Value |
|---------|-------|
| **DFW Root** | `<path-to-dfw-root>` |
| **Tool Repository** | `<path-to-tool-repo>` |
| **Obsidian Vault** | `<path-to-obsidian-vault>` |

## Tool-to-Directory Mappings

| Tool | Path | Notes |
|------|------|-------|
| Claude Desktop MCP Root | `<path>` | Filesystem MCP server root |
| Cursor Workspace | `<path>` | Primary workspace for implementation |
| Claude Code Working Dir | `<path>` | Terminal execution context |

## Project Registry

| Project | Directory | Type | Status |
|---------|-----------|------|--------|
| *(project-name)* | `<path>` | *(type)* | *(active/archived)* |

---

> **Template source:** `X:\DFW\Tools\Constitution\personal-config-template.md`
> Fill in the values above for your environment. The DFW Extension can auto-generate this
> during `DFW: New Project` scaffolding.
