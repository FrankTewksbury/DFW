<#
.SYNOPSIS
    Scaffolds the DFWP meta-project directory from templates.

.DESCRIPTION
    Creates the DFWP project directory structure, copies stub files from
    Tools/templates/dfwp/, copies the constitution and operating manual
    from Tools/, generates personal-config, and initializes a local git repo.

.PARAMETER ProjectPath
    Absolute path where DFWP should be created. Defaults to X:\DFWP.

.PARAMETER DFWRoot
    Root of the DFW installation. Defaults to the parent of this script's location.

.PARAMETER GitHubUser
    GitHub username for the DFWP remote. Defaults to prompting.

.PARAMETER SkipGit
    If set, skips git init and remote setup.

.PARAMETER Force
    If set, overwrites existing files. Otherwise skips if project already exists.
#>
[CmdletBinding()]
param(
    [string]$ProjectPath,
    [string]$DFWRoot,
    [string]$GitHubUser,
    [switch]$SkipGit,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Resolve DFW root from script location if not provided
if (-not $DFWRoot) {
    $DFWRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

if (-not $ProjectPath) {
    $ProjectPath = Join-Path $DFWRoot 'DFWP'
}

$TemplatePath = Join-Path $DFWRoot 'Tools\templates\dfwp'
$ToolsPath = Join-Path $DFWRoot 'Tools'

Write-Host ''
Write-Host '=== Initialize-DFWP ===' -ForegroundColor Cyan
Write-Host "  DFW Root:     $DFWRoot"
Write-Host "  Project Path: $ProjectPath"
Write-Host "  Template Src: $TemplatePath"
Write-Host ''

# Guard: check template source exists
if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template directory not found: $TemplatePath"
    return
}

# Guard: check if project already exists
if ((Test-Path $ProjectPath) -and -not $Force) {
    Write-Host "Project already exists at $ProjectPath. Use -Force to overwrite." -ForegroundColor Yellow
    return
}

# Create project directory
if (-not (Test-Path $ProjectPath)) {
    New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    Write-Host "  Created: $ProjectPath" -ForegroundColor Green
}

# --- Step 1: Copy template files with variable substitution ---
Write-Host '  Copying DFWP templates...' -ForegroundColor Gray

$today = Get-Date -Format 'yyyy-MM-dd'
$todayISO = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'

# Generate a Project ID
$pidChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
$ProjectID = 'PID-'
for ($i = 0; $i -lt 5; $i++) {
    $ProjectID += $pidChars[(Get-Random -Maximum $pidChars.Length)]
}

$templateFiles = Get-ChildItem -Path $TemplatePath -Recurse -File

foreach ($file in $templateFiles) {
    $relativePath = $file.FullName.Substring($TemplatePath.Length + 1)
    $destPath = Join-Path $ProjectPath $relativePath
    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ((Test-Path $destPath) -and -not $Force) {
        Write-Host "  Skipped (exists): $relativePath" -ForegroundColor DarkGray
        continue
    }

    $content = Get-Content -Path $file.FullName -Raw

    $content = $content -replace '\{\{PID\}\}', $ProjectID
    $content = $content -replace '\{\{DATE\}\}', $today
    $content = $content -replace '\{\{DATE_ISO\}\}', $todayISO
    $content = $content -replace '\{\{OWNER\}\}', $env:USERNAME
    $content = $content -replace '\{\{PROJECT_PATH\}\}', $ProjectPath
    $content = $content -replace '\{\{DFW_ROOT\}\}', $DFWRoot

    Set-Content -Path $destPath -Value $content -NoNewline
    Write-Host "  Created: $relativePath" -ForegroundColor Green
}

# --- Step 2: Copy constitution docs from Tools ---
Write-Host '  Copying DFW docs from Tools...' -ForegroundColor Gray

$docsDir = Join-Path $ProjectPath 'docs'
if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}

$docsToCopy = @(
    @{ Src = 'Constitution\DFW-PROJECT-CONSTITUTION.md'; Dest = 'docs\DFW-PROJECT-CONSTITUTION.md' },
    @{ Src = 'Manuals\DFW-OPERATING-MANUAL.md'; Dest = 'docs\DFW-OPERATING-MANUAL.md' },
    @{ Src = 'Constitution\DFW-GLOSSARY.md'; Dest = 'docs\DFW-GLOSSARY.md' }
)

