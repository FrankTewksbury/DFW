[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
    [Parameter(Position = 0, ParameterSetName = 'Run')]
    [string]$TargetDir = (Get-Location).Path,

    [ValidateSet('codex', 'claude')]
    [string]$Agent,

    [string[]]$AgentArgs = @(),

    [ValidateSet('interactive', 'autonomous')]
    [string]$Mode,

    [ValidateSet('read', 'safe-write', 'full-local')]
    [string]$AutonomyLevel,

    [ValidateSet('real', 'alias')]
    [string]$CanonicalPath,

    [string]$RuntimeConfig,

    [switch]$God,

    [Parameter(ParameterSetName = 'Help')]
    [switch]$Help,

    [switch]$InstallDeps,

    [switch]$ActivateVenv,

    [switch]$SkipEnv,

    [switch]$NoPanes,

    [switch]$NoEditor,

    [string]$LogFile,

    [string]$SessionNote
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'DFW-Helpers.ps1')

# --- Help ---
if ($Help) {
    Write-Host ''
    Write-Host 'coder.ps1  DFW Session Launcher' -ForegroundColor Cyan
    Write-Host 'Usage: .\coder.ps1 -TargetDir PATH [options]' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'REQUIRED' -ForegroundColor Yellow
    Write-Host '  -TargetDir PATH           Project directory to launch the agent in.'
    Write-Host ''
    Write-Host 'AGENT' -ForegroundColor Yellow
    Write-Host '  -Agent (codex|claude)     Which agent to launch. Default: from runtime.json, else codex.'
    Write-Host '  -AgentArgs ARGS           Extra arguments passed directly to the agent executable.'
    Write-Host ''
    Write-Host 'SESSION MODE' -ForegroundColor Yellow
    Write-Host '  -Mode (interactive|autonomous)'
    Write-Host '                            Session mode. Default: interactive.'
    Write-Host '  -AutonomyLevel (read|safe-write|full-local)'
    Write-Host '                            Autonomy tier for the session. Default: safe-write.'
    Write-Host '  -God                      GOD MODE. Skips all permission prompts.' -ForegroundColor Red
    Write-Host '                            Passes --dangerously-skip-permissions (Claude) or --full-auto (Codex).' -ForegroundColor Red
    Write-Host '                            Use with intent. There is no undo.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'PATH' -ForegroundColor Yellow
    Write-Host '  -CanonicalPath (real|alias)'
    Write-Host '                            Display real paths or subst-alias paths. Default: real.'
    Write-Host '  -RuntimeConfig PATH       Explicit path to .dfw\runtime.json. Auto-discovered if omitted.'
    Write-Host ''
    Write-Host 'ENVIRONMENT' -ForegroundColor Yellow
    Write-Host '  -SkipEnv                  Skip loading .env into session environment.'
    Write-Host '  -InstallDeps              Run npm install if node_modules is missing.'
    Write-Host '  -ActivateVenv             Activate .venv\Scripts\Activate.ps1 if present.'
    Write-Host ''
    Write-Host 'TERMINAL' -ForegroundColor Yellow
    Write-Host '  -NoPanes                  Skip Windows Terminal split panes (log tail + editor).'
    Write-Host '  -NoEditor                 Skip VS Code pane (log tail pane still opens).'
    Write-Host ''
    Write-Host 'LOGGING' -ForegroundColor Yellow
    Write-Host '  -LogFile PATH             Log path relative to TargetDir. Default: .dfw\logs\coder.log'
    Write-Host '  -SessionNote TEXT         Freeform note appended to the log entry for this session.'
    Write-Host ''
    Write-Host 'EXAMPLES' -ForegroundColor Yellow
    Write-Host '  .\coder.ps1 -TargetDir <ProjectDir>'
    Write-Host '  .\coder.ps1 -TargetDir <ProjectDir> -Agent claude'
    Write-Host '  .\coder.ps1 -TargetDir <ProjectDir> -Agent claude -God'
    Write-Host '  .\coder.ps1 -TargetDir <ProjectDir> -Agent codex -Mode autonomous -AutonomyLevel full-local'
    Write-Host '  .\coder.ps1 -TargetDir <ProjectDir> -Agent claude -God -SessionNote "pipeline build sprint"'
    Write-Host ''
    exit 0
}

