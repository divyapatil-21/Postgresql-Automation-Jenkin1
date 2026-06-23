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

$ExpectedPort    = [int]$Config["POSTGRESQL_PORT"]
$AdminPassword   = $Config["POSTGRESQL_ADMIN_PASSWORD"]
$PgProjectBin    = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgProjectData   = Join-Path $ProjectRoot "databases\postgresql\data"
$PgProjectLib    = Join-Path $ProjectRoot "databases\postgresql\lib"
$PgProjectShare  = Join-Path $ProjectRoot "databases\postgresql\share"

Write-Log "Expected Port     : $ExpectedPort"
Write-Log "Project PG Bin    : $PgProjectBin"

# ---- Check if already deployed to project folder ----
if (Test-Path (Join-Path $PgProjectBin "pg_ctl.exe")) {
    Write-Log "PostgreSQL binaries already present in project folder - skipping install"
    exit 0
}

# ---- Find system-installed PostgreSQL binaries ----
$SystemBinPaths = @(
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin",
    "C:\Program Files\PostgreSQL\15\bin"
)

$SystemBin = $null
foreach ($BinPath in $SystemBinPaths) {
    if (Test-Path (Join-Path $BinPath "pg_ctl.exe")) {
        $SystemBin = $BinPath
        Write-Log "Found system PostgreSQL binaries at: $SystemBin"
        break
    }
}

# ---- If not found system-wide, run installer ----
if (!$SystemBin) {

    Write-Log "PostgreSQL not found in system locations"
    Write-Log "Checking for pre-downloaded installer..."

    $InstallerDir  = Join-Path $ProjectRoot "databases\postgresql\installer"
    $InstallerFile = Join-Path $InstallerDir "postgresql-installer.exe"

    if (!(Test-Path $InstallerFile)) {
        Write-Log "Installer not found - downloading automatically..."
        New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
        $DownloadUrl = "https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64.exe"
        Write-Log "Downloading from: $DownloadUrl"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerFile -TimeoutSec 600
        Write-Log "Download complete"
    }

    Write-Log "Running unattended installer (installs to system)..."

    $Arguments = @(
        "--mode",         "unattended",
        "--superpassword", $AdminPassword,
        "--serverport",   $ExpectedPort.ToString()
    )

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

    # Locate the installed binaries
    foreach ($BinPath in $SystemBinPaths) {
        if (Test-Path (Join-Path $BinPath "pg_ctl.exe")) {
            $SystemBin = $BinPath
            Write-Log "Installer placed binaries at: $SystemBin"
            break
        }
    }

    if (!$SystemBin) {
        throw "PostgreSQL binaries not found after installation - check installer logs"
    }
}

# ---- Copy binaries to project folder ----
Write-Log "Copying binaries from $SystemBin to $PgProjectBin ..."

$SystemRoot = Split-Path $SystemBin -Parent   # e.g. C:\Program Files\PostgreSQL\17

New-Item -ItemType Directory -Path $PgProjectBin   -Force | Out-Null
New-Item -ItemType Directory -Path $PgProjectLib   -Force | Out-Null
New-Item -ItemType Directory -Path $PgProjectShare -Force | Out-Null

Copy-Item -Path (Join-Path $SystemRoot "bin\*")   -Destination $PgProjectBin   -Recurse -Force
Copy-Item -Path (Join-Path $SystemRoot "lib\*")   -Destination $PgProjectLib   -Recurse -Force
Copy-Item -Path (Join-Path $SystemRoot "share\*") -Destination $PgProjectShare -Recurse -Force

Write-Log "Binaries copied successfully"

# ---- Initialize project data directory with initdb ----
if (!(Test-Path (Join-Path $PgProjectData "PG_VERSION"))) {

    Write-Log "Initializing PostgreSQL data directory at: $PgProjectData"

    New-Item -ItemType Directory -Path $PgProjectData -Force | Out-Null

    $InitDb = Join-Path $PgProjectBin "initdb.exe"

    $env:PATH = "$PgProjectBin;$env:PATH"

    & "$InitDb" `
        -D "$PgProjectData" `
        -U postgres `
        --encoding=UTF8 `
        --locale=en_US.UTF-8

    Write-Log "Data directory initialized"

    # Write port to postgresql.conf
    $PgConf = Join-Path $PgProjectData "postgresql.conf"
    Add-Content -Path $PgConf -Value "`nport = $ExpectedPort"
    Write-Log "Port $ExpectedPort written to postgresql.conf"

} else {
    Write-Log "Data directory already initialized - skipping initdb"
}

Write-Log "PostgreSQL project-folder deployment complete"
Write-Log "Binaries : $PgProjectBin"
Write-Log "Data     : $PgProjectData"