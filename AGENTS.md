# Agent Instructions

This repository is a patch overlay for the OpenBao JWT authentication backend.
It does not vendor OpenBao source.

## Workflow

1. Read `openbao.lock.json`.
2. Run `scripts/Prepare-Upstream.ps1` to create a verified checkout under
   ignored `.work/openbao`.
3. Make JWT-backend changes only in that checkout.
4. Run `scripts/New-Patch.ps1` to regenerate
   `patches/public-client.patch`.
5. Run `scripts/Verify-Build.ps1` on Linux or GitHub Actions.

Never edit the patch by hand when a source checkout can generate it.

## Boundaries

- Keep changes within `builtin/credential/jwt/` or
  `internal/builtin/credential/jwt/`.
- Do not modify OpenBao dependency manifests, workflows, server packages, or
  unrelated backends to make the patch apply.
- Do not add retailer names, endpoints, client IDs, tokens, device identifiers,
  captures, or provider secrets.
- Do not replace the built-in `auth/jwt` mount. The external plugin is
  registered as `jwt-public-client` at `auth/retailer-oidc/`.
- Do not deploy to a live OpenBao server from CI.

## Upstream Policy

OpenBao prohibits AI-generated upstream issues and contributions. AI-assisted
work in this repository must not be submitted to `openbao/openbao`. Upstream
research may inform expected behavior, but implementation changes must remain
in this independently maintained overlay.

## Completion

A change is complete only when the patch applies to the exact locked commit,
the public and confidential client tests pass on Linux, the full JWT package
tests pass, vulnerability checks are reviewed, and a Linux AMD64 artifact plus
checksum and source manifest are produced.
