#!/bin/bash
set -euo pipefail

LB_HOME="/var/lib/jenkins/liquibase"
CHANGELOG_FILE="changelog/db.changelog-master.yaml"

SECRET_ID="rds!cluster-1cf6b26b-e9f5-46b8-a1fb-6933aba6d6c1"
REGION="us-east-1"

echo "[INFO] Fetching DB credentials from Secrets Manager: $SECRET_ID"

SECRET_JSON=$(aws secretsmanager get-secret-value       --secret-id "$SECRET_ID"       --region "$REGION"       --query SecretString       --output text)

DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')
DB_PORT=$(echo "$SECRET_JSON" | jq -r '.port')
DB_NAME=$(echo "$SECRET_JSON" | jq -r '.dbname')
DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')

echo "[INFO] Using host: $DB_HOST, port: $DB_PORT, db: $DB_NAME, user: $DB_USER"

JDBC_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

cd "$LB_HOME"

echo "[INFO] Running Liquibase update..."
bash ./liquibase       --url="$JDBC_URL"       --username="$DB_USER"       --password="$DB_PASS"       --driver=org.postgresql.Driver       --classpath="$LB_HOME/postgresql-42.2.8.jar"       --changeLogFile="/var/lib/jenkins/workspace/liquibase-rds-demo/${CHANGELOG_FILE}"       update

echo "[INFO] Liquibase update completed successfully."
