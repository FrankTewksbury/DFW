<#
.SYNOPSIS
    Sync-CardBoardConfig.ps1 - Scans vault projects and generates CardBoard plugin config

.DESCRIPTION
    DevFlywheel automation that scans projects/ in the Obsidian vault, discovers
    all project directories, and generates/updates the CardBoard plugin data.json
    with a tag-based kanban board per project.

    Each board gets:
    - Standard DFW status columns: backlog, active, build, deploy, completed
    - Path filter scoped to the project's vault directory
    - Allow polarity so only that project's tasks appear

    Preserves existing globalSettings and any manually-created boards (non-DFW).

.PARAMETER VaultPath
    Root path of the Obsidian vault. Defaults to X:\DFW\Vault.

.PARAMETER ProjectsDir
    Subdirectory within the vault containing projects. Default: projects.

.PARAMETER Columns
    Ordered list of status tags for kanban columns. Default: status/backlog, status/active, status/build, status/deploy.

.PARAMETER DryRun
    Preview changes without writing to data.json.

.PARAMETER Force
    Overwrite existing DFW-managed boards (re-generates columns and filters).

.PARAMETER IncludeProjects
    If specified, only generate boards for these project names. Otherwise, all projects.

.PARAMETER ExcludeProjects
    Project names to skip (e.g., "Tools").

.EXAMPLE
    .\Sync-CardBoardConfig.ps1
.EXAMPLE
    .\Sync-CardBoardConfig.ps1 -VaultPath "C:\DATA\dfw-hub" -DryRun
.EXAMPLE
    .\Sync-CardBoardConfig.ps1 -ExcludeProjects @("Tools") -Force
.NOTES
    Conforms to DevFlywheel methodology.
    CardBoard plugin: https://github.com/roovo/obsidian-card-board
    Version: 1.0.0
#>

param(
    [string]$VaultPath = "X:\DFW\Vault",
    [string]$ProjectsDir = "projects",
    [string[]]$Columns = @("status/backlog", "status/active", "status/build", "status/deploy"),
    [switch]$DryRun,
    [switch]$Force,
    [string[]]$IncludeProjects = @(),
    [string[]]$ExcludeProjects = @("Tools"),
    [switch]$Verbose
)

# =============================================================================
#      CONFIGURATION
# =============================================================================
$CardBoardDataPath = Join-Path $VaultPath ".obsidian\plugins\card-board\data.json"
$CardBoardVersion  = "0.13.0"

# DFW-managed board marker — we embed this in the board name prefix so we can
# distinguish DFW-generated boards from user-created ones.
$DfwBoardPrefix = ""  # No prefix — use exact project name. Identification via metadata.

# Default global settings (used if data.json doesn't exist yet)
$DefaultGlobalSettings = @{
    defaultColumnNames = @{
        today     = ""
        tomorrow  = ""
        future    = ""
        undated   = ""
        otherTags = ""
        untagged  = ""
        completed = ""
    }
    filters                     = @()
    firstDayOfWeek              = "FromLocale"
    ignoreFileNameDates         = $false
    taskCompletionFormat        = "ObsidianCardBoard"
    taskCompletionInLocalTime   = $true
    taskCompletionShowUtcOffset = $true
}

# =============================================================================
#      HELPERS
# =============================================================================
function Write-Header {
    param([string]$Text, [string]$Style = "Major")
    $Width = 60
    $Line = if ($Style -eq "Major") { "=" * $Width } else { "-" * $Width }
    $Color = if ($Style -eq "Major") { "Blue" } else { "Green" }
    Write-Host ""
    Write-Host $Line -ForegroundColor $Color
    Write-Host "     $Text" -ForegroundColor $Color
    Write-Host $Line -ForegroundColor $Color
}

function Write-Status {
    param([string]$Label, [string]$Value, [string]$ValueColor = "White")
    Write-Host "  $Label`: " -ForegroundColor Gray -NoNewline
    Write-Host $Value -ForegroundColor $ValueColor
}

function Build-BoardColumns {
    param([string[]]$StatusTags)

    $columns = @()
    foreach ($tag in $StatusTags) {
        $columns += @{
            tag  = "namedTag"
            data = @{
                collapsed = $false
                name      = $tag
                tag       = $tag
            }
        }
    }

    # Always add Completed column at the end
    $columns += @{
        tag  = "completed"
        data = @{
            collapsed = $false
            index     = $StatusTags.Count
            limit     = 10
            name      = "Completed"
        }
    }

    return $columns
}

