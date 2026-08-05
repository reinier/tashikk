# Signed update stream (deferred — needs a keypair)

- **Status:** deferred (blocked on a signing keypair + CI secret)
- **Created:** 2026-08-05
- **Area:** image (`Containerfile` policy + CI signing) — security
- **Depends:** 0000
- **Related:** Steen's `0001` (the proven signed-image bootstrap this ports from)

## Why deferred

Steen bakes a `cosign.pub` + a `sigstoreSigned` `policy.json` entry that *requires* every
update to `ghcr.io/reinier/steen` be signed, and CI signs the push with a private key from the
`SIGNING_SECRET` secret. Tashikk needs the same, but it requires a **Tashikk-specific keypair**
that doesn't exist yet, and only the repo owner can set the `SIGNING_SECRET` GitHub secret.

Until that's done, Tashikk ships **unsigned**: the Containerfile bakes **no** requiring policy,
CI pushes unsigned (with a warning), and the first `bootc switch` is **trust-on-first-use**.
This is safe for a personal WIP but should be closed before daily-driving.

## Implementation (when the key exists)

1. Generate a passphrase-less cosign keypair (`cosign generate-key-pair`), commit `cosign.pub`
   to the repo, set the private key as the `SIGNING_SECRET` repo secret. **Never commit the
   private key.**
2. Port Steen's policy machinery: `patch-policy.py` (adds the `sigstoreSigned` entry for
   `ghcr.io/reinier/tashikk`) + `files/tashikk-registries.yaml` (enables sigstore attachment
   reads), and the `COPY cosign.pub /usr/share/pki/containers/` + `RUN patch-policy.py` block.
3. The CI already signs when `SIGNING_SECRET` is present (ported from Steen) — no CI change
   needed beyond setting the secret.

## Verification

- After the key is set: a fresh push is signed; `bootc switch` to it verifies against the
  baked policy; a deliberately unsigned/tampered push is **rejected**.
