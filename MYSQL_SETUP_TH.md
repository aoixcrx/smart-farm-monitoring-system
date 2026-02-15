# คู่มือการตั้งค่า MySQL สำหรับแอพ Smart Farm

## ปัญหาที่พบ
แอพแสดงข้อความ: `SocketException: Connection timed out, host: 10.0.2.2, port: 3306`

**สาเหตุ:**
- IP `10.0.2.2` ใช้ได้เฉพาะใน **Android Emulator** เท่านั้น
- **มือถือจริง** ต้องใช้ IP ของคอมพิวเตอร์ที่รัน MySQL

## วิธีแก้ไข - 3 ขั้นตอน

### ขั้นตอนที่ 1: ตรวจสอบ IP ของคอมพิวเตอร์

**IP ของคุณคือ:** `10.234.125.225` ✓

(ตรวจสอบแล้วด้วย `ipconfig`)

### ขั้นตอนที่ 2: ตั้งค่า MySQL ให้รับ Connection จากภายนอก

เปิดไฟล์ `my.ini` (อยู่ที่ `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`)

แก้ไขบรรทัดนี้:
```ini
[mysqld]
bind-address = 0.0.0.0
```

หรือ comment บรรทัดนี้ออก:
```ini
# bind-address = 127.0.0.1
```

**Restart MySQL:**
```bash
net stop MySQL80
net start MySQL80
```

### ขั้นตอนที่ 3: สร้าง User สำหรับ Remote Access

เปิด MySQL Command Line หรือ MySQL Workbench และรันคำสั่ง:

```sql
-- สร้าง user ที่สามารถเชื่อมต่อจาก IP ใดก็ได้
CREATE USER 'root'@'%' IDENTIFIED BY '200413';
GRANT ALL PRIVILEGES ON smart_farm_db.* TO 'root'@'%';
FLUSH PRIVILEGES;
```

หรือถ้ามี user อยู่แล้ว ให้อัพเดท:
```sql
UPDATE mysql.user SET host='%' WHERE user='root' AND host='localhost';
FLUSH PRIVILEGES;
```

### ขั้นตอนที่ 4: เปิด Port 3306 ใน Windows Firewall

เปิด Command Prompt (Run as Administrator) และรันคำสั่ง:

```bash
netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
```

### ขั้นตอนที่ 5: ตรวจสอบการเชื่อมต่อ

```bash
netstat -an | findstr 3306
```

ต้องแสดงผลเป็น:
```
TCP    0.0.0.0:3306    0.0.0.0:0    LISTENING
```

ถ้าแสดง `127.0.0.1:3306` แทน แปลว่า MySQL ยังไม่เปิดรับ connection จากภายนอก (ให้กลับไปทำขั้นตอนที่ 2)

## ทดสอบแอพ

### บน Android Emulator:
```bash
flutter run
```
จะเชื่อมต่อด้วย `10.0.2.2` อัตโนมัติ ✓

### บนมือถือจริง:
1. เชื่อมต่อมือถือและคอมพิวเตอร์ **เข้า WiFi เดียวกัน**
2. ปิด Mobile Data บนมือถือ
3. รันแอพ:
```bash
flutter run
```

จะเชื่อมต่อด้วย `10.234.125.225` อัตโนมัติ ✓

## ตรวจสอบข้อความใน Console

เมื่อแอพเริ่มทำงาน ให้ดูใน Flutter console:

**สำเร็จ:**
```
Attempting to connect to MySQL at 10.234.125.225:3306...
✓ Successfully connected to MySQL at 10.234.125.225
```

**ล้มเหลว:**
```
✗ Failed to connect to 10.234.125.225: Connection timed out
Attempting to connect to MySQL at 10.0.2.2:3306...
✓ Successfully connected to MySQL at 10.0.2.2
```

## แก้ปัญหาที่พบบ่อย

### 1. มือถือและคอมไม่ได้อยู่ WiFi เดียวกัน
- ตรวจสอบให้แน่ใจว่าทั้งสองเครื่องเชื่อมต่อ WiFi เดียวกัน
- ปิด Mobile Data บนมือถือ
- ลองใช้ Personal Hotspot จากมือถือเป็น WiFi

### 2. Firewall บล็อก Connection
```bash
# ตรวจสอบ Firewall rules
netsh advfirewall firewall show rule name=MySQL

# ถ้าไม่มี ให้เพิ่มใหม่
netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
```

### 3. MySQL ไม่รัน
```bash
# ตรวจสอบสถานะ
sc query MySQL80

# Start MySQL
net start MySQL80
```

### 4. ทดสอบ Connection จากมือถือ
- ติดตั้ง Network Analyzer app
- Ping ไป `10.234.125.225`
- ต้องได้รับ reply กลับมา

## สรุป

| อุปกรณ์ | IP ที่ใช้ |
|---------|-----------|
| Android Emulator | `10.0.2.2` |
| มือถือจริง | `10.234.125.225` |

แอพจะลองเชื่อมต่อตามลำดับ:
1. `10.234.125.225` (สำหรับมือถือจริง)
2. `10.0.2.2` (สำหรับ emulator)
3. `localhost` (fallback)

## Checklist ก่อนทดสอบ

- [ ] MySQL รันอยู่
- [ ] แก้ไข `my.ini` เป็น `bind-address = 0.0.0.0`
- [ ] Restart MySQL
- [ ] สร้าง user `root@'%'` หรืออัพเดท host permission
- [ ] เปิด port 3306 ใน Firewall
- [ ] มือถือและคอมอยู่ WiFi เดียวกัน
- [ ] ปิด Mobile Data บนมือถือ

## Hot Reload

หลังจากแก้ไข code แล้ว ไม่ต้อง rebuild ใหม่:
```
กด R ใน terminal (Hot Restart)
```

แอพจะรีสตาร์ทและลองเชื่อมต่อ MySQL ใหม่พร้อม IP ที่อัพเดทแล้ว!
