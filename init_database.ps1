# Initialize Smart Farm Database
# This script properly handles the MySQL initialization

$mysqlPath = "mysql"
$user = "root"
$password = "200413"
$database = "smart_farm_db"
$scriptPath = "scripts/init_database.sql"

$commonPaths = @(
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe",
    "C:\xampp\mysql\bin\mysql.exe"
)

$found = $false
foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $mysqlPath = $path
        $found = $true
        Write-Host "Found MySQL at: $path"
        break
    }
}

if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Script file not found: $scriptPath"
    exit 1
}

Write-Host "Initializing database..."
$sqlContent = Get-Content $scriptPath -Raw

try {
    $sqlContent | &$mysqlPath -u $user -p$password $database
    Write-Host "Success! Database initialized."
} catch {
    Write-Host "Error: $_"
    Write-Host "Try running in MySQL Workbench or phpMyAdmin instead"
    exit 1
}
