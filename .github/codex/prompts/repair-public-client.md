The daily OpenBao release update failed because the public-client JWT patch no
longer applies or its verification failed.

Work only in the prepared upstream checkout at `.work/openbao`.

Goals:

1. Preserve confidential-client behavior.
2. Permit an OIDC authorization-code client ID without a client secret.
3. Require PKCE using S256.
4. Send `client_id` and `code_verifier` to the token endpoint.
5. Never send an empty `client_secret` or an HTTP Basic authorization header
   for a public client.
6. Keep or adapt focused tests that prove the public-client exchange and the
   confidential-client regression behavior.

Constraints:

- Modify files only below the JWT backend path recorded in
  `openbao.lock.json`.
- Do not change dependency manifests, generated files, workflows, scripts, or
  the lock file.
- Do not weaken tests, skip security checks, add provider-specific behavior, or
  introduce credentials and real provider details.
- Do not submit anything to `openbao/openbao`.
- Keep the change narrowly scoped. The workflow rejects patches over 300
  changed lines.

Before finishing, run the focused JWT tests that cover the changed behavior.
The workflow will regenerate the overlay patch and perform full verification
after your work.
