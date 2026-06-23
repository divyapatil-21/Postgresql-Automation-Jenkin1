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
$PgData      = Join-Path $PgDir "data"
$PgCtl       = Join-Path $PgBin "pg_ctl.exe"
$PgLog       = Join-Path $ProjectRoot "outputs\logs\postgresql.log"

$ConfigFile = Join-Path $ProjectRoot "config\postgresql.conf"
$Config = @{}
Get-Content $ConfigFile | ForEach-Object {
    if ($_ -match "^([^#=]+)=(.*)$") {
        $Config[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}
$Port = $Config["POSTGRESQL_PORT"]

Write-Log "Project Root : $ProjectRoot"
Write-Log "PG Bin       : $PgBin"
Write-Log "PG Data      : $PgData"
Write-Log "Port         : $Port"

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl not found at: $PgCtl - install step failed?"
}

# Already running check
$StatusOutput = & $PgCtl -D $PgData status 2>&1
if ($StatusOutput -match "server is running") {
    Write-Log "PostgreSQL already running from project folder"
    exit 0
}

Write-Log "Starting PostgreSQL from project folder..."
New-Item -ItemType Directory -Path (Split-Path $PgLog) -Force | Out-Null

& $PgCtl -D $PgData -l $PgLog -o "-p $Port" start

Start-Sleep -Seconds 5

$StatusOutput = & $PgCtl -D $PgData status 2>&1
Write-Log "Status: $StatusOutput"
Write-Log "PostgreSQL started successfully on port $Port"