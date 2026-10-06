# Trivy

Scans the repository for known vulnerabilities in dependencies and for misconfigurations (Dockerfile, Docker Compose, Kubernetes, Terraform, …).

- **Compose file:** [docker/trivy/docker-compose.trivy.yml](../docker/trivy/docker-compose.trivy.yml)
- **Image:** `aquasec/trivy:0.75.0`
- **Profile:** `security`
- **Used by:** the `pre-push` hook (commented out by default)

## Service

| Service | Description |
| ------- | ----------- |
| `trivy` | Filesystem scan (`trivy fs`) of the analyzed project (`STACK_PROJECT_ROOT`, the repository root by default), mounted read-only at `/src` |

Default scan options:

| Option | Value | Meaning |
| ------ | ----- | ------- |
| `--scanners` | `vuln,misconfig` | Vulnerable dependencies and misconfigurations |
| `--severity` | `HIGH,CRITICAL` | Only high and critical issues are reported |
| `--exit-code` | `1` | The command fails when an issue is found |

The vulnerability database is cached in the `trivy_cache` volume, so only the first run downloads it.

## Commands

Run the scan:

```bash
docker compose --profile security run --rm trivy
```

Override the options (the arguments replace the default command):

```bash
docker compose --profile security run --rm trivy \
  fs --scanners vuln --severity MEDIUM,HIGH,CRITICAL /src
```

Scan a Docker image instead of the files:

```bash
docker compose --profile security run --rm trivy image nginx:latest
```

> [!NOTE]
> Scanning a **local** image requires access to the Docker daemon. Add `-v /var/run/docker.sock:/var/run/docker.sock` to the `run` command only when needed.

Clear the vulnerability database cache:

```bash
docker volume ls | grep trivy_cache
docker volume rm <volume-name>
```

## Enabling Trivy Before Each Push

Uncomment the Trivy block in [git-hooks/pre-push](../git-hooks/pre-push):

```sh
docker compose --profile security run --rm -T trivy
```

## Ignoring Findings

Create a `.trivyignore` file at the repository root with one vulnerability ID or misconfiguration ID per line:

```text
# Not exploitable: the affected function is not used
CVE-2024-12345
```

Trivy reads it automatically, as the repository root is the working directory.
