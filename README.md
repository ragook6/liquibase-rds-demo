# Liquibase RDS Demo

This project demonstrates database schema deployments to Amazon Aurora PostgreSQL using:

- Jenkins Pipeline
- Liquibase
- AWS Secrets Manager
- Amazon RDS (Aurora PostgreSQL)

## Structure

- `Jenkinsfile` – Jenkins Pipeline as Code.
- `callLiquibaseDemoDeployment.sh` – Shell script that:
  - Fetches DB credentials from AWS Secrets Manager.
  - Builds JDBC URL.
  - Calls Liquibase to apply changes.
- `changelog/db.changelog-master.yaml` – Root Liquibase changelog.
- `changelog/changes/001-create-student-table.yaml` – Example change that creates a `student` table.

## Usage (high level)

1. Jenkins clones this repo.
2. Jenkins runs `callLiquibaseDemoDeployment.sh`.
3. Script reads DB credentials from Secrets Manager and runs Liquibase.
4. Liquibase applies the changelog to your Aurora PostgreSQL database.
