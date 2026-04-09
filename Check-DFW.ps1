<#
.SYNOPSIS
    Validates that the DFW environment is correctly configured for coder.ps1.

.DESCRIPTION
    Checks prerequisites, environment variables, config files, directory structure,
    and script availability. Reports PASS/FAIL for each check with actionable fixes.

.PARAMETER Fix
    Attempt to auto-fix issues where possible (e.g., set missing env vars).

.EXAMPLE
    .\Check-DFW.ps1

.EXAMPLE
    .\Check-DFW.ps1 -Fix
#>
[CmdletBinding()]
param(
    [switch]$Fix
)

$ErrorActionPreference = 'Continue'

$pass = 0
$fail = 0
$warn = 0

function Write-Check {
    param(
        [string]$Name,
        [string]$Status,  # PASS, FAIL, WARN, FIXED
        [string]$Detail = '',
        [string]$FixHint = ''
    )

    $icon = switch ($Status) {
        'PASS'  { '[PASS]'; }
        'FAIL'  { '[FAIL]'; }
        'WARN'  { '[WARN]'; }
        'FIXED' { '[FIXED]'; }
    }
    $color = switch ($Status) {
        'PASS'  { 'Green' }
        'FAIL'  { 'Red' }
        'WARN'  { 'Yellow' }
        'FIXED' { 'Cyan' }
    }

    Write-Host "  $icon " -ForegroundColor $color -NoNewline
    Write-Host $Name -NoNewline
    if ($Detail) {
        Write-Host " — $Detail" -ForegroundColor Gray
    } else {
        Write-Host ''
    }
    if ($FixHint -and $Status -eq 'FAIL') {
        Write-Host "         Fix: $FixHint" -ForegroundColor Yellow
    }

    switch ($Status) {
        'PASS'  { $script:pass++ }
        'FIXED' { $script:pass++ }
        'FAIL'  { $script:fail++ }
        'WARN'  { $script:warn++ }
    }
}

Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  DFW Environment Check' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host ''

# =========================================================================
# 1. PowerShell Version
# =========================================================================
Write-Host '  --- Prerequisites ---' -ForegroundColor White
$psVer = $PSVersionTable.PSVersion
if ($psVer -ge [version]'7.0') {
    Write-Check 'PowerShell 7.0+' 'PASS' "v$psVer"
} else {
    Write-Check 'PowerShell 7.0+' 'FAIL' "v$psVer" 'Install from https://github.com/PowerShell/PowerShell/releases'
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVer = (git --version) -replace 'git version ', ''
    Write-Check 'Git' 'PASS' "v$gitVer"
} else {
    Write-Check 'Git' 'FAIL' 'not found' 'winget install Git.Git'
}

# Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVer = (node --version)
    Write-Check 'Node.js' 'PASS' $nodeVer
} else {
    Write-Check 'Node.js' 'FAIL' 'not found' 'winget install OpenJS.NodeJS.LTS'
}

# Agent executables
foreach ($agent in @('claude', 'codex')) {
    if (Get-Command $agent -ErrorAction SilentlyContinue) {
        Write-Check "$agent CLI" 'PASS' (Get-Command $agent).Source
    } else {
        Write-Check "$agent CLI" 'WARN' 'not found (ok if you only use the other agent)'
    }
}

Write-Host ''

# =========================================================================
# 2. Environment Variables
# =========================================================================
Write-Host '  --- Environment Variables ---' -ForegroundColor White

# DFW_ROOT
$dfwRootEnv = [Environment]::GetEnvironmentVariable('DFW_ROOT', 'User')
$dfwRootProcess = $env:DFW_ROOT

if ($dfwRootEnv -and (Test-Path $dfwRootEnv)) {
    Write-Check 'DFW_ROOT (User-level)' 'PASS' $dfwRootEnv
} elseif ($dfwRootEnv) {
    Write-Check 'DFW_ROOT (User-level)' 'FAIL' "set to '$dfwRootEnv' but path does not exist" 'Run Start-Here.ps1 or set manually'
} else {
    # Try to resolve from script location
    $scriptDfwRoot = $null
    $candidate = $PSScriptRoot
    while ($candidate) {
        if (Test-Path (Join-Path $candidate 'Tools\scripts\coder.ps1')) {
            $scriptDfwRoot = $candidate
            break
        }
        $parent = Split-Path $candidate -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $candidate) { break }
        $candidate = $parent
    }

    if ($Fix -and $scriptDfwRoot) {
        [Environment]::SetEnvironmentVariable('DFW_ROOT', $scriptDfwRoot, 'User')
        $env:DFW_ROOT = $scriptDfwRoot
        Write-Check 'DFW_ROOT (User-level)' 'FIXED' "set to $scriptDfwRoot"
    } else {
        $hint = if ($scriptDfwRoot) { "Run with -Fix or: [Environment]::SetEnvironmentVariable('DFW_ROOT', '$scriptDfwRoot', 'User')" } else { 'Run Start-Here.ps1' }
        Write-Check 'DFW_ROOT (User-level)' 'FAIL' 'not set' $hint
    }
}

