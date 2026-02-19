# Trash Bin Data API Documentation

**Version**: 1.0  
**Last Updated**: February 16, 2026  
**Base URL**: `http://localhost:5000/api`

---

## Overview

The Trash Bin Data API provides endpoints for recording and retrieving distance measurements from ultrasonic sensors mounted on trash bins. This API is designed to work with ESP32 controllers that monitor bin fill levels in real-time.

### Key Features
- Real-time data collection from ESP32 sensors
- Historical data retrieval and analysis
- Automatic table initialization
- RESTful JSON interface
- Timestamp support for data recording

---

## Database Schema

### trash_bin_logs Table

```sql
CREATE TABLE trash_bin_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    bin_id VARCHAR(50) NOT NULL,
    distance_cm DECIMAL(6,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bin_created (bin_id, created_at)
)
```

| Column | Type | Description |
|--------|------|-------------|
| `log_id` | BIGINT | Unique identifier for the record |
| `bin_id` | VARCHAR(50) | Identifier for the trash bin (e.g., "BIN001") |
| `distance_cm` | DECIMAL(6,2) | Distance from sensor to waste level in centimeters |
| `created_at` | DATETIME | Timestamp when data was recorded (default: current time) |

---

## Endpoints

### 1. Record Bin Data

**Endpoint**: `POST /api/bin-data`

**Description**: Record trash bin distance data from an ESP32 sensor. This endpoint accepts sensor readings and stores them in the database.

#### Request

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
    "bin_id": "BIN001",
    "distance_cm": 4.5,
    "timestamp": "2026-02-15T17:00:00"
}
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `bin_id` | String | Yes | Unique identifier for the trash bin |
| `distance_cm` | Float/Decimal | Yes | Distance from sensor to waste surface (in cm) |
| `timestamp` | String | No | ISO 8601 timestamp of measurement. If omitted, uses server time |

#### Response

**Success (201 Created)**:
```json
{
    "status": "success",
    "message": "Data recorded",
    "log_id": 123
}
```

**Error (400 Bad Request)**:
```json
{
    "error": "Missing required fields: bin_id, distance_cm"
}
```

**Error (500 Server Error)**:
```json
{
    "error": "Database connection failed"
}
```

#### Example Usage (cURL)

```bash
curl -X POST http://localhost:5000/api/bin-data \
  -H "Content-Type: application/json" \
  -d '{
    "bin_id": "BIN001",
    "distance_cm": 4.5,
    "timestamp": "2026-02-15T17:00:00"
  }'
```

#### Example Usage (Python)

```python
import requests
import json
from datetime import datetime

url = "http://localhost:5000/api/bin-data"
payload = {
    "bin_id": "BIN001",
    "distance_cm": 4.5,
    "timestamp": datetime.now().isoformat()
}

response = requests.post(url, json=payload)
print(response.json())
```

#### Example Usage (ESP32 Arduino Code)

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
const char* serverUrl = "http://your-server:5000/api/bin-data";
const char* binId = "BIN001";

void sendBinData(float distance) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    
    DynamicJsonDocument doc(200);
    doc["bin_id"] = binId;
    doc["distance_cm"] = distance;
    doc["timestamp"] = getISOTimestamp();
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.POST(payload);
    String response = http.getString();
    
    Serial.println("HTTP Code: " + String(httpCode));
    Serial.println("Response: " + response);
    
    http.end();
  } else {
    Serial.println("WiFi not connected");
  }
}

String getISOTimestamp() {
  time_t now = time(nullptr);
  struct tm* timeinfo = localtime(&now);
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%S", timeinfo);
  return String(buffer);
}
```

---

### 2. Retrieve Bin Data

**Endpoint**: `GET /api/bin-data`

**Description**: Retrieve historical distance measurements for trash bins. Can filter by bin ID and limit results.

#### Request

**Query Parameters**:
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `bin_id` | String | No | All bins | Filter results by specific bin ID |
| `limit` | Integer | No | 100 | Maximum number of records to return |

#### Response

**Success (200 OK)**:
```json
{
    "logs": [
        {
            "log_id": 123,
            "bin_id": "BIN001",
            "distance_cm": 4.5,
            "created_at": "2026-02-15 17:00:00"
        },
        {
            "log_id": 122,
            "bin_id": "BIN001",
            "distance_cm": 5.2,
            "created_at": "2026-02-15 16:55:00"
        }
    ],
    "count": 2
}
```

**Error (500 Server Error)**:
```json
{
    "error": "Database connection failed"
}
```

#### Example Usage (cURL)

```bash
# Get all data
curl http://localhost:5000/api/bin-data

# Get data for specific bin
curl "http://localhost:5000/api/bin-data?bin_id=BIN001"

# Get last 50 records
curl "http://localhost:5000/api/bin-data?limit=50"

# Combined filter
curl "http://localhost:5000/api/bin-data?bin_id=BIN001&limit=50"
```

#### Example Usage (JavaScript/Fetch)

```javascript
async function getBinData(binId = null, limit = 100) {
  let url = 'http://localhost:5000/api/bin-data?limit=' + limit;
  
  if (binId) {
    url += '&bin_id=' + binId;
  }
  
  try {
    const response = await fetch(url);
    const data = await response.json();
    console.log('Bin Data:', data);
    return data;
  } catch (error) {
    console.error('Error fetching bin data:', error);
  }
}

