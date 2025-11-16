#!/bin/bash
set -euo pipefail

# Where Liquibase is installed on the Jenkins server
LB_HOME="/var/lib/jenkins/liquibase"

# Jenkins workspace (where the repo is checked out)
WORKSPACE_DIR="${WORKSPACE:-/var/lib/jenkins/workspace/liquibase-rds-demo}"
CHANGELOG_FILE="changelog/db.changelog-master.yaml"

# RDS secret info (contains ONLY username and password)
SECRET_ID='rds!cluster-1cf6b26b-e9f5-46b8-a1fb-6933aba6d6c1'
REGION='us-east-1'

echo "[INFO] Using WORKSPACE: $WORKSPACE_DIR"

echo "[INFO] Fetching DB credentials from Secrets Manager: $SECRET_ID"
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$REGION" \
  --query 'SecretString' \
  --output text)

echo "[DEBUG] Raw secret JSON from AWS:"
echo "$SECRET_JSON"

DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')

# Aurora connection details (since secret has only user/pass)
DB_HOST="dbdevopsaurora-instance-1.c0x0408m8e23.us-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_NAME="postgres"

if [[ -z "$DB_USER" || "$DB_USER" == "null" ]]; then
  echo "[ERROR] Could not read username from secret."
  exit 1
fi

if [[ -z "$DB_PASS" || "$DB_PASS" == "null" ]]; then
  echo "[ERROR] Could not read password from secret."
  exit 1
fi

echo "[INFO] Using host: $DB_HOST, port: $DB_PORT, db: $DB_NAME, user: $DB_USER"

JDBC_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Move into the workspace so we can use relative changelog path
cd "$WORKSPACE_DIR"

echo "[INFO] Checking for changelog file: $CHANGELOG_FILE"
if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "[ERROR] Changelog file not found at: $WORKSPACE_DIR/$CHANGELOG_FILE"
  ls -R .
  exit 1
fi

echo "[INFO] Running Liquibase update from workspace..."
bash "$LB_HOME/liquibase" \
  --url="$JDBC_URL" \
  --username="$DB_USER" \
  --password="$DB_PASS" \
  --driver=org.postgresql.Driver \
  --classpath="$LB_HOME/postgresql-42.2.8.jar" \
  --changeLogFile="$CHANGELOG_FILE" \
  update

echo "[INFO] Liquibase update completed successfully."
