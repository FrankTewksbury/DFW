# Scripts

## Resync-PromptsAndPlans.ps1

Sequences prompt/plan/retrospective/journal/doc files with `###-type-slug.md` numbering (globally by creation date across all directories) and generates `docs\PROMPT_OUTPUT_GRAPH.md` with a Mermaid dependency graph and index. Supports chronology tracking and optional `phase:` / `iteration:` in front matter for Obsidian and Claude journal workflows.

### RGR-AWS recommended usage

From the **project root** (`x:\RGR-AWS`):

```powershell
# Preview only (no renames, no graph write)
.\Scripts\Resync-PromptsAndPlans.ps1 -ProjectRoot "x:\RGR-AWS" -Directories @("docs","AWSIaC","docs\Retrospectives") -GraphOutputFile "docs\PROMPT_OUTPUT_GRAPH.md" -DryRun

# Run sequence + graph
.\Scripts\Resync-PromptsAndPlans.ps1 -ProjectRoot "x:\RGR-AWS" -Directories @("docs","AWSIaC","docs\Retrospectives") -GraphOutputFile "docs\PROMPT_OUTPUT_GRAPH.md"

# Graph only (no renames)
.\Scripts\Resync-PromptsAndPlans.ps1 -ProjectRoot "x:\RGR-AWS" -Directories @("docs","AWSIaC","docs\Retrospectives") -GraphOutputFile "docs\PROMPT_OUTPUT_GRAPH.md" -PhaseGraph
```

### Caches

- `.prompt-sync-cache.json` — tracks file signatures so unchanged files are not re-sequenced.
- `.prompt-graph-cache.json` — tracks indexed files for graph incremental updates.

Both live in `ProjectRoot`. Use `-Force` to ignore caches.

### Types

The script classifies `.md` files by name into: **retrospective**, **journal**, **note**, **plan**, **prompt**, **spec**, **analysis**, **output**, **doc**. Sequenced names look like `001-retrospective-phase1-aws-instance-config.md`.

### Front matter (optional)

In YAML front matter, the script reads `source_prompt`, `created`, `description`, `phase`, `iteration`, etc. Use `phase: 2` or `iteration: 1` for filtering in Obsidian/Claude.