foreach ($doc in $docsToCopy) {
    $srcPath = Join-Path $ToolsPath $doc.Src
    $destPath = Join-Path $ProjectPath $doc.Dest

    if (-not (Test-Path $srcPath)) {
        Write-Host "  Warning: Source not found: $($doc.Src)" -ForegroundColor Yellow
        continue
    }

    if ((Test-Path $destPath) -and -not $Force) {
        Write-Host "  Skipped (exists): $($doc.Dest)" -ForegroundColor DarkGray
        continue
    }

    Copy-Item -Path $srcPath -Destination $destPath -Force
    Write-Host "  Copied: $($doc.Dest)" -ForegroundColor Green
}

# --- Step 3: Copy CLAUDE.md from template with variable substitution ---
Write-Host '  Setting up CLAUDE.md...' -ForegroundColor Gray

$claudeTemplateSrc = Join-Path $ToolsPath 'Constitution\CLAUDE-PROJECT-TEMPLATE.md'
$claudeDest = Join-Path $ProjectPath 'CLAUDE.md'
$projectName = Split-Path $ProjectPath -Leaf

if ((Test-Path $claudeTemplateSrc) -and (-not (Test-Path $claudeDest) -or $Force)) {
    $claudeContent = Get-Content -Path $claudeTemplateSrc -Raw
    $claudeContent = $claudeContent -replace '\{\{PROJECT_NAME\}\}', $projectName
    $claudeContent = $claudeContent -replace '\{\{PROJECT_PATH\}\}', $ProjectPath
    $claudeContent = $claudeContent -replace '\{\{DFW_ROOT\}\}', $DFWRoot
    $claudeContent = $claudeContent -replace '\{\{PID\}\}', $ProjectID
    $claudeContent = $claudeContent -replace '\{\{PERSONA\}\}', 'Donna'
    $claudeContent = $claudeContent -replace '\{\{SUB_PROJECTS\}\}', 'None'
    Set-Content -Path $claudeDest -Value $claudeContent -NoNewline
    Write-Host "  Created: CLAUDE.md (with project paths)" -ForegroundColor Green
}

# --- Step 3.5: Copy AGENTS.md from template with variable substitution ---
Write-Host '  Setting up AGENTS.md...' -ForegroundColor Gray

$agentsTemplateSrc = Join-Path $ToolsPath 'templates\AGENTS-PROJECT-TEMPLATE.md'
$agentsDest = Join-Path $ProjectPath 'AGENTS.md'
$projectSlug = $projectName.ToLowerInvariant() -replace '[^a-z0-9]', '-'

if ((Test-Path $agentsTemplateSrc) -and (-not (Test-Path $agentsDest) -or $Force)) {
    $agentsContent = Get-Content -Path $agentsTemplateSrc -Raw
    $agentsContent = $agentsContent -replace '\{\{PROJECT_NAME\}\}', $projectName
    $agentsContent = $agentsContent -replace '\{\{PROJECT_PATH\}\}', $ProjectPath
    $agentsContent = $agentsContent -replace '\{\{DFW_ROOT\}\}', $DFWRoot
    $agentsContent = $agentsContent -replace '\{\{PID\}\}', $ProjectID
    $agentsContent = $agentsContent -replace '\{\{PERSONA\}\}', 'Donna'
    $agentsContent = $agentsContent -replace '\{\{PROJECT_SLUG\}\}', $projectSlug
    $agentsContent = $agentsContent -replace '\{\{SUB_PROJECTS\}\}', 'None'
    $agentsContent = $agentsContent -replace '\{\{RELATED_PROJECTS\}\}', 'None'
    $agentsContent = $agentsContent -replace '\{\{STACK_SUMMARY\}\}', 'TBD'
    $agentsContent = $agentsContent -replace '\{\{PROJECT_TYPE\}\}', 'TBD'
    Set-Content -Path $agentsDest -Value $agentsContent -NoNewline
    Write-Host "  Created: AGENTS.md (with project identity)" -ForegroundColor Green
} elseif (-not (Test-Path $agentsTemplateSrc)) {
    Write-Host "  Warning: AGENTS-PROJECT-TEMPLATE.md not found at $agentsTemplateSrc" -ForegroundColor Yellow
}

