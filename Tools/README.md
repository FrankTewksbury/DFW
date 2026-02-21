# DFW Tools Repository

Canonical source for DevFlywheel (DFW) methodology tools, rules, constitution, operating manual templates, and model-specific agent files. Lives at `X:\DFW\Tools` alongside the Obsidian vault at `X:\DFW\Vault`.

## Directory Structure

```
X:\DFW\Tools\
├── Constitution\                  # Universal DFW rules (model-agnostic)
│   ├── DFW-CONSTITUTION.md        # Universal principles, rules, protocols
│   ├── CLAUDE-PROJECT-TEMPLATE.md # Per-project Claude template (copied during scaffold)
│   ├── DFW-GLOSSARY.md            # Terminology reference
│   ├── personal-config.md         # Frank's config (.gitignored)
│   ├── personal-config-template.md # Environment config template
│   └── archive/                   # Archived versions
├── Model\                         # Model-specific agent entry points
│   ├── CLAUDE.md                  # Claude-specific: refs constitution + Claude bootstrap
│   ├── OPENAI.md                  # Future: GPT-specific adapter
│   └── GEMINI.md                  # Future: Gemini-specific adapter
├── Manuals\                       # Operational manual templates
│   └── DFW-OPERATING-MANUAL.md    # Full DFW methodology (copied to docs/)
├── rules\                         # Cursor rules (.mdc files)
│   ├── agent-constitution.mdc     # Fraternal twin of DFW-CONSTITUTION.md
│   ├── plan-persistence-and-sequencing.mdc
│   ├── log-file-rule.mdc
│   ├── print-header-style.mdc
│   ├── venv-management.mdc
│   ├── anthropic-model-rules.mdc
│   ├── gemini-model-rules.mdc
│   ├── openai-model-rules.mdc
│   └── sports-nomenclature-rule.mdc
├── scripts\                       # PowerShell automation
│   ├── Resync-PromptsAndPlans.ps1 # File sequencing & dependency graph (v2.0.0)
│   └── Sync-CardBoardConfig.ps1   # Obsidian CardBoard sync
├── skills\                        # Reusable agent skills
└── .dfw-state\                    # Transient scaffold state files
    └── archive\
```

## Usage

### New Project (via Claude Desktop)
1. Add `X:\DFW\Tools\Model\CLAUDE.md` to Claude Desktop project instructions
2. Ask Claude Desktop to create the project — it reads the model file, constitution, and scaffolds

### New Project (via DFW Extension)
1. Run `DFW: New Project` in Cursor
2. The scaffolder copies from this repo: model file, constitution, operating manual, rules, scripts

### Sync Existing Project
1. Run `DFW: Sync Tools` in Cursor
2. Multi-select import of rules, constitution, manuals, and scripts
