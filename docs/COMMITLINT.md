# Commitlint

Checks that commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).

- **Compose file:** [docker/commitlint/docker-compose.commitlint.yml](../docker/commitlint/docker-compose.commitlint.yml)
- **Image:** `commitlint/commitlint:21.2.3`
- **Profile:** `security`
- **Used by:** the `commit-msg` hook

## Service

| Service | Description |
| ------- | ----------- |
| `commitlint` | Lints commit messages. By default, it checks the last commit (`--last`). |

The analyzed project (`STACK_PROJECT_ROOT`, the repository root by default) is mounted read-only at `/repo`, and the stack configuration at `/commitlint.config.js`.

A `commitlint.config.js` (or `.cjs` / `.mjs`) at the root of the analyzed project takes precedence over the stack configuration. The file used is printed at startup (`commitlint config: ...`).

## Commit Format

```text
type(scope): subject
```

Examples:

```text
feat(auth): add password reset
fix(api): handle empty response
docs: update installation steps
```

The scope is optional. A ticket reference can be used as scope: `fix(PROJ-123): ...`.

Allowed types:

| Type | Usage |
| ---- | ----- |
| `feat` | New feature |
| `fix` | Bug fix |
| `perf` | Performance improvement |
| `refactor` | Refactoring without behavior change |
| `docs` | Documentation |
| `style` | Formatting, no code impact |
| `test` | Add or update tests |
| `build` | Build system, dependencies |
| `ci` | CI/CD pipelines |
| `chore` | Miscellaneous maintenance |
| `revert` | Revert a commit |

## Commands

Check the last commit:

```bash
docker compose --profile security run --rm commitlint
```

Check a range of commits:

```bash
docker compose --profile security run --rm commitlint \
  --from=origin/main \
  --to=HEAD
```

Check a message without committing:

```bash
echo "feat: my message" | docker compose --profile security run --rm -T commitlint --verbose
```

## Configuration

[docker/commitlint/commitlint.config.js](../docker/commitlint/commitlint.config.js) extends `@commitlint/config-conventional`:

- `type-enum` — the allowed types listed above. Keep it aligned with the groups in [cliff.toml](../docker/cliff/cliff.toml).
- `subject-case` — disabled: the subject case is not enforced.
- `body-max-line-length` — disabled: no limit on the body line length.

To add a type, add it to `type-enum`, then add the matching group in `cliff.toml` so it appears in the changelog.
