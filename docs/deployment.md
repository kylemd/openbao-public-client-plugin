# Deployment

This repository does not deploy the plugin. Promote a verified artifact only
after the management repository's initialization, backup, and restore gates
are complete.

## Invariants

- The live OpenBao server release must equal the artifact's
  `source-manifest.json` release.
- Verify the artifact SHA-256 and GitHub provenance before copying it.
- Register the binary as the external plugin `jwt-public-client`.
- Mount it at `auth/retailer-oidc/`.
- Leave built-in `auth/jwt` enabled and unchanged for rollback.
- Keep provider configuration and all token material outside Git and CI.

Follow the management repository's OpenBao change log, backup, health-check,
and rollback procedures for the actual registration and mount commands.
