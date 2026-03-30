[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedLogPath = [System.IO.Path]::GetFullPath($LogPath)
$directory = Split-Path -Path $resolvedLogPath -Parent

if ($directory) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
}

if (-not (Test-Path -LiteralPath $resolvedLogPath)) {
    New-Item -ItemType File -Force -Path $resolvedLogPath | Out-Null
}

Get-Content -LiteralPath $resolvedLogPath -Tail 10 -Wait
