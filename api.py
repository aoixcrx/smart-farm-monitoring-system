import requests
import mysql.connector
import math
from datetime import datetime

# ===== ThingSpeak =====
CHANNEL_ID = "3211612"        # Channel ID
READ_API_KEY = "DUJ1X4OCWFMWH1U0"   # Read API Key
RESULTS_COUNT = 1000

url = f"https://api.thingspeak.com/channels/{CHANNEL_ID}/feeds.json?api_key={READ_API_KEY}&results={RESULTS_COUNT}"

# ===== MySQL Connection =====
try:
    db = mysql.connector.connect(
        host="localhost",
        user="root",
        password="200413", 
        database="smart_farm_db"
    )
    cursor = db.cursor()
    print("Connected to MySQL database")
except mysql.connector.Error as err:
    print(f"Error connecting to MySQL: {err}")
    exit(1)

# ===== 1. Setup Database Schema =====
def create_tables():
    # DROP TABLES in reverse dependency order
    cursor.execute("DROP TABLE IF EXISTS device_logs")
    cursor.execute("DROP TABLE IF EXISTS device_schedules")
    cursor.execute("DROP TABLE IF EXISTS devices")
    cursor.execute("DROP TABLE IF EXISTS stress_predictions")
    cursor.execute("DROP TABLE IF EXISTS sensor_logs")
    cursor.execute("DROP TABLE IF EXISTS plots")
    cursor.execute("DROP TABLE IF EXISTS users")
    
    # Table 9: users
    cursor.execute("""
    CREATE TABLE users (
        user_id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(200) NOT NULL,
        created_at DATETIME NOT NULL
    )
    """)

    # Table 10: plots
    cursor.execute("""
    CREATE TABLE plots (
        plot_id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        plot_name VARCHAR(100) NOT NULL,
        planting_date DATE NOT NULL,
        CONSTRAINT fk_plots_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    )
    """)

    # Table 11: sensor_logs (The main data table)
    cursor.execute("""
    CREATE TABLE sensor_logs (
        log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
        plot_id INT NOT NULL,
        timestamp DATETIME NOT NULL,
        air_temp DECIMAL(5,2) NOT NULL,
        humidity DECIMAL(5,2) NOT NULL,
        light_lux DECIMAL(10,2) NOT NULL,
        leaf_temp DECIMAL(5,2) NOT NULL,
        water_level DECIMAL(5,2) NOT NULL,
        cwsi_value DECIMAL(4,3) NOT NULL,
        CONSTRAINT fk_sensor_plot FOREIGN KEY (plot_id) REFERENCES plots(plot_id) ON DELETE CASCADE
    )
    """)

    # Table 12: stress_predictions
    cursor.execute("""
    CREATE TABLE stress_predictions (
        pred_id BIGINT AUTO_INCREMENT PRIMARY KEY,
        plot_id INT NOT NULL,
        pred_time DATETIME NOT NULL,
        target_time DATETIME NOT NULL,
        CONSTRAINT fk_pred_plot FOREIGN KEY (plot_id) REFERENCES plots(plot_id) ON DELETE CASCADE,
        CONSTRAINT chk_time CHECK (target_time > pred_time)
    )
    """)

    # Table 13: devices (Updated for Operational realism)
    cursor.execute("""
    CREATE TABLE devices (
        device_id INT AUTO_INCREMENT PRIMARY KEY,
        plot_id INT NOT NULL,
        device_name VARCHAR(50) NOT NULL,
        device_type VARCHAR(30) NOT NULL,
        status ENUM('ON','OFF') NOT NULL,
        mode ENUM('AUTO','MANUAL') NOT NULL,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT fk_device_plot FOREIGN KEY (plot_id) REFERENCES plots(plot_id) ON DELETE CASCADE
    )
    """)

    # New Table: device_schedules (For Automation)
    cursor.execute("""
    CREATE TABLE device_schedules (
        schedule_id INT AUTO_INCREMENT PRIMARY KEY,
        device_id INT NOT NULL,
        on_time TIME NOT NULL,
        off_time TIME NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        CONSTRAINT fk_schedule_device FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
    )
    """)
    
    # New Table: device_logs (For Action Tracking)
    cursor.execute("""
    CREATE TABLE device_logs (
        log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
        device_id INT NOT NULL,
        action VARCHAR(20),  # ON / OFF
        source VARCHAR(20),  # APP / AUTO / ESP32
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_log_device FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
    )
    """)

    print("Database schema ensured.")

