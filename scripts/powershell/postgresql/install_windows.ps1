$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

function Get-ProjectRoot {
    $Root = Split-Path $PSScriptRoot -Parent
    $Root = Split-Path $Root -Parent
    $Root = Split-Path $Root -Parent
    return $Root
}

$ProjectRoot = Get-ProjectRoot

Write-Log "Project Root : $ProjectRoot"

# Read config
$ConfigFile = Join-Path $ProjectRoot "config\postgresql.conf"

if (!(Test-Path $ConfigFile)) {
    throw "Configuration file not found: $ConfigFile"
}

$Config = @{}
Get-Content $ConfigFile | ForEach-Object {
    if ($_ -match "^([^#=]+)=(.*)$") {
        $Config[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

$ExpectedPort = [int]$Config["POSTGRESQL_PORT"]
$DBName       = $Config["POSTGRESQL_DATABASE"]
$AdminUser    = $Config["POSTGRESQL_ADMIN_USER"]

Write-Log "Expected Database : $DBName"
Write-Log "Expected Port     : $ExpectedPort"

# ---- Check if PostgreSQL already installed ----
Write-Log "Searching for existing PostgreSQL installation..."

$PsqlCmd = Get-Command psql -ErrorAction SilentlyContinue

if ($PsqlCmd) {

    $Version = (& $PsqlCmd.Source "--version" 2>&1)
    Write-Log "PostgreSQL already installed : $Version"

    # Verify service exists
    $Service = Get-Service | Where-Object { $_.Name -match "postgres" } | Select-Object -First 1

    if ($Service) {
        Write-Log "Service detected : $($Service.Name) [$($Service.Status)]"
    } else {
        Write-Log "WARNING: No PostgreSQL service found - may need manual start"
    }

    Write-Log "Reusing existing installation"
    exit 0
}

# ---- PostgreSQL not found - try to install ----
Write-Log "PostgreSQL not found in PATH"
Write-Log "Checking for pre-downloaded installer..."

$InstallerDir  = Join-Path $ProjectRoot "databases\postgresql\installer"
$InstallerFile = Join-Path $InstallerDir "postgresql-installer.exe"

if (!(Test-Path $InstallerFile)) {

    Write-Log "Installer not found at: $InstallerFile"
    Write-Log ""
    Write-Log "============================================"
    Write-Log "MANUAL ACTION REQUIRED"
    Write-Log "============================================"
    Write-Log "1. Download PostgreSQL installer from:"
    Write-Log "   https://www.enterprisedb.com/downloads/postgres-postgresql-downloads"
    Write-Log "2. Rename it to: postgresql-installer.exe"
    Write-Log "3. Place it in: databases\postgresql\installer\"
    Write-Log "4. Re-run this pipeline"
    Write-Log "============================================"
    exit 1
}

# Create installer dir if missing
if (!(Test-Path $InstallerDir)) {
    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
}

Write-Log "Installer found : $InstallerFile"
Write-Log "Starting unattended installation..."

$Arguments = @(
    "--mode",         "unattended",
    "--superpassword", "",
    "--serverport",   $ExpectedPort.ToString()
)

$Process = Start-Process `
    -FilePath  $InstallerFile `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru

Write-Log "Installer exit code: $($Process.ExitCode)"

if ($Process.ExitCode -ne 0) {
    throw "PostgreSQL installation failed with exit code: $($Process.ExitCode)"
}

# Refresh PATH
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

Start-Sleep -Seconds 15

$PsqlCmd = Get-Command psql -ErrorAction SilentlyContinue

if (!$PsqlCmd) {
    throw "PostgreSQL not found in PATH after installation - please add PostgreSQL bin to system PATH"
}

$Version = (& $PsqlCmd.Source "--version" 2>&1)
Write-Log "PostgreSQL installed successfully : $Version"