function Build-BoardConfig {
    param(
        [string]$ProjectName,
        [string]$ProjectVaultPath,
        [string[]]$StatusTags
    )

    $columns = Build-BoardColumns -StatusTags $StatusTags

    return @{
        columns         = $columns
        filters         = @(
            @{
                tag  = "pathFilter"
                data = $ProjectVaultPath
            }
        )
        filterPolarity  = "Allow"
        filterScope     = "Both"
        name            = $ProjectName
        showColumnTags  = $false
        showFilteredTags = $false
    }
}

function Read-CardBoardConfig {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Host "  CardBoard data.json not found — will create new." -ForegroundColor Yellow
        return @{
            version = $CardBoardVersion
            data    = @{
                boardConfigs   = @()
                globalSettings = $DefaultGlobalSettings
            }
        }
    }

    try {
        $raw = Get-Content $Path -Raw -Encoding UTF8
        $config = $raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Host "  ERROR: Could not parse $Path — $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Write-CardBoardConfig {
    param(
        [string]$Path,
        [object]$Config
    )

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # ConvertTo-Json with sufficient depth for nested structures
    $json = $Config | ConvertTo-Json -Depth 20

    # Write with UTF8 no BOM (Obsidian prefers this)
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Get-ExistingBoardNames {
    param([object]$Config)

    $names = @()
    if ($Config.data -and $Config.data.boardConfigs) {
        foreach ($board in $Config.data.boardConfigs) {
            if ($board.name) {
                $names += $board.name
            }
        }
    }
    return $names
}

# =============================================================================
#      MAIN
# =============================================================================
Write-Header "DFW CARDBOARD SYNC" "Major"

# ── Validate vault path ─────────────────────────────────────────────────
if (-not (Test-Path $VaultPath)) {
    Write-Host "  ERROR: Vault not found at $VaultPath" -ForegroundColor Red
    Write-Host "  Use -VaultPath to specify your Obsidian vault location." -ForegroundColor Yellow
    exit 1
}

$projectsFullPath = Join-Path $VaultPath $ProjectsDir
if (-not (Test-Path $projectsFullPath)) {
    Write-Host "  ERROR: Projects directory not found at $projectsFullPath" -ForegroundColor Red
    exit 1
}

Write-Status "Vault" $VaultPath
Write-Status "Projects dir" $projectsFullPath
Write-Status "CardBoard config" $CardBoardDataPath
Write-Status "Mode" $(if ($DryRun) { "DRY RUN" } else { "LIVE" }) $(if ($DryRun) { "Yellow" } else { "Green" })
Write-Host ""

# ── Discover projects ────────────────────────────────────────────────────
Write-Header "Discovering Projects" "Minor"

$projectDirs = Get-ChildItem -Path $projectsFullPath -Directory | Sort-Object Name
$projects = @()

foreach ($dir in $projectDirs) {
    $name = $dir.Name

    # Apply include/exclude filters
    if ($IncludeProjects.Count -gt 0 -and $name -notin $IncludeProjects) {
        if ($Verbose) { Write-Host "  [SKIP] $name (not in include list)" -ForegroundColor DarkGray }
        continue
    }
    if ($name -in $ExcludeProjects) {
        Write-Host "  [SKIP] $name (excluded)" -ForegroundColor DarkGray
        continue
    }

    # Check for task files (any .md with checkboxes)
    $vaultRelPath = "$ProjectsDir/$name"
    $hasTaskFiles = $false
    $taskFileCount = 0

    $mdFiles = Get-ChildItem -Path $dir.FullName -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    foreach ($md in $mdFiles) {
        $content = Get-Content $md.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "- \[[ x]\]") {
            $hasTaskFiles = $true
            $taskFileCount++
        }
    }

    $projects += @{
        Name         = $name
        VaultRelPath = $vaultRelPath
        FullPath     = $dir.FullName
        HasTasks     = $hasTaskFiles
        TaskFiles    = $taskFileCount
    }

    $taskStatus = if ($hasTaskFiles) { "$taskFileCount task file(s)" } else { "no tasks found" }
    $statusColor = if ($hasTaskFiles) { "Green" } else { "Yellow" }
    Write-Host "  [FOUND] $name — $taskStatus" -ForegroundColor $statusColor
}

