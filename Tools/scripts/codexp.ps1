[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetDir,

    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$RemainingArgs
)

$scriptPath = Join-Path $PSScriptRoot 'coder.ps1'
& $scriptPath -TargetDir $TargetDir -Agent codex @RemainingArgs
exit $LASTEXITCODE
