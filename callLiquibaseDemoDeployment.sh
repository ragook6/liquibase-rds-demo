#!/bin/bash
set -euo pipefail

# Where Liquibase is installed on the Jenkins server
LB_HOME="/var/lib/jenkins/liquibase"

# Jenkins workspace & changelog location
WORKSPACE_DIR="${WORKSPACE:-/var/lib/jenkins/workspace/liquibase-rds-demo}"
CHANGELOG_FILE="${WORKSPACE_DIR}/changelog/db.changelog-master.yaml"

# RDS secret info
SECRET_ID='rds!cluster-1cf6b26b-e9f5-46b8-a1fb-6933aba6d6c1'  # single quotes avoid '!' history issue
REGION='us-east-1'

echo "[INFO] Fetching DB credentials from Secrets Manager: $SECRET_ID"

# Get the secret JSON and store it in a temp file so we can debug it easily
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$REGION" \
  --query 'SecretString' \
  --output text > /tmp/liquibase-secret.json

echo "[DEBUG] Raw secret JSON from AWS:"
cat /tmp/liquibase-secret.json || echo "[DEBUG] (could not read temp file)"

SECRET_JSON=$(cat /tmp/liquibase-secret.json 2>/dev/null || echo "")

DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')
DB_PORT=$(echo "$SECRET_JSON" | jq -r '.port')
DB_NAME=$(echo "$SECRET_JSON" | jq -r '.dbname')
DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')

# Safety check so we don't try to connect with null values
if [[ -z "$SECRET_JSON" || "$DB_HOST" == "null" || -z "$DB_HOST" ]]; then
  echo "[ERROR] Failed to read database connection details from Secrets Manager."
  echo "[ERROR] SECRET_JSON='$SECRET_JSON'"
  exit 1
fi

echo "[INFO] Using host: $DB_HOST, port: $DB_PORT, db: $DB_NAME, user: $DB_USER"

JDBC_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

cd "$LB_HOME"

echo "[INFO] Running Liquibase update..."
bash ./liquibase \
  --url="$JDBC_URL" \
  --username="$DB_USER" \
  --password="$DB_PASS" \
  --driver=org.postgresql.Driver \
  --classpath="$LB_HOME/postgresql-42.2.8.jar" \
  --changeLogFile="$CHANGELOG_FILE" \
  update

echo "[INFO] Liquibase update completed successfully."