function Find-UpwardFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $current = [System.IO.Path]::GetFullPath($StartPath)

    while ($true) {
        $candidate = Join-Path $current $RelativePath
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }

        $parent = Split-Path -Path $current -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
            break
        }

        $current = $parent
    }

    return $null
}

function Read-JsonFile {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Warning "Could not parse JSON file '$Path': $_"
        return $null
    }
}

function Convert-RealPathToAlias {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [hashtable]$SubstMap
    )

    foreach ($drive in $SubstMap.Keys) {
        $realRoot = $SubstMap[$drive].TrimEnd('\')
        if ($Path.StartsWith($realRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $drive + $Path.Substring($realRoot.Length)
        }
    }

    return ''
}

function Convert-WindowsPathToWsl {
    param([string]$Path)

    if ($Path -match '^(?<drive>[A-Za-z]):\\(?<rest>.*)$') {
        $drive = $Matches['drive'].ToLowerInvariant()
        $rest = $Matches['rest'] -replace '\\', '/'
        if ([string]::IsNullOrWhiteSpace($rest)) {
            return "/mnt/$drive"
        }

        return "/mnt/$drive/$rest"
    }

    return ''
}

function New-RuntimeConfigFromTemplate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootReal,
        [Parameter(Mandatory = $true)]
        [string]$RuntimeConfigPath,
        [string]$ProjectName,
        [string]$Persona,
        [hashtable]$SubstMap
    )

    $dfwRootReal = Get-DFWRoot
    $templatePath = Join-Path $dfwRootReal 'Tools\Constitution\runtime-template.json'
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Runtime template not found: $templatePath"
    }

    $projectRootReal = [System.IO.Path]::GetFullPath($ProjectRootReal)
    $vaultRootReal = Join-Path $dfwRootReal 'Vault'
    $projectRootAlias = Convert-RealPathToAlias -Path $projectRootReal -SubstMap $SubstMap
    $dfwRootAlias = Convert-RealPathToAlias -Path $dfwRootReal -SubstMap $SubstMap
    $vaultRootAlias = Convert-RealPathToAlias -Path $vaultRootReal -SubstMap $SubstMap
    $runtimeContent = Get-Content -LiteralPath $templatePath -Raw
    $runtimeContent = $runtimeContent -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    $runtimeContent = $runtimeContent -replace '\{\{PERSONA\}\}', $Persona
    $runtimeContent = $runtimeContent -replace '\{\{PROJECT_PATH_REAL\}\}', $projectRootReal
    $runtimeContent = $runtimeContent -replace '\{\{PROJECT_PATH_ALIAS\}\}', $projectRootAlias
    $runtimeContent = $runtimeContent -replace '\{\{DFW_ROOT_REAL\}\}', $dfwRootReal
    $runtimeContent = $runtimeContent -replace '\{\{DFW_ROOT_ALIAS\}\}', $dfwRootAlias
    $runtimeContent = $runtimeContent -replace '\{\{VAULT_PATH_REAL\}\}', $vaultRootReal
    $runtimeContent = $runtimeContent -replace '\{\{VAULT_PATH_ALIAS\}\}', $vaultRootAlias
    $runtimeContent = $runtimeContent -replace '\{\{WSL_PROJECT_ROOT\}\}', (Convert-WindowsPathToWsl -Path $projectRootReal)

    $runtimeDirectory = Split-Path -Path $RuntimeConfigPath -Parent
    if ($runtimeDirectory) {
        New-Item -ItemType Directory -Force -Path $runtimeDirectory | Out-Null
    }

    Set-Content -LiteralPath $RuntimeConfigPath -Value $runtimeContent -Encoding utf8
}

function Convert-ToRealPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [object]$Runtime,
        [hashtable]$SubstMap
    )

    $candidate = [System.IO.Path]::GetFullPath($Path)

    if ($Runtime -and $Runtime.paths) {
        $pairs = @(
            @{ Alias = $Runtime.paths.projectRootAlias; Real = $Runtime.paths.projectRootReal },
            @{ Alias = $Runtime.paths.hostRootAlias; Real = $Runtime.paths.hostRootReal },
            @{ Alias = $Runtime.paths.vaultRootAlias; Real = $Runtime.paths.vaultRootReal }
        )

        foreach ($pair in $pairs) {
            if (-not [string]::IsNullOrWhiteSpace($pair.Alias) -and -not [string]::IsNullOrWhiteSpace($pair.Real)) {
                if ($candidate.StartsWith($pair.Alias, [System.StringComparison]::OrdinalIgnoreCase)) {
                    return $pair.Real + $candidate.Substring($pair.Alias.Length)
                }
            }
        }
    }

    if ($candidate -match '^(?<drive>[A-Z]:)(?<rest>\\.*)?$') {
        $drive = $Matches['drive']
        $rest = if ($Matches['rest']) { $Matches['rest'] } else { '' }

        if ($SubstMap.ContainsKey($drive)) {
            return $SubstMap[$drive] + $rest
        }
    }

    return $candidate
}

