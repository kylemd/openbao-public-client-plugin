[CmdletBinding()]
param(
  [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "OpenBaoOverlay.psm1") -Force

$root = Get-OverlayRoot
$lockPath = Join-Path $root "openbao.lock.json"
$lock = Get-OpenBaoLock
$headers = @{
  Accept = "application/vnd.github+json"
  "X-GitHub-Api-Version" = "2022-11-28"
  "User-Agent" = "openbao-public-client-plugin"
}
$release = Invoke-RestMethod `
  -Uri "https://api.github.com/repos/$($lock.upstream_slug)/releases/latest" `
  -Headers $headers

if ($release.draft -or $release.prerelease) {
  throw "GitHub returned a non-stable release as latest"
}
if ($release.tag_name -eq $lock.release_tag) {
  Write-Output "current"
  exit 0
}

$tempRoot = Assert-SafeWorkspace (Join-Path $root ".work/release-check")
if (Test-Path -LiteralPath $tempRoot) {
  Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

Invoke-Native git init $tempRoot
Invoke-Native git -C $tempRoot remote add origin $lock.upstream_url
Invoke-Native git -C $tempRoot fetch --depth 1 origin "refs/tags/$($release.tag_name)"

$commit = (& git -C $tempRoot rev-parse FETCH_HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch "^[0-9a-f]{40}$") {
  throw "Unable to resolve the latest release commit"
}

$goVersion = (& git -C $tempRoot show "$commit`:.go-version").Trim()
if ($LASTEXITCODE -ne 0 -or -not $goVersion) {
  throw "Unable to read .go-version from $commit"
}

$treePaths = @(& git -C $tempRoot ls-tree -r --name-only $commit)
if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect the release tree"
}
$pluginPath = @(
  "internal/builtin/credential/jwt",
  "builtin/credential/jwt"
) | Where-Object {
  $treePaths -contains "$($_)/path_config.go"
} | Select-Object -First 1
if (-not $pluginPath) {
  throw "The release does not contain a recognized JWT backend path"
}

if ($CheckOnly) {
  Write-Output "$($release.tag_name) $commit $pluginPath $goVersion"
  exit 2
}

$lock.release_tag = $release.tag_name
$lock.release_commit = $commit
$lock.plugin_source_path = $pluginPath
$lock.go_version = $goVersion
$lock | ConvertTo-Json | Set-Content -LiteralPath $lockPath -Encoding utf8
Write-Output "updated"
