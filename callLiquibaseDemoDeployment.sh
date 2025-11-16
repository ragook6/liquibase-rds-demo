#!/bin/bash
set -euo pipefail

LB_HOME="/var/lib/jenkins/liquibase"
WORKSPACE_DIR="${WORKSPACE:-/var/lib/jenkins/workspace/liquibase-rds-demo}"
CHANGELOG_FILE="changelog/db.changelog-master.yaml"

# RDS secret info (username + password only)
SECRET_ID='rds!cluster-1cf6b26b-e9f5-46b8-a1fb-6933aba6d6c1'
REGION='us-east-1'

# Liquibase action: 'update' (deploy) or 'rollback'
ACTION="${LB_ACTION:-update}"   # default to update if not set

echo "[INFO] Using WORKSPACE: $WORKSPACE_DIR"
echo "[INFO] Liquibase ACTION: $ACTION"

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

# Aurora connection details
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

cd "$WORKSPACE_DIR"

echo "[INFO] Checking for changelog file: $CHANGELOG_FILE"
if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "[ERROR] Changelog file not found at: $WORKSPACE_DIR/$CHANGELOG_FILE"
  ls -R .
  exit 1
fi

# Liquibase action: 'update' (deploy) or 'rollback'
ACTION="${LB_ACTION:-update}"   # default to update if not set

echo "[INFO] Liquibase ACTION: $ACTION"


# Decide Liquibase command based on ACTION
LB_CMD=""
LB_ARGS=""

case "$ACTION" in
  update)
    LB_CMD="update"
    LB_ARGS=""
    ;;
  rollback)
    LB_CMD="rollbackCount"
    LB_ARGS="1"
    ;;
  *)
    echo "[ERROR] Unknown ACTION '$ACTION'. Use 'update' or 'rollback'."
    exit 1
    ;;
esac

echo "[INFO] Running Liquibase: $LB_CMD $LB_ARGS ..."
bash "$LB_HOME/liquibase" \
  --url="$JDBC_URL" \
  --username="$DB_USER" \
  --password="$DB_PASS" \
  --driver=org.postgresql.Driver \
  --classpath="$LB_HOME/postgresql-42.2.8.jar" \
  --changeLogFile="$CHANGELOG_FILE" \
  $LB_CMD $LB_ARGS

echo "[INFO] Liquibase $ACTION completed successfully."
