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
$PgDir       = Join-Path $ProjectRoot "databases\postgresql"
$PgBin       = Join-Path $PgDir "bin"

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

Write-Log "Expected Database : $DBName"
Write-Log "Expected Port     : $ExpectedPort"

# ---- Check project folder first ----
Write-Log "Searching for existing PostgreSQL installation..."

if (Test-Path "$PgBin\psql.exe") {
    Write-Log "PostgreSQL already installed in project folder: $PgDir"
    exit 0
}

# ---- Check system PATH ----
$PsqlCmd = Get-Command psql -ErrorAction SilentlyContinue
if ($PsqlCmd) {
    $Version = (& $PsqlCmd.Source "--version" 2>&1)
    Write-Log "PostgreSQL found in system PATH: $Version"
    Write-Log "Copying binaries to project folder..."

    # Find PostgreSQL base dir
    $PgSystemBin = Split-Path $PsqlCmd.Source -Parent
    $PgSystemDir = Split-Path $PgSystemBin -Parent

    New-Item -ItemType Directory -Path $PgBin -Force | Out-Null

    # Copy binaries
    Copy-Item "$PgSystemBin\*" -Destination $PgBin -Recurse -Force

    # Copy lib if exists
    $PgSystemLib = Join-Path $PgSystemDir "lib"
    if (Test-Path $PgSystemLib) {
        $PgLib = Join-Path $PgDir "lib"
        New-Item -ItemType Directory -Path $PgLib -Force | Out-Null
        Copy-Item "$PgSystemLib\*" -Destination $PgLib -Recurse -Force
    }

    # Copy share if exists
    $PgSystemShare = Join-Path $PgSystemDir "share"
    if (Test-Path $PgSystemShare) {
        $PgShare = Join-Path $PgDir "share"
        New-Item -ItemType Directory -Path $PgShare -Force | Out-Null
        Copy-Item "$PgSystemShare\*" -Destination $PgShare -Recurse -Force
    }

    Write-Log "Binaries copied to project folder: $PgDir"

    # Initialize data directory
    $PgData = Join-Path $PgDir "data"
    if (!(Test-Path "$PgData\PG_VERSION")) {
        Write-Log "Initializing data directory..."
        & "$PgBin\initdb.exe" -D $PgData --auth=trust --username=postgres
        Write-Log "Data directory initialized: $PgData"
    }

    Write-Log "PostgreSQL project folder setup complete"
    exit 0
}

# ---- Download and install ----
Write-Log "PostgreSQL not found - downloading installer..."

$InstallerDir  = Join-Path $ProjectRoot "databases\postgresql\installer"
$InstallerFile = Join-Path $InstallerDir "postgresql-installer.exe"

if (!(Test-Path $InstallerFile)) {
    New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
    $DownloadUrl = "https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64.exe"
    Write-Log "Downloading from: $DownloadUrl"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerFile -TimeoutSec 600
    Write-Log "Download complete"
}

Write-Log "Installer found : $InstallerFile"
Write-Log "Starting unattended installation..."

$Arguments = "--mode unattended --superpassword postgres --serverport $($ExpectedPort.ToString())"

$Process = Start-Process `
    -FilePath    $InstallerFile `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru

Write-Log "Installer exit code: $($Process.ExitCode)"

if ($Process.ExitCode -ne 0) {
    throw "PostgreSQL installation failed with exit code: $($Process.ExitCode)"
}

Start-Sleep -Seconds 15

# Find installed location and copy to project folder
$PgBinPaths = @(
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin",
    "C:\Program Files\PostgreSQL\15\bin"
)

foreach ($BinPath in $PgBinPaths) {
    if (Test-Path "$BinPath\psql.exe") {
        Write-Log "Found installation at: $BinPath"
        $PgSystemDir = Split-Path $BinPath -Parent

        New-Item -ItemType Directory -Path $PgBin -Force | Out-Null
        Copy-Item "$BinPath\*" -Destination $PgBin -Recurse -Force

        $PgSystemLib = Join-Path $PgSystemDir "lib"
        if (Test-Path $PgSystemLib) {
            $PgLib = Join-Path $PgDir "lib"
            New-Item -ItemType Directory -Path $PgLib -Force | Out-Null
            Copy-Item "$PgSystemLib\*" -Destination $PgLib -Recurse -Force
        }

        $PgSystemShare = Join-Path $PgSystemDir "share"
        if (Test-Path $PgSystemShare) {
            $PgShare = Join-Path $PgDir "share"
            New-Item -ItemType Directory -Path $PgShare -Force | Out-Null
            Copy-Item "$PgSystemShare\*" -Destination $PgShare -Recurse -Force
        }

        Write-Log "Binaries copied to project folder: $PgDir"
        break
    }
}

# Initialize data directory
$PgData = Join-Path $PgDir "data"
if (!(Test-Path "$PgData\PG_VERSION")) {
    Write-Log "Initializing data directory..."
    & "$PgBin\initdb.exe" -D $PgData --auth=trust --username=postgres
    Write-Log "Data directory initialized: $PgData"
}

Write-Log "PostgreSQL project folder installation complete"