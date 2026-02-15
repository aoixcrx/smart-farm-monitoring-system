# Smart Farm Flutter Application

แอปพลิเคชัน Smart Farm ที่แปลงจาก React Native เป็น Flutter พร้อมระบบตรวจสอบข้อมูล (Data Validation) และการเชื่อมต่อ MySQL

## คุณสมบัติหลัก

### 1. ระบบตรวจสอบข้อมูล (Data Validation)

#### หน้าลงทะเบียน (Register Screen)
- ✅ ตรวจสอบความครบถ้วนของฟอร์ม (Empty State)
- ✅ ตรวจสอบรหัสผ่านให้ตรงกัน (Password Matching)
- ✅ แสดงความแข็งแรงของรหัสผ่าน (Password Strength Indicator)
- ✅ ตรวจสอบความแข็งแรงของรหัสผ่าน (ต้องมีตัวเลขผสมตัวอักษร)

#### หน้าเข้าสู่ระบบ (Login Screen)
- ✅ ตรวจสอบรูปแบบอีเมล (Email Format Check)
- ✅ ตรวจสอบความถูกต้องของบัญชีจากฐานข้อมูล MySQL (Account Verification)

#### หน้าควบคุมอุปกรณ์ (Control Screen)
- ✅ ตรวจสอบสถานะการเชื่อมต่อ (Connection Status)
- ✅ ตรวจสอบโหมดอัตโนมัติ (Auto Mode Conflict Check)
- ✅ ปิดการใช้งานปุ่มเมื่ออุปกรณ์ออฟไลน์หรืออยู่ในโหมดอัตโนมัติ

#### หน้าข้อมูล CWSI (Data Screen)
- ✅ ตรวจสอบประเภทไฟล์ (File Extension: .csv, .xlsx เท่านั้น)
- ✅ ตรวจสอบรูปแบบไฟล์ (File Format Validation)
- ✅ แสดงข้อความผิดพลาดเมื่อไฟล์ไม่ถูกต้อง

### 2. การเชื่อมต่อ MySQL

ระบบใช้ MySQL สำหรับ:
- เก็บข้อมูลผู้ใช้ (users)
- ตรวจสอบการเข้าสู่ระบบ
- เก็บสถานะอุปกรณ์ (device_status)
- เก็บข้อมูลเซนเซอร์ (sensor_data)

### 3. หน้าจอและฟีเจอร์

- **Splash Screen**: หน้าจอเริ่มต้นพร้อมแอนิเมชัน
- **Welcome Screen**: หน้าต้อนรับพร้อมการนำทาง
- **Login Screen**: เข้าสู่ระบบพร้อมการตรวจสอบ
- **Register Screen**: ลงทะเบียนพร้อมการตรวจสอบ
- **Home Screen**: แสดงข้อมูลสภาพอากาศและ GPS
- **Control Screen**: ควบคุมอุปกรณ์พร้อมการตรวจสอบสถานะ
- **Data Screen**: แสดงกราฟข้อมูล CWSI จาก ThingSpeak หรือไฟล์
- **Settings Screen**: หน้าตั้งค่าแอปพลิเคชัน

## การติดตั้ง

### 1. ความต้องการของระบบ

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- MySQL Server
- Android Studio / VS Code with Flutter extensions

### 2. ติดตั้ง Dependencies

```bash
cd smart-farm-flutter
flutter pub get
```

### 3. ตั้งค่า MySQL

1. สร้างฐานข้อมูล:

```sql
CREATE DATABASE smart_farm_db;
```

2. แก้ไขการตั้งค่าใน `lib/services/database_service.dart`:

```dart
static const String _host = 'localhost';  // หรือ IP ของ MySQL server
static const int _port = 3306;
static const String _database = 'smart_farm_db';
static const String _username = 'root';
static const String _password = 'your_password';
```

3. ตารางจะถูกสร้างอัตโนมัติเมื่อเปิดแอปครั้งแรก

