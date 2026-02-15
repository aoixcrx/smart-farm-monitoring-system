@echo off
REM Smart Farm - Quick Fix Script for Windows
REM Run this script to apply all database fixes

echo.
echo ================================================
echo Smart Farm Flutter - Database Fix Script
echo ================================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if errorlevel 1 (
    echo ❌ Flutter not found. Please install Flutter first.
    pause
    exit /b 1
)

echo ✅ Flutter found
echo.

REM Clean Flutter build
echo 🧹 Cleaning Flutter build...
call flutter clean
if errorlevel 1 (
    echo ❌ Error during clean
    pause
    exit /b 1
)
echo ✅ Clean complete
echo.

REM Get dependencies
echo 📦 Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ❌ Error getting dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies updated
echo.

REM Database Setup
echo ================================================
echo Database Setup Instructions
echo ================================================
echo.
echo You need to initialize your MySQL database with the correct schema.
echo.
echo Option 1: Using MySQL Command Line
echo    mysql -u root -p smart_farm_db ^< scripts/init_database.sql
echo.
echo Option 2: Open MySQL Workbench or phpMyAdmin and run scripts/init_database.sql
echo.
echo Option 3: Run the SQL queries manually
echo    Copy the content from scripts/init_database.sql and paste them
echo    into your MySQL client
echo.
echo Option 4 (Recommended): Use this command if MySQL is in your PATH
echo    mysql -u root -p200413 smart_farm_db ^< scripts\init_database.sql
echo.

set /p proceed="Have you initialized your database? (y/n): "
if /i "%proceed%"=="y" (
    echo.
    echo 🚀 Ready to run the app!
    echo.
    echo Run: flutter run
    echo.
) else (
    echo.
    echo ⚠️  Please initialize your database first before running the app.
    echo Follow the instructions above.
    echo.
)

pause