# Resolve effective DFW_ROOT for remaining checks
$effectiveDfwRoot = $dfwRootEnv
if (-not $effectiveDfwRoot) { $effectiveDfwRoot = $dfwRootProcess }
if (-not $effectiveDfwRoot) {
    # Auto-discover from script location
    $candidate = $PSScriptRoot
    while ($candidate) {
        if (Test-Path (Join-Path $candidate 'Tools\scripts\coder.ps1')) {
            $effectiveDfwRoot = $candidate
            break
        }
        $parent = Split-Path $candidate -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $candidate) { break }
        $candidate = $parent
    }
}

# DFW_TOOLS
$dfwToolsEnv = [Environment]::GetEnvironmentVariable('DFW_TOOLS', 'User')
$expectedTools = if ($effectiveDfwRoot) { Join-Path $effectiveDfwRoot 'Tools' } else { $null }

if ($dfwToolsEnv -and (Test-Path $dfwToolsEnv)) {
    Write-Check 'DFW_TOOLS (User-level)' 'PASS' $dfwToolsEnv
} elseif ($Fix -and $expectedTools -and (Test-Path $expectedTools)) {
    [Environment]::SetEnvironmentVariable('DFW_TOOLS', $expectedTools, 'User')
    $env:DFW_TOOLS = $expectedTools
    Write-Check 'DFW_TOOLS (User-level)' 'FIXED' "set to $expectedTools"
} else {
    Write-Check 'DFW_TOOLS (User-level)' 'FAIL' $(if ($dfwToolsEnv) { "set to '$dfwToolsEnv' but path does not exist" } else { 'not set' }) 'Run Start-Here.ps1'
}

# PATH includes Tools\scripts
$expectedScriptsPath = if ($effectiveDfwRoot) { Join-Path $effectiveDfwRoot 'Tools\scripts' } else { $null }
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = if ($userPath) { $userPath.Split(';') } else { @() }

if ($expectedScriptsPath -and ($pathEntries -contains $expectedScriptsPath)) {
    Write-Check 'PATH includes Tools\scripts' 'PASS' $expectedScriptsPath
} elseif ($Fix -and $expectedScriptsPath -and (Test-Path $expectedScriptsPath)) {
    $newPath = if ($userPath) { "$userPath;$expectedScriptsPath" } else { $expectedScriptsPath }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$env:Path;$expectedScriptsPath"
    Write-Check 'PATH includes Tools\scripts' 'FIXED' "added $expectedScriptsPath"
} else {
    Write-Check 'PATH includes Tools\scripts' 'FAIL' $(if ($expectedScriptsPath) { "$expectedScriptsPath not in User PATH" } else { 'cannot determine (DFW_ROOT unknown)' }) 'Run Start-Here.ps1'
}

Write-Host ''

# =========================================================================
# 3. Config Files
# =========================================================================
Write-Host '  --- Config Files ---' -ForegroundColor White

# ~/.dfw/config.json
$userConfigPath = Join-Path $HOME '.dfw\config.json'
if (Test-Path $userConfigPath) {
    try {
        $cfg = Get-Content $userConfigPath -Raw | ConvertFrom-Json
        if ($cfg.dfwRoot -and (Test-Path $cfg.dfwRoot)) {
            Write-Check '~/.dfw/config.json' 'PASS' "dfwRoot=$($cfg.dfwRoot)"
        } else {
            Write-Check '~/.dfw/config.json' 'FAIL' "dfwRoot='$($cfg.dfwRoot)' — path does not exist" 'Run Start-Here.ps1 or fix the path'
        }
    } catch {
        Write-Check '~/.dfw/config.json' 'FAIL' 'exists but cannot be parsed' 'Delete and re-run Start-Here.ps1'
    }
} else {
    if ($Fix -and $effectiveDfwRoot) {
        $configDir = Join-Path $HOME '.dfw'
        if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Force -Path $configDir | Out-Null }
        $configObj = [ordered]@{
            dfwRoot      = $effectiveDfwRoot
            vaultRoot    = Join-Path $effectiveDfwRoot 'Vault'
            hostRootReal = Split-Path $effectiveDfwRoot -Parent
            hostRootAlias = ''
        }
        $configObj | ConvertTo-Json -Depth 3 | Set-Content -Path $userConfigPath -Encoding utf8
        Write-Check '~/.dfw/config.json' 'FIXED' "created with dfwRoot=$effectiveDfwRoot"
    } else {
        Write-Check '~/.dfw/config.json' 'FAIL' 'not found' 'Run Start-Here.ps1'
    }
}

