# Security

Report vulnerabilities privately through this repository's GitHub security
advisory interface. Do not place credentials, token material, custom provider
details, or live OpenBao logs in a public issue.

This repository builds from official OpenBao releases but is not supported by
the OpenBao project. OpenBao vulnerabilities should also be checked against
the upstream project's published security policy and advisories.

Artifacts are acceptable for promotion only when:

- The upstream tag resolves to the commit in `openbao.lock.json`.
- The overlay patch applies without fuzz or rejected hunks.
- Required tests and security checks pass.
- The artifact SHA-256, SBOM, and provenance are available.
- The artifact's OpenBao version matches the target server.

No workflow in this repository is authorized to deploy to a live OpenBao
server.
