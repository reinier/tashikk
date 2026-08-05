# Signed update stream

- **Status:** done (2026-08-05) — signing key + policy in place
- **Created:** 2026-08-05
- **Area:** image (`Containerfile` policy + CI signing) — security
- **Depends:** 0000
- **Related:** Steen's `0001` (the proven signed-image bootstrap this ports from)

## What shipped

Tashikk verifies its own update stream (`ghcr.io/reinier/tashikk`):

- **Baked** `cosign.pub` + a `sigstoreSigned` `policy.json` entry (`patch-policy.py`) keyed on
  the `ghcr.io/reinier` namespace with `signedIdentity: matchRepository`, plus
  `files/tashikk-registries.yaml` enabling sigstore-attachment reads.
- **CI signs** the `:latest` push with the private key from the `SIGNING_SECRET` repo secret.

## Shared key with Steen (deliberate)

The `SIGNING_SECRET` is the **same private key as Steen**, so `cosign.pub` is identical. This
is a shared trust root, but **not** cross-repo authorization: `matchRepository` binds each
signature to the exact repo it was made for, so a Steen signature (identity
`ghcr.io/reinier/steen`) cannot satisfy a Tashikk pull, and vice-versa. One key to manage, no
weakening of per-image trust.

## Verification

- CI push log shows `--sign-by-sigstore-private-key` ran and `Storing signatures` succeeded.
- On hardware: `bootc switch ghcr.io/reinier/tashikk:latest` verifies against the baked policy;
  every subsequent `bootc upgrade` is signature-enforced. (First rebase from Silverblue is
  still TOFU — the *source* system's policy doesn't require our key; enforcement takes over
  once on Tashikk.)
- Negative: an unsigned push would now be **rejected** by the baked policy (CI warns loudly if
  `SIGNING_SECRET` is ever unset).