# Execution policy
$execPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($execPolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')) {
    Write-Check 'Execution policy' 'PASS' "$execPolicy (CurrentUser)"
} elseif ($Fix) {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Check 'Execution policy' 'FIXED' 'set to RemoteSigned (CurrentUser)'
} else {
    Write-Check 'Execution policy' 'FAIL' "$execPolicy — scripts may be blocked" 'Run with -Fix or: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
}

Write-Host ''

# =========================================================================
# 4. Directory Structure
# =========================================================================
Write-Host '  --- Directory Structure ---' -ForegroundColor White

if (-not $effectiveDfwRoot) {
    Write-Check 'DFW directory structure' 'FAIL' 'cannot check — DFW_ROOT not resolved'
} else {
    $requiredDirs = @(
        @{ Path = 'Tools';                     Desc = 'Tools directory' },
        @{ Path = 'Tools\scripts';             Desc = 'Scripts directory' },
        @{ Path = 'Tools\Constitution';        Desc = 'Constitution templates' },
        @{ Path = 'Tools\templates';           Desc = 'Project templates' }
    )

    foreach ($dir in $requiredDirs) {
        $fullPath = Join-Path $effectiveDfwRoot $dir.Path
        if (Test-Path $fullPath) {
            Write-Check $dir.Desc 'PASS' $dir.Path
        } else {
            Write-Check $dir.Desc 'FAIL' "$($dir.Path) missing" 'DFW repo may be incomplete — re-clone'
        }
    }

    $optionalDirs = @(
        @{ Path = 'DFWP';    Desc = 'DFWP project' },
        @{ Path = 'Vault';   Desc = 'Obsidian vault' }
    )

    foreach ($dir in $optionalDirs) {
        $fullPath = Join-Path $effectiveDfwRoot $dir.Path
        if (Test-Path $fullPath) {
            Write-Check $dir.Desc 'PASS' $dir.Path
        } else {
            Write-Check $dir.Desc 'WARN' "$($dir.Path) not found (run Start-Here.ps1 to scaffold)"
        }
    }
}

Write-Host ''

# =========================================================================
# 5. Key Scripts
# =========================================================================
Write-Host '  --- Key Scripts ---' -ForegroundColor White

if ($effectiveDfwRoot) {
    $requiredScripts = @(
        'Tools\scripts\DFW-Helpers.ps1',
        'Tools\scripts\coder.ps1',
        'Tools\scripts\Initialize-DFW.ps1',
        'Tools\scripts\Initialize-DFWP.ps1',
        'Tools\Constitution\runtime-template.json'
    )

    foreach ($script in $requiredScripts) {
        $fullPath = Join-Path $effectiveDfwRoot $script
        $name = Split-Path $script -Leaf
        if (Test-Path $fullPath) {
            # Check for Zone.Identifier (download block)
            $blocked = $null -ne (Get-Item -Path $fullPath -Stream Zone.Identifier -ErrorAction SilentlyContinue)
            if ($blocked -and $Fix) {
                Unblock-File -Path $fullPath
                Write-Check $name 'FIXED' "unblocked $script"
            } elseif ($blocked) {
                Write-Check $name 'WARN' "exists but blocked (downloaded from internet)" "Run with -Fix or: Unblock-File '$fullPath'"
            } else {
                Write-Check $name 'PASS' $script
            }
        } else {
            Write-Check $name 'FAIL' "$script missing" 'DFW repo may be incomplete'
        }
    }
} else {
    Write-Check 'Key scripts' 'FAIL' 'cannot check — DFW_ROOT not resolved'
}

Write-Host ''

# =========================================================================
# Summary
# =========================================================================
Write-Host '================================================================' -ForegroundColor Cyan
$total = $pass + $fail + $warn
Write-Host "  Results: " -NoNewline
Write-Host "$pass passed" -ForegroundColor Green -NoNewline
Write-Host ', ' -NoNewline
Write-Host "$fail failed" -ForegroundColor $(if ($fail -gt 0) { 'Red' } else { 'Green' }) -NoNewline
Write-Host ', ' -NoNewline
Write-Host "$warn warnings" -ForegroundColor $(if ($warn -gt 0) { 'Yellow' } else { 'Green' })
Write-Host '================================================================' -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host ''
    Write-Host '  Some checks failed. Run Start-Here.ps1 to fix, or use:' -ForegroundColor Yellow
    Write-Host '    .\Check-DFW.ps1 -Fix' -ForegroundColor Cyan
    Write-Host '  to auto-fix what can be fixed.' -ForegroundColor Yellow
}

Write-Host ''

exit $fail
