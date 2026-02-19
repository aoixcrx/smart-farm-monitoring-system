# Smart Farm - Complete Production Setup Guide

**Version**: 2.0 (Dual-Write Architecture)  
**Last Updated**: February 18, 2026  
**Status**: Production Ready

---

## 📋 Table of Contents

1. [Quick Start (5 minutes)](#quick-start)
2. [Full Production Setup (30 minutes)](#full-production-setup)
3. [Firebase Configuration](#firebase-configuration)
4. [Database Schema Updates](#database-schema-updates)
5. [Testing & Verification](#testing--verification)
6. [Deployment Instructions](#deployment-instructions)
7. [Troubleshooting](#troubleshooting)
8. [Monitoring & Maintenance](#monitoring--maintenance)

---

## ⚡ Quick Start

### Prerequisites
- Python 3.10+
- MySQL 8.0
- Firebase project (Google Cloud)

### 1️⃣ Setup Virtual Environment

```bash
# Navigate to project
cd d:\flutterfarmreact\smart-farm-flutter

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

### 2️⃣ Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 3️⃣ Configure Environment

```bash
# Copy .env.production template
copy .env.production .env

# Edit .env with your settings
# Edit with your editor (VS Code, vim, etc.)
```

### 4️⃣ Start API Server

```bash
python api_server.py
```

**Expected Output:**
```
================================================== 70
[*] Flask API Server for Smart Farm
================================================== 70
Server running at: http://0.0.0.0:5000
Database: MySQL connected
Firebase: Enabled (if configured)
Logging: logs/smartfarm.log
```

✅ API is now running on `http://localhost:5000/api`

---

## 🏗 Full Production Setup

### Step 1: MySQL Database Setup

#### 1a. Create Database & User

```bash
# Connect to MySQL
mysql -u root -p

# Create database
CREATE DATABASE smart_farm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Create user
CREATE USER 'smartfarm'@'localhost' IDENTIFIED BY 'your_secure_password_here';

# Grant privileges
GRANT ALL PRIVILEGES ON smart_farm_db.* TO 'smartfarm'@'localhost';
GRANT SUPER ON *.* TO 'smartfarm'@'localhost';
FLUSH PRIVILEGES;

# Exit MySQL
EXIT;
```

#### 1b. Initialize Database Tables

```bash
# Option 1: Using existing api_server.py initialization
python api_server.py
# Then CTRL+C to stop

# Option 2: Manual schema creation
mysql -u smartfarm -p smart_farm_db < database_schema.sql

# Option 3: Run schema updates for production
mysql -u smartfarm -p smart_farm_db < database_updates.sql
```

### Step 2: Firebase Setup

#### 2a. Create Firebase Project

1. Go to [Google Firebase Console](https://console.firebase.google.com)
2. Click "Create Project"
3. Name: `smart-farm-prod`
4. Enable Google Analytics (optional)
5. Click "Create"

#### 2b. Create Firestore Database

1. In Firebase Console: "Build → Firestore Database"
2. Click "Create Database"
3. Start in **Production mode**
4. Location: `asia-southeast1` (or your region)
5. Click "Create"

#### 2c. Add Firestore Rules

In Firestore → Rules tab, add:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated reads/writes
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow service account (backend) to write
    match /{document=**} {
      allow read, write: if request.auth.uid != null || 
                           request.auth.token.firebase.identities != null;
    }
  }
}
```

#### 2d. Generate Service Account Key

1. Firebase Console → Settings (⚙️) → Service Accounts
2. Click "Generate New Private Key"
3. Save as `firebase_key.json` in project root
4. **IMPORTANT**: Add to `.gitignore` (never commit!)

```bash
# Add to .gitignore
echo "firebase_key.json" >> .gitignore
echo ".env" >> .gitignore
```

### Step 3: Environment Configuration

Create `.env` file:

```bash
# Copy template
copy .env.production .env

# Edit .env
cat > .env << 'EOF'
# Flask
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=your_super_secret_key_change_this_now_12345
JWT_SECRET=jwt_secret_key_change_this_now_67890

# MySQL
DB_HOST=localhost
DB_PORT=3306
DB_USER=smartfarm
DB_PASSWORD=your_secure_password_here
DB_NAME=smart_farm_db
DB_POOL_SIZE=10

# Firebase
FIREBASE_CONFIG_PATH=firebase_key.json
FIREBASE_ENABLED=True

# API
API_HOST=0.0.0.0
API_PORT=5000
API_WORKERS=4

# Logging
LOG_DIR=logs
LOG_LEVEL=INFO

# Thingspeak
THINGSPEAK_ENABLED=True
THINGSPEAK_CHANNEL_ID=3211612
THINGSPEAK_READ_KEY=DUJ1X4OCWFMWH1U0

# Alerts
ALERT_TEMP_MAX=40.0
ALERT_TEMP_MIN=10.0
ALERT_HUMIDITY_MAX=95.0
ALERT_HUMIDITY_MIN=20.0
ALERT_STRESS_MAX=0.8
EOF
```

### Step 4: Database Schema Updates

```bash
# Create new tables for production monitoring
mysql -u smartfarm -p smart_farm_db < database_updates.sql

# Verify
mysql -u smartfarm -p smart_farm_db -e "SHOW TABLES LIKE '%';"
```

Expected output:
```
+---------------------------+
| Tables_in_smart_farm_db   |
+---------------------------+
| users                     |
| plots                     |
| devices                   |
| device_logs               |
| sensor_logs               |
| stress_predictions        |
| device_schedules          |
| audit_logs                | ← NEW
| sync_status               | ← NEW
+---------------------------+
```

### Step 5: Create Log Directory

```bash
mkdir -p logs

# Verify permissions
ls -la logs/
```

---

## 🔥 Firebase Configuration

### Collections Setup

Firebase will auto-create collections on first write. Expected structure:

```
smart-farm-prod (Firestore Database)
├── sensor_readings/
│   ├── {entry_id_1}
│   │   ├── air_temperature: 32.5
│   │   ├── humidity: 65.0
│   │   ├── timestamp: "2026-02-18T10:30:00Z"
│   │   └── synced_from: "mysql"
│   └── {entry_id_2}
│       └── ...
│
├── device_logs/
│   ├── {log_id_1}
│   └── ...
│
├── alerts/
│   ├── {alert_id_1}
│   │   ├── type: "HIGH_TEMPERATURE"
│   │   ├── severity: "critical"
│   │   └── created_at: "2026-02-18T10:30:00Z"
│   └── ...
│
└── devices/
    ├── {device_id_1}
    │   ├── status: "on"
    │   └── updated_at: "2026-02-18T10:30:00Z"
    └── ...
```

### Firestore Indexes (for performance)

Add in Firestore Console → Indexes:

```
Collection: sensor_readings
Fields:
  - timestamp (Descending)
  - synced_from (Ascending)

Collection: alerts
Fields:
  - created_at (Descending)
  - severity (Ascending)
```

---

## 📊 Database Schema Updates

### What's New

```sql
-- Track Firebase synchronization
ALTER TABLE sensor_logs ADD COLUMN firebase_synced BOOLEAN;
ALTER TABLE sensor_logs ADD COLUMN firebase_sync_time TIMESTAMP;
ALTER TABLE sensor_logs ADD COLUMN firebase_doc_id VARCHAR(255);

-- Prevent duplicates
ALTER TABLE sensor_logs ADD UNIQUE INDEX unique_entry_id (entry_id);

-- New tables for production monitoring
CREATE TABLE audit_logs (...)
CREATE TABLE sync_status (...)

-- Performance indexes
CREATE INDEX idx_sensor_timestamp ON sensor_logs(created_at DESC);
```

Run:
```bash
mysql -u smartfarm -p smart_farm_db < database_updates.sql
```

---

## ✅ Testing & Verification

### 1. Health Check

```bash
# Test API is running
curl http://localhost:5000/api/health

# Expected response:
# {
#   "status": "success",
#   "data": {
#     "status": "healthy",
#     "database": "connected",
#     "version": "2.0.0"
#   }
# }
```

### 2. Test Dual-Write (MySQL + Firebase)

```bash
# Import Thingspeak data
curl -X POST http://localhost:5000/api/import_thingspeak \
  -H "Content-Type: application/json" \
  -d '{
    "entry_id": 12345,
    "plot_id": 1,
    "field1": 32.5,
    "field2": 65.0,
    "field3": 500.0,
    "field4": 45.0,
    "field5": 0.65,
    "created_at": "2026-02-18T10:30:00Z"
  }'

# Expected response:
# {
#   "status": "success",
#   "message": "Data imported successfully",
#   "data": {
#     "entry_id": 12345,
#     "mysql_status": "saved",
#     "firebase_status": "queued"
#   }
# }
```

### 3. Verify MySQL Data

```bash
mysql -u smartfarm -p smart_farm_db

SELECT * FROM sensor_logs WHERE entry_id = 12345;
```

### 4. Verify Firebase Data

```bash
# Use Firebase Console → Firestore → sensor_readings collection
# Should see document: 12345 with the data
```

### 5. Check Synchronization Status

```bash
curl http://localhost:5000/api/health/sync

# Expected:
# {
#   "status": "success",
#   "data": {
#     "mysql": "connected",
#     "firebase": "connected",
#     "dual_write_active": true
#   }
# }
```

### 6. Run Automated Tests

```bash
# Run test suite
pytest tests/ -v

# With coverage report
pytest tests/ --cov=app --cov-report=html

# View report
open htmlcov/index.html
```

---

## 🚀 Deployment Instructions

### Option 1: Development (with Flask Built-in Server)

```bash
# Activate venv
source venv/bin/activate  # or: venv\Scripts\activate on Windows

# Run directly
python api_server.py

# Or with FLASK_ENV=production
FLASK_ENV=production python api_server.py
```

**Note**: Only for development! Do NOT use in production.

### Option 2: Production (with Gunicorn)

```bash
# Install Gunicorn (already in requirements.txt)
pip install gunicorn

# Run with 4 workers
gunicorn -w 4 -b 0.0.0.0:5000 api_server:app

# Or with environment file
gunicorn -w 4 -b 0.0.0.0:5000 \
  --env FLASK_ENV=production \
  --access-logfile logs/access.log \
  --error-logfile logs/error.log \
  api_server:app
```

### Option 3: Systemd Service (Linux/macOS)

Create `/etc/systemd/system/smartfarm-api.service`:

```ini
[Unit]
Description=Smart Farm API Service
After=network.target mysql.service

[Service]
Type=notify
User=smartfarm
WorkingDirectory=/home/smartfarm/smart-farm-flutter
ExecStart=/home/smartfarm/smart-farm-flutter/venv/bin/gunicorn \
  -w 4 -b 0.0.0.0:5000 api_server:app
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Start service:

```bash
sudo systemctl enable smartfarm-api
sudo systemctl start smartfarm-api
sudo systemctl status smartfarm-api

# View logs
sudo journalctl -u smartfarm-api -f
```

### Option 4: Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FLASK_ENV=production
EXPOSE 5000

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "api_server:app"]
```

Build and run:

```bash
docker build -t smartfarm-api:2.0 .
docker run -d \
  --name smartfarm \
  -p 5000:5000 \
  -e DB_HOST=db \
  -e FIREBASE_ENABLED=true \
  -v $(pwd)/firebase_key.json:/app/firebase_key.json \
  smartfarm-api:2.0
```

---

## 🔧 Troubleshooting

### Issue: "Connection refused" to MySQL

```bash
# Check MySQL is running
mysql -u root -p

# If not running, start it:
# macOS: brew services start mysql
# Linux: sudo systemctl start mysql
# Windows: Start MySQL from Services
```

### Issue: "Firebase config not found"

```bash
# Check file exists
ls -la firebase_key.json

# Check permissions
chmod 600 firebase_key.json

# Check path in .env
cat .env | grep FIREBASE_CONFIG_PATH
```

### Issue: "Port 5000 already in use"

```bash
# Find process using port 5000
lsof -i :5000

# Kill process
kill -9 <PID>

# Or use different port
export API_PORT=5001
python api_server.py
```

### Issue: "Module not found" errors

```bash
# Make sure venv is activated
source venv/bin/activate

# Reinstall requirements
pip install --upgrade -r requirements.txt

# Check installed packages
pip list
```

---

## 📊 Monitoring & Maintenance

### Daily Tasks

```bash
# Check log size
ls -lh logs/

# Verify API is running
curl http://localhost:5000/api/health/sync

# Check database connection
mysql -u smartfarm -p smart_farm_db -e "SELECT COUNT(*) FROM sensor_logs;"
```

### Weekly Tasks

```bash
# Check error rate
grep ERROR logs/smartfarm.log | wc -l

# Verify Firebase sync
mysql -u smartfarm -p smart_farm_db -e "SELECT COUNT(*) FROM sensor_logs WHERE firebase_synced=1;"

# Database maintenance
mysql -u smartfarm -p smart_farm_db -e "OPTIMIZE TABLE sensor_logs;"
```

### Monthly Tasks

```bash
# Backup database
mysqldump -u smartfarm -p smart_farm_db > backup_$(date +%Y%m%d).sql

# Rotate logs
rm logs/smartfarm.log logs/smartfarm_errors.log

# Update dependencies
pip list --outdated
pip install --upgrade <package-name>

# Verify performance
tail -100 logs/smartfarm.log | grep "ERROR\|WARNING"
```

---

## 🎓 For Your Thesis

This setup demonstrates:

✅ **Production Architecture**: Dual-write pattern  
✅ **High Availability**: Failover between MySQL ↔ Firebase  
✅ **Security**: JWT + Bcrypt + RBAC  
✅ **Monitoring**: Health checks + logging  
✅ **Scalability**: Stateless app + connection pooling  
✅ **Data Integrity**: Unique constraints + transactions  

---

## 📝 Next Steps

1. ✅ Complete this setup
2. ✅ Run tests: `pytest tests/`
3. ✅ Deploy: Start API server
4. ✅ Test Flutter app connection
5. ✅ Document in thesis
6. ✅ Present to advisors

---

**Questions?** Check the logs or create an issue on GitHub.

Good luck with your project! 🚀
