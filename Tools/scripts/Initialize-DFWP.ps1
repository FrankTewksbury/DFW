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
    $ProjectPath = Join-Path (Split-Path $DFWRoot -Parent) 'DFWP'
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
    @{ Src = 'Constitution\DFW-CONSTITUTION.md'; Dest = 'docs\DFW-CONSTITUTION.md' },
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

# --- Step 3: Copy CLAUDE.md from template ---
Write-Host '  Setting up CLAUDE.md...' -ForegroundColor Gray

$claudeTemplateSrc = Join-Path $ToolsPath 'Constitution\CLAUDE-PROJECT-TEMPLATE.md'
$claudeDest = Join-Path $ProjectPath 'CLAUDE.md'

if ((Test-Path $claudeTemplateSrc) -and (-not (Test-Path $claudeDest) -or $Force)) {
    Copy-Item -Path $claudeTemplateSrc -Destination $claudeDest -Force
    Write-Host "  Copied: CLAUDE.md" -ForegroundColor Green
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
