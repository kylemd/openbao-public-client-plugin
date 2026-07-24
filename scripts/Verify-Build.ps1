[CmdletBinding()]
param(
  [string]$Workspace,
  [switch]$SkipPrepare,
  [switch]$SkipRace,
  [switch]$RequireVulnerabilityCheck
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

if (-not $SkipPrepare) {
  & (Join-Path $PSScriptRoot "Prepare-Upstream.ps1") -Workspace $workspacePath
  if ($LASTEXITCODE -ne 0) {
    throw "Preparing upstream source failed"
  }
}

$distPath = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $distPath | Out-Null
$package = "./$($lock.plugin_source_path)/..."
$commandPackage = "./$($lock.plugin_source_path)/cmd/jwt"

Push-Location $workspacePath
try {
  Invoke-Native go test $package -count=1
  Invoke-Native go vet $package

  if (-not $SkipRace) {
    Invoke-Native go test -race $package -count=1
  }

  $govulncheck = Get-Command govulncheck -ErrorAction SilentlyContinue
  if ($govulncheck) {
    Invoke-Native $govulncheck.Source $package
  }
  elseif ($RequireVulnerabilityCheck) {
    throw "govulncheck is required but was not found"
  }

  $artifactPath = Join-Path $distPath $lock.artifact_name
  $previousCgo = $env:CGO_ENABLED
  $previousGoos = $env:GOOS
  $previousGoarch = $env:GOARCH
  try {
    $env:CGO_ENABLED = "0"
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    Invoke-Native -FilePath go -Arguments @(
      "build",
      "-trimpath",
      "-ldflags=-s -w",
      "-o",
      $artifactPath,
      $commandPackage
    )
  }
  finally {
    $env:CGO_ENABLED = $previousCgo
    $env:GOOS = $previousGoos
    $env:GOARCH = $previousGoarch
  }
}
finally {
  Pop-Location
}

$artifact = Join-Path $distPath $lock.artifact_name
$hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumPath = "$artifact.sha256"
"$hash  $($lock.artifact_name)" | Set-Content -LiteralPath $checksumPath -Encoding ascii

$manifest = [ordered]@{
  schema_version = 1
  upstream_slug = $lock.upstream_slug
  release_tag = $lock.release_tag
  release_commit = $lock.release_commit
  patch_revision = $lock.patch_revision
  plugin_source_path = $lock.plugin_source_path
  artifact_name = $lock.artifact_name
  sha256 = $hash
}
$manifest | ConvertTo-Json | Set-Content `
  -LiteralPath (Join-Path $distPath "source-manifest.json") `
  -Encoding utf8

Write-Output $artifact
