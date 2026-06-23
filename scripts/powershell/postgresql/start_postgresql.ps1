$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

# Resolve project root
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

$ConfigFile = Join-Path $ProjectRoot "config\postgresql.conf"
$Config = @{}
if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match "^([^#=]+)=(.*)$") {
            $Config[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
}

$Port          = [int]($Config["POSTGRESQL_PORT"] ?? "5432")
$MaxRetries    = 30
$RetryInterval = 5

$PgBin  = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgData = Join-Path $ProjectRoot "databases\postgresql\data"
$PgLog  = Join-Path $ProjectRoot "databases\postgresql\pg_server.log"
$PgCtl  = Join-Path $PgBin "pg_ctl.exe"

Write-Log "Project Root : $ProjectRoot"
Write-Log "pg_ctl path  : $PgCtl"
Write-Log "Data dir     : $PgData"
Write-Log "Port         : $Port"

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl not found at: $PgCtl - install step failed"
}

# Add pg bin to PATH so pg_ctl can find its own DLLs
$env:PATH = "$PgBin;$env:PATH"

# ---- Check if already running ----
$StatusOutput = & "$PgCtl" -D "$PgData" status 2>&1
Write-Log "pg_ctl status: $StatusOutput"

if ($StatusOutput -match "server is running") {
    Write-Log "PostgreSQL already running"
} else {
    Write-Log "Starting PostgreSQL..."
    & "$PgCtl" -D "$PgData" -l "$PgLog" start
    Start-Sleep -Seconds 5
}

# ---- Wait for port to be ready ----
Write-Log "Waiting for PostgreSQL to be ready on port $Port..."

$Ready = $false
for ($i = 1; $i -le $MaxRetries; $i++) {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", $Port)
        $tcpClient.Close()
        $Ready = $true
        Write-Log "PostgreSQL is ready on port $Port (attempt $i)"
        break
    }
    catch {
        Write-Log "Waiting... attempt $i/$MaxRetries"
        Start-Sleep -Seconds $RetryInterval
    }
}

if (!$Ready) {
    throw "PostgreSQL did not become ready within timeout ($MaxRetries retries x $RetryInterval seconds)"
}

Write-Log "PostgreSQL started and ready"