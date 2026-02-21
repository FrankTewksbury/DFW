# DFW Environment Setup Guide

Complete step-by-step instructions for setting up the Development Flywheel (DFW) environment from scratch on a new machine.

---

## Prerequisites

Before you begin, make sure you have:

| Tool | Required | Download |
|------|----------|----------|
| **Git** | Yes | https://git-scm.com/downloads |
| **Node.js** (LTS) | Yes | https://nodejs.org — needed for MCP servers (`npx`) |
| **PowerShell 5.1+** | Yes | Built into Windows 10/11. On macOS/Linux: https://github.com/PowerShell/PowerShell |
| **Obsidian** | Yes | https://obsidian.md — free, no account required |
| **Claude Desktop** | Yes | https://claude.ai/download |
| **Cursor** (or VS Code) | Yes | https://cursor.com or https://code.visualstudio.com |

---

## Step 1: Clone the DFW Repository

Open a terminal and clone the repo to your preferred location:

```powershell
git clone https://github.com/FrankTewksbury/DFW.git <your-dfw-directory>
```

**Example:**
```powershell
git clone https://github.com/FrankTewksbury/DFW.git C:\Projects\DFW
```

This creates the DFW infrastructure directory with Tools, templates, constitution, and scripts.

---

## Step 2: Run the Bootstrap Script

The bootstrap script creates your Obsidian vault and scaffolds the DFWP meta-project.

```powershell
cd <your-dfw-directory>\Tools\scripts
.\Initialize-DFW.ps1 -ProjectPath <your-dfwp-directory>
```

**Example:**
```powershell
cd C:\Projects\DFW\Tools\scripts
.\Initialize-DFW.ps1 -ProjectPath C:\Projects\DFWP
```

**What this does:**
- Creates the Obsidian vault at `<your-dfw-directory>\Vault`
- Scaffolds the DFWP project with all DFW directories, constitution, operating manual, and Cursor rules
- Initializes a local git repo for DFWP
- Prints post-setup instructions

**Optional parameters:**
- `-VaultPath <path>` — custom vault location (default: `<DFWRoot>\Vault`)
- `-GitHubUser <username>` — sets up the DFWP git remote
- `-SkipVault` — skip vault creation
- `-SkipProject` — skip DFWP scaffolding
- `-Force` — overwrite existing files

---

## Step 3: Install Obsidian

If you don't already have Obsidian installed:

1. Go to https://obsidian.md
2. Download and install for your platform
3. Launch Obsidian

**No account is required.** Obsidian is free for personal use and runs entirely locally.

---

## Step 4: Open the Vault in Obsidian

1. In Obsidian, click **Open folder as vault**
2. Navigate to `<your-dfw-directory>\Vault`
3. Click **Open**

The vault comes pre-configured with:
- `meta/` — scope rules, tag taxonomy
- `journal/` — journal config and templates
- `projects/dfwp/` — DFWP project stub
- `.obsidian/` — pre-configured settings and CSS snippets

---

## Step 5: Install Community Plugins

1. Go to **Settings** (gear icon, bottom-left)
2. Go to **Community plugins**
3. Click **Turn on community plugins** (if prompted)
4. Click **Browse** and install each of these plugins:

| Search For | Plugin Name | ID | Purpose |
|------------|-------------|-----|---------|
| `card-board` | **CardBoard** | `card-board` | Kanban boards driven by tags |
| `templater` | **Templater** | `templater-obsidian` | Advanced template engine |
| `local rest api` | **Local REST API** | `obsidian-local-rest-api` | **Required** — connects Claude Desktop to Obsidian |
| `smart connections` | **Smart Connections** | `smart-connections` | Semantic search across notes |
| `smart templates` | **Smart Templates** | `smart-templates` | AI-powered templates |
| `mcp tools` | **MCP Tools** | `mcp-tools` | MCP integration for Obsidian |
| `cao` | **Cao** | `cao` | Canvas advanced objects |
| `large language models` | **Large Language Models** | `large-language-models` | *(Optional)* LLM integration |

5. After installing all plugins, **enable each one** by toggling them on in the Community plugins list.

---

## Step 6: Configure the Local REST API Plugin

This is the bridge between Claude Desktop and your Obsidian vault. **Do not skip this step.**

1. Go to **Settings > Community plugins > Local REST API** (click the gear icon next to it)
2. You'll see an **API Key** field — either:
   - Copy the auto-generated key, **or**
   - Set your own key (any string you choose)
3. **Save the API key somewhere** — you'll need it in Step 8
4. Note the **port** (default: `27124`) — leave it as-is unless you have a conflict
5. Make sure the plugin is **enabled** (toggled on)

**Test it:** Open a browser and go to `http://localhost:27124` — you should see the REST API documentation page. If you set an API key, requests require the header `Authorization: Bearer <your-key>`.

---

## Step 7: Enable the CardBoard CSS Snippet

The DFW theme colors the Kanban board columns by lifecycle status.

1. Go to **Settings > Appearance**
2. Scroll down to **CSS snippets**
3. Click the **refresh icon** (circular arrow) to detect snippets
4. Toggle on **cardboard-dfw-theme**

Your CardBoard boards will now show color-coded columns: blue (backlog), amber (active), orange (build), green (deploy), red (feedback).

---

## Step 8: Configure Claude Desktop MCP

Claude Desktop uses MCP (Model Context Protocol) servers to access your files and Obsidian vault. You need to edit its config file.

