# 🔧 Connection Error - Troubleshooting Guide

**Problem**: `Connection error: TimeoutException after 0:00:10.000000`

**Cause**: Android Emulator cannot connect to your local API server

---

## ✅ Solution Steps

### 1️⃣ **API Server must be running**

Start your Flask API server FIRST:

```bash
cd smart-farm-flutter
python api_server.py
```

**Expected output:**
```
================================================== 70
[*] Flask API Server for Smart Farm
================================================== 70
Server running at: http://0.0.0.0:5000
```

✅**Wait for this before starting Flutter app**

---

### 2️⃣ **Verify the Fix in Code** ✅ (Already Done)

We already updated `lib/services/database_service.dart` to automatically detect platform:

```dart
// Auto-detects:
// - Android Emulator   → http://10.0.2.2:5000/api
// - iOS Simulator      → http://localhost:5000/api  
// - Web                → http://localhost:5000/api

late final String _apiBaseUrl = getApiBaseUrl();
```

**No manual IP changes needed!** ✅

---

### 3️⃣ **Verify AndroidManifest.xml** ✅ (Already Done)

We already added permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<application android:usesCleartextTraffic="true">
```

---

## 🚀 Steps to Test

### Option A: Android Emulator (Recommended)

```bash
# 1. Make sure API Server is running
python api_server.py    # Terminal 1

# 2. In another terminal, run Flutter
cd smart-farm-flutter
flutter clean           # Clear cache
flutter pub get        # Get deps
flutter run            # Run on emulator

# 3. Press 'R' for hot reload if you still see errors
```

**Expected Flow:**
1. Server starts on port 5000
2. Emulator app auto-connects to `http://10.0.2.2:5000/api`
3. Login screen shows message "✅ Credentials auto-filled"
4. Click LOGIN

---

### Option B: Physical Android Device (LAN Debug)

If you want to test on a real phone:

1. **Find your PC's IP address:**

```bash
# Windows - open PowerShell
ipconfig | findstr IPv4
# Look for something like: 192.168.1.100
```

2. **Edit database_service.dart** to use your IP:

```dart
String getApiBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://YOUR_PC_IP:5000/api'; // e.g., 192.168.1.100
  }
  return 'http://localhost:5000/api';
}
```

3. **Make sure:**
   - PC and phone on same WiFi network
   - API Server running and accessible: `http://192.168.1.100:5000`
   - Firewall allows port 5000

---

## ⚠️ Common Issues & Fixes

### Issue: Still Getting Timeout

**Solution:**
```bash
# 1. Hard clean and restart
flutter clean
flutter pub get

# 2. Restart emulator
flutter emulators
flutter emulators launch Pixel_4_API_34   # Your emulator name

# 3. Rebuild app
flutter run -v     # Verbose to see what's happening
```

---

### Issue: "Connection refused"

**Means:** API Server not running

**Fix:**
```bash
# Start server in separate terminal
python api_server.py

# Check it's working:
# Open browser: http://localhost:5000/api/environment
```

---

### Issue: "Certificate verification failed"

This shouldn't happen with HTTP, but if it does:

```dart
// Add to database_service.dart (temporary fix only):
var httpClient = HttpClient();
httpClient.badCertificateCallback = (cert, host, port) => true;
```

---

## 📋 Checklist Before Testing

- [ ] API Server running (`python api_server.py`)
- [ ] Firebase emulation (optional, flutter_fire)
- [ ] Emulator/device has internet permission
- [ ] `flutter clean && flutter pub get` completed
- [ ] Code changes applied (they are ✅)
- [ ] No hardcoded `localhost` URLs (auto-detection ✅)

---

## 🎯 Current Configuration

| Component | Android Emulator | iOS Simulator | Web |
|-----------|-----------------|---------------|-----|
| API Base URL | `10.0.2.2:5000` | `localhost:5000` | `localhost:5000` |
| Database Direct | Not used (HTTP API) | Uses direct MySQL if on same network | Not supported |
| Cleartext Traffic | ✅ Enabled | ✅ Enabled | ✅ Enabled |
| Status | ✅ Fixed | ✅ Ready | ✅ Ready |

---

## 🔍 Debug Mode (Verbose Output)

To see what's happening:

```bash
flutter run -v

# Look for these lines:
# - "Connecting to 10.0.2.2:5000"
# - "Response: 200"
# - "Login successful"
```

---

## 📞 If Still Having Issues

### Check API Server logs:

```bash
# Terminal where server is running should show:
✅ Bin data recorded: BIN001 - 4.5cm
POST /api/auth/login
Response: {'access_token': '...'}
```

### Check Flutter logs:

```bash
flutter logs  # In separate terminal

# Look for:
# ✅ Connected to API: 10.0.2.2:5000
# ✅ Database initialized
# ✅ Login response received
```

---

## 📝 Summary

**What we fixed:**
1. ✅ Auto-detect platform (Android/iOS/Web)
2. ✅ Use correct IP for Android Emulator (`10.0.2.2`)
3. ✅ Added INTERNET permission
4. ✅ Enabled cleartext traffic (HTTP)

**What you need to do:**
1. ✅ Run API Server first
2. ✅ Run Flutter app
3. ✅ Login with `admin` / `admin123`

**Result:** ✅ Should connect without timeout!

---

**Date**: February 16, 2026  
**Status**: Ready to Test ✅