# --- Step 4: Generate personal-config from template ---
Write-Host '  Generating personal-config...' -ForegroundColor Gray

$pcTemplateSrc = Join-Path $ToolsPath 'Constitution\personal-config-template.md'
$pcDest = Join-Path $ProjectPath '.dfw\personal-config.md'

if ((Test-Path $pcTemplateSrc) -and (-not (Test-Path $pcDest) -or $Force)) {
    $pcContent = Get-Content -Path $pcTemplateSrc -Raw
    $pcContent = $pcContent -replace '\{\{DFW_ROOT\}\}', $DFWRoot
    $pcContent = $pcContent -replace '\{\{PROJECT_PATH\}\}', $ProjectPath
    $pcContent = $pcContent -replace '\{\{VAULT_PATH\}\}', (Join-Path $DFWRoot 'Vault')
    $pcContent = $pcContent -replace '\{\{TOOLS_PATH\}\}', $ToolsPath
    Set-Content -Path $pcDest -Value $pcContent -NoNewline
    Write-Host "  Generated: .dfw/personal-config.md" -ForegroundColor Green
}

# --- Step 4.5: Generate runtime.json from template ---
Write-Host '  Generating runtime.json...' -ForegroundColor Gray

function Get-SubstMap {
    $map = @{}

    try {
        $lines = cmd /c subst 2>$null
        foreach ($line in $lines) {
            if ($line -match '^(?<drive>[A-Z]:)\\: => (?<path>.+)$') {
                $map[$Matches.drive] = $Matches.path.TrimEnd('\')
            }
        }
    } catch {
    }

    return $map
}

function Convert-RealPathToAlias {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [hashtable]$SubstMap
    )

    foreach ($drive in $SubstMap.Keys) {
        $realRoot = $SubstMap[$drive]
        if ($Path.StartsWith($realRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $drive + $Path.Substring($realRoot.Length)
        }
    }

    return ''
}

function Convert-WindowsPathToWsl {
    param([string]$Path)

    if ($Path -match '^(?<drive>[A-Za-z]):\\(?<rest>.*)$') {
        $drive = $Matches.drive.ToLowerInvariant()
        $rest = $Matches.rest -replace '\\', '/'
        if ([string]::IsNullOrWhiteSpace($rest)) {
            return "/mnt/$drive"
        }
        return "/mnt/$drive/$rest"
    }

    return ''
}

$runtimeTemplateSrc = Join-Path $ToolsPath 'Constitution\runtime-template.json'
$runtimeDest = Join-Path $ProjectPath '.dfw\runtime.json'

if ((Test-Path $runtimeTemplateSrc) -and (-not (Test-Path $runtimeDest) -or $Force)) {
    $substMap = Get-SubstMap
    $projectPathReal = [System.IO.Path]::GetFullPath($ProjectPath)
    $dfwRootReal = [System.IO.Path]::GetFullPath($DFWRoot)
    $vaultPathReal = [System.IO.Path]::GetFullPath((Join-Path $DFWRoot 'Vault'))
    $projectPathAlias = Convert-RealPathToAlias -Path $projectPathReal -SubstMap $substMap
    $dfwRootAlias = Convert-RealPathToAlias -Path $dfwRootReal -SubstMap $substMap
    $vaultPathAlias = Convert-RealPathToAlias -Path $vaultPathReal -SubstMap $substMap
    $projectName = Split-Path -Path $projectPathReal -Leaf

    $runtimeContent = Get-Content -Path $runtimeTemplateSrc -Raw
    $runtimeContent = $runtimeContent -replace '\{\{PROJECT_NAME\}\}', $projectName.ToLowerInvariant()
    $runtimeContent = $runtimeContent -replace '\{\{PERSONA\}\}', 'Donna'
    $runtimeContent = $runtimeContent -replace '\{\{PROJECT_PATH_REAL\}\}', $projectPathReal
    $runtimeContent = $runtimeContent -replace '\{\{PROJECT_PATH_ALIAS\}\}', $projectPathAlias
    $runtimeContent = $runtimeContent -replace '\{\{DFW_ROOT_REAL\}\}', $dfwRootReal
    $runtimeContent = $runtimeContent -replace '\{\{DFW_ROOT_ALIAS\}\}', $dfwRootAlias
    $runtimeContent = $runtimeContent -replace '\{\{VAULT_PATH_REAL\}\}', $vaultPathReal
    $runtimeContent = $runtimeContent -replace '\{\{VAULT_PATH_ALIAS\}\}', $vaultPathAlias
    $runtimeContent = $runtimeContent -replace '\{\{WSL_PROJECT_ROOT\}\}', (Convert-WindowsPathToWsl -Path $projectPathReal)
    Set-Content -Path $runtimeDest -Value $runtimeContent -NoNewline
    Write-Host "  Generated: .dfw/runtime.json" -ForegroundColor Green
}

# --- Step 5: Copy Cursor rules ---
Write-Host '  Copying Cursor rules...' -ForegroundColor Gray

$rulesDir = Join-Path $ProjectPath '.cursor\rules'
if (-not (Test-Path $rulesDir)) {
    New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null
}

$rulesSrc = Join-Path $ToolsPath 'rules'
if (Test-Path $rulesSrc) {
    $ruleFiles = Get-ChildItem -Path $rulesSrc -Filter '*.mdc' -File
    foreach ($rule in $ruleFiles) {
        $destRule = Join-Path $rulesDir $rule.Name
        if (-not (Test-Path $destRule) -or $Force) {
            Copy-Item -Path $rule.FullName -Destination $destRule -Force
            Write-Host "  Copied rule: $($rule.Name)" -ForegroundColor Green
        }
    }
}

# --- Step 5.5: Create .claude/settings.local.json for Claude Code ---
Write-Host '  Setting up Claude Code config...' -ForegroundColor Gray

$claudeCodeDir = Join-Path $ProjectPath '.claude'
if (-not (Test-Path $claudeCodeDir)) {
    New-Item -ItemType Directory -Path $claudeCodeDir -Force | Out-Null
}

$claudeSettingsDest = Join-Path $claudeCodeDir 'settings.local.json'
if (-not (Test-Path $claudeSettingsDest) -or $Force) {
    $settingsContent = @'
{
  "permissions": {
    "allow": [
      "Bash(uv run:*)",
      "Bash(git:*)",
      "WebSearch",
      "Bash(node:*)",
      "Bash(npm:*)",
      "Bash(pwsh:*)",
      "Bash(mv:*)"
    ]
  }
}
'@
    Set-Content -Path $claudeSettingsDest -Value $settingsContent -NoNewline
    Write-Host "  Created: .claude/settings.local.json" -ForegroundColor Green
}

# --- Step 6: Create empty DFW directories ---
$emptyDirs = @('prompts', 'prompts\handoffs', 'research', 'scripts')
foreach ($dir in $emptyDirs) {
    $dirPath = Join-Path $ProjectPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Host "  Created dir: $dir" -ForegroundColor Green
    }
}

# --- Step 7: Git init ---
if (-not $SkipGit) {
    Write-Host '  Initializing git repository...' -ForegroundColor Gray

    Push-Location $ProjectPath
    try {
        if (-not (Test-Path '.git')) {
            git init | Out-Null
            git add .
            git commit -m "Initial commit: DFWP scaffolded by DFW bootstrap" | Out-Null
            Write-Host "  Git repo initialized with first commit." -ForegroundColor Green

            if ($GitHubUser) {
                git remote add origin "https://github.com/$GitHubUser/DFWP.git" 2>$null
                Write-Host "  Remote added: https://github.com/$GitHubUser/DFWP.git" -ForegroundColor Green
                Write-Host "  (Create the repo on GitHub, then run: git push -u origin main)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Git repo already exists, skipping init." -ForegroundColor DarkGray
        }
    } finally {
        Pop-Location
    }
}

Write-Host ''
Write-Host "  DFWP project scaffolded at: $ProjectPath" -ForegroundColor Green
Write-Host "  Project ID: $ProjectID" -ForegroundColor Green
Write-Host ''
