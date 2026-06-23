$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

# Read config for port
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
$Port = [int]($Config["POSTGRESQL_PORT"] ?? "5432")
$MaxRetries    = [int]($Config["MAX_RETRIES"] ?? "30")
$RetryInterval = [int]($Config["RETRY_INTERVAL_SECONDS"] ?? "5")

Write-Log "Locating PostgreSQL service dynamically..."

# Dynamic service discovery
$Service = Get-Service | Where-Object { $_.Name -match "postgres" } | Select-Object -First 1

if (!$Service) {
    Write-Log "WARNING: No PostgreSQL service found in service manager"
    Write-Log "Checking if PostgreSQL is already listening on port $Port..."
} else {
    Write-Log "Detected service : $($Service.Name)"
    Write-Log "Current status   : $($Service.Status)"

    if ($Service.Status -ne "Running") {
        Write-Log "Starting service: $($Service.Name)"
        Start-Service $Service.Name
        Start-Sleep -Seconds 3
    } else {
        Write-Log "Service already running"
    }
}

# Wait for PostgreSQL to be ready (Service Running != DB Ready)
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
