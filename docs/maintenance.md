# Maintenance

## Release Tracking

`Upstream Watch` runs daily and compares `openbao.lock.json` with GitHub's
latest stable OpenBao release. A new release produces an `automation/*` branch
and pull request. Auto-merge is requested only after the overlay patch applies
and the local verification gate passes; branch protection keeps merge waiting
for the full `Verify` workflow.

The lock records both the release tag and its resolved commit. Builds refuse a
tag that does not resolve to that commit.

## Verification Gate

The `Verify` workflow performs:

- Fresh clone and commit verification.
- Patch application with whitespace checks.
- JWT backend tests, race detection, and `go vet`.
- `govulncheck` and CodeQL.
- Linux AMD64 build, SHA-256, source manifest, and SPDX JSON SBOM.
- GitHub artifact provenance attestation.

Main-branch builds publish a prerelease identified by the OpenBao release and
overlay patch revision. Artifacts are never deployed automatically.

## Codex Repair

Codex repair is off by default. Enable it only after adding the
`OPENAI_API_KEY` Actions secret and setting repository variable
`CODEX_REPAIR_ENABLED` to `true`.

The repair job has read-only GitHub permissions and loses `sudo` before Codex
runs. Dependencies and the exact upstream source are prepared first. Codex may
write only in the disposable JWT source checkout. The workflow then enforces
the allowed path and patch-size limits, regenerates the overlay patch, and
reruns verification.

A separate job with no API key receives only the validated patch artifact and
opens a draft pull request against the failed update branch. If repair is
disabled or fails, the workflow opens or updates a maintenance issue.

## Human Review

Do not merge when:

- OpenBao and the plugin artifact are based on different releases.
- Security scans are incomplete or unexplained.
- The patch expands beyond the JWT backend.
- Public-client tests no longer prove S256 PKCE and an unauthenticated token
  request.
- Confidential-client regression tests fail.