### 4. ตั้งค่า Assets

คัดลอกไฟล์รูปภาพ `tree1.png` จาก `smart-farm/assets/` ไปยัง `smart-farm-flutter/assets/`

```bash
mkdir -p smart-farm-flutter/assets
cp smart-farm/assets/tree1.png smart-farm-flutter/assets/
```

### 5. ตั้งค่า Permissions

สำหรับ Android (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

สำหรับ iOS (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show weather information</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show weather information</string>
```

## การรันแอป

```bash
flutter run
```

## โครงสร้างโปรเจกต์

```
smart-farm-flutter/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── providers/
│   │   ├── theme_provider.dart   # Theme management
│   │   ├── auth_provider.dart    # Authentication logic
│   │   └── device_provider.dart  # Device control logic
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── control_screen.dart
│   │   ├── data_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── database_service.dart # MySQL connection
│   │   └── weather_service.dart  # Weather API
│   └── widgets/
│       └── theme_toggle.dart     # Theme toggle widget
├── assets/
│   └── tree1.png                 # Background image
└── pubspec.yaml                  # Dependencies
```

## การตรวจสอบข้อมูล (Validation Logic)

### Register Screen
- **Empty Check**: ตรวจสอบทุกช่องต้องกรอกครบ
- **Password Match**: รหัสผ่านและยืนยันรหัสผ่านต้องตรงกัน
- **Password Strength**: 
  - ตรวจสอบความยาว (>= 6 ตัวอักษร)
  - ตรวจสอบตัวพิมพ์ใหญ่
  - ตรวจสอบตัวเลข
  - ตรวจสอบอักขระพิเศษ
- **User Type**: ต้องเลือกประเภทผู้ใช้

### Login Screen
- **Email Format**: ถ้า username เป็นอีเมล ต้องมีรูปแบบถูกต้อง
- **Database Verification**: ตรวจสอบ username/password จาก MySQL

### Control Screen
- **Connection Status**: ตรวจสอบอุปกรณ์ออนไลน์หรือไม่
- **Auto Mode Check**: ถ้าอยู่ในโหมดอัตโนมัติ ไม่สามารถควบคุมด้วยมือได้
- **Button Disable**: ปุ่มควบคุมจะถูกปิดใช้งานเมื่อไม่สามารถควบคุมได้

### Data Screen
- **File Extension**: ตรวจสอบเฉพาะไฟล์ .csv, .xlsx, .xls
- **File Format**: ตรวจสอบรูปแบบไฟล์และโครงสร้างข้อมูล
- **Error Handling**: แสดงข้อความผิดพลาดที่ชัดเจน

## API และบริการภายนอก

- **Weather API**: Open-Meteo (ฟรี, ไม่ต้องใช้ API Key)
- **ThingSpeak**: Channel ID 12397 (Public Channel)
- **Location**: ใช้ GPS ของอุปกรณ์

## หมายเหตุ

1. ระบบใช้ MySQL ชั่วคราวสำหรับการตรวจสอบข้อมูลตามที่กำหนด
2. รหัสผ่านยังไม่ได้เข้ารหัส (ควรเพิ่ม bcrypt หรือ hashing อื่นๆ ในโปรดักชัน)
3. ไฟล์รูปภาพ `tree1.png` ต้องถูกคัดลอกไปยัง `assets/` folder

## การพัฒนาต่อ

- [ ] เพิ่มการเข้ารหัสรหัสผ่าน (bcrypt)
- [ ] เพิ่ม JWT Authentication
- [ ] เพิ่ม Unit Tests
- [ ] เพิ่ม Integration Tests
- [ ] เพิ่ม Error Logging
- [ ] เพิ่ม Push Notifications

## ผู้พัฒนา

Smart Farm Application - Converted from React Native to Flutter

## License

Private Project
# smart-farm-monitoring-system
