param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TargetDir
)

# Store the original environment variables to clean up later
$originalEnv = [System.Collections.Generic.HashSet[string]]::new()
Get-ChildItem Env: | ForEach-Object { $originalEnv.Add($_.Name) | Out-Null }

try {
    # 1 & 2: Change to the specified Drive and Directory
    if (Test-Path $TargetDir) {
        Set-Location $TargetDir
        Write-Host "Moved to: $(Get-Location)" -ForegroundColor Cyan
    } else {
        Write-Error "Directory not found: $TargetDir"
        return
    }

    # 3: Read local .env and set environment variables
    $envPath = Join-Path $TargetDir ".env"
    if (Test-Path $envPath) {
        Write-Host "Loading environment variables from .env..." -ForegroundColor Yellow
        Get-Content $envPath | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
            $name, $value = $_.Split('=', 2).Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }

    # 4: Dependency Check & Activation (Python/Node)
    # Check for Python Virtual Env
    $venvPath = Join-Path $TargetDir ".venv"
    if (Test-Path "$venvPath\Scripts\Activate.ps1") {
        Write-Host "Activating Python Virtual Environment..." -ForegroundColor Blue
        & "$venvPath\Scripts\Activate.ps1"
    }

    # Check for Node modules
    $nodeModules = Join-Path $TargetDir "node_modules"
    if (!(Test-Path $nodeModules) -and (Test-Path (Join-Path $TargetDir "package.json"))) {
        Write-Host "node_modules missing. Running npm install..." -ForegroundColor Blue
        npm install
    }

    # 5: Login Check
    # (Generic placeholder for your tool's auth check)
    # if (!(codex auth status)) { codex login }

    # 6: Multiplexing / Launching
    # This checks if you're running inside Windows Terminal and splits the pane
    if ($env:WT_SESSION) {
        Write-Host "Detected Windows Terminal. Splitting panes..." -ForegroundColor DarkCyan
        
        # 1. Main pane runs CODEX
        # 2. Split vertical for logs (using 'Get-Content -Wait' as a placeholder)
        # 3. Split horizontal for editor (VS Code)
        wt -w 0 split-pane -v --title "CODEX Logs" powershell -NoExit -Command "Write-Host 'Viewing logs...'; Get-Content -Path (Join-Path $TargetDir 'codex.log') -Wait -Tail 10"
        wt -w 0 split-pane -h --title "Editor" powershell -Command "code ."
        
        # Finally, launch CODEX in the current pane
        Write-Host "Launching CODEX..." -ForegroundColor Green
        codex start
    } else {
        # Fallback for standard PowerShell or CMD
        Write-Host "Launching CODEX (Standard Terminal)..." -ForegroundColor Green
        codex start
    }

} catch {
    Write-Error "An unexpected error occurred: $_"
} finally {
    # 7: Automatic Clean-up
    Write-Host "`nCleaning up environment variables..." -ForegroundColor Gray
    $currentEnv = Get-ChildItem Env:
    foreach ($item in $currentEnv) {
        if (-not $originalEnv.Contains($item.Name)) {
            # This variable was added by the script/env file, so we remove it
            [System.Environment]::SetEnvironmentVariable($item.Name, $null, "Process")
        }
    }
    Write-Host "Cleanup complete." -ForegroundColor DarkGray
}