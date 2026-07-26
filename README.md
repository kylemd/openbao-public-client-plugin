# OpenBao Public-Client JWT Plugin

This repository builds a separately registered OpenBao JWT authentication
plugin that supports OAuth/OIDC public clients using authorization code with
PKCE and no client secret.

It is a patch overlay, not an OpenBao source fork. Each build clones the exact
official `openbao/openbao` release recorded in `openbao.lock.json`, verifies
the commit, applies `patches/public-client.patch`, tests the JWT backend, and
builds a Linux AMD64 plugin.

For public clients, the overlay also supplies a neutral OpenBao user agent on
OIDC discovery and token requests when the caller did not set one. This avoids
provider edge filters that reject Go's default transport user agent without
adding provider-specific headers or endpoints to the plugin.

## Security Model

- Official OpenBao source is fetched from a pinned release tag and commit.
- The overlay patch is limited to the JWT backend and its tests.
- The external plugin is named `jwt-public-client`.
- The external mount is `auth/retailer-oidc/`.
- The built-in `auth/jwt` backend remains unchanged for rollback.
- CI may build and publish prerelease artifacts, but it cannot deploy to a live
  OpenBao server.
- Provider credentials, callbacks, token values, and reverse-engineering
  evidence never belong in this repository or CI logs.

OpenBao's contribution policy prohibits AI-generated upstream issues and code.
This AI-assisted overlay is for the owner's deployment and is not an upstream
contribution.

## Local Verification

PowerShell:

```powershell
pwsh ./scripts/Prepare-Upstream.ps1
pwsh ./scripts/Verify-Build.ps1 -SkipRace
```

Linux CI runs the authoritative test suite, race detector, vulnerability scan,
CodeQL analysis, Linux build, SBOM generation, and provenance attestation.
The upstream package currently contains a Unix-specific connection-error
assertion, so a complete Windows package run is expected to fail that one
upstream test; focused public-client and confidential-client tests still run
locally on Windows.

Generated artifacts are written under ignored `dist/`. Temporary upstream
source is written under ignored `.work/openbao/`.

See [`docs/maintenance.md`](docs/maintenance.md) for the update and repair
controls and [`docs/deployment.md`](docs/deployment.md) for promotion
invariants.

## Maintenance

The daily release watcher updates `openbao.lock.json` when OpenBao publishes a
stable release. A clean patch application and passing checks allow the lock
update to merge automatically. A failed update can invoke the Codex repair
workflow once and open a draft repair pull request.

Codex repair is disabled until both repository variable
`CODEX_REPAIR_ENABLED=true` and secret `OPENAI_API_KEY` are configured. Codex
never receives repository write credentials; a separate job opens the draft
pull request from a validated patch artifact.

## Deployment Gate

Do not install this plugin until the management repository's OpenBao
initialization, recovery-material custody, Raft snapshot, and restore-test
gates are complete. The built artifact's OpenBao base version must match the
live server version.
