# Resync Prompts & Plans — Plan (Whited Out)

## Goal
Maintain a consistent, chronological numbering scheme for project Markdown artifacts (prompts/plans/specs/etc.) and generate a single dependency graph document that links outputs back to their source prompts.

## Scope
This plan describes running the PowerShell script `scripts/Resync-PromptsAndPlans.ps1` in two phases:
- **Phase 1 (Sequence):** Renames `.md` files to a normalized `NNN-type-slug.md` format.
- **Phase 2 (Graph):** Generates a Markdown report with a Mermaid dependency diagram and an index.

## Inputs (Whited Out)
- **Project root:** `<PROJECT_ROOT>` (defaults to current directory)
- **Directories scanned (relative to project root):** `docs`, `Prompts`, `Plans`, `Root-Prompts` (override as needed)
- **Graph output file (relative to project root):** `docs/PROMPT_OUTPUT_GRAPH.md` (override as needed)

## Outputs
- Renamed/normalized `.md` files in the scanned directories
- Graph report: `<PROJECT_ROOT>/<GRAPH_OUTPUT_FILE>`
- Caches stored at project root:
  - `.prompt-sync-cache.json`
  - `.prompt-graph-cache.json`

## Operating Plan

### 0) Safety Check (Recommended)
1. Ensure you’re targeting the correct project by setting `-ProjectRoot`.
2. Run with `-DryRun` first to preview renames and graph output.

### 1) Phase 1 — Sequence
**Objective:** Ensure every scanned Markdown file has a stable, chronological prefix.

**What it does (high level):**
- Scans configured directories for `*.md`.
- Skips known non-content files and hidden/cache files.
- Determines a **type** from filename patterns (e.g., `plan`, `prompt`, `spec`, `output`).
- Renames files into: `NNN-<type>-<slug>.md`.
- Uses a cache to avoid rework unless `-Force` is set.

**Run (preview):**
```powershell
pwsh -File "<PROJECT_ROOT>/scripts/Resync-PromptsAndPlans.ps1" `
  -ProjectRoot "<PROJECT_ROOT>" `
  -Directories @("docs","Prompts","Plans","Root-Prompts") `
  -DryRun -PhaseSequence
```

**Run (live):**
```powershell
pwsh -File "<PROJECT_ROOT>/scripts/Resync-PromptsAndPlans.ps1" `
  -ProjectRoot "<PROJECT_ROOT>" `
  -Directories @("docs","Prompts","Plans","Root-Prompts") `
  -PhaseSequence
```

### 2) Phase 2 — Graph
**Objective:** Build a single, navigable Markdown reference that includes:
- Mermaid diagram of relationships (based on front matter `source_prompt`)
- Directory index table
- Basic stats and timeline summary

**Run (preview):**
```powershell
pwsh -File "<PROJECT_ROOT>/scripts/Resync-PromptsAndPlans.ps1" `
  -ProjectRoot "<PROJECT_ROOT>" `
  -Directories @("docs","Prompts","Plans","Root-Prompts") `
  -GraphOutputFile "docs/PROMPT_OUTPUT_GRAPH.md" `
  -DryRun -PhaseGraph
```

**Run (live):**
```powershell
pwsh -File "<PROJECT_ROOT>/scripts/Resync-PromptsAndPlans.ps1" `
  -ProjectRoot "<PROJECT_ROOT>" `
  -Directories @("docs","Prompts","Plans","Root-Prompts") `
  -GraphOutputFile "docs/PROMPT_OUTPUT_GRAPH.md" `
  -PhaseGraph
```

### 3) Typical “Do Everything” Run
(Default behavior runs Sequence then Graph.)

**Preview:**
```powershell
pwsh -File "<PROJECT_ROOT>/scripts/Resync-PromptsAndPlans.ps1" `
  -ProjectRoot "<PROJECT_ROOT>" `
  -Directories @("docs","Prompts","Plans","Root-Prompts") `
  -GraphOutputFile "docs/PROMPT_OUTPUT_GRAPH.md" `
  -DryRun
```

**Live:**
```powershell
pwsh -File "<PROJECT_ROOT>/scripts/Resync-PromptsAndPlans.ps1" `
  -ProjectRoot "<PROJECT_ROOT>" `
  -Directories @("docs","Prompts","Plans","Root-Prompts") `
  -GraphOutputFile "docs/PROMPT_OUTPUT_GRAPH.md"
```

## Front Matter Convention (for Relationships)
To show an edge in the Mermaid graph, add front matter to a Markdown file with `source_prompt`.

Example (whited out):
```yaml
---
source_prompt: "<RELATIVE/PATH/TO/SOURCE_PROMPT.md>"
description: "<SHORT_DESCRIPTION>"
created: "<YYYY-MM-DD>"
phase: "<OPTIONAL_PHASE>"
iteration: "<OPTIONAL_ITERATION>"
---
```

## Notes / Caveats
- Sequencing is **global across all configured directories**, sorted by file `CreationTime` then `LastWriteTime`.
- Renames can affect links between files; prefer using the graph/index as the primary navigation.
- Use `-Force` to ignore caches and fully reprocess.

## Rollback Strategy
- If running in a git repo: revert renames via `git restore -SW .` (or equivalent).
- Otherwise: always run `-DryRun` first and keep a backup/snapshot before live execution.