function Convert-ToAliasPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [object]$Runtime,
        [string]$RequestedPath
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath) -and $RequestedPath -ne $Path) {
        return [System.IO.Path]::GetFullPath($RequestedPath)
    }

    if ($Runtime -and $Runtime.paths -and $Runtime.paths.projectRootAlias -and $Runtime.paths.projectRootReal) {
        if ($Path.StartsWith($Runtime.paths.projectRootReal, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $Runtime.paths.projectRootAlias + $Path.Substring($Runtime.paths.projectRootReal.Length)
        }
    }

    return $Path
}

function Get-ProjectRootFromProjectJson {
    param([string]$ProjectJsonPath)

    if (-not $ProjectJsonPath) {
        return $null
    }

    return Split-Path -Path (Split-Path -Path $ProjectJsonPath -Parent) -Parent
}

function Get-PersonaName {
    param([string]$ProjectRoot)

    if (-not $ProjectRoot) {
        return $null
    }

    $agentsPath = Join-Path $ProjectRoot 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $agentsPath)) {
        return $null
    }

    $content = Get-Content -LiteralPath $agentsPath -Raw
    # Match table row: | **Persona** | Donna ... |
    if ($content -match '\*\*Persona\*\*\s*\|\s*(?<persona>[^\s|/\n(]+)') {
        return $Matches['persona'].Trim()
    }
    # Fallback: legacy format "Persona for this project: Donna"
    if ($content -match 'Persona for this project:\s*(?<persona>\S+)') {
        return $Matches['persona'].Trim()
    }

    return $null
}

function Parse-DotEnvLine {
    param([string]$Line)

    if ($Line -match '^\s*$' -or $Line -match '^\s*#') {
        return $null
    }

    if ($Line -notmatch '^\s*(?:export\s+)?(?<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?<value>.*)$') {
        return $null
    }

    $name = $Matches['n'].Trim()
    $value = if ($null -ne $Matches['value']) { $Matches['value'].Trim() } else { '' }

    if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
        $value = $value.Substring(1, $value.Length - 2)
    } else {
        $value = [regex]::Replace($value, '\s+#.*$', '').TrimEnd()
    }

    return @{ Name = $name; Value = $value }
}

function Load-DotEnvFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Write-Host 'Loading environment variables from .env...' -ForegroundColor Yellow

    foreach ($line in Get-Content -LiteralPath $Path) {
        $entry = Parse-DotEnvLine -Line $line
        if ($entry) {
            [System.Environment]::SetEnvironmentVariable($entry.Name, $entry.Value, 'Process')
        }
    }
}

function Ensure-LogFile {
    param([string]$Path)

    $directory = Split-Path -Path $Path -Parent
    if ($directory) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType File -Force -Path $Path | Out-Null
    }
}

function Get-AgentSpec {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedAgent,
        [object]$Runtime
    )

    if ($Runtime -and $Runtime.launch -and $Runtime.launch.commands) {
        $property = $Runtime.launch.commands.PSObject.Properties[$SelectedAgent]
        if ($property) {
            $value = $property.Value
            if ($value.exe) {
                return @{
                    Exe = [string]$value.exe
                    Args = @($value.args)
                }
            }
        }
    }

    switch ($SelectedAgent) {
        'codex' {
            return @{ Exe = 'codex'; Args = @('start') }
        }
        'claude' {
            return @{ Exe = 'claude'; Args = @() }
        }
        default {
            throw "Unsupported agent: $SelectedAgent"
        }
    }
}

function Get-GodFlag {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedAgent
    )

    switch ($SelectedAgent) {
        'claude' { return '--dangerously-skip-permissions' }
        'codex'  { return '--full-auto' }
        default  {
            Write-Warning "No god mode flag known for agent '$SelectedAgent'. -God ignored."
            return $null
        }
    }
}

