# Smart Farm API - Comprehensive Documentation

**Version**: 2.0  
**Last Updated**: February 16, 2026  
**Base URL**: `http://localhost:5000/api`

---

## Table of Contents

1. [Device Logs API](#device-logs-api)
2. [Weather API](#weather-api)
3. [Alerts API](#alerts-api)
4. [Maintenance Schedule API](#maintenance-schedule-api)
5. [Crop Health Metrics API](#crop-health-metrics-api)
6. [Farm Statistics API](#farm-statistics-api)
7. [Device Status History API](#device-status-history-api)

---

## Overview

The Smart Farm API provides comprehensive endpoints for managing agricultural operations, including device monitoring, environmental data collection, crop health tracking, and maintenance scheduling.

### Key Features
- Real-time device operation logging
- Weather data integration
- Smart alert system with severity levels
- Preventive maintenance scheduling
- Crop health monitoring via CWSI
- Farm-wide statistics and analytics
- Device status history tracking

---

---

## 1. Device Logs API

### Overview
Track all device actions and state changes in the farm system.

### Database Schema

```sql
CREATE TABLE device_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    device_name VARCHAR(100),
    action VARCHAR(50),
    source VARCHAR(20),
    old_value VARCHAR(255),
    new_value VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_device_created (device_id, created_at)
)
```

### Endpoints

#### Initialize Table
**POST** `/api/device-logs/init`

Initialize the device_logs table.

**Response:**
```json
{
    "message": "device_logs table created successfully"
}
```

#### Record Device Log
**POST** `/api/device-logs`

Record a device action/state change.

**Request Body:**
```json
{
    "device_id": 1,
    "device_name": "Pump001",
    "action": "ON",
    "source": "APP",
    "old_value": "OFF",
    "new_value": "ON"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "log_id": 123,
    "message": "Device log recorded"
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | Integer | Yes | Device identifier |
| `device_name` | String | No | Device display name |
| `action` | String | Yes | Action performed (ON, OFF, MODE_CHANGE, etc.) |
| `source` | String | No | Source of action (APP, AUTO, MANUAL) |
| `old_value` | String | No | Previous state value |
| `new_value` | String | No | New state value |

#### Get Device Logs
**GET** `/api/device-logs`

Retrieve device logs, optionally filtered by device.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `device_id` | Integer | All | Filter by device ID |
| `limit` | Integer | 100 | Maximum records to return |

**Response:**
```json
{
    "logs": [
        {
            "log_id": 123,
            "device_id": 1,
            "device_name": "Pump001",
            "action": "ON",
            "source": "APP",
            "old_value": "OFF",
            "new_value": "ON",
            "created_at": "2026-02-15 17:00:00"
        }
    ],
    "count": 1
}
```

---

## 2. Weather API

### Overview
Record and retrieve weather data for farm locations.

### Database Schema

```sql
CREATE TABLE weather_logs (
    weather_id INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    wind_speed DECIMAL(6,2),
    rainfall DECIMAL(6,2),
    weather_condition VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location_created (location, created_at)
)
```

### Endpoints

#### Initialize Table
**POST** `/api/weather/init`

Initialize the weather_logs table.

**Response:**
```json
{
    "message": "weather_logs table created successfully"
}
```

#### Record Weather
**POST** `/api/weather`

Record weather data for a location.

**Request Body:**
```json
{
    "location": "Farm A",
    "latitude": 13.7563,
    "longitude": 100.5018,
    "temperature": 28.5,
    "humidity": 75.0,
    "wind_speed": 5.2,
    "rainfall": 0.0,
    "weather_condition": "Partly Cloudy"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "weather_id": 456
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | String | Yes | Location name |
| `latitude` | Float | No | GPS latitude |
| `longitude` | Float | No | GPS longitude |
| `temperature` | Float | No | Temperature in °C |
| `humidity` | Float | No | Relative humidity % |
| `wind_speed` | Float | No | Wind speed in km/h |
| `rainfall` | Float | No | Rainfall in mm |
| `weather_condition` | String | No | Weather description |

#### Get Weather
**GET** `/api/weather`

Retrieve weather data by location.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | String | All | Filter by location name |
| `limit` | Integer | 1 | Maximum records to return |

**Response:**
```json
{
    "weather": [
        {
            "weather_id": 456,
            "location": "Farm A",
            "latitude": 13.7563,
            "longitude": 100.5018,
            "temperature": 28.5,
            "humidity": 75.0,
            "wind_speed": 5.2,
            "rainfall": 0.0,
            "weather_condition": "Partly Cloudy",
            "created_at": "2026-02-15 17:00:00"
        }
    ],
    "count": 1
}
```

---

## 3. Alerts API

### Overview
Create and manage farm alerts with severity levels and resolution tracking.

### Database Schema

```sql
CREATE TABLE alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    plot_id INT,
    alert_type VARCHAR(50),
    severity VARCHAR(20),
    message TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME,
    INDEX idx_plot_created (plot_id, created_at)
)
```

### Endpoints

#### Initialize Table
**POST** `/api/alerts/init`

Initialize the alerts table.

**Response:**
```json
{
    "message": "alerts table created successfully"
}
```

#### Create Alert
**POST** `/api/alerts`

Create a new farm alert.

**Request Body:**
```json
{
    "plot_id": 1,
    "alert_type": "HIGH_TEMP",
    "severity": "HIGH",
    "message": "Temperature exceeded threshold of 35°C"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "alert_id": 789
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `plot_id` | Integer | No | Associated plot ID |
| `alert_type` | String | Yes | Alert type (HIGH_TEMP, LOW_MOISTURE, DEVICE_FAILURE, etc.) |
| `severity` | String | Yes | Severity level (LOW, MEDIUM, HIGH, CRITICAL) |
| `message` | String | No | Alert description |

#### Get Alerts
**GET** `/api/alerts`

Retrieve alerts with filtering options.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `plot_id` | Integer | All | Filter by plot ID |
| `is_resolved` | Boolean | false | Show resolved/unresolved alerts |
| `limit` | Integer | 50 | Maximum records to return |

**Response:**
```json
{
    "alerts": [
        {
            "alert_id": 789,
            "plot_id": 1,
            "alert_type": "HIGH_TEMP",
            "severity": "HIGH",
            "message": "Temperature exceeded threshold...",
            "is_resolved": false,
            "created_at": "2026-02-15 17:00:00",
            "resolved_at": null
        }
    ],
    "count": 1
}
```

#### Resolve Alert
**PUT** `/api/alerts/<alert_id>/resolve`

Mark an alert as resolved.

**Response:**
```json
{
    "success": true,
    "message": "Alert resolved"
}
```

---

## 4. Maintenance Schedule API

### Overview
Plan and track equipment maintenance schedules.

### Database Schema

```sql
CREATE TABLE maintenance_schedules (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    device_name VARCHAR(100),
    maintenance_type VARCHAR(100),
    scheduled_date DATE,
    last_maintenance_date DATE,
    status VARCHAR(50),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_device_date (device_id, scheduled_date)
)
```

### Endpoints

#### Initialize Table
**POST** `/api/maintenance/init`

Initialize the maintenance_schedules table.

**Response:**
```json
{
    "message": "maintenance_schedules table created successfully"
}
```

#### Schedule Maintenance
**POST** `/api/maintenance`

Schedule maintenance for a device.

**Request Body:**
```json
{
    "device_id": 1,
    "device_name": "Pump001",
    "maintenance_type": "Oil Change",
    "scheduled_date": "2026-03-15",
    "status": "PENDING",
    "notes": "Routine maintenance - check oil level and filter"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "maintenance_id": 101
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | Integer | Yes | Device to maintain |
| `device_name` | String | No | Device display name |
| `maintenance_type` | String | Yes | Type of maintenance |
| `scheduled_date` | Date | Yes | Scheduled date (YYYY-MM-DD) |
| `status` | String | No | Status (PENDING, IN_PROGRESS, COMPLETED) |
| `notes` | String | No | Additional notes |

#### Get Maintenance Schedules
**GET** `/api/maintenance`

Retrieve maintenance schedules.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `device_id` | Integer | All | Filter by device ID |
| `status` | String | PENDING | Filter by status |
| `limit` | Integer | 50 | Maximum records to return |

**Response:**
```json
{
    "schedules": [
        {
            "maintenance_id": 101,
            "device_id": 1,
            "device_name": "Pump001",
            "maintenance_type": "Oil Change",
            "scheduled_date": "2026-03-15",
            "last_maintenance_date": null,
            "status": "PENDING",
            "notes": "Routine maintenance...",
            "created_at": "2026-02-15 17:00:00"
        }
    ],
    "count": 1
}
```

---

## 5. Crop Health Metrics API

### Overview
Monitor crop health using CWSI (Crop Water Stress Index) and other metrics.

### Database Schema

```sql
CREATE TABLE crop_health_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    plot_id INT NOT NULL,
    cwsi_value DECIMAL(5,2),
    leaf_temperature DECIMAL(5,2),
    air_temperature DECIMAL(5,2),
    soil_moisture DECIMAL(5,2),
    soil_ec DECIMAL(6,3),
    health_status VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_plot_created (plot_id, created_at)
)
```

### Endpoints

#### Initialize Table
**POST** `/api/crop-health/init`

Initialize the crop_health_metrics table.

**Response:**
```json
{
    "message": "crop_health_metrics table created successfully"
}
```

#### Record Crop Health
**POST** `/api/crop-health`

Record crop health measurements.

**Request Body:**
```json
{
    "plot_id": 1,
    "cwsi_value": 0.45,
    "leaf_temperature": 28.5,
    "air_temperature": 29.0,
    "soil_moisture": 65.0,
    "soil_ec": 2.5
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "metric_id": 202,
    "health_status": "Healthy"
}
```

**Health Status Calculation:**
- **Healthy**: CWSI < 0.5
- **Stressed**: CWSI 0.5 - 0.8
- **Critical**: CWSI > 0.8

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `plot_id` | Integer | Yes | Associated plot |
| `cwsi_value` | Float | No | Crop Water Stress Index (0-1) |
| `leaf_temperature` | Float | No | Leaf temperature (°C) |
| `air_temperature` | Float | No | Air temperature (°C) |
| `soil_moisture` | Float | No | Soil moisture (%) |
| `soil_ec` | Float | No | Soil electrical conductivity (dS/m) |

#### Get Crop Health
**GET** `/api/crop-health`

Retrieve crop health metrics for a plot.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `plot_id` | Integer | Required | Plot ID |
| `limit` | Integer | 100 | Maximum records to return |

**Response:**
```json
{
    "metrics": [
        {
            "metric_id": 202,
            "plot_id": 1,
            "cwsi_value": 0.45,
            "leaf_temperature": 28.5,
            "air_temperature": 29.0,
            "soil_moisture": 65.0,
            "soil_ec": 2.5,
            "health_status": "Healthy",
            "created_at": "2026-02-15 17:00:00"
        }
    ],
    "count": 1
}
```

---

## 6. Farm Statistics API

### Overview
Get aggregated farm data and analytics.

### Endpoints

#### Farm Overview
**GET** `/api/statistics/overview`

Get overall farm statistics.

**Response:**
```json
{
    "total_plots": 5,
    "active_devices": 12,
    "total_sensor_readings": 1250,
    "avg_temperature": 28.5,
    "avg_humidity": 72.3,
    "pending_alerts": 2
}
```

#### Plot Statistics
**GET** `/api/statistics/plot/<plot_id>`

Get statistics for a specific plot.

**Response:**
```json
{
    "plot_id": 1,
    "plot_name": "Greenhouse A",
    "plant_type": "Andrographis",
    "latest_health": {
        "metric_id": 202,
        "cwsi_value": 0.45,
        "health_status": "Healthy",
        "created_at": "2026-02-15T17:00:00"
    },
    "week_avg_cwsi": 0.48,
    "week_avg_moisture": 65.5
}
```

---

## 7. Device Status History API

### Overview
Track device status and performance history over time.

### Database Schema

```sql
CREATE TABLE device_status_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    device_name VARCHAR(100),
    status VARCHAR(20),
    mode VARCHAR(20),
    uptime_seconds INT,
    error_count INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_device_created (device_id, created_at)
)
```

### Endpoints

#### Initialize Table
**POST** `/api/device-history/init`

Initialize the device_status_history table.

**Response:**
```json
{
    "message": "device_status_history table created successfully"
}
```

#### Record Device Status
**POST** `/api/device-history`

Record device status snapshot.

**Request Body:**
```json
{
    "device_id": 1,
    "device_name": "Pump001",
    "status": "ON",
    "mode": "AUTO",
    "uptime_seconds": 3600,
    "error_count": 0
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "history_id": 303
}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | Integer | Yes | Device identifier |
| `device_name` | String | No | Device display name |
| `status` | String | No | Current status (ON, OFF, ERROR) |
| `mode` | String | No | Operating mode (AUTO, MANUAL) |
| `uptime_seconds` | Integer | No | Total uptime in seconds |
| `error_count` | Integer | No | Number of errors since last reset |

#### Get Device History
**GET** `/api/device-history`

Retrieve device status history.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `device_id` | Integer | Required | Device ID |
| `limit` | Integer | 100 | Maximum records to return |

**Response:**
```json
{
    "history": [
        {
            "history_id": 303,
            "device_id": 1,
            "device_name": "Pump001",
            "status": "ON",
            "mode": "AUTO",
            "uptime_seconds": 3600,
            "error_count": 0,
            "created_at": "2026-02-15 17:00:00"
        }
    ],
    "count": 1
}
```

---

## Integration Examples

### Python - Complete Farm Monitoring

```python
import requests
from datetime import datetime

API_URL = "http://localhost:5000/api"

def initialize_all_tables():
    """Initialize all database tables"""
    tables = [
        '/device-logs/init',
        '/weather/init',
        '/alerts/init',
        '/maintenance/init',
        '/crop-health/init',
        '/device-history/init'
    ]
    
    for table in tables:
        response = requests.post(f"{API_URL}{table}")
        print(f"{table}: {response.json()}")

def log_device_action(device_id, action, old_value, new_value):
    """Log device state change"""
    payload = {
        "device_id": device_id,
        "device_name": f"Device_{device_id}",
        "action": action,
        "source": "APP",
        "old_value": old_value,
        "new_value": new_value
    }
    
    response = requests.post(f"{API_URL}/device-logs", json=payload)
    return response.json()

def record_crop_health(plot_id, cwsi, leaf_temp, soil_moisture):
    """Record crop health metrics"""
    payload = {
        "plot_id": plot_id,
        "cwsi_value": cwsi,
        "leaf_temperature": leaf_temp,
        "air_temperature": leaf_temp + 0.5,
        "soil_moisture": soil_moisture
    }
    
    response = requests.post(f"{API_URL}/crop-health", json=payload)
    result = response.json()
    
    if result.get('health_status') == 'Critical':
        create_alert(plot_id, "CROP_STRESS", "CRITICAL", 
                    f"CWSI critical: {cwsi}")
    
    return result

def create_alert(plot_id, alert_type, severity, message):
    """Create alert"""
    payload = {
        "plot_id": plot_id,
        "alert_type": alert_type,
        "severity": severity,
        "message": message
    }
    
    return requests.post(f"{API_URL}/alerts", json=payload).json()

def schedule_maintenance(device_id, maint_type, scheduled_date):
    """Schedule device maintenance"""
    payload = {
        "device_id": device_id,
        "maintenance_type": maint_type,
        "scheduled_date": scheduled_date,
        "status": "PENDING"
    }
    
    return requests.post(f"{API_URL}/maintenance", json=payload).json()

def get_farm_stats():
    """Get farm overview"""
    response = requests.get(f"{API_URL}/statistics/overview")
    return response.json()

# Usage
if __name__ == "__main__":
    initialize_all_tables()
    
    log_device_action(1, "ON", "OFF", "ON")
    record_crop_health(1, 0.45, 28.5, 65.0)
    get_farm_stats()
```

---

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request succeeded |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource not found |
| 500 | Server Error - Internal error |

---

## Best Practices

1. **Initialization**: Always call the `/init` endpoints when first deploying
2. **Error Handling**: Check HTTP status codes and error messages
3. **Rate Limiting**: Space API calls appropriately
4. **Data Validation**: Validate inputs before sending
5. **Timestamps**: Use ISO 8601 format for dates
6. **Security**: Use HTTPS in production
7. **Monitoring**: Log all critical operations

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-15 | Bin Data API |
| 2.0 | 2026-02-16 | Added 7 comprehensive endpoints |

