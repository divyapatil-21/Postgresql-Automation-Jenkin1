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

    Write-Log "Installer not found - downloading automatically..."

    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null

    $DownloadUrl = "https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64.exe"

    Write-Log "Downloading from: $DownloadUrl"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Invoke-WebRequest `
        -Uri     $DownloadUrl `
        -OutFile $InstallerFile `
        -TimeoutSec 600

    Write-Log "Download complete"
}

# Create installer dir if missing
if (!(Test-Path $InstallerDir)) {
    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
}

Write-Log "Installer found : $InstallerFile"
Write-Log "Starting unattended installation..."

$Arguments = "--mode unattended --superpassword postgres --serverport $($ExpectedPort.ToString())"

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

# Refresh PATH after install
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH","User")

# Also search common PostgreSQL bin locations
$PgBinPaths = @(
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin",
    "C:\Program Files\PostgreSQL\15\bin"
)

foreach ($BinPath in $PgBinPaths) {
    if (Test-Path "$BinPath\psql.exe") {
        $env:PATH = "$BinPath;$env:PATH"
        Write-Log "Added to PATH: $BinPath"
        break
    }
}

$PsqlCmd = Get-Command psql -ErrorAction SilentlyContinue

if (!$PsqlCmd) {
    Write-Log "WARNING: psql not in PATH yet - PostgreSQL service may still need restart"
    Write-Log "Continuing deployment..."
}
