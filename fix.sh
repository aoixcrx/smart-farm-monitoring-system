#!/bin/bash
# Smart Farm - Quick Fix Script
# Run this script to apply all database fixes

echo "================================================"
echo "Smart Farm Flutter - Database Fix Script"
echo "================================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found"
echo ""

# Clean Flutter build
echo "🧹 Cleaning Flutter build..."
flutter clean
echo "✅ Clean complete"
echo ""

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get
echo "✅ Dependencies updated"
echo ""

# Database Setup
echo "================================================"
echo "Database Setup Instructions"
echo "================================================"
echo ""
echo "You need to initialize your MySQL database with the correct schema."
echo ""
echo "Option 1: Using MySQL Command Line"
echo "   mysql -u root -p smart_farm_db < scripts/init_database.sql"
echo ""
echo "Option 2: Open MySQL Workbench or phpMyAdmin and run scripts/init_database.sql"
echo ""
echo "Option 3: Run the SQL queries manually"
echo "   Copy the content from scripts/init_database.sql and paste them"
echo "   into your MySQL client"
echo ""

# Ask user if they want to proceed
read -p "Have you initialized your database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Ready to run the app!"
    echo ""
    echo "Run: flutter run"
    echo ""
else
    echo ""
    echo "⚠️  Please initialize your database first before running the app."
    echo "Follow the instructions above."
    echo ""
fi
