#!/bin/sh

set -eu

SONAR_URL="${SONAR_URL:-http://localhost:9001}"
SONAR_USER="${SONAR_USER:-admin}"
SONAR_PASSWORD="${SONAR_PASSWORD:-admin}"
PROJECT_DIR="${PROJECT_DIR:-.}"
BADGES_DIR="${SONAR_BADGES_DIR:-reports/sonarqube/badges}"
METRICS="${SONAR_BADGE_METRICS:-coverage bugs vulnerabilities code_smells security_hotspots duplicated_lines_density ncloc sqale_rating reliability_rating security_rating}"

PROJECT_KEY="${SONAR_PROJECT_KEY:-}"
if [ -z "$PROJECT_KEY" ] && [ -f "$PROJECT_DIR/sonar-project.properties" ]; then
    PROJECT_KEY=$(sed -n 's/^sonar\.projectKey=[[:space:]]*//p' "$PROJECT_DIR/sonar-project.properties" | tr -d '\r' | head -n 1)
fi
[ -n "$PROJECT_KEY" ] || { echo "No project key: set SONAR_PROJECT_KEY or sonar.projectKey in sonar-project.properties." >&2; exit 1; }

# Credentials go through stdin (-K -) so they never show up in the process list.
api() {
    printf 'user = "%s:%s"\n' "$SONAR_USER" "$SONAR_PASSWORD" | curl -fsS -K - "$SONAR_URL$1"
}

# The project badge token works whatever the project visibility or the force-authentication setting.
BADGE_TOKEN=$(api "/api/project_badges/token?project=$PROJECT_KEY" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
[ -n "$BADGE_TOKEN" ] || { echo "Cannot get the badge token of $PROJECT_KEY (check SONAR_USER / SONAR_PASSWORD)." >&2; exit 1; }

OUT_DIR="$PROJECT_DIR/$BADGES_DIR"
mkdir -p "$OUT_DIR"

fetch() {
    tmp="$OUT_DIR/.$2.tmp"
    if curl -fsS -o "$tmp" "$SONAR_URL$1&token=$BADGE_TOKEN"; then
        mv "$tmp" "$OUT_DIR/$2.svg"
        echo "  $BADGES_DIR/$2.svg"
    else
        rm -f "$tmp"
        echo "  $2: failed" >&2
        return 1
    fi
}

echo "Generating SonarQube badges for $PROJECT_KEY..."
failed=0
fetch "/api/project_badges/quality_gate?project=$PROJECT_KEY" quality_gate || failed=1
for metric in $METRICS; do
    fetch "/api/project_badges/measure?project=$PROJECT_KEY&metric=$metric" "$metric" || failed=1
done

# Running as root in the container: hand the files back to the owner of the project.
if [ "$(id -u)" = 0 ]; then
    chown -R "$(stat -c '%u:%g' "$PROJECT_DIR")" "$OUT_DIR"
fi

exit "$failed"
