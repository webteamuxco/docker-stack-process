# SonarQube

Static code analysis: bugs, code smells, security hotspots, duplication and coverage.

- **Compose file:** [docker/sonarqube/docker-compose.sonarqube.yml](../docker/sonarqube/docker-compose.sonarqube.yml)
- **Profile:** `security`
- **Used by:** the `pre-push` hook (commented out by default)

## Services

| Service | Image | Description |
| ------- | ----- | ----------- |
| `sonarqube` | `sonarqube:26.9.0.129388-community` | SonarQube server, exposed on `http://localhost:9001` |
| `sonar_db` | `postgres:13` | SonarQube database |
| `sonar-scanner` | `sonarsource/sonar-scanner-cli:12` | Analyzes the code and sends the results to the server |
| `sonar-badges` | `curlimages/curl:latest` | Downloads the project badges (SVG) into the repository |

Startup order is handled by healthchecks: `sonar_db` → `sonarqube` (status `UP`) → `sonar-scanner`.

Data is kept in named volumes (`sonarqube_data`, `sonar_db_data`, …) and survives `docker compose down`.

## Environment Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `SONAR_PORT` | `9001` | Host port of the SonarQube web UI |
| `SONAR_TOKEN` | *(empty)* | Token used by the scanner to authenticate |
| `SONAR_PROJECT_DIR` | `STACK_PROJECT_ROOT` | Directory to analyze (use an absolute path) |
| `SONAR_USER` / `SONAR_PASSWORD` | `admin` / `admin` | Account used by `sonar-badges` to read the project badge token |
| `SONAR_PROJECT_KEY` | `sonar.projectKey` of `sonar-project.properties` | Project whose badges are generated |
| `SONAR_BADGES_DIR` | `reports/sonarqube/badges` | Output directory of the badges, relative to the project |
| `SONAR_BADGE_METRICS` | `coverage bugs vulnerabilities code_smells security_hotspots duplicated_lines_density ncloc sqale_rating reliability_rating security_rating` | Space-separated metrics to export (the quality gate badge is always generated) |
| `STACK_PROJECT_ROOT` | repository root | Project analyzed by all the tools (set automatically by the hooks; see the README for submodules) |

They can be set in the shell or in a `.env` file at the repository root.

## First Setup

1. Start the server:

   ```bash
   docker compose --profile security up -d sonarqube sonar_db
   ```

2. Open `http://localhost:9001` and log in with `admin` / `admin`. SonarQube asks to change the password.

3. Create a project, then generate a token: **My Account → Security → Generate Tokens**.

4. Store the token in the root `.env` file (never commit it):

   ```dotenv
   SONAR_TOKEN=squ_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

5. Create `sonar-project.properties` at the repository root:

   ```properties
   sonar.projectKey=my-project
   sonar.projectName=My Project
   sonar.sources=.
   sonar.exclusions=**/node_modules/**,**/vendor/**,**/dist/**,**/build/**
   ```

## Commands

Run the analysis (starts the server if needed and waits until it is ready):

```bash
docker compose --profile security run --rm sonar-scanner
```

Generate the badges from the last analysis:

```bash
docker compose --profile security run --rm sonar-badges
```

Follow the server logs:

```bash
docker compose logs -f sonarqube
```

Stop the server:

```bash
docker compose --profile security stop sonarqube sonar_db
```

Delete all SonarQube data:

```bash
docker compose --profile security down -v
```

> [!WARNING]
> `down -v` removes **every** volume of the stack, including the Trivy cache.

## Badges

SonarQube stays local, so badge URLs pointing to `http://localhost:9001` cannot be rendered by GitHub or by anyone else. Instead, `sonar-badges` downloads them as SVG files into `reports/sonarqube/badges/`, to be committed and referenced with relative paths:

```markdown
![Quality Gate](reports/sonarqube/badges/quality_gate.svg)
![Coverage](reports/sonarqube/badges/coverage.svg)
```

The badges are refreshed after every analysis run by the `pre-push` hook and by `make test-stack`, even when the quality gate fails. They reflect the analysis of the pushed code, so they show up as modified files to commit with the next change.

The script reads the project badge token (`/api/project_badges/token`) with `SONAR_USER` / `SONAR_PASSWORD`, so it works whatever the project visibility. `SONAR_TOKEN` cannot be used: an analysis token is not allowed to read it.

## Troubleshooting

**SonarQube stops right after starting** (`max virtual memory areas vm.max_map_count [65530] is too low`)

SonarQube's embedded Elasticsearch needs a higher limit on the host:

```bash
sudo sysctl -w vm.max_map_count=524288
```

On WSL2, add it to `%UserProfile%\.wslconfig`:

```ini
[wsl2]
kernelCommandLine = "sysctl.vm.max_map_count=524288"
```

**The scanner fails with `Not authorized`**

`SONAR_TOKEN` is missing or invalid. Generate a new token and update `.env`.

**The scanner waits for a long time**

The first start of SonarQube takes 1 to 2 minutes. Check progress with `docker compose logs -f sonarqube`.
