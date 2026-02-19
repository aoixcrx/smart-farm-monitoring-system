# Smart Farm Flutter Application

Smart Farm application developed using Flutter.

## Core Features

### 1. Data Validation System

#### Register Screen

* Form completeness validation (Empty state check)
* Password confirmation matching
* Password strength indicator
* Password strength validation (must include both letters and numbers)

#### Login Screen

* Account verification from the database

#### Control Screen

* Connection status verification
* Automatic mode conflict check
* Disable control buttons when the device is offline or in automatic mode

#### CWSI Data Screen

* File type validation (File extensions: .csv, .xlsx only)
* File format validation
* Display error messages when the file is invalid

---

## 2. Connectivity

* Store user data (`users`)
* Verify login authentication
* Store device status (`device_status`)
* Store sensor data (`sensor_data`)

---

## 3. Screens and Features

* **Splash Screen**: Startup screen with animation
* **Welcome Screen**: Welcome page with navigation
* **Login Screen**: Login with validation
* **Register Screen**: Registration with validation
* **Home Screen**: Displays weather information and GPS location
* **Control Screen**: Device control with status verification
* **Data Screen**: Displays CWSI graphs from ThingSpeak or uploaded files
* **Settings Screen**: Application settings page

---

## Installation

### 1. System Requirements

* Flutter SDK (>= 3.0.0)
* Dart SDK (>= 3.0.0)
* MySQL Server
* Android Studio / VS Code with Flutter extensions

---

### 2. Install Dependencies

```bash
cd smart-farm-flutter
flutter pub get
```

---

### 3. MySQL Configuration

1. Create the database:

```sql
CREATE DATABASE smart_farm_db;
```

2. Update the configuration in `lib/services/database_service.dart`:

```dart
static const String _host = 'localhost';  // Or MySQL server IP
static const int _port = 3306;
static const String _database = 'smart_farm_db';
static const String _username = 'root';
static const String _password = 'your_password';
```

3. Tables will be created automatically when the app runs for the first time.

---

### 4. Configure Assets

Copy the image file `tree1.png` from `smart-farm/assets/` to `smart-farm-flutter/assets/`

```bash
mkdir -p smart-farm-flutter/assets
cp smart-farm/assets/tree1.png smart-farm-flutter/assets/
```

---

### 5. Set Permissions

For Android (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

For iOS (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show weather information</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show weather information</string>
```

---

## Running the Application

```bash
flutter run
```

---

## Project Structure

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

---

## Validation Logic

### Register Screen

* **Empty Check**: All fields must be completed
* **Password Match**: Password and confirm password must match
* **Password Strength**:

  * Minimum length (>= 6 characters)
  * Must include uppercase letters
  * Must include numbers
  * Must include special characters
* **User Type**: User type selection is required

### Login Screen

* **Email Format**: If the username is an email, it must follow a valid format
* **Database Verification**: Validate username/password against MySQL

### Control Screen

* **Connection Status**: Check whether the device is online
* **Auto Mode Check**: Manual control is disabled when automatic mode is enabled
* **Button Disable**: Control buttons are disabled when control is not allowed

### Data Screen

* **File Extension**: Only .csv, .xlsx, .xls files are allowed
* **File Format**: Validate file structure and data format
* **Error Handling**: Display clear error messages

---

## External APIs and Services

* **Weather API**: Open-Meteo (free, no API key required)
* **ThingSpeak**: Channel ID 12397 (Public Channel)
* **Location Services**: Device GPS

---

## Notes

1. The system currently uses MySQL for validation and data storage.
2. Passwords are not encrypted (bcrypt or other hashing methods are recommended for production).
3. The image file `tree1.png` must be placed in the `assets/` folder.

---

## Future Improvements

* [ ] Implement password encryption (bcrypt)
* [ ] Add JWT authentication
* [ ] Add unit tests
* [ ] Add integration tests
* [ ] Add structured error logging
* [ ] Add push notifications

---

## Developer

Smart Farm Application – Flutter

---

## License

Private Project
