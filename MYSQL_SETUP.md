# MySQL Connection Setup Guide

## Problem
The app shows: `SocketException: Connection timed out, host: 10.0.2.2, port: 3306`

This happens because:
- `10.0.2.2` only works for **Android Emulator**
- **Physical devices** need your computer's actual IP address

## Quick Fix - 3 Steps

### Step 1: Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your active network (WiFi or Ethernet)
Example: `192.168.1.100`

**macOS/Linux:**
```bash
ifconfig
# or
ip addr show
```

### Step 2: Update Database Service

Open `lib/services/database_service.dart` and replace the IP address:

```dart
static const List<String> _hosts = [
  '192.168.1.100',  // ← Replace with YOUR computer's IP
  '10.0.2.2',       // Keep for emulator support
  'localhost',
];
```

### Step 3: Configure MySQL for Remote Access

**Edit MySQL Configuration:**

1. Find `my.ini` (Windows) or `my.cnf` (Linux/macOS):
   - Windows: `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
   - Linux: `/etc/mysql/my.cnf`

2. Change bind-address:
```ini
[mysqld]
bind-address = 0.0.0.0
# or comment it out:
# bind-address = 127.0.0.1
```

3. Restart MySQL:

**Windows:**
```bash
net stop MySQL80
net start MySQL80
```

**Linux:**
```bash
sudo systemctl restart mysql
```

**macOS:**
```bash
brew services restart mysql
```

**Grant Remote Access (Optional but recommended):**
```sql
CREATE USER 'root'@'%' IDENTIFIED BY '200413';
GRANT ALL PRIVILEGES ON smart_farm_db.* TO 'root'@'%';
FLUSH PRIVILEGES;
```

### Step 4: Ensure Same Network

Make sure your **phone and computer are on the same WiFi network**!

## Testing Connection

### Test from Command Line (Optional)
```bash
mysql -h YOUR_COMPUTER_IP -u root -p200413 smart_farm_db
```

### Test from App
1. Update the IP in `database_service.dart`
2. Hot restart the app: `R` in terminal
3. Check the Flutter console for connection messages:
   ```
   ✓ Successfully connected to MySQL at 192.168.1.100
   ```

## Troubleshooting

### Still can't connect?

1. **Firewall**: Allow port 3306 through Windows Firewall
   ```bash
   netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
   ```

2. **Verify MySQL is listening**:
   ```bash
   netstat -an | findstr 3306
   ```
   Should show: `0.0.0.0:3306` (not `127.0.0.1:3306`)

3. **Check phone can reach computer**:
   - Ping from phone using a network tool app
   - Try accessing `http://YOUR_IP:3306` in phone browser (will show error but proves connectivity)

4. **Different WiFi network?**
   - Both devices MUST be on same network
   - Disable mobile data on phone
   - Forget and reconnect to WiFi

## Quick Reference

| Device Type | Host to Use |
|------------|-------------|
| Android Emulator | `10.0.2.2` |
| Physical Phone | Your computer's IP (e.g., `192.168.1.100`) |
| iOS Simulator | `localhost` or your computer's IP |

## Current Configuration

The app will automatically try connections in this order:
1. First IP in list (your computer's IP for physical devices)
2. `10.0.2.2` (Android emulator)
3. `localhost` (fallback)

Just update the first IP address to match your setup!
