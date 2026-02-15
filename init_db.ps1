# Initialize Smart Farm Database
# This script properly handles the MySQL initialization with correct escaping

$mysqlPath = "mysql"  # Will use PATH lookup
$user = "root"
$password = "200413"
$database = "smart_farm_db"
$scriptPath = "scripts/init_database.sql"

# Try to find mysql.exe in common locations if PATH doesn't work
$commonPaths = @(
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe",
    "C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\xampp\mysql\bin\mysql.exe",
    "C:\wamp\bin\mysql\mysql5.7.9\bin\mysql.exe"
)

$found = $false
foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $mysqlPath = $path
        $found = $true
        Write-Host "✅ Found MySQL at: $path" -ForegroundColor Green
        break
    }
}

if (-not $found) {
    Write-Host "⚠️  MySQL not found in common paths. Trying PATH..." -ForegroundColor Yellow
}

# Check if script file exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script file not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "🔄 Initializing Smart Farm database..." -ForegroundColor Cyan

# Read the SQL script
$sqlContent = Get-Content $scriptPath -Raw

# Execute the SQL
try {
    $sqlContent | & $mysqlPath -u $user -p$password $database
    Write-Host "✅ Database initialization complete!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error running MySQL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try one of these alternatives:" -ForegroundColor Yellow
    Write-Host "1. Open MySQL Workbench and execute scripts/init_database.sql"
    Write-Host "2. Open phpMyAdmin and import scripts/init_database.sql"
    Write-Host "3. Add MySQL to PATH and re-run this script"
    Write-Host ""
    exit 1
}