Write-Host ""
Write-Status "Projects discovered" $projects.Count
Write-Status "With tasks" ($projects | Where-Object { $_.HasTasks }).Count "Green"

# ── Read existing config ─────────────────────────────────────────────────
Write-Header "Reading CardBoard Config" "Minor"

$config = Read-CardBoardConfig -Path $CardBoardDataPath
if ($null -eq $config) {
    Write-Host "  FATAL: Cannot proceed with corrupt config." -ForegroundColor Red
    exit 1
}

$existingBoards = Get-ExistingBoardNames -Config $config
Write-Status "Existing boards" ($existingBoards -join ", ")

# ── Generate / update boards ─────────────────────────────────────────────
Write-Header "Generating Board Configs" "Minor"

$stats = @{ Added = 0; Updated = 0; Skipped = 0; Unchanged = 0 }

# Build list of board configs, preserving non-project (manual) boards
$newBoardConfigs = @()
$projectNames = $projects | ForEach-Object { $_.Name }

# Keep non-project boards untouched
foreach ($existingBoard in $config.data.boardConfigs) {
    if ($existingBoard.name -notin $projectNames) {
        $newBoardConfigs += $existingBoard
        if ($Verbose) { Write-Host "  [KEEP] $($existingBoard.name) (not a project board)" -ForegroundColor DarkGray }
    }
}

# Add/update project boards
foreach ($project in $projects) {
    $boardExists = $project.Name -in $existingBoards

    if ($boardExists -and -not $Force) {
        # Keep existing board untouched
        $existing = $config.data.boardConfigs | Where-Object { $_.name -eq $project.Name }
        $newBoardConfigs += $existing
        Write-Host "  [UNCHANGED] $($project.Name) (already exists, use -Force to regenerate)" -ForegroundColor DarkGray
        $stats.Unchanged++
        continue
    }

    if ($boardExists -and $Force) {
        Write-Host "  [UPDATE] $($project.Name) (regenerating)" -ForegroundColor Yellow
        $stats.Updated++
    }
    else {
        Write-Host "  [ADD] $($project.Name) — board created" -ForegroundColor Green
        $stats.Added++
    }

    $board = Build-BoardConfig `
        -ProjectName $project.Name `
        -ProjectVaultPath $project.VaultRelPath `
        -StatusTags $Columns

    $newBoardConfigs += $board
}

# ── Assemble final config ────────────────────────────────────────────────
$finalConfig = @{
    version = if ($config.version) { $config.version } else { $CardBoardVersion }
    data    = @{
        boardConfigs   = $newBoardConfigs
        globalSettings = if ($config.data.globalSettings) { $config.data.globalSettings } else { $DefaultGlobalSettings }
    }
}

# ── Write config ─────────────────────────────────────────────────────────
Write-Header "SUMMARY" "Major"
Write-Status "Boards added" $stats.Added "Green"
Write-Status "Boards updated" $stats.Updated "Yellow"
Write-Status "Boards unchanged" $stats.Unchanged
Write-Status "Total boards" $newBoardConfigs.Count

if ($DryRun) {
    Write-Host ""
    Write-Host "  [DRY RUN] Would write to: $CardBoardDataPath" -ForegroundColor Yellow
    Write-Host ""

    if ($Verbose) {
        Write-Host "  Preview JSON:" -ForegroundColor Gray
        $finalConfig | ConvertTo-Json -Depth 20 | Write-Host -ForegroundColor DarkGray
    }
}
else {
    try {
        Write-CardBoardConfig -Path $CardBoardDataPath -Config $finalConfig
        Write-Host ""
        Write-Host "  Config written to: $CardBoardDataPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "  IMPORTANT: Reload Obsidian or reopen CardBoard to pick up changes." -ForegroundColor Cyan
    }
    catch {
        Write-Host ""
        Write-Host "  ERROR: Failed to write config — $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Make sure Obsidian's CardBoard plugin is not actively writing to the file." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Blue
Write-Host "  CardBoard Sync completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ("=" * 60) -ForegroundColor Blue
Write-Host ""
