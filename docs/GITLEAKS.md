# Gitleaks

Detects secrets (API keys, tokens, passwords, private keys) committed in the repository.

- **Compose file:** [docker/gitleaks/docker-compose.gitleaks.yml](../docker/gitleaks/docker-compose.gitleaks.yml)
- **Image:** `ghcr.io/gitleaks/gitleaks:v8.30.1`
- **Profile:** `security`
- **Used by:** the `pre-commit` hook

## Services

| Service            | Scans                                 | Typical use                  |
| ------------------ | ------------------------------------- | ---------------------------- |
| `gitleaks`         | Current files only (`--no-git`)       | `pre-commit` hook, local run |
| `gitleaks-history` | Every commit in the Git history       | Audit, CI                    |

Both services mount the analyzed project (`STACK_PROJECT_ROOT`, the repository root by default) read-only at `/repo`, and the stack configuration read-only at `/stack`.

## Commands

Scan the current files:

```bash
docker compose --profile security run --rm gitleaks
```

Scan the full Git history:

```bash
docker compose --profile security run --rm gitleaks-history
```

The exit code is `1` when a leak is found, `0` otherwise:

```bash
docker compose --profile security run --rm gitleaks; echo $?
```

## Configuration

| File | Purpose |
| ---- | ------- |
| [docker/gitleaks/.gitleaks.toml](../docker/gitleaks/.gitleaks.toml) | Rules and allowlists |
| [docker/gitleaks/.gitleaksignore](../docker/gitleaks/.gitleaksignore) | Ignored findings (confirmed false positives) |

### Project override

A `.gitleaks.toml` or `.gitleaksignore` at the root of the analyzed project takes precedence over the stack default (each file independently). The file used is printed at startup (`gitleaks config: ...`).

To keep the stack rules and only add project rules, extend the stack config from the project's `.gitleaks.toml`:

```toml
[extend]
path = "/stack/gitleaks/.gitleaks.toml"

[[rules]]
id = "my-service-token"
# ...
```

### Rules

`.gitleaks.toml` enables the [default gitleaks rules](https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml) (`useDefault = true`) and adds one generic rule:

- `env-secret-assignment` — a variable named `*_SECRET`, `*_TOKEN`, `*_PASSWORD`, `*_API_KEY`, `*_PRIVATE_KEY`… assigned a literal value in a configuration file (`.env*`, YAML, TOML, INI, shell, Dockerfile). The name must end with the keyword (`ECCO_TOKEN_GRANT_TYPE` is not matched), and values containing a variable reference (`$ENV`, `${VAR}`, `${{ secrets.X }}`) are ignored, so CI files (Bitbucket Pipelines, GitHub Actions) do not trigger it.

Project-specific rules can be added as new `[[rules]]` blocks:

```toml
[[rules]]
id = "my-service-token"
description = "My service token"
regex = '''mysvc_[A-Za-z0-9]{32}'''
keywords = ["mysvc_"]
```

### Allowlists

Not scanned:

- lock files (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `composer.lock`, …)
- `node_modules/`, `vendor/`, `dist/`, `build/`, `.next/`, `coverage/`
- local `.env` files (`.env`, `.env.local`, …) — they must never be committed

Ignored values:

- template variables: `{{token}}`, `${TOKEN}`
- truncated examples: `sk-...`
- values containing a stopword: `change-me`, `example`, `your-`, `placeholder`, `xxxx`, `dummy`, …

### Ignoring a false positive

1. Run the scan and copy the `Fingerprint` of the finding (`commit:file:rule:line`).
2. Add it to `.gitleaksignore`, with a comment explaining why it is not a real secret.

> [!WARNING]
> If the secret is real, ignoring it is not enough: revoke it and rotate it. It remains in the Git history.
