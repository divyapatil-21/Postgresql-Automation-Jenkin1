# DataPlatform-Automation-PostgreSQL

Enterprise-grade PostgreSQL Automation Framework.

## Technology Stack

- PostgreSQL
- Terraform
- PowerShell
- Batch
- Python
- Liquibase
- Jenkins

## Supported Platforms

- Windows

## Deployment Flow

Repository Audit

→ Validate Python Runtime

→ Install Python Requirements

→ Validate Python Requirements

→ Validate Java Runtime

→ Install Tools

→ Deploy PostgreSQL

→ Validate Database

→ Create Database If Missing

→ Validate Schema

→ Create Schema If Missing

→ Run Liquibase

→ Load Data

→ Validate PostgreSQL

## Safety Features

- Duplicate Database Protection
- Duplicate Schema Protection
- Duplicate Table Protection
- Duplicate Seed Protection
- Dynamic PostgreSQL Discovery
- Dynamic Service Discovery
- Dynamic Port Discovery
- Dynamic Tool Discovery
- Dynamic Workspace Discovery

## Default Configuration

Database:
DataManagementDB

Schema:
public

User:
postgres

Port:
5432

## Repository Goals

Machine Independent

Portable

Reusable

Production Ready