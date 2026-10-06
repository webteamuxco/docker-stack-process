# git-cliff

Generates `CHANGELOG.md` from the Conventional Commits history.

- **Compose file:** [docker/cliff/docker-compose.cliff.yml](../docker/cliff/docker-compose.cliff.yml)
- **Image:** `orhunp/git-cliff:2.13.1`
- **Profile:** `security`
- **Used by:** run manually (not called by a hook)

## Service

| Service | Description |
| ------- | ----------- |
| `cliff` | Writes `CHANGELOG.md` at the repository root |

The analyzed project (`STACK_PROJECT_ROOT`, the repository root by default) is mounted read-write at `/repo`, so the changelog can be written. The stack configuration is mounted read-only at `/stack`.

The container runs with the host user ID (`UID`/`GID`, default `1000`). This avoids the libgit2 "dubious ownership" error and keeps `CHANGELOG.md` editable on the host. If your user ID is not `1000`, export it before running:

```bash
export UID GID=$(id -g)
```

## Commands

Generate `CHANGELOG.md`:

```bash
docker compose --profile security run --rm cliff
```

Preview the changelog in the terminal without writing the file:

```bash
docker compose --profile security run --rm cliff \
  --config /stack/cliff/cliff.toml
```

Preview only the unreleased changes:

```bash
docker compose --profile security run --rm cliff \
  --config /stack/cliff/cliff.toml \
  --unreleased
```

Generate the changelog for a new version before tagging it:

```bash
docker compose --profile security run --rm cliff \
  --config /stack/cliff/cliff.toml \
  --tag v1.2.0 \
  --output CHANGELOG.md
```

## Versions

Versions come from Git tags matching `v[0-9]*` (e.g. `v1.2.3`). Commits after the last tag are listed under **Unreleased**.

```bash
git tag v1.2.0
git push origin v1.2.0
```

## Configuration

[docker/cliff/cliff.toml](../docker/cliff/cliff.toml):

- Only conventional commits are included (`filter_unconventional = true`).
- Sections by commit type:

  | Type | Section |
  | ---- | ------- |
  | `feat` | 🚀 Features |
  | `fix` | 🐛 Bug Fixes |
  | `perf` | ⚡ Performance |
  | `refactor` | ♻️ Refactoring |
  | `docs` | 📚 Documentation |
  | `test` | 🧪 Tests |
  | `build` | 📦 Build & Dependencies |
  | `ci` | ⚙️ CI/CD |
  | `revert` | ⏪ Reverts |
  | `style`, `chore` | *(not included)* |

- The `<!-- N -->` prefix in each group name sets the section order. It is removed from the output.

### Linking Ticket References

To turn `(PROJ-123)` scopes into links, uncomment and adapt the `postprocessors` example in `cliff.toml`:

```toml
postprocessors = [
  { pattern = '\(PROJ-(\d+)\)', replace = "([PROJ-${1}](https://tracker.example.com/browse/PROJ-${1}))" },
]
```
