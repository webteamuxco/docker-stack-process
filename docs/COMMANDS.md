# Git Hooks — Commands

Detailed documentation for each tool: [Gitleaks](GITLEAKS.md) · [Trivy](TRIVY.md) · [SonarQube](SONARQUBE.md) · [Commitlint](COMMITLINT.md) · [git-cliff](CLIFF.md)

## Prerequisite: Docker Compose Setup

All commands below are run from the repository root. The root `compose.yaml` (or `docker-compose.yml`) must include the stack:

```yaml
include:
  - docker-compose.stack.yml
```

If the project has no compose file, create a `compose.yaml` at the root with this content. Otherwise, add the entry to the existing file's `include` section.

When the stack is a submodule (for example in `tools/docker-stack-process/`), include `tools/docker-stack-process/docker-compose.stack.yml` instead, and set `STACK_PROJECT_ROOT` in the root `.env` (see the README, *Installing as a Git Submodule*). Scripts are then run as `./tools/docker-stack-process/install-hooks.sh`.

Check the setup:

```bash
docker compose --profile security config --services
```

---

## Installing Native Git Hooks

Installs wrappers in `.git/hooks/` that call the hooks from `git-hooks/`.

```bash
chmod +x install-hooks.sh
./install-hooks.sh
```

Check the installed hooks:

```bash
ls -la .git/hooks/
```

---

## Installing With Husky

If the project uses Husky, register the hooks from `git-hooks/` in `.husky/`.

```bash
chmod +x init-husky.sh
./init-husky.sh
```

Check the Husky hooks:

```bash
ls -la .husky/
```

---

## Gitleaks

Scan the project files for secrets:

```bash
docker compose --profile security run --rm gitleaks
```

Also scan the Git history:

```bash
docker compose --profile security run --rm gitleaks-history
```

Check the exit code:

```bash
docker compose --profile security run --rm gitleaks; echo $?
```

---

## Trivy

Run the Trivy security scan:

```bash
docker compose --profile security run --rm trivy
```

---

## SonarQube

Start SonarQube and its database:

```bash
docker compose --profile security up -d sonarqube sonar_db
```

Run the analysis:

```bash
docker compose --profile security run --rm sonar-scanner
```

The scanner waits until SonarQube is healthy. It analyzes the repository root by default; set `SONAR_PROJECT_DIR` to an absolute path to analyze another directory.

Stop SonarQube:

```bash
docker compose --profile security down
```

---

## Commitlint

Check the last commit:

```bash
docker compose --profile security run --rm commitlint
```

Check a specific commit message:

```bash
docker compose --profile security run --rm commitlint \
  --edit /repo/.git/COMMIT_EDITMSG
```

---

## git-cliff

Generate the changelog:

```bash
docker compose --profile security run --rm cliff
```

Preview the result without modifying the file:

```bash
docker compose --profile security run --rm cliff \
  --config /stack/cliff/cliff.toml
```

Explicitly generate `CHANGELOG.md`:

```bash
docker compose --profile security run --rm cliff \
  --config /stack/cliff/cliff.toml \
  --output /repo/CHANGELOG.md
```

---

## Docker Compose

List the available services:

```bash
docker compose config --services
```

Start all services in the `security` profile:

```bash
docker compose --profile security up
```

Start the services in the background:

```bash
docker compose --profile security up -d
```

Show the container status:

```bash
docker compose ps
```

Show the logs:

```bash
docker compose logs -f
```

Stop the services:

```bash
docker compose --profile security down
```

---

## Adding a New Hook

Create the hook in:

```text
git-hooks/
```

Example:

```text
git-hooks/pre-push
```

Make it executable:

```bash
chmod +x git-hooks/pre-push
```

Then reinstall the hooks:

### Native Git

```bash
./install-hooks.sh
```

### Husky

```bash
./init-husky.sh
```

---

## Checking Active Git Hooks

Check the path used by Git:

```bash
git config --get core.hooksPath
```

If no value is returned, Git uses the default:

```text
.git/hooks/
```

If a value is returned, Git uses that directory instead.

With Husky, it is common to get:

```text
.husky/_
```

In that case, hooks placed directly in `.git/hooks/` will not be executed.

---

## Testing a Hook

Create a test commit:

```bash
git commit -m "chore: test git hooks"
```

Or run a hook directly:

```bash
.git/hooks/pre-commit
```

With Husky:

```bash
.husky/pre-commit
```

---

## Recommended Architecture

Reusable hooks should stay in:

```text
git-hooks/
```

The installation mechanisms remain separate:

```text
.
├── git-hooks/
│   ├── pre-commit
│   ├── commit-msg
│   └── pre-push
├── install-hooks.sh
└── init-husky.sh
```

This way, the same hook can be used with:

```text
Native Git
    ↓
.git/hooks/

or

Husky
    ↓
.husky/
```

The hook's business logic remains independent from Husky and can call the project's Docker tools.
