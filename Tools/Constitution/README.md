# DFW Constitution System

Two-tier architecture for AI agent behavioral governance across all DFW projects.

## Architecture (v0.4.0 — Constitution Split)

The constitution is split into three composable files:

| File | Purpose | Changes How Often |
|------|---------|-------------------|
| `CLAUDE.md` | Principles (P1-P9), behavioral rules, file safety, scope rules, project init, bootstrap | Rarely — amendments only |
| `DFW-OPERATING-MANUAL.md` (in `Manuals/`) | Full methodology: tagging, session lifecycle, handoffs, sequencing, journals, flywheel effect | Evolves with methodology |
| `personal-config-template.md` | Environment-specific: paths, tool mappings, drive aliases, MCP roots, project registry | Per machine/user |

## Files in This Directory

| File | What It Is | Where It Goes |
|------|-----------|---------------|
| `CLAUDE.md` | Canonical constitution (synced from DevFlywheel) | Reference copy — projects get `CLAUDE-PROJECT-TEMPLATE.md` |
| `CLAUDE-GLOBAL.md` | Global template | `~/.claude/CLAUDE.md` (one-time setup) |
| `CLAUDE-PROJECT-TEMPLATE.md` | Per-project template | `<project>/CLAUDE.md` (during scaffold) |
| `personal-config-template.md` | Environment config template | `<project>/.dfw/personal-config.md` (during scaffold, NOT committed) |
| `DFW-GLOSSARY.md` | Terminology reference | `<project>/docs/DFW-GLOSSARY.md` |

## Setup

### One-Time (Global)
```bash
cp Constitution/CLAUDE-GLOBAL.md ~/.claude/CLAUDE.md
```

### Per Project (via DFW Extension — automatic)
The DFW Extension `DFW: New Project` copies:
- `CLAUDE-PROJECT-TEMPLATE.md` → `<project>/CLAUDE.md`
- `personal-config-template.md` → `<project>/.dfw/personal-config.md`
- `DFW-GLOSSARY.md` → `<project>/docs/DFW-GLOSSARY.md`
- `DFW-OPERATING-MANUAL.md` → `<project>/docs/DFW-OPERATING-MANUAL.md`

### Per Project (Manual)
```bash
cp Constitution/CLAUDE-PROJECT-TEMPLATE.md <project>/CLAUDE.md
cp Constitution/personal-config-template.md <project>/.dfw/personal-config.md
cp Constitution/DFW-GLOSSARY.md <project>/docs/DFW-GLOSSARY.md
cp Manuals/DFW-OPERATING-MANUAL.md <project>/docs/DFW-OPERATING-MANUAL.md
```

## Fraternal Twin

`CLAUDE.md` and `rules/agent-constitution.mdc` are fraternal twins — same rules, different formats:
- `CLAUDE.md`: Full prose for Claude Desktop, Claude Code, and any agent
- `agent-constitution.mdc`: Compact Cursor rules format

Any rule change in one MUST be made in the other.