# ===== 2. Seed Default Data (Required for Foreign Keys) =====
def seed_initial_data():
    # Ensure at least one user exists
    cursor.execute("SELECT user_id FROM users LIMIT 1")
    user = cursor.fetchone()
    if not user:
        sql_user = "INSERT INTO users (username, password, created_at) VALUES (%s, %s, %s)"
        cursor.execute(sql_user, ("admin", "admin123", datetime.now()))
        user_id = cursor.lastrowid
        print(f"Created default user (ID: {user_id})")
    else:
        user_id = user[0]

    # Ensure at least one plot exists
    cursor.execute("SELECT plot_id FROM plots LIMIT 1")
    plot = cursor.fetchone()
    if not plot:
        sql_plot = "INSERT INTO plots (user_id, plot_name, planting_date) VALUES (%s, %s, %s)"
        cursor.execute(sql_plot, (user_id, "Default Plot", datetime.now().date()))
        plot_id = cursor.lastrowid
        print(f"Created default plot (ID: {plot_id})")
    else:
        plot_id = plot[0]

    # Seed Devices if not exist
    cursor.execute("SELECT device_id FROM devices WHERE plot_id = %s LIMIT 1", (plot_id,))
    if not cursor.fetchone():
        # 1. Water Pump (AUTO, ON)
        cursor.execute("""
            INSERT INTO devices (plot_id, device_name, device_type, status, mode)
            VALUES (%s, 'Water Pump', 'WATER_PUMP', 'ON', 'AUTO')
        """, (plot_id,))
        pump_id = cursor.lastrowid
        
        # 2. Grow Light (MANUAL, OFF)
        cursor.execute("""
            INSERT INTO devices (plot_id, device_name, device_type, status, mode)
            VALUES (%s, 'Grow Light', 'LIGHT', 'OFF', 'MANUAL')
        """, (plot_id,))
        
        print("Created default devices (Pump, Light)")

        # Seed Schedules for Pump
        cursor.execute("""
            INSERT INTO device_schedules (device_id, on_time, off_time, is_active)
            VALUES (%s, '06:00:00', '18:00:00', TRUE)
        """, (pump_id,))
        print("Created default schedule for Water Pump")
        
        # Seed Log for Pump
        cursor.execute("""
            INSERT INTO device_logs (device_id, action, source, created_at)
            VALUES (%s, 'ON', 'AUTO', %s)
        """, (pump_id, datetime.now()))
        print("Created sample device log")
        
    return plot_id

# ===== 3. Import Data =====
def import_thingspeak_data(target_plot_id):
    print("Fetching data from ThingSpeak...")
    try:
        response = requests.get(url)
        data = response.json().get("feeds", [])
    except Exception as e:
        print(f"Error fetching data: {e}")
        return

    sql = """
    INSERT INTO sensor_logs
    (plot_id, timestamp, air_temp, humidity, leaf_temp, light_lux, water_level, cwsi_value)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """

    imported_count = 0
    
    # Helper for safe float conversion
    def safe_float(val, default=0.0):
        if val is None or val == "":
            return default
        try:
            f = float(val)
            if math.isnan(f):
                return default
            return f
        except ValueError:
            return default

    for row in data:
        # Prevent duplicates based on timestamp for this plot? 
        # For simplicity in this script, we insert. Ideally we check existence.
        # But `sensor_logs` doesn't have a unique constraint on timestamp+plot_id in the provided schema.
        # We will check if exact record exists to avoid duplication if re-run.
        
        timestamp_str = row["created_at"].replace("T", " ").replace("Z", "")
        
        # Check duplicate (Optional but good practice)
        check_sql = "SELECT log_id FROM sensor_logs WHERE plot_id = %s AND timestamp = %s LIMIT 1"
        cursor.execute(check_sql, (target_plot_id, timestamp_str))
        if cursor.fetchone():
            continue # Skip existing

        air_temp = safe_float(row.get("field1"))
        humidity = safe_float(row.get("field2"))
        leaf_temp = safe_float(row.get("field3"))
        # field 4? Not used in old script.
        light_lux = safe_float(row.get("field5"))
        # field 6 used to be pump, field 7 light_status.
        # Mapping water_level? Old script didn't map water_level. 
        # Using 0.0 as default for water_level since not clearly in ThingSpeak feeds list provided in old code.
        water_level = 0.0 
        
        # CWSI Calculation placeholder
        # CWSI = (dT - dT_lower) / (dT_upper - dT_lower)
        # Simplified placeholder: just leaf - air difference or 0
        cwsi_value = 0.0 # Placeholder
        
        values = (
            target_plot_id,
            timestamp_str,
            air_temp,
            humidity,
            leaf_temp,
            light_lux,
            water_level,
            cwsi_value
        )
        
        cursor.execute(sql, values)
        imported_count += 1

    db.commit()
    print(f"Data imported successfully. New records: {imported_count}")

# ===== Execution Flow =====
create_tables()
default_plot_id = seed_initial_data()
import_thingspeak_data(default_plot_id)

cursor.close()
db.close()
