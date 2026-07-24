Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-OverlayRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-OpenBaoLock {
  $lockPath = Join-Path (Get-OverlayRoot) "openbao.lock.json"
  return Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
}

function Invoke-Native {
  param(
    [Parameter(Mandatory)]
    [string]$FilePath,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath exited with code $LASTEXITCODE"
  }
}

function Assert-SafeWorkspace {
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  $root = Get-OverlayRoot
  $workRoot = [System.IO.Path]::GetFullPath((Join-Path $root ".work"))
  $resolved = [System.IO.Path]::GetFullPath($Path)
  $prefix = $workRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  ) + [System.IO.Path]::DirectorySeparatorChar

  if (-not $resolved.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Workspace must remain under $workRoot"
  }

  return $resolved
}

function Get-AllowedJwtPaths {
  return @(
    "builtin/credential/jwt/",
    "internal/builtin/credential/jwt/"
  )
}

Export-ModuleMember -Function @(
  "Get-OverlayRoot",
  "Get-OpenBaoLock",
  "Invoke-Native",
  "Assert-SafeWorkspace",
  "Get-AllowedJwtPaths"
)