### 8a: Locate the config file

```
Windows:  %APPDATA%\Claude\claude_desktop_config.json
macOS:    ~/Library/Application Support/Claude/claude_desktop_config.json
Linux:    ~/.config/Claude/claude_desktop_config.json
```

On Windows, press `Win+R`, type `%APPDATA%\Claude`, and press Enter. Open `claude_desktop_config.json` in any text editor. If the file doesn't exist, create it.

### 8b: Paste the MCP configuration

A template is provided at `Tools/templates/claude-desktop-config-template.json` in your DFW directory. Copy its contents into your config file, then replace the placeholders:

```json
{
  "mcpServers": {
    "dfw-filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@anthropic-ai/mcp-filesystem-server",
        "<YOUR_DFW_ROOT>",
        "<YOUR_DFWP_PATH>"
      ]
    },
    "obsidian-mcp-tools": {
      "command": "npx",
      "args": ["-y", "obsidian-mcp-tools"],
      "env": {
        "OBSIDIAN_API_KEY": "<YOUR_OBSIDIAN_REST_API_KEY>"
      }
    }
  }
}
```

### 8c: Replace the placeholders

| Placeholder | Replace With | Example |
|-------------|-------------|---------|
| `<YOUR_DFW_ROOT>` | Full path to your DFW directory (use `\\` on Windows) | `C:\\Projects\\DFW` |
| `<YOUR_DFWP_PATH>` | Full path to your DFWP project | `C:\\Projects\\DFWP` |
| `<YOUR_OBSIDIAN_REST_API_KEY>` | The API key from Step 6 | `abc123mykey` |

**Important:** On Windows, paths in JSON use double backslashes: `C:\\Projects\\DFW`, not `C:\Projects\DFW`.

### 8d: Restart Claude Desktop

Close and reopen Claude Desktop completely. MCP config changes only take effect on restart.

### 8e: Verify MCP is working

In a new Claude Desktop conversation, Claude should now be able to:
- Read and write files in your DFW and DFWP directories (via `dfw-filesystem`)
- Search and read your Obsidian vault notes (via `obsidian-mcp-tools`)

If Claude says it can't access files, double-check your paths and API key in the config.

---

## Step 9: Create a Claude Desktop Project

Claude Desktop Projects give Claude persistent memory and instructions for your DFW work.

1. In Claude Desktop, click **Projects** in the sidebar
2. Click **Create a project**
3. Name it (e.g., "DFWP" or "DFW Development")
4. In **Project knowledge**, upload or paste the contents of `<your-dfwp-directory>\CLAUDE.md`
5. In **Custom instructions**, paste:

```
ON EVERY CONVERSATION START:
1. Read the CLAUDE.md file from the project root directory via filesystem MCP
2. Read docs/DFW-CONSTITUTION.md via filesystem MCP
3. Read docs/DFW-OPERATING-MANUAL.md via filesystem MCP
4. Read .dfw/personal-config.md via filesystem MCP
5. Read context/_ACTIVE_CONTEXT.md if it exists
6. Follow ALL rules defined in the constitution and CLAUDE.md
7. Display the constitution status card
8. If this is the first session, run the full Project Initialization Protocol

DFW = Development Flywheel. It is the mandatory project methodology.
```

6. Under **Connectors**, enable the MCP servers you configured:
   - `dfw-filesystem`
   - `obsidian-mcp-tools`

---

## Step 10: Open DFWP in Cursor

1. Open **Cursor** (or VS Code)
2. Open the folder: `<your-dfwp-directory>`
3. Verify that `.cursor/rules/` contains the DFW rule files (they were copied by the bootstrap script)
4. Check `context/_ACTIVE_CONTEXT.md` for your project's current state
5. Check `plans/_TODO.md` for initial setup tasks

You're ready to start working with DFW.

---

## Step 11: (Optional) Push DFWP to GitHub

If you want version control for your DFWP project:

1. Create a new repo on GitHub (empty — no README, no .gitignore, no license)
2. Push:

```powershell
cd <your-dfwp-directory>
git remote add origin https://github.com/<your-username>/DFWP.git
git push -u origin main
```

---

## Troubleshooting

### Claude Desktop can't access files
- Verify paths in `claude_desktop_config.json` use double backslashes on Windows
- Make sure you restarted Claude Desktop after editing the config
- Check that Node.js is installed (`node --version` in terminal)

### Obsidian REST API not responding
- Make sure the Local REST API plugin is enabled in Obsidian
- Check that Obsidian is running (the API only works while Obsidian is open)
- Try `http://localhost:27124` in a browser to verify

### CardBoard not showing colored columns
- Go to Settings > Appearance > CSS Snippets
- Click the refresh icon, then enable `cardboard-dfw-theme`

### Bootstrap script errors
- Make sure you're running PowerShell 5.1+ (`$PSVersionTable.PSVersion`)
- Make sure Git is installed and in your PATH
- Run with `-Force` to overwrite existing files if re-running

---

## What's Next

After setup, read these files to understand the methodology:

1. `docs/DFW-CONSTITUTION.md` — The 9 principles and behavioral rules
2. `docs/DFW-OPERATING-MANUAL.md` — Full methodology reference
3. `context/_ACTIVE_CONTEXT.md` — Current project state
4. `plans/_TODO.md` — Your task list

Welcome to the Development Flywheel.
