# วิธีรัน Smart Farm บน Chrome/Desktop (Flutter Web)

## ขั้นตอนที่ 1: ติดตั้ง Dependencies สำหรับ API Server

```bash
pip install flask flask-cors mysql-connector-python
```

## ขั้นตอนที่ 2: เริ่ม API Server

เปิด Terminal แรก และรัน:

```bash
cd d:\flutterfarmreact\smart-farm-flutter
python api_server.py
```

ต้องเห็นข้อความ:
```
🚀 Flask API Server for Smart Farm
Server running at: http://localhost:5000
```

**ไม่ต้องปิด Terminal นี้** - ให้ API Server รันต่อไป

## ขั้นตอนที่ 3: รัน Flutter Web

เปิด Terminal ใหม่ (Terminal ที่สอง) และรัน:

```bash
cd d:\flutterfarmreact\smart-farm-flutter
flutter run -d chrome
```

หรือถ้าต้องการรันบน Edge:
```bash
flutter run -d edge
```

## ขั้นตอนที่ 4: ทดสอบ

เปิด Developer Console ใน Chrome (F12) และดู Console logs:

**สำเร็จ:**
```
[OK] Successfully connected to MySQL at localhost (via HTTP API)
```

**ล้มเหลว:**
```
✗ Failed to connect to API server
```

## การทำงาน

### บน Mobile/Desktop App:
- เชื่อมต่อ MySQL โดยตรง (ไม่ผ่าน API)
- ใช้ `mysql1` package

### บน Web (Chrome/Edge):
- เชื่อมต่อผ่าน REST API (`api_server.py`)
- API Server เชื่อมต่อ MySQL แทน
- ใช้ `http` package

## Architecture

```
┌─────────────────┐
│  Mobile App     │ ──┐
└─────────────────┘   │
                      ├──► MySQL Database
┌─────────────────┐   │     (localhost:3306)
│  Desktop App    │ ──┘
└─────────────────┘

┌─────────────────┐      ┌──────────────┐
│   Web Browser   │ ───► │ API Server   │ ───► MySQL
│ (Chrome/Edge)   │ HTTP │ (Flask:5000) │
└─────────────────┘      └──────────────┘
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/environment` | ข้อมูลสภาพแวดล้อม (temp, humidity, lux) |
| GET | `/api/plots` | รายชื่อโรงเรือนทั้งหมด |
| POST | `/api/plots` | สร้างโรงเรือนใหม่ |
| PUT | `/api/plots/<id>` | แก้ไขโรงเรือน |
| DELETE | `/api/plots/<id>` | ลบโรงเรือน |
| GET | `/api/devices/<name>` | สถานะอุปกรณ์ |
| PUT | `/api/devices/<name>` | อัพเดทสถานะอุปกรณ์ |

## Troubleshooting

### CORS Error
ถ้าเจอ error เกี่ยวกับ CORS:
```
Access to XMLHttpRequest has been blocked by CORS policy
```

แก้ไข: API Server มี CORS enabled อยู่แล้ว (`flask-cors`)

### API Server ไม่ทำงาน
```bash
# ตรวจสอบว่า port 5000 ยังไม่ถูกใช้
netstat -an | findstr 5000

# ถ้า port ถูกใช้แล้ว ให้เปลี่ยนใน api_server.py:
app.run(debug=True, host='0.0.0.0', port=5001)

# และอัพเดทใน database_service.dart:
static const String _apiBaseUrl = 'http://localhost:5001/api';
```

### MySQL Connection Failed
ตรวจสอบว่า MySQL รันอยู่:
```bash
net start MySQL80
```

## Hot Reload

เมื่อแก้ไข code:
- **Flutter Web**: กด `r` ใน terminal (hot reload)
- **API Server**: จะ auto-reload เอง (debug mode)

## Production

สำหรับ production ควรใช้:
- **API Server**: Gunicorn หรือ uWSGI
- **Database**: Connection pooling
- **Security**: JWT authentication, HTTPS

## สรุป

| Platform | Connection Method |
|----------|-------------------|
| Android/iOS App | Direct MySQL |
| Windows/macOS Desktop | Direct MySQL |
| Web (Chrome/Edge/Safari) | HTTP API → MySQL |

[OK] รองรับครบทุก platform!