// Usage
getBinData('BIN001', 50);
```

---

### 3. Initialize Bin Table

**Endpoint**: `POST /api/bin-data/init`

**Description**: Create the `trash_bin_logs` table if it doesn't already exist. This is useful for initial setup or resetting the database.

#### Request

**Headers**:
```
Content-Type: application/json
```

**Body**: (empty)

#### Response

**Success (200 OK)**:
```json
{
    "message": "trash_bin_logs table created successfully"
}
```

**Error (500 Server Error)**:
```json
{
    "error": "Database connection failed"
}
```

#### Example Usage (cURL)

```bash
curl -X POST http://localhost:5000/api/bin-data/init \
  -H "Content-Type: application/json"
```

---

## HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource successfully created |
| 400 | Bad Request | Missing or invalid parameters |
| 500 | Server Error | Database or server error |

---

## Data Validation

### Input Validation

- **bin_id**: Required, non-empty string (max 50 characters)
- **distance_cm**: Required, numeric value (max 999.99 cm)
- **timestamp**: Optional, should be ISO 8601 format

### Database Constraints

- Unique combination of bin_id + timestamp is not enforced (duplicates allowed)
- Distance values are stored with 2 decimal precision
- Records are indexed by (bin_id, created_at) for efficient queries

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Missing required fields: bin_id, distance_cm" | Missing required parameter | Ensure both bin_id and distance_cm are provided |
| "Database connection failed" | Database unavailable | Check MySQL server status and connection config |
| "No data provided" | Empty request body | Ensure request body contains valid JSON |

---

## Usage Examples

### Scenario 1: Single Bin Monitoring

Monitor a single trash bin and check fill level every 5 minutes:

```python
import requests
from datetime import datetime
import time

BIN_ID = "BIN001"
API_URL = "http://localhost:5000/api/bin-data"
MAX_DISTANCE = 30  # cm (empty bin)
MIN_DISTANCE = 5   # cm (full bin)

def check_bin_fill_level():
    while True:
        # Simulate sensor reading
        distance = read_ultrasonic_sensor()
        
        # Calculate fill percentage
        fill_percent = ((MAX_DISTANCE - distance) / (MAX_DISTANCE - MIN_DISTANCE)) * 100
        fill_percent = max(0, min(100, fill_percent))  # Clamp 0-100
        
        # Send data to API
        payload = {
            "bin_id": BIN_ID,
            "distance_cm": distance,
            "timestamp": datetime.now().isoformat()
        }
        
        response = requests.post(API_URL, json=payload)
        
        if response.status_code == 201:
            print(f"✅ Bin fill: {fill_percent:.1f}%")
            
            if fill_percent >= 90:
                print("⚠️  BIN FULL - Alert maintenance!")
        else:
            print(f"❌ Error: {response.json()}")
        
        time.sleep(300)  # Wait 5 minutes

def read_ultrasonic_sensor():
    # Replace with actual sensor reading code
    pass
```

### Scenario 2: Multiple Bins Monitoring

Monitor multiple trash bins in a facility:

```python
import requests
from datetime import datetime

BINS = ["BIN001", "BIN002", "BIN003", "BIN004"]
API_URL = "http://localhost:5000/api/bin-data"

def monitor_all_bins(sensor_readings):
    """
    sensor_readings: dict like {"BIN001": 4.5, "BIN002": 12.3, ...}
    """
    for bin_id, distance in sensor_readings.items():
        payload = {
            "bin_id": bin_id,
            "distance_cm": distance,
            "timestamp": datetime.now().isoformat()
        }
        
        response = requests.post(API_URL, json=payload)
        
        if response.status_code == 201:
            print(f"✅ {bin_id}: {distance}cm recorded")
        else:
            print(f"❌ {bin_id}: {response.json()['error']}")

# Get last 24 hours of data for BIN001
def get_bin_history(bin_id, limit=288):  # ~288 readings = 24 hours at 5min intervals
    response = requests.get(API_URL, params={"bin_id": bin_id, "limit": limit})
    
    if response.status_code == 200:
        data = response.json()
        print(f"Retrieved {data['count']} records for {bin_id}")
        return data['logs']
    else:
        print(f"Error: {response.json()['error']}")
        return []
```

---

## Integration Checklist

- [ ] Verify MySQL database is running and accessible
- [ ] Ensure Flask server is running on port 5000
- [ ] Test `POST /api/bin-data/init` to create table
- [ ] Test `POST /api/bin-data` with sample data
- [ ] Test `GET /api/bin-data` to retrieve records
- [ ] Configure ESP32 with correct WiFi and server URL
- [ ] Set up monitoring dashboard (optional)
- [ ] Configure alerts for high fill levels (optional)

---

## Support & Troubleshooting

### Server Not Responding

```bash
# Check if server is running
curl http://localhost:5000/api/bin-data

# View Flask logs for detailed error messages
# Restart server: python api_server.py
```

### Database Connection Issues

```bash
# Test MySQL connection
mysql -u root -p -h localhost -D smart_farm_db

# Check MySQL service status (Windows)
# Check MySQL service status (Linux)
sudo systemctl status mysql
```

### Data Not Saving

1. Verify `bin_id` and `distance_cm` are provided
2. Check database disk space
3. Review Flask server logs for SQL errors
4. Ensure table exists: `SHOW TABLES LIKE 'trash_bin_logs';`

---

## Future Enhancements

- [ ] Add authentication/API key requirements
- [ ] Implement data retention policies (auto-delete old records)
- [ ] Add alerts for abnormal patterns
- [ ] Real-time WebSocket updates
- [ ] Data export to CSV/Excel
- [ ] Predictive analytics for maintenance scheduling
- [ ] Mobile app integration
- [ ] Dashboard with visualization charts

---

**Revision History**

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-16 | Initial API documentation |
