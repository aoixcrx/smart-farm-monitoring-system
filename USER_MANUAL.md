# Smart Farm User Manual v2.0

**Version:** 2.0  
**Last Updated:** February 15, 2026  
**Language:** English

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [User Registration](#user-registration)
5. [User Login](#user-login)
6. [Dashboard & Navigation](#dashboard--navigation)
7. [Managing Plots](#managing-plots)
8. [Monitoring Sensors](#monitoring-sensors)
9. [Controlling Devices](#controlling-devices)
10. [Data Analysis](#data-analysis)
11. [Settings](#settings)
12. [Troubleshooting](#troubleshooting)
13. [FAQ](#faq)

---

## Getting Started

Welcome to the Smart Farm application! This manual will guide you through all features and how to use them effectively.

### What is Smart Farm?

Smart Farm is an IoT-powered agriculture management system that helps you:
- **Monitor** soil conditions, temperature, humidity, and plant health in real-time
- **Control** irrigation systems, lights, and other devices remotely
- **Analyze** historical data to optimize crop production
- **Predict** plant stress and take preventive action
- **Track** multiple farms/plots simultaneously

### Key Features

✅ Real-time sensor monitoring  
✅ Device automation and control  
✅ Data analytics and trends  
✅ Mobile-first design  
✅ Offline functionality  
✅ Multi-plot management  

---

## System Requirements

### Minimum Requirements

| Requirement | Specification |
|-------------|---------------|
| **OS** | Android 5.0+, iOS 11.0+ |
| **Storage** | 50 MB minimum |
| **RAM** | 2 GB minimum |
| **Network** | WiFi or 4G/5G |
| **Camera** | Not required |
| **GPS** | Optional (for location tagging) |

### Recommended Requirements

| Specification |
|---------------|
| Android 10+ or iOS 14+ |
| 100 MB free storage |
| 4 GB+ RAM |
| High-speed WiFi (5 GHz) |
| Modern smartphone processor |

---

## Installation

### Step 1: Download the App

**For Android:**
1. Open Google Play Store on your device
2. Search for "Smart Farm"
3. Tap "Install"
4. Accept permissions when prompted

**For iOS:**
1. Open App Store on your device
2. Search for "Smart Farm"
3. Tap "Get"
4. Authenticate with Face ID, Touch ID or Apple ID
5. Wait for installation to complete

### Step 2: Grant Permissions

The app requests the following permissions:

| Permission | Purpose |
|-----------|---------|
| **Internet** | Connect to Smart Farm API |
| **Camera** | Scan QR codes for device pairing |
| **Location** | Tag photos with GPS coordinates |
| **Storage** | Save photos and data files |

### Step 3: Initial Setup

1. Launch the Smart Farm app
2. Choose language preference
3. Review terms of service
4. Proceed to registration or login

---

## User Registration

### Create New Account

1. **Open the app** and tap "Create Account"

2. **Enter your details:**
   - **Username:** 3-50 characters (letters, numbers, _, -)
   - **Email:** Valid email address
   - **Password:** At least 6 characters (strong password recommended)

3. **Password Requirements:**
   - ✓ Minimum 6 characters
   - ✓ Mix of uppercase and lowercase (recommended)
   - ✓ Include numbers/special characters (recommended)

4. **Tap "Create Account"**

5. **Verify Email:**
   - Check your email for verification link
   - Click the link to activate your account
   - Return to the app to login

### Password Tips

✅ Use a mix of letters, numbers, and symbols  
✅ Make it at least 12 characters for better security  
✅ Avoid common patterns (123456, qwerty)  
✅ Use a unique password not used elsewhere  
❌ Don't share with anyone  

---

## User Login

### Log In to Your Account

1. **Open the app**

2. **On Welcome Screen:**
   - Tap "Login" (if you already have account)

3. **Enter Credentials:**
   - **Username:** Your registered username
   - **Password:** Your account password

4. **Optional - Remember Me:**
   - Check "Remember Me" to auto-fill username next time
   - Uncheck for shared devices

5. **Tap "Login"**

### First Login

- System initializes your account
- Empty dashboard is normal (no data yet)
- Create your first plot in next section

### Login Issues

**Forgot Password?**
- Tap "Forgot Password"
- Enter registered email
- Click recovery link sent to your email
- Create new password

**Account Locked?**
- Wait 30 minutes and try again
- Contact support if issue persists

---

## Dashboard & Navigation

### Main Dashboard

After login, you'll see the main dashboard with:

**Top Section:**
- Welcome greeting with current date/time
- Quick status summary
- Active alerts (if any)

**Main Sections:**
- **Overview:** Quick glance of all plots and devices
- **Plots:** Manage your agricultural plots
- **Sensors:** View real-time sensor readings
- **Devices:** Control irrigation, lights, fans, etc.
- **Analysis:** Historical data and trends
- **Settings:** User preferences

### Bottom Navigation

| Icon | Screen | Function |
|------|--------|----------|
| 🏠 | Home | Main dashboard |
| 📊 | Data | Sensor data and analytics |
| ⚙️ | Devices | Device control |
| 👤 | Account | Profile and settings |

### Quick Access Menu

Swipe left from left edge to access:
- Favorites
- Recent activity
- Quick shortcuts

---

## Managing Plots

### Create a New Plot

1. **Tap "Plots" on Dashboard**

2. **Tap "+" or "Add New Plot"**

3. **Enter Plot Details:**
   - **Plot Name:** E.g., "North Field", "Greenhouse 1" (max 100 characters)
   - **Planting Date:** Select date plant was sown/transplanted
   - **Crop Type:** Select from dropdown (optional)
   - **Area:** Size in acres or hectares (optional)

4. **Tap "Create Plot"**

5. **Next Steps:**
   - Assign devices to plot
   - Connect sensors
   - Set automation rules

### View Plot Details

1. Tap any plot from the list
2. See:
   - Latest sensor readings
   - Device status
   - Historical trends
   - Plot information

### Edit Plot

1. **Open Plot**
2. **Tap "Edit" or ⚙️ icon**
3. **Update information:**
   - Plot name
   - Planting date
   - Crop type
   - Other details
4. **Tap "Save Changes"**

### Delete Plot

1. **Open Plot**
2. **Tap "More" (three dots)**
3. **Select "Delete Plot"**
4. **Confirm deletion**
   - All associated data will be deleted
   - Cannot be undone

### Best Practices

✅ Use descriptive plot names  
✅ Update planting date accurately  
✅ Assign appropriate soil type  
✅ Set realistic crop duration  

---

## Monitoring Sensors

### View Real-Time Data

1. **Tap "Sensors" in navigation**

2. **Select Plot:**
   - Choose which plot to monitor
   - Swipe to switch between plots

3. **Current Readings:**
   - **Temperature (Air):** Ambient temperature in °C
   - **Temperature (Leaf):** Plant leaf temperature
   - **Humidity:** Relative humidity %
   - **Light Intensity:** LUX (brightness)
   - **Soil Moisture:** %
   - **Stress Index:** CWSI value (0-1)
   - **Last Updated:** Time of latest reading

### Update Frequency

- **Real-time:** Updates every 5 minutes
- **Manual Refresh:** Pull down to refresh immediately
- **Auto-sync:** Syncs when app regains network

### Understanding Sensor Values

| Sensor | Ideal Range | Warning | Critical |
|--------|------------|---------|----------|
| **Air Temp** | 20-30°C | 15-35°C | <10°C, >40°C |
| **Humidity** | 60-80% | 40-90% | <30%, >95% |
| **Light (Lux)** | 20,000-50,000 | 5,000-100,000 | <2,000 |
| **Soil Moisture** | 60-80% | 40-90% | <30%, >95% |
| **Stress Index** | 0-0.3 | 0.3-0.7 | >0.7 |

### View History

1. **Tap "History" or "View More"**

2. **Select time range:**
   - Last 24 hours
   - Last 7 days
   - Last 30 days
   - Custom range

3. **View charts:**
   - Line graphs for each sensor
   - Compare readings over time
   - Identify patterns and trends

### Export Data

1. **Tap "Export" button**
2. **Select format:**
   - CSV (for Excel)
   - PDF (for printing/sharing)
   - JSON (for analysis)
3. **Choose email or save to device**

---

## Controlling Devices

### Device Types

The system supports:
- **Water Pump:** Irrigation control
- **Grow Light:** LED/fluorescent lighting
- **Fan:** Air circulation
- **Heater:** Temperature control
- **Cooler:** Cooling system

### Add Device

1. **Tap "Devices"**

2. **Tap "+" or "Add Device"**

3. **Enter Device Details:**
   - **Device Name:** E.g., "Main Pump", "East Lights"
   - **Device Type:** Select from list
   - **Plot:** Assign to plot
   - **Status:** ON/OFF
   - **Mode:** AUTO or MANUAL

4. **Tap "Create Device"**

### Control Device Manually

1. **Tap desired device**

2. **Toggle Status:**
   - **ON (Blue):** Device is running
   - **OFF (Gray):** Device is stopped

3. **Changes apply immediately**

4. **Feedback:** Confirmation notification shows

### Set Automation Schedule

1. **Select Device**

2. **Tap "Schedule"**

3. **Create Schedule:**
   - **ON Time:** When to turn on (e.g., 6:00 AM)
   - **OFF Time:** When to turn off (e.g., 6:00 PM)
   - **Days:** Select days of week
   - **Repeat:** Daily/Weekly/Custom

4. **Enable Schedule** - Toggle switch

5. **Tap "Save"**

### Schedule Management

| Feature | Details |
|---------|---------|
| **Multiple Schedules** | Create different schedules per day |
| **Override** | Manually control overrides automation |
| **Pause** | Disable schedule temporarily |
| **Edit** | Modify time or days |
| **Delete** | Remove schedule |

### Device History

1. **Select Device**
2. **Tap "History"** or "Activity Log"
3. See all ON/OFF actions with:
   - Timestamp
   - Source (AUTO, APP, MANUAL)
   - Duration

---

## Data Analysis

### Dashboard Statistics

**Top Cards Show:**
- Average temperature
- Cumulative water used
- Light hours today
- Device uptime %

### Charts & Graphs

**Available Views:**
- Temperature trends
- Humidity patterns
- Light cycles
- Water consumption
- Stress predictions

**Time Ranges:**
- Daily (24 hours)
- Weekly (7 days)
- Monthly (30 days)
- Yearly (365 days)
- Custom range

### Insights

1. **Tap "Insights"**

2. **View recommendations:**
   - "Increase irrigation by 20%"
   - "Temperature dropping - check heater"
   - "Plant stress detected in Plot 2"

3. **Take Action:**
   - Implement suggested changes
   - Disable notifications if not needed

### Stress Prediction

**CWSI (Crop Water Stress Index):**
- **Green (0-0.3):** Plant is well-watered
- **Yellow (0.3-0.7):** Mild stress, monitor closely
- **Red (0.7-1.0):** Severe stress, take action immediately

**Actions to take:**
1. Increase watering frequency
2. Check for pest/disease
3. Review humidity levels
4. Consult agronomist

---

## Settings

### Account Settings

1. **Tap Account icon (bottom)**

2. **Options:**
   - **Profile:** Edit username, email
   - **Password:** Change password
   - **Notifications:** Enable/disable alerts
   - **Language:** Change app language
   - **Timezone:** Set your timezone

### Notification Preferences

**Types:**
- Critical Alerts (device failures)
- Warnings (values out of range)
- Info (daily summary)
- Reminders (maintenance)

**Turn On/Off:**
- Toggle switches per type
- Set quiet hours (no notifications 10 PM - 6 AM)
- Customize alert thresholds

### App Settings

| Setting | Options |
|---------|---------|
| **Theme** | Light, Dark, Auto |
| **Data Updates** | 5 min, 15 min, 30 min, 1 hour |
| **Units** | Metric (°C) or Fahrenheit (°F) |
| **Date Format** | DD/MM/YYYY, MM/DD/YYYY, etc. |
| **Offline Mode** | Enable for local-only access |

### Data & Privacy

- **Export My Data:** Download all your data
- **Delete Account:** Permanently remove account
- **Privacy Policy:** View data handling practices
- **Terms of Service:** View app terms

---

## Troubleshooting

### Login Issues

**Problem:** "Invalid credentials"
- **Solution:** 
  - Verify username is correct (case-sensitive)
  - Check CAPS LOCK is off
  - Reset password if forgotten

**Problem:** "Cannot connect to server"
- **Solution:**
  - Check internet connection
  - Wait a few moments and retry
  - Check if API is accessible
  - Contact support if persistent

### Sensor Issues

**Problem:** "No sensor data"
- **Solution:**
  - Verify sensor is powered on
  - Check WiFi connection
  - Ensure sensors are properly connected
  - Restart app

**Problem:** "Outdated readings"
- **Solution:**
  - Check internet connection
  - Manually refresh by pulling down
  - Restart app
  - Check sensor battery level

### Device Issues

**Problem:** "Cannot control device"
- **Solution:**
  - Verify device is paired with app
  - Check device power
  - Verify WiFi signal strength
  - Restart device

**Problem:** "Device offline"
- **Solution:**
  - Check device network connection
  - Restart device
  - Move closer to WiFi router
  - Check firewall/router settings

### App Crashes

**Problem:** "App keeps crashing"
- **Solution:**
  - Force close app (Settings > Apps > Smart Farm > Force Stop)
  - Clear app cache (Settings > Apps > Smart Farm > Storage > Clear Cache)
  - Reinstall app if issue persists

### Data Issues

**Problem:** "Missing historical data"
- **Solution:**
  - Check selected plot
  - Ensure sensors were active during that period
  - Verify date range selection

**Problem:** "Graphs not loading"
- **Solution:**
  - Refresh data by pulling down
  - Try 1-hour update interval first
  - Check available storage space

---

## FAQ

### General Questions

**Q: How much does the app cost?**  
A: Smart Farm is free to download. Some premium features may require subscription.

**Q: Can I use multiple devices?**  
A: Yes, your account syncs across devices. Login with same credentials.

**Q: Is my data secure?**  
A: Yes, all data is encrypted in transit and at rest. Passwords are securely hashed.

**Q: Can I offline without internet?**  
A: Limited offline mode available. Most features require internet connection.

### Technical Questions

**Q: How often are sensor readings updated?**  
A: Default 5 minutes. Adjustable in settings (5 min - 1 hour).

**Q: What's the maximum number of plots?**  
A: Unlimited plots with standard account.

**Q: How far back can I see historical data?**  
A: 2 years of historical data stored.

**Q: Can I export my data?**  
A: Yes, from Settings > Export Data (CSV, PDF, JSON formats).

### Troubleshooting

**Q: Why is the app slow?**  
A: 
- Clear app cache
- Reduce data update frequency
- Close other apps
- Check available storage (need 50+ MB free)

**Q: Can I delete my account?**  
A: Yes, from Settings > Delete Account. All data will be permanently removed.

**Q: How do I get support?**  
A: Contact: support@smartfarm.com or use in-app chat feature.

---

## Contact & Support

### Technical Support

**Email:** support@smartfarm.com  
**Phone:** +1 (800) FARM-101  
**Website:** https://www.smartfarm.com  
**Hours:** Monday-Friday, 9 AM - 5 PM (EST)

### Community

- **Forum:** https://forum.smartfarm.com
- **Facebook:** @SmartFarmApp
- **Twitter:** @SmartFarmApp
- **YouTube:** SmartFarm Channel

### Feedback

We value your feedback! 
- Rate the app on Play Store/App Store
- Send feature requests via Settings > Feedback
- Report bugs at issues@smartfarm.com

---

## Version History

### v2.0 (February 2026)
- New Flask backend REST API
- Improved authentication with JWT
- Enhanced error handling
- Better data visualization
- Offline sync capability
- Performance optimizations

### v1.5 (December 2025)
- Added device automation schedules
- Improved sensor alerts
- Better mobile responsiveness

### v1.0 (June 2025)
- Initial release
- Basic plot management
- Sensor monitoring
- Manual device control

---

## Glossary

- **CWSI:** Crop Water Stress Index (0-1 scale)
- **JWT:** JSON Web Token (authentication)
- **LUX:** Unit of light intensity
- **Plot:** Agricultural area being monitored
- **Relative Humidity:** Water vapor in air as percentage
- **Sensor:** IoT device measuring environmental data

---

**Thank you for using Smart Farm!**  
*Making agriculture smarter, one plot at a time.*

