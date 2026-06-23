# PostgreSQL Automation - DataPlatform-Automation

## Overview

Fully portable, enterprise-grade PostgreSQL deployment framework running locally on Windows.
Tested via Jenkins. No Docker. No Kubernetes. No Cloud.

---

## Architecture

```
Jenkins Pipeline
      |
      v
Batch Scripts (.bat)
      |
      +---> PowerShell Scripts (.ps1)   [Service / Install / Validate]
      |
      +---> Python Scripts (.py)        [DB / Data / Validation]
      |
      +---> Liquibase (.xml)            [Schema Migrations]
      |
      +---> Terraform (.tf)             [Optional: Orchestration]
```

---

## Jenkins Pipelines

| Pipeline | Jenkinsfile | Purpose |
|---|---|---|
| Setup | `jenkins/postgresql/Jenkinsfile.setup` | Install PostgreSQL + run migrations |
| Load  | `jenkins/postgresql/Jenkinsfile.load`  | Generate datasets + load data |

---

## Setup Pipeline Stages

1. Repository Audit
2. Validate Python Runtime
3. Install Python Requirements
4. Validate Python Requirements
5. Validate Java Runtime
6. Install Tools (Liquibase + JDBC Driver)
7. Deploy PostgreSQL (install → start → create DB → run Liquibase)
8. Validate PostgreSQL

---

## Load Pipeline Stages

1. Repository Audit
2. Validate Environment
3. Generate Datasets (auto-generates CSVs if missing)
4. Validate CSV Schema
5. Load Data
6. Validate Loaded Data
7. Validate PostgreSQL

---

## Database

| Setting | Value |
|---|---|
| Database | DataManagementDB |
| Port | 5432 (auto-discovered) |
| User | postgres |
| Schema | public |

---

## Tables

| Table | Rows |
|---|---|
| customers | 100 |
| products | 100 |
| orders | 500 |
| sellers | 50 |
| orderdetails | 500 |

---

## Portability

All scripts use **dynamic discovery**. Nothing is hardcoded:

- PostgreSQL service discovered via `Get-Service *postgres*`
- Project root discovered via `%~dp0` and `$PSScriptRoot`
- JDBC driver discovered via wildcard `postgresql*.jar`
- Liquibase discovered in `tools\liquibase\` or system PATH
- Port validated before use; retry logic for readiness

---

## Requirements

- Windows 10/11 or Windows Server 2016+
- Jenkins (any version with Pipeline plugin)
- Python 3.8+ with pip
- Java 11+ (for Liquibase)
- PostgreSQL 14+ (auto-installed if installer placed in `databases\postgresql\installer\`)

---

## Quick Start

### Jenkins Setup Job
1. Create a new Pipeline job in Jenkins
2. Set Definition to "Pipeline script from SCM"
3. Point to this repository
4. Set Script Path to `jenkins/postgresql/Jenkinsfile.setup`
5. Build

### Jenkins Load Job
1. Create a new Pipeline job in Jenkins
2. Set Script Path to `jenkins/postgresql/Jenkinsfile.load`
3. Build (after Setup job succeeds)

---

## Folder Structure

```
DataPlatform-Automation/
├── config/
│   ├── postgresql.conf            # All configuration
│   └── python.conf
├── datasets/postgresql/           # Auto-generated CSVs
├── docs/README.md
├── jenkins/postgresql/
│   ├── Jenkinsfile.setup
│   ├── Jenkinsfile.load
│   ├── postgresql_setup_pipeline.groovy
│   ├── postgresql_load_pipeline.groovy
│   └── scripts/
├── liquibase/postgresql/          # Schema migrations
├── scripts/
│   ├── batch/postgresql/          # Windows .bat orchestration
│   ├── powershell/postgresql/     # Service management
│   └── python/postgresql/        # DB + data operations
├── terraform/postgresql/          # Terraform orchestration
├── tools/
│   ├── drivers/                   # JDBC .jar (auto-downloaded)
│   └── liquibase/                 # Liquibase binary
└── outputs/logs/                  # Pipeline logs
```
