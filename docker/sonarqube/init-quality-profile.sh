#!/usr/bin/env bash

set -e

SONAR_URL="${SONAR_URL:-http://localhost:9001}"
SONAR_USER="${SONAR_USER:-admin}"
SONAR_PASSWORD="${SONAR_PASSWORD:-admin}"

echo $SONAR_USER
echo $SONAR_PASSWORD

PROFILE_FILE="$(dirname "$0")/quality-profile.xml"

echo "Waiting for SonarQube..."

until curl -fsS "$SONAR_URL/api/system/status" | grep -q '"status":"UP"'; do
    sleep 2
done

echo "SonarQube is ready."

echo "Restoring UXCO quality profile..."

curl -fsS \
    -u "$SONAR_USER:$SONAR_PASSWORD" \
    -X POST \
    -F "backup=@${PROFILE_FILE}" \
    "$SONAR_URL/api/qualityprofiles/restore"

echo "Quality profile restored."