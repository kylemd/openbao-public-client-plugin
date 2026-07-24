[CmdletBinding()]
param(
  [string]$Workspace,
  [switch]$SkipPatch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "OpenBaoOverlay.psm1") -Force

$root = Get-OverlayRoot
$lock = Get-OpenBaoLock
if (-not $Workspace) {
  $Workspace = Join-Path $root ".work/openbao"
}
$workspacePath = Assert-SafeWorkspace $Workspace
$workRoot = Split-Path -Parent $workspacePath

if (Test-Path -LiteralPath $workspacePath) {
  Remove-Item -LiteralPath $workspacePath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null

Invoke-Native git clone `
  --filter=blob:none `
  --no-checkout `
  $lock.upstream_url `
  $workspacePath

Push-Location $workspacePath
try {
  Invoke-Native git fetch --depth 1 origin "refs/tags/$($lock.release_tag)"
  Invoke-Native git checkout --detach $lock.release_commit

  $actualCommit = (& git rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $actualCommit -ne $lock.release_commit) {
    throw "Expected $($lock.release_commit), got $actualCommit"
  }

  $tagCommit = (& git rev-list -n 1 $lock.release_tag).Trim()
  if ($LASTEXITCODE -ne 0 -or $tagCommit -ne $lock.release_commit) {
    throw "Tag $($lock.release_tag) does not resolve to the locked commit"
  }

  $pluginPath = Join-Path $workspacePath $lock.plugin_source_path
  if (-not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
    throw "Locked plugin path does not exist: $($lock.plugin_source_path)"
  }

  if (-not $SkipPatch) {
    $patchPath = Join-Path $root "patches/public-client.patch"
    if (-not (Test-Path -LiteralPath $patchPath -PathType Leaf)) {
      throw "Patch does not exist: $patchPath"
    }
    Invoke-Native git apply --check --whitespace=error-all $patchPath
    Invoke-Native git apply --whitespace=error-all $patchPath
  }
}
finally {
  Pop-Location
}

Write-Output $workspacePath
