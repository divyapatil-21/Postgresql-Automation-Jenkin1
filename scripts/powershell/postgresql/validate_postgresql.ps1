$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

function Write-Report {
    param([string]$Label, [string]$Expected, [string]$Detected, [bool]$Pass = $true)
    $Status = if ($Pass) { "OK" } else { "WARN" }
    Write-Host ""
    Write-Host "  $Label"
    Write-Host "    Expected : $Expected"
    Write-Host "    Detected : $Detected   [$Status]"
}

# Read config
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

$ExpectedDatabase = $Config["POSTGRESQL_DATABASE"]
$ExpectedPort     = $Config["POSTGRESQL_PORT"]
$ExpectedSchema   = $Config["POSTGRESQL_SCHEMA"]
$ExpectedUser     = $Config["POSTGRESQL_ADMIN_USER"]

Write-Host ""
Write-Host "========================================================"
Write-Host "POSTGRESQL VALIDATION REPORT"
Write-Host "========================================================"

# --- Service ---
$Service = Get-Service | Where-Object { $_.Name -match "postgres" } | Select-Object -First 1
$DetectedService = if ($Service) { "$($Service.Name) [$($Service.Status)]" } else { "NOT FOUND" }
$ServiceOK = ($Service -and $Service.Status -eq "Running")
Write-Report "SERVICE" "PostgreSQL (Running)" $DetectedService $ServiceOK

# --- Version ---
$PsqlCmd = Get-Command psql -ErrorAction SilentlyContinue
$DetectedVersion = if ($PsqlCmd) { (& $PsqlCmd.Source "--version" 2>&1) } else { "psql NOT IN PATH" }
Write-Report "VERSION" "PostgreSQL AUTO" $DetectedVersion ($PsqlCmd -ne $null)

# --- Port ---
$PortInUse = $false
try {
    $conn = New-Object System.Net.Sockets.TcpClient
    $conn.Connect("localhost", [int]$ExpectedPort)
    $PortInUse = $true
    $conn.Close()
} catch {}
$DetectedPort = if ($PortInUse) { "$ExpectedPort (OPEN)" } else { "$ExpectedPort (CLOSED)" }
Write-Report "PORT" "$ExpectedPort (OPEN)" $DetectedPort $PortInUse

# --- Database ---
$DetectedDB = "CANNOT CHECK (psql not available)"
$DBExists = $false
if ($PsqlCmd) {
    $DBResult = & $PsqlCmd.Source -U $ExpectedUser -t -c "SELECT COUNT(*) FROM pg_database WHERE datname='$ExpectedDatabase';" 2>&1
    $DBExists = ($DBResult -match "1")
    $DetectedDB = if ($DBExists) { "$ExpectedDatabase (EXISTS)" } else { "$ExpectedDatabase (NOT FOUND)" }
}
Write-Report "DATABASE" "$ExpectedDatabase (EXISTS)" $DetectedDB $DBExists

# --- Schema ---
$DetectedSchema = "CANNOT CHECK"
$SchemaExists = $false
if ($PsqlCmd -and $DBExists) {
    $SchResult = & $PsqlCmd.Source -U $ExpectedUser -d $ExpectedDatabase -t -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='$ExpectedSchema';" 2>&1
    $SchemaExists = ($SchResult -match "1")
    $DetectedSchema = if ($SchemaExists) { "$ExpectedSchema (EXISTS)" } else { "$ExpectedSchema (NOT FOUND)" }
}
Write-Report "SCHEMA" "$ExpectedSchema (EXISTS)" $DetectedSchema $SchemaExists

# --- Tables ---
$EXPECTED_TABLES = @("customers","products","orders","sellers","orderdetails")
Write-Host ""
Write-Host "  TABLES"

foreach ($Table in $EXPECTED_TABLES) {
    $TableExists = $false
    if ($PsqlCmd -and $DBExists) {
        $TResult = & $PsqlCmd.Source -U $ExpectedUser -d $ExpectedDatabase -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$ExpectedSchema' AND table_name='$Table';" 2>&1
        $TableExists = ($TResult -match "1")
    }
    $TStatus = if ($TableExists) { "EXISTS" } else { "MISSING" }
    Write-Host "    $Table : $TStatus"
}

# --- Row counts ---
Write-Host ""
Write-Host "  ROW COUNTS"
foreach ($Table in $EXPECTED_TABLES) {
    if ($PsqlCmd -and $DBExists) {
        $CResult = & $PsqlCmd.Source -U $ExpectedUser -d $ExpectedDatabase -t -c "SELECT COUNT(*) FROM $Table;" 2>&1
        $Count = ($CResult -replace '\s','').Trim()
        Write-Host "    $Table : $Count rows"
    }
}

Write-Host ""
Write-Host "========================================================"
Write-Host "Validation completed"
Write-Host "========================================================"