$originalEnv = @{}
Get-ChildItem Env: | ForEach-Object {
    $originalEnv[$_.Name] = $_.Value
}

$agentExitCode = 0

try {
    $requestedTargetDir = [System.IO.Path]::GetFullPath($TargetDir)
    $substMap = Get-SubstMap

    $runtimeConfigPath = if ($RuntimeConfig) {
        [System.IO.Path]::GetFullPath($RuntimeConfig)
    } else {
        Find-UpwardFile -StartPath $requestedTargetDir -RelativePath '.dfw\runtime.json'
    }

    $runtime = Read-JsonFile -Path $runtimeConfigPath

    if (-not $PSBoundParameters.ContainsKey('Agent')) {
        $Agent = if ($runtime -and $runtime.launch -and $runtime.launch.defaultAgent) { [string]$runtime.launch.defaultAgent } else { 'codex' }
    }

    if (-not $PSBoundParameters.ContainsKey('Mode')) {
        $Mode = if ($runtime -and $runtime.launch -and $runtime.launch.defaultMode) { [string]$runtime.launch.defaultMode } else { 'interactive' }
    }

    if (-not $PSBoundParameters.ContainsKey('AutonomyLevel')) {
        $AutonomyLevel = if ($runtime -and $runtime.launch -and $runtime.launch.defaultAutonomyLevel) { [string]$runtime.launch.defaultAutonomyLevel } else { 'safe-write' }
    }

    if (-not $PSBoundParameters.ContainsKey('CanonicalPath')) {
        $CanonicalPath = if ($runtime -and $runtime.launch -and $runtime.launch.canonicalPath) { [string]$runtime.launch.canonicalPath } else { 'real' }
    }

    $godFlag = $null
    if ($God) {
        $godFlag = Get-GodFlag -SelectedAgent $Agent
        if ($godFlag) {
            Write-Host "GOD MODE ENGAGED: $godFlag" -ForegroundColor Red
        }
    }

    $realTargetCandidate = Convert-ToRealPath -Path $requestedTargetDir -Runtime $runtime -SubstMap $substMap
    if (-not (Test-Path -LiteralPath $realTargetCandidate)) {
        if (-not (Test-Path -LiteralPath $requestedTargetDir)) {
            throw "Directory not found: $TargetDir"
        }
        $realTargetCandidate = $requestedTargetDir
    }

    $resolvedTargetDir = (Resolve-Path -LiteralPath $realTargetCandidate).Path
    $aliasTargetDir = Convert-ToAliasPath -Path $resolvedTargetDir -Runtime $runtime -RequestedPath $requestedTargetDir
    $displayTargetDir = if ($CanonicalPath -eq 'alias') { $aliasTargetDir } else { $resolvedTargetDir }

    $projectJsonPath = Find-UpwardFile -StartPath $resolvedTargetDir -RelativePath '.dfw\project.json'
    $projectConfig = Read-JsonFile -Path $projectJsonPath
    $projectRootByJson = if ($projectJsonPath) { Get-ProjectRootFromProjectJson -ProjectJsonPath $projectJsonPath } else { $resolvedTargetDir }
    $agentsPersona = Get-PersonaName -ProjectRoot $projectRootByJson

    if (-not $runtime) {
        $runtimeConfigPath = Join-Path $projectRootByJson '.dfw\runtime.json'
        Write-Warning "No .dfw/runtime.json found for this project."
        $createRuntime = if ([Environment]::UserInteractive) {
            Read-Host "Create runtime config now at $runtimeConfigPath ? [Y/n]"
        } else {
            Write-Warning 'Non-interactive session — skipping runtime config creation.'
            'n'
        }
        if ([string]::IsNullOrWhiteSpace($createRuntime) -or $createRuntime -match '^(y|yes)$') {
            $suggestedProjectName = if ($projectConfig -and $projectConfig.name) {
                [string]$projectConfig.name
            } else {
                (Split-Path -Path $projectRootByJson -Leaf).ToLowerInvariant()
            }
            $suggestedPersona = if ($agentsPersona) { $agentsPersona } else { 'Donna' }
            New-RuntimeConfigFromTemplate -ProjectRootReal $projectRootByJson -RuntimeConfigPath $runtimeConfigPath -ProjectName $suggestedProjectName -Persona $suggestedPersona -SubstMap $substMap
            $runtime = Read-JsonFile -Path $runtimeConfigPath
            Write-Host "Created runtime config: $runtimeConfigPath" -ForegroundColor Green
        } else {
            Write-Warning 'Continuing without .dfw/runtime.json; inferred defaults will be used for this session.'
        }
    }

    $projectRootReal = if ($runtime -and $runtime.paths -and $runtime.paths.projectRootReal) {
        [string]$runtime.paths.projectRootReal
    } elseif ($projectJsonPath) {
        Get-ProjectRootFromProjectJson -ProjectJsonPath $projectJsonPath
    } else {
        $resolvedTargetDir
    }

    $projectRootAlias = if ($runtime -and $runtime.paths -and $runtime.paths.projectRootAlias) {
        [string]$runtime.paths.projectRootAlias
    } elseif (
        -not [string]::IsNullOrEmpty($aliasTargetDir) -and
        -not [string]::IsNullOrEmpty($projectRootReal) -and
        $resolvedTargetDir.StartsWith($projectRootReal, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        $relativeSuffix = $resolvedTargetDir.Substring($projectRootReal.Length)
        if ([string]::IsNullOrEmpty($relativeSuffix)) {
            $aliasTargetDir
        } elseif ($aliasTargetDir.EndsWith($relativeSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $aliasTargetDir.Substring(0, $aliasTargetDir.Length - $relativeSuffix.Length)
        } else {
            $aliasTargetDir
        }
    } else {
        $null
    }

    $projectName = if ($projectConfig -and $projectConfig.name) {
        [string]$projectConfig.name
    } elseif ($runtime -and $runtime.projectName) {
        [string]$runtime.projectName
    } else {
        Split-Path -Path $projectRootReal -Leaf
    }

    $persona = if ($runtime -and $runtime.persona) {
        [string]$runtime.persona
    } else {
        $agentsPersona
    }

    $hostRootReal = if ($runtime -and $runtime.paths -and $runtime.paths.hostRootReal) { [string]$runtime.paths.hostRootReal } else { $env:DFW_HOST_ROOT_REAL }
    $hostRootAlias = if ($runtime -and $runtime.paths -and $runtime.paths.hostRootAlias) { [string]$runtime.paths.hostRootAlias } else { $env:DFW_HOST_ROOT_ALIAS }
    $vaultRootReal = if ($runtime -and $runtime.paths -and $runtime.paths.vaultRootReal) { [string]$runtime.paths.vaultRootReal } else { $env:DFW_VAULT_ROOT_REAL }
    $vaultRootAlias = if ($runtime -and $runtime.paths -and $runtime.paths.vaultRootAlias) { [string]$runtime.paths.vaultRootAlias } else { $env:DFW_VAULT_ROOT_ALIAS }
    $wslProjectRoot = if ($runtime -and $runtime.paths -and $runtime.paths.wslProjectRoot) { [string]$runtime.paths.wslProjectRoot } else { $env:DFW_WSL_PROJECT_ROOT }

    $sessionLogPath = if ($LogFile) {
        [System.IO.Path]::GetFullPath((Join-Path $resolvedTargetDir $LogFile))
    } elseif ($runtime -and $runtime.launch -and $runtime.launch.logFile) {
        [System.IO.Path]::GetFullPath((Join-Path $resolvedTargetDir ([string]$runtime.launch.logFile)))
    } else {
        Join-Path $resolvedTargetDir '.dfw\logs\coder.log'
    }

    Ensure-LogFile -Path $sessionLogPath
    $godLogNote = if ($God) { ' god=true' } else { '' }
    Add-Content -LiteralPath $sessionLogPath -Value "[$(Get-Date -Format 's')] agent=$Agent mode=$Mode autonomy=$AutonomyLevel$godLogNote path=$resolvedTargetDir"

    Set-Location -LiteralPath $resolvedTargetDir
    Write-Host "Working directory: $displayTargetDir" -ForegroundColor Cyan

    [System.Environment]::SetEnvironmentVariable('DFW_AGENT', $Agent, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_ROOT', (Get-DFWRoot), 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_SESSION_MODE', $Mode, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_AUTONOMY_LEVEL', $AutonomyLevel, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_GOD_MODE', $(if ($God) { 'true' } else { 'false' }), 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_PROJECT_NAME', $projectName, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_PROJECT_ROOT_REAL', $projectRootReal, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_PROJECT_ROOT_ALIAS', $projectRootAlias, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_HOST_ROOT_REAL', $hostRootReal, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_HOST_ROOT_ALIAS', $hostRootAlias, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_VAULT_ROOT_REAL', $vaultRootReal, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_VAULT_ROOT_ALIAS', $vaultRootAlias, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_WSL_PROJECT_ROOT', $wslProjectRoot, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_PREFERRED_CWD', $resolvedTargetDir, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_CANONICAL_PATH_MODE', $CanonicalPath, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_LOG_FILE', $sessionLogPath, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_PERSONA', $persona, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_RUNTIME_CONFIG', $runtimeConfigPath, 'Process')
    [System.Environment]::SetEnvironmentVariable('DFW_SESSION_NOTE', $SessionNote, 'Process')

    if (-not $SkipEnv) {
        $envPath = Join-Path $resolvedTargetDir '.env'
        if (Test-Path -LiteralPath $envPath) {
            Load-DotEnvFile -Path $envPath
        }
    }

    if ($InstallDeps -and (Test-Path -LiteralPath (Join-Path $resolvedTargetDir 'package.json')) -and -not (Test-Path -LiteralPath (Join-Path $resolvedTargetDir 'node_modules'))) {
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            throw 'npm is not available on PATH.'
        }

        Write-Host 'node_modules missing. Running npm install...' -ForegroundColor Blue
        npm install
        if ($LASTEXITCODE) {
            throw "npm install failed with exit code $LASTEXITCODE"
        }
    }

    if ($ActivateVenv) {
        $venvActivatePath = Join-Path $resolvedTargetDir '.venv\Scripts\Activate.ps1'
        if (Test-Path -LiteralPath $venvActivatePath) {
            Write-Host 'Activating Python virtual environment...' -ForegroundColor Blue
            . $venvActivatePath
        }
    }

    if ($env:WT_SESSION -and -not $NoPanes) {
        try {
            $logTailScriptPath = Join-Path $PSScriptRoot 'coder-log-tail.ps1'
            & wt.exe @(
                '-w', '0', 'split-pane', '-v',
                '-d', $resolvedTargetDir,
                '--title', 'Coder Log',
                'pwsh', '-NoExit', '-File', $logTailScriptPath, $sessionLogPath
            ) | Out-Null

            if (-not $NoEditor -and (Get-Command code -ErrorAction SilentlyContinue)) {
                & wt.exe @(
                    '-w', '0', 'split-pane', '-h',
                    '-d', $resolvedTargetDir,
                    '--title', 'Editor',
                    'pwsh', '-NoExit', '-Command', 'code .'
                ) | Out-Null
            }
        } catch {
            Write-Warning "Windows Terminal pane setup failed: $_"
        }
    }

    $agentSpec = Get-AgentSpec -SelectedAgent $Agent -Runtime $runtime
    if (-not (Get-Command $agentSpec.Exe -ErrorAction SilentlyContinue)) {
        throw "Agent command not found on PATH: $($agentSpec.Exe)"
    }

    $finalArgs = @($agentSpec.Args)
    if ($godFlag) {
        $finalArgs += $godFlag
    }
    $finalArgs += $AgentArgs

    Write-Host "Launching $Agent ($Mode / $AutonomyLevel$(if ($God) { ' / GOD MODE' }))..." -ForegroundColor Green
    & $agentSpec.Exe @finalArgs
    $agentExitCode = if ($LASTEXITCODE) { $LASTEXITCODE } else { 0 }
} catch {
    Write-Error "coder.ps1 failed: $_ (at line $($_.InvocationInfo.ScriptLineNumber))"
    $agentExitCode = 1
} finally {
    Write-Host "`nRestoring session environment..." -ForegroundColor Gray

    foreach ($item in Get-ChildItem Env:) {
        if (-not $originalEnv.ContainsKey($item.Name)) {
            [System.Environment]::SetEnvironmentVariable($item.Name, $null, 'Process')
        }
    }

    foreach ($name in $originalEnv.Keys) {
        [System.Environment]::SetEnvironmentVariable($name, $originalEnv[$name], 'Process')
    }

    Write-Host 'Environment restore complete.' -ForegroundColor DarkGray
}

exit $agentExitCode
