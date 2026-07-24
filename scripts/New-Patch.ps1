[CmdletBinding()]
param(
  [string]$Workspace,
  [int]$MaximumChangedLines = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "OpenBaoOverlay.psm1") -Force

$root = Get-OverlayRoot
if (-not $Workspace) {
  $Workspace = Join-Path $root ".work/openbao"
}
$workspacePath = Assert-SafeWorkspace $Workspace
if (-not (Test-Path -LiteralPath (Join-Path $workspacePath ".git"))) {
  throw "No prepared upstream checkout exists at $workspacePath"
}

$changedPaths = @(& git -C $workspacePath diff --name-only)
if ($LASTEXITCODE -ne 0 -or $changedPaths.Count -eq 0) {
  throw "The prepared checkout has no source changes"
}

$allowedPrefixes = Get-AllowedJwtPaths
foreach ($path in $changedPaths) {
  if (-not ($allowedPrefixes | Where-Object { $path.StartsWith($_) })) {
    throw "Change outside the JWT backend is not allowed: $path"
  }
}

$numstat = @(& git -C $workspacePath diff --numstat)
if ($LASTEXITCODE -ne 0) {
  throw "Unable to calculate patch size"
}
$changedLines = 0
foreach ($line in $numstat) {
  $parts = $line -split "\s+"
  if ($parts[0] -match "^\d+$") {
    $changedLines += [int]$parts[0]
  }
  if ($parts[1] -match "^\d+$") {
    $changedLines += [int]$parts[1]
  }
}
if ($changedLines -gt $MaximumChangedLines) {
  throw "Patch changes $changedLines lines; limit is $MaximumChangedLines"
}

$patchPath = Join-Path $root "patches/public-client.patch"
Invoke-Native git -C $workspacePath diff `
  --binary `
  --full-index `
  --output=$patchPath

Write-Output $patchPath
