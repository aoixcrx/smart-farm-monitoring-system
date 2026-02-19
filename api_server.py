from flask import Flask, jsonify, request
from flask_cors import CORS
import mysql.connector
from datetime import datetime, timedelta
import jwt
import bcrypt
from functools import wraps
import os
import logging

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter Web

# ==================== PRODUCTION CONFIG ====================
# Load from environment variables (with defaults for development)
SECRET_KEY = os.getenv("SECRET_KEY", "smart_farm_secret_key_2026")
DEBUG_MODE = os.getenv("FLASK_DEBUG", "False").lower() == "true"

JWT_ACCESS_EXPIRES = timedelta(minutes=30)
JWT_REFRESH_EXPIRES = timedelta(days=7)

# MySQL Configuration - Load from .env or use defaults
DB_CONFIG = {
    'host': os.getenv("DB_HOST", "localhost"),
    'port': int(os.getenv("DB_PORT", 3306)),
    'user': os.getenv("DB_USER", "root"),
    'password': os.getenv("DB_PASSWORD", "200413"),
    'database': os.getenv("DB_NAME", "smart_farm_db")
}

# ==================== LOGGING SETUP ====================
os.makedirs("logs", exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def get_db_connection():
    """Create and return a MySQL connection"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

# JWT HELPERS

def hash_password(password):
    """Hash password using bcrypt"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(password, hashed):
    """Verify password against hash"""
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    except:
        # Fallback for plaintext passwords (migration support)
        return password == hashed

def generate_tokens(user_id, username, user_type):
    """Generate access and refresh tokens"""
    now = datetime.utcnow()
    
    access_payload = {
        'user_id': user_id,
        'username': username,
        'user_type': user_type,
        'exp': now + JWT_ACCESS_EXPIRES,
        'iat': now,
        'type': 'access'
    }
    
    refresh_payload = {
        'user_id': user_id,
        'exp': now + JWT_REFRESH_EXPIRES,
        'iat': now,
        'type': 'refresh'
    }
    
    access_token = jwt.encode(access_payload, SECRET_KEY, algorithm='HS256')
    refresh_token = jwt.encode(refresh_payload, SECRET_KEY, algorithm='HS256')
    
    return access_token, refresh_token

def token_required(f):
    """Decorator for protected routes"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
        
        if not token:
            return jsonify({'error': 'Token is missing'}), 401
        
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            if payload.get('type') != 'access':
                return jsonify({'error': 'Invalid token type'}), 401
            request.current_user = payload
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        
        return f(*args, **kwargs)
    return decorated


# ENVIRONMENT DATA
@app.route('/api/environment', methods=['GET'])
def get_environment():
    """Get latest environment data (air temp, humidity, lux, leaf temp)"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT air_temp, humidity, light_lux as lux, leaf_temp
            FROM sensor_logs
            ORDER BY timestamp DESC
            LIMIT 1
        ''')
        result = cursor.fetchone()
        cursor.close()
        conn.close()

        if result:
            return jsonify(result)
        return jsonify({'air_temp': 0, 'humidity': 0, 'lux': 0, 'leaf_temp': 0})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

# PLOTS 

@app.route('/api/plots', methods=['GET'])
def get_plots():
    """Get all plots"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('SELECT * FROM plots ORDER BY plot_id ASC')
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(results)
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/plots', methods=['POST'])
def create_plot():
    """Create a new plot"""
    data = request.json
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO plots 
            (user_id, plot_name, image_path, plant_type, planting_date, leaf_temp, water_level, note)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ''', (
            data.get('user_id', 1),
            data.get('plot_name', ''),
            data.get('image_path', ''),
            data.get('plant_type', ''),
            data.get('planting_date', datetime.now().date()),
            data.get('leaf_temp', 0.0),
            data.get('water_level', 0.0),
            data.get('note', '')
        ))
        conn.commit()
        plot_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'plot_id': plot_id, 'message': 'Plot created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/plots/<int:plot_id>', methods=['PUT'])
def update_plot(plot_id):
    """Update a plot"""
    data = request.json
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE plots 
            SET plot_name=%s, image_path=%s, plant_type=%s, planting_date=%s,
                leaf_temp=%s, water_level=%s, note=%s
            WHERE plot_id=%s
        ''', (
            data.get('plot_name', ''),
            data.get('image_path', ''),
            data.get('plant_type', ''),
            data.get('planting_date', datetime.now().date()),
            data.get('leaf_temp', 0.0),
            data.get('water_level', 0.0),
            data.get('note', ''),
            plot_id
        ))
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Plot updated successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/plots/<int:plot_id>', methods=['DELETE'])
def delete_plot(plot_id):
    """Delete a plot"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('DELETE FROM plots WHERE plot_id = %s', (plot_id,))
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Plot deleted successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

# DEVICES

@app.route('/api/devices/<device_name>', methods=['GET'])
def get_device_status(device_name):
    """Get device status"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT status, mode 
            FROM devices 
            WHERE device_name = %s 
            LIMIT 1
        ''', (device_name,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            return jsonify({
                'status': result['status'] == 'ON',
                'online': True,
                'auto_mode': result['mode'] == 'AUTO'
            })
        return jsonify({'status': False, 'online': True, 'auto_mode': False})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/devices/<device_name>', methods=['PUT'])
def update_device_status(device_name):
    """Update device status"""
    data = request.json
    status = 'ON' if data.get('status', False) else 'OFF'
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE devices 
            SET status = %s 
            WHERE device_name = %s
        ''', (status, device_name))
        
        # Log the action
        cursor.execute('''
            INSERT INTO device_logs (device_name, action, timestamp)
            VALUES (%s, %s, NOW())
        ''', (device_name, status))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Device status updated'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

# SENSOR DATA

@app.route('/api/sensor/latest', methods=['GET'])
def get_latest_sensor():
    """Get latest sensor value"""
    sensor_type = request.args.get('type', 'air_temp')
    
    column_map = {
        'air_temp': 'air_temp',
        'humidity': 'humidity',
        'lux': 'light_lux',
        'leaf_temp': 'leaf_temp',
        'water_level': 'water_level'
    }
    
    column = column_map.get(sensor_type, 'air_temp')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute(f'''
            SELECT {column} 
            FROM sensor_logs 
            ORDER BY timestamp DESC 
            LIMIT 1
        ''')
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result and result[0] is not None:
            return jsonify({'value': float(result[0])})
        return jsonify({'value': 0.0})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

# SENSOR DATA CRUD 

@app.route('/api/sensor/init', methods=['POST'])
def init_sensor_table():
    """Create sensor_data table if not exists"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS sensor_data (
                data_id INT AUTO_INCREMENT PRIMARY KEY,
                device_id INT DEFAULT 1,
                temperature_air DECIMAL(5,2),
                temperature_leaf DECIMAL(5,2),
                humidity DECIMAL(5,2),
                water_level DECIMAL(5,2),
                light_lux DECIMAL(10,2),
                soil_moisture DECIMAL(5,2),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_device_created (device_id, created_at)
            )
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'sensor_data table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/sensor', methods=['POST'])
def insert_sensor_data():
    """Create sensor data - for ESP32 to send data"""
    data = request.json
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO sensor_data
            (device_id, temperature_air, temperature_leaf, humidity, water_level, light_lux, soil_moisture)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        ''', (
            data.get('device_id', 1),
            data.get('temperature_air', 0),
            data.get('temperature_leaf', 0),
            data.get('humidity', 0),
            data.get('water_level', 0),
            data.get('light_lux', 0),
            data.get('soil_moisture', 0)
        ))
        conn.commit()
        data_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'data_id': data_id, 'message': 'Sensor data inserted'}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/sensor/latest', methods=['GET'])
@token_required
def get_latest_sensor_data():
    """Get latest sensor data for all devices or specific device"""
    device_id = request.args.get('device_id', 1, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT * FROM sensor_data
            WHERE device_id = %s
            ORDER BY created_at DESC
            LIMIT 1
        ''', (device_id,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            # Convert Decimal to float for JSON
            for key in result:
                if hasattr(result[key], 'is_integer'):
                    result[key] = float(result[key])
            return jsonify(result)
        return jsonify({
            'temperature_air': 0,
            'temperature_leaf': 0,
            'humidity': 0,
            'water_level': 0,
            'light_lux': 0,
            'soil_moisture': 0
        })
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/sensor/history', methods=['GET'])
@token_required
def get_sensor_history():
    """Get sensor history for graphs - returns last 50 readings"""
    device_id = request.args.get('device_id', 1, type=int)
    limit = request.args.get('limit', 50, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT * FROM sensor_data
            WHERE device_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        ''', (device_id, limit))
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Convert Decimal to float for JSON
        for row in results:
            for key in row:
                if hasattr(row[key], 'is_integer'):
                    row[key] = float(row[key])
        
        return jsonify(results)
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/sensor/<int:data_id>', methods=['PUT'])
@token_required
def update_sensor_data(data_id):
    """Update sensor data record"""
    data = request.json
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE sensor_data
            SET temperature_air=%s, temperature_leaf=%s, humidity=%s, 
                water_level=%s, light_lux=%s, soil_moisture=%s
            WHERE data_id=%s
        ''', (
            data.get('temperature_air'),
            data.get('temperature_leaf'),
            data.get('humidity'),
            data.get('water_level'),
            data.get('light_lux'),
            data.get('soil_moisture'),
            data_id
        ))
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Sensor data updated'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/sensor/cleanup', methods=['DELETE'])
@token_required
def delete_old_sensor_data():
    """Delete sensor data older than specified days (default 30)"""
    days = request.args.get('days', 30, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            DELETE FROM sensor_data
            WHERE created_at < NOW() - INTERVAL %s DAY
        ''', (days,))
        deleted_count = cursor.rowcount
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True, 
            'deleted_count': deleted_count,
            'message': f'Deleted {deleted_count} records older than {days} days'
        })
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# DEVICE CONTROL API

@app.route('/api/device/<device_name>', methods=['GET'])
def api_get_device_status(device_name):
    """Get status of a specific device"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('SELECT * FROM devices WHERE device_name = %s', (device_name,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            return jsonify({
                'status': result['status'] == 'ON',
                'online': True,
                'auto_mode': result.get('mode', 'MANUAL') == 'AUTO'
            })
        else:
            return jsonify({'status': False, 'online': True, 'auto_mode': False})
    except Exception as e:
        print(f"Device Status Error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/device/<device_name>', methods=['PUT'])
def api_update_device_status(device_name):
    """Update status of a specific device (ON/OFF)"""
    data = request.json
    new_status = 'ON' if data.get('status', False) else 'OFF'
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Update device status
        cursor.execute('''
            UPDATE devices SET status = %s, updated_at = NOW() 
            WHERE device_name = %s
        ''', (new_status, device_name))
        
        if cursor.rowcount == 0:
            # Device doesn't exist, insert it
            cursor.execute('''
                INSERT INTO devices (device_name, status, plot_id, device_type, mode)
                VALUES (%s, %s, 1, 'GENERAL', 'MANUAL')
            ''', (device_name, new_status))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"✅ Device '{device_name}' toggled to {new_status}")
        return jsonify({'success': True, 'device': device_name, 'status': new_status})
    except Exception as e:
        print(f"Device Update Error: {e}")
        return jsonify({'error': str(e)}), 500


# ENVIRONMENT API 

@app.route('/api/environment', methods=['GET'])
def get_environment_data():
    """Get latest environment sensor data from sensor_logs"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT air_temp, humidity, light_lux, leaf_temp 
            FROM sensor_logs 
            ORDER BY timestamp DESC 
            LIMIT 1
        ''')
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            return jsonify({
                'air_temp': float(result['air_temp'] or 0),
                'humidity': float(result['humidity'] or 0),
                'lux': float(result['light_lux'] or 0),
                'leaf_temp': float(result['leaf_temp'] or 0)
            })
        else:
            return jsonify({
                'air_temp': 0.0,
                'humidity': 0.0,
                'lux': 0.0,
                'leaf_temp': 0.0
            })
    except Exception as e:
        print(f"Environment API Error: {e}")
        return jsonify({'error': str(e)}), 500

# AUTH

@app.route('/api/sensor-logs', methods=['GET'])
def get_sensor_logs():
    """Get sensor logs for display and CSV export"""
    limit = request.args.get('limit', 100, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT log_id, plot_id, air_temp, humidity, light_lux, leaf_temp, 
                   water_level, cwsi_value, timestamp
            FROM sensor_logs 
            ORDER BY timestamp DESC 
            LIMIT %s
        ''', (limit,))
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Convert datetime to string for JSON
        logs = []
        for row in results:
            logs.append({
                'log_id': row['log_id'],
                'plot_id': row['plot_id'],
                'air_temp': float(row['air_temp'] or 0),
                'humidity': float(row['humidity'] or 0),
                'lux': float(row['light_lux'] or 0),
                'leaf_temp': float(row['leaf_temp'] or 0),
                'water_level': float(row['water_level'] or 0),
                'cwsi_value': float(row['cwsi_value'] or 0),
                'timestamp': str(row['timestamp']) if row['timestamp'] else ''
            })
        
        return jsonify({'logs': logs, 'count': len(logs)})
    except Exception as e:
        print(f"Sensor Logs API Error: {e}")
        return jsonify({'error': str(e)}), 500


# TRASH BIN DATA

@app.route('/api/bin-data/init', methods=['POST'])
def init_bin_table():
    """Create trash_bin_logs table if not exists"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS trash_bin_logs (
                log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                bin_id VARCHAR(50) NOT NULL,
                distance_cm DECIMAL(6,2) NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_bin_created (bin_id, created_at)
            )
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'trash_bin_logs table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/bin-data', methods=['POST'])
def record_bin_data():
    """Record trash bin distance data from ESP32 sensor
    
    Request JSON:
    {
        "bin_id": "BIN001",
        "distance_cm": 4.5,
        "timestamp": "2026-02-15T17:00:00"
    }
    
    Response:
    {
        "status": "success",
        "message": "Data recorded",
        "log_id": 123
    }
    """
    data = request.json
    
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    bin_id = data.get('bin_id')
    distance_cm = data.get('distance_cm')
    timestamp = data.get('timestamp')
    
    # Validate required fields
    if not bin_id or distance_cm is None:
        return jsonify({'error': 'Missing required fields: bin_id, distance_cm'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        # Ensure table exists
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS trash_bin_logs (
                log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                bin_id VARCHAR(50) NOT NULL,
                distance_cm DECIMAL(6,2) NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_bin_created (bin_id, created_at)
            )
        ''')
        
        # Insert data
        if timestamp:
            cursor.execute('''
                INSERT INTO trash_bin_logs (bin_id, distance_cm, created_at)
                VALUES (%s, %s, %s)
            ''', (bin_id, distance_cm, timestamp))
        else:
            cursor.execute('''
                INSERT INTO trash_bin_logs (bin_id, distance_cm)
                VALUES (%s, %s)
            ''', (bin_id, distance_cm))
        
        conn.commit()
        log_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        print(f"✅ Bin data recorded: {bin_id} - {distance_cm}cm")
        return jsonify({
            'status': 'success',
            'message': 'Data recorded',
            'log_id': log_id
        }), 201
    except Exception as e:
        print(f"Error recording bin data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/bin-data', methods=['GET'])
def get_bin_data():
    """Get trash bin data history"""
    bin_id = request.args.get('bin_id')
    limit = request.args.get('limit', 100, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        if bin_id:
            cursor.execute('''
                SELECT log_id, bin_id, distance_cm, created_at
                FROM trash_bin_logs
                WHERE bin_id = %s
                ORDER BY created_at DESC
                LIMIT %s
            ''', (bin_id, limit))
        else:
            cursor.execute('''
                SELECT log_id, bin_id, distance_cm, created_at
                FROM trash_bin_logs
                ORDER BY created_at DESC
                LIMIT %s
            ''', (limit,))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        logs = []
        for row in results:
            logs.append({
                'log_id': row['log_id'],
                'bin_id': row['bin_id'],
                'distance_cm': float(row['distance_cm']),
                'created_at': str(row['created_at']) if row['created_at'] else ''
            })
        
        return jsonify({'logs': logs, 'count': len(logs)})
    except Exception as e:
        print(f"Bin Data Retrieval Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== DEVICE LOGS API ====================

@app.route('/api/device-logs/init', methods=['POST'])
def init_device_logs_table():
    """Initialize device_logs table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS device_logs (
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
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'device_logs table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/device-logs', methods=['POST'])
def record_device_log():
    """Record device action/state change
    
    Request: {
        "device_id": 1,
        "device_name": "Pump001",
        "action": "ON/OFF/MODE_CHANGE",
        "source": "APP/AUTO/MANUAL",
        "old_value": "OFF",
        "new_value": "ON"
    }
    """
    data = request.json
    if not data or 'device_id' not in data or 'action' not in data:
        return jsonify({'error': 'Missing required fields'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS device_logs (
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
        ''')
        
        cursor.execute('''
            INSERT INTO device_logs (device_id, device_name, action, source, old_value, new_value)
            VALUES (%s, %s, %s, %s, %s, %s)
        ''', (
            data.get('device_id'),
            data.get('device_name', ''),
            data.get('action'),
            data.get('source', 'MANUAL'),
            data.get('old_value', ''),
            data.get('new_value', '')
        ))
        
        conn.commit()
        log_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'log_id': log_id, 'message': 'Device log recorded'}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/device-logs', methods=['GET'])
def get_device_logs():
    """Get device logs filtered by device_id"""
    device_id = request.args.get('device_id', type=int)
    limit = request.args.get('limit', 100, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        if device_id:
            cursor.execute('''
                SELECT * FROM device_logs
                WHERE device_id = %s
                ORDER BY created_at DESC
                LIMIT %s
            ''', (device_id, limit))
        else:
            cursor.execute('''
                SELECT * FROM device_logs
                ORDER BY created_at DESC
                LIMIT %s
            ''', (limit,))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        logs = [dict(row) for row in results]
        for log in logs:
            if 'created_at' in log:
                log['created_at'] = str(log['created_at'])
        
        return jsonify({'logs': logs, 'count': len(logs)})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== WEATHER API ====================

@app.route('/api/weather/init', methods=['POST'])
def init_weather_table():
    """Initialize weather_logs table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS weather_logs (
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
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'weather_logs table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/weather', methods=['POST'])
def record_weather():
    """Record weather data
    
    Request: {
        "location": "Farm A",
        "latitude": 13.7563,
        "longitude": 100.5018,
        "temperature": 28.5,
        "humidity": 75.0,
        "wind_speed": 5.2,
        "rainfall": 0.0,
        "weather_condition": "Partly Cloudy"
    }
    """
    data = request.json
    if not data or 'location' not in data:
        return jsonify({'error': 'Location required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS weather_logs (
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
        ''')
        
        cursor.execute('''
            INSERT INTO weather_logs 
            (location, latitude, longitude, temperature, humidity, wind_speed, rainfall, weather_condition)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ''', (
            data.get('location'),
            data.get('latitude', 0),
            data.get('longitude', 0),
            data.get('temperature', 0),
            data.get('humidity', 0),
            data.get('wind_speed', 0),
            data.get('rainfall', 0),
            data.get('weather_condition', '')
        ))
        
        conn.commit()
        weather_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'weather_id': weather_id}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/weather', methods=['GET'])
def get_weather():
    """Get latest weather data by location"""
    location = request.args.get('location')
    limit = request.args.get('limit', 1, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        if location:
            cursor.execute('''
                SELECT * FROM weather_logs
                WHERE location = %s
                ORDER BY created_at DESC
                LIMIT %s
            ''', (location, limit))
        else:
            cursor.execute('''
                SELECT * FROM weather_logs
                ORDER BY created_at DESC
                LIMIT %s
            ''', (limit,))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        logs = [dict(row) for row in results]
        return jsonify({'weather': logs, 'count': len(logs)})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== ALERTS API ====================

@app.route('/api/alerts/init', methods=['POST'])
def init_alerts_table():
    """Initialize alerts table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS alerts (
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
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'alerts table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/alerts', methods=['POST'])
def create_alert():
    """Create farm alert
    
    Request: {
        "plot_id": 1,
        "alert_type": "HIGH_TEMP/LOW_MOISTURE/DEVICE_FAILURE",
        "severity": "LOW/MEDIUM/HIGH",
        "message": "Temperature exceeded threshold"
    }
    """
    data = request.json
    if not data or 'alert_type' not in data or 'severity' not in data:
        return jsonify({'error': 'Missing required fields'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS alerts (
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
        ''')
        
        cursor.execute('''
            INSERT INTO alerts (plot_id, alert_type, severity, message)
            VALUES (%s, %s, %s, %s)
        ''', (
            data.get('plot_id', 1),
            data.get('alert_type'),
            data.get('severity'),
            data.get('message', '')
        ))
        
        conn.commit()
        alert_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'alert_id': alert_id}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/alerts', methods=['GET'])
def get_alerts():
    """Get alerts, optionally filtered by plot_id and resolution status"""
    plot_id = request.args.get('plot_id', type=int)
    is_resolved = request.args.get('is_resolved', 'false').lower() == 'true'
    limit = request.args.get('limit', 50, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        if plot_id:
            cursor.execute('''
                SELECT * FROM alerts
                WHERE plot_id = %s AND is_resolved = %s
                ORDER BY created_at DESC
                LIMIT %s
            ''', (plot_id, is_resolved, limit))
        else:
            cursor.execute('''
                SELECT * FROM alerts
                WHERE is_resolved = %s
                ORDER BY created_at DESC
                LIMIT %s
            ''', (is_resolved, limit))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        alerts = [dict(row) for row in results]
        return jsonify({'alerts': alerts, 'count': len(alerts)})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/alerts/<int:alert_id>/resolve', methods=['PUT'])
def resolve_alert(alert_id):
    """Mark alert as resolved"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE alerts
            SET is_resolved = TRUE, resolved_at = NOW()
            WHERE alert_id = %s
        ''', (alert_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Alert resolved'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== MAINTENANCE SCHEDULE API ====================

@app.route('/api/maintenance/init', methods=['POST'])
def init_maintenance_table():
    """Initialize maintenance table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS maintenance_schedules (
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
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'maintenance_schedules table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/maintenance', methods=['POST'])
def schedule_maintenance():
    """Schedule device maintenance
    
    Request: {
        "device_id": 1,
        "device_name": "Pump001",
        "maintenance_type": "Oil Change/Filter Replacement",
        "scheduled_date": "2026-03-15",
        "notes": "Routine maintenance"
    }
    """
    data = request.json
    if not data or 'device_id' not in data or 'scheduled_date' not in data:
        return jsonify({'error': 'Missing required fields'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS maintenance_schedules (
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
        ''')
        
        cursor.execute('''
            INSERT INTO maintenance_schedules 
            (device_id, device_name, maintenance_type, scheduled_date, status, notes)
            VALUES (%s, %s, %s, %s, %s, %s)
        ''', (
            data.get('device_id'),
            data.get('device_name', ''),
            data.get('maintenance_type', ''),
            data.get('scheduled_date'),
            data.get('status', 'PENDING'),
            data.get('notes', '')
        ))
        
        conn.commit()
        maintenance_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'maintenance_id': maintenance_id}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/maintenance', methods=['GET'])
def get_maintenance():
    """Get maintenance schedules"""
    device_id = request.args.get('device_id', type=int)
    status = request.args.get('status', 'PENDING')
    limit = request.args.get('limit', 50, type=int)
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        if device_id:
            cursor.execute('''
                SELECT * FROM maintenance_schedules
                WHERE device_id = %s AND status = %s
                ORDER BY scheduled_date ASC
                LIMIT %s
            ''', (device_id, status, limit))
        else:
            cursor.execute('''
                SELECT * FROM maintenance_schedules
                WHERE status = %s
                ORDER BY scheduled_date ASC
                LIMIT %s
            ''', (status, limit))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        schedules = [dict(row) for row in results]
        return jsonify({'schedules': schedules, 'count': len(schedules)})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== CROP HEALTH METRICS API ====================

@app.route('/api/crop-health/init', methods=['POST'])
def init_crop_health_table():
    """Initialize crop health table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS crop_health_metrics (
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
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'crop_health_metrics table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/crop-health', methods=['POST'])
def record_crop_health():
    """Record crop health metrics
    
    Request: {
        "plot_id": 1,
        "cwsi_value": 0.45,
        "leaf_temperature": 28.5,
        "air_temperature": 29.0,
        "soil_moisture": 65.0,
        "soil_ec": 2.5
    }
    """
    data = request.json
    if not data or 'plot_id' not in data:
        return jsonify({'error': 'plot_id required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS crop_health_metrics (
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
        ''')
        
        cwsi = data.get('cwsi_value', 0)
        health_status = 'Healthy' if cwsi < 0.5 else ('Stressed' if cwsi < 0.8 else 'Critical')
        
        cursor.execute('''
            INSERT INTO crop_health_metrics 
            (plot_id, cwsi_value, leaf_temperature, air_temperature, soil_moisture, soil_ec, health_status)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        ''', (
            data.get('plot_id'),
            cwsi,
            data.get('leaf_temperature', 0),
            data.get('air_temperature', 0),
            data.get('soil_moisture', 0),
            data.get('soil_ec', 0),
            health_status
        ))
        
        conn.commit()
        metric_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'metric_id': metric_id, 'health_status': health_status}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/crop-health', methods=['GET'])
def get_crop_health():
    """Get crop health metrics for a plot"""
    plot_id = request.args.get('plot_id', type=int)
    limit = request.args.get('limit', 100, type=int)
    
    if not plot_id:
        return jsonify({'error': 'plot_id required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT * FROM crop_health_metrics
            WHERE plot_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        ''', (plot_id, limit))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        metrics = [dict(row) for row in results]
        return jsonify({'metrics': metrics, 'count': len(metrics)})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== FARM STATISTICS API ====================

@app.route('/api/statistics/overview', methods=['GET'])
def get_farm_statistics():
    """Get farm overview statistics"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        
        stats = {}
        
        # Total plots
        cursor.execute('SELECT COUNT(*) as count FROM plots')
        stats['total_plots'] = cursor.fetchone()['count'] or 0
        
        # Active devices
        cursor.execute("SELECT COUNT(*) as count FROM devices WHERE status = 'ON'")
        stats['active_devices'] = cursor.fetchone()['count'] or 0
        
        # Total sensors
        cursor.execute('SELECT COUNT(*) as count FROM sensor_logs')
        stats['total_sensor_readings'] = cursor.fetchone()['count'] or 0
        
        # Latest sensor data
        cursor.execute('''
            SELECT AVG(CAST(air_temp AS DECIMAL)) as avg_temp,
                   AVG(CAST(humidity AS DECIMAL)) as avg_humidity
            FROM sensor_logs WHERE timestamp > DATE_SUB(NOW(), INTERVAL 1 DAY)
        ''')
        latest = cursor.fetchone()
        stats['avg_temperature'] = float(latest['avg_temp']) if latest['avg_temp'] else 0
        stats['avg_humidity'] = float(latest['avg_humidity']) if latest['avg_humidity'] else 0
        
        # Unresolved alerts
        cursor.execute("SELECT COUNT(*) as count FROM alerts WHERE is_resolved = FALSE")
        stats['pending_alerts'] = cursor.fetchone()['count'] or 0
        
        cursor.close()
        conn.close()
        
        return jsonify(stats)
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/statistics/plot/<int:plot_id>', methods=['GET'])
def get_plot_statistics(plot_id):
    """Get statistics for a specific plot"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        
        stats = {'plot_id': plot_id}
        
        # Get plot info
        cursor.execute('SELECT * FROM plots WHERE plot_id = %s', (plot_id,))
        plot = cursor.fetchone()
        
        if not plot:
            return jsonify({'error': 'Plot not found'}), 404
        
        stats['plot_name'] = plot.get('plot_name', '')
        stats['plant_type'] = plot.get('plant_type', '')
        
        # Latest crop health
        cursor.execute('''
            SELECT * FROM crop_health_metrics
            WHERE plot_id = %s
            ORDER BY created_at DESC
            LIMIT 1
        ''', (plot_id,))
        health = cursor.fetchone()
        
        if health:
            stats['latest_health'] = dict(health)
            stats['latest_health']['created_at'] = str(health['created_at'])
        
        # 7-day average
        cursor.execute('''
            SELECT AVG(CAST(cwsi_value AS DECIMAL)) as avg_cwsi,
                   AVG(CAST(soil_moisture AS DECIMAL)) as avg_moisture
            FROM crop_health_metrics
            WHERE plot_id = %s AND created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
        ''', (plot_id,))
        avg = cursor.fetchone()
        stats['week_avg_cwsi'] = float(avg['avg_cwsi']) if avg['avg_cwsi'] else 0
        stats['week_avg_moisture'] = float(avg['avg_moisture']) if avg['avg_moisture'] else 0
        
        cursor.close()
        conn.close()
        
        return jsonify(stats)
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== DEVICE STATUS HISTORY API ====================

@app.route('/api/device-history/init', methods=['POST'])
def init_device_history_table():
    """Initialize device status history table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS device_status_history (
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
        ''')
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'device_status_history table created successfully'})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/device-history', methods=['POST'])
def record_device_history():
    """Record device status history
    
    Request: {
        "device_id": 1,
        "device_name": "Pump001",
        "status": "ON/OFF",
        "mode": "AUTO/MANUAL",
        "uptime_seconds": 3600,
        "error_count": 0
    }
    """
    data = request.json
    if not data or 'device_id' not in data:
        return jsonify({'error': 'device_id required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS device_status_history (
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
        ''')
        
        cursor.execute('''
            INSERT INTO device_status_history 
            (device_id, device_name, status, mode, uptime_seconds, error_count)
            VALUES (%s, %s, %s, %s, %s, %s)
        ''', (
            data.get('device_id'),
            data.get('device_name', ''),
            data.get('status', 'OFF'),
            data.get('mode', 'MANUAL'),
            data.get('uptime_seconds', 0),
            data.get('error_count', 0)
        ))
        
        conn.commit()
        history_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'history_id': history_id}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/device-history', methods=['GET'])
def get_device_history():
    """Get device status history"""
    device_id = request.args.get('device_id', type=int)
    limit = request.args.get('limit', 100, type=int)
    
    if not device_id:
        return jsonify({'error': 'device_id required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT * FROM device_status_history
            WHERE device_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        ''', (device_id, limit))
        
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        history = [dict(row) for row in results]
        for h in history:
            if 'created_at' in h:
                h['created_at'] = str(h['created_at'])
        
        return jsonify({'history': history, 'count': len(history)})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


# AUTH 

@app.route('/api/auth/check', methods=['POST'])
def check_user():
    """Check if username exists"""
    data = request.json
    username = data.get('username', '')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT 1 FROM users WHERE username = %s', (username,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        return jsonify({'exists': result is not None})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/user/profile', methods=['PUT'])
def update_user_profile():
    """Update user profile (display_name, email)"""
    data = request.json
    username = data.get('username', '')
    display_name = data.get('display_name', '')
    email = data.get('email', '')
    
    if not username:
        return jsonify({'error': 'Username required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        
        # First ensure columns exist
        for col_sql in [
            "ALTER TABLE users ADD COLUMN display_name VARCHAR(100)",
            "ALTER TABLE users ADD COLUMN email VARCHAR(150)"
        ]:
            try:
                cursor.execute(col_sql)
                conn.commit()
            except:
                pass
        
        # Update user profile
        cursor.execute('''
            UPDATE users SET display_name = %s, email = %s 
            WHERE username = %s
        ''', (display_name, email, username))
        
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        conn.close()
        
        if affected > 0:
            print(f"✅ Profile updated for {username}: name='{display_name}', email='{email}'")
            return jsonify({
                'success': True,
                'message': 'Profile updated',
                'username': username,
                'display_name': display_name,
                'email': email
            })
        else:
            return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        print(f"Profile Update Error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/init-db', methods=['POST'])
def init_all_tables():
    """Initialize/fix ALL database tables with required columns"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    messages = []
    
    try:
        cursor = conn.cursor()
        
        # USERS TABLE
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                user_id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(100) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                user_type VARCHAR(50) DEFAULT 'user',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        messages.append("Users table OK")
        
        # Add missing columns to users (safe)
        for col_sql in [
            "ALTER TABLE users ADD COLUMN user_type VARCHAR(50) DEFAULT 'user'"
        ]:
            try:
                cursor.execute(col_sql)
                conn.commit()
            except:
                pass
        
        #  PLOTS TABLE 
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS plots (
                plot_id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT DEFAULT 1,
                plot_name VARCHAR(100) NOT NULL,
                image_path VARCHAR(255) DEFAULT '',
                plant_type VARCHAR(100) DEFAULT '',
                planting_date DATE,
                leaf_temp DECIMAL(5,2) DEFAULT 0,
                water_level DECIMAL(5,2) DEFAULT 0,
                note TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        messages.append("Plots table OK")
        
        # Add missing columns to plots (safe)
        plot_columns = [
            "ALTER TABLE plots ADD COLUMN leaf_temp DECIMAL(5,2) DEFAULT 0",
            "ALTER TABLE plots ADD COLUMN water_level DECIMAL(5,2) DEFAULT 0",
            "ALTER TABLE plots ADD COLUMN image_path VARCHAR(255) DEFAULT ''",
            "ALTER TABLE plots ADD COLUMN plant_type VARCHAR(100) DEFAULT ''",
            "ALTER TABLE plots ADD COLUMN note TEXT"
        ]
        for col_sql in plot_columns:
            try:
                cursor.execute(col_sql)
                conn.commit()
                messages.append(f"Added column: {col_sql.split('ADD COLUMN ')[1].split()[0]}")
            except:
                pass
        
        # SENSOR_DATA TABLE
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS sensor_data (
                data_id INT AUTO_INCREMENT PRIMARY KEY,
                device_id INT DEFAULT 1,
                temperature_air DECIMAL(5,2),
                temperature_leaf DECIMAL(5,2),
                humidity DECIMAL(5,2),
                water_level DECIMAL(5,2),
                light_lux DECIMAL(10,2),
                soil_moisture DECIMAL(5,2),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_device_created (device_id, created_at)
            )
        ''')
        messages.append("Sensor_data table OK")
        
        # SENSOR_LOGS TABLE
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS sensor_logs (
                log_id INT AUTO_INCREMENT PRIMARY KEY,
                air_temp DECIMAL(5,2),
                humidity DECIMAL(5,2),
                light_lux DECIMAL(10,2),
                leaf_temp DECIMAL(5,2),
                water_level DECIMAL(5,2),
                soil_moisture DECIMAL(5,2),
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        messages.append("Sensor_logs table OK")
        
        # DEVICES TABLE
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS devices (
                device_id INT AUTO_INCREMENT PRIMARY KEY,
                device_name VARCHAR(100) NOT NULL,
                status VARCHAR(20) DEFAULT 'off',
                humidity_value DECIMAL(5,2) DEFAULT 0,
                auto_mode BOOLEAN DEFAULT FALSE,
                schedule_start TIME,
                schedule_end TIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        messages.append("Devices table OK")
        
        # Insert default devices if not exist
        cursor.execute("SELECT COUNT(*) FROM devices")
        if cursor.fetchone()[0] == 0:
            cursor.execute('''
                INSERT INTO devices (device_name, status) VALUES 
                ('light', 'off'), 
                ('water_pump', 'off')
            ''')
            messages.append("Default devices inserted")
        
        # DEVICE_LOGS TABLE
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS device_logs (
                log_id INT AUTO_INCREMENT PRIMARY KEY,
                device_name VARCHAR(100) NOT NULL,
                action VARCHAR(20) NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_device_time (device_name, timestamp)
            )
        ''')
        messages.append("Device_logs table OK")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'success': True, 
            'message': 'All tables initialized successfully',
            'details': messages
        })
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/login', methods=['POST'])
def login():
    """Verify user credentials and return JWT tokens"""
    data = request.json
    username = data.get('username', '')
    password = data.get('password', '')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            'SELECT user_id, username, password, user_type FROM users WHERE username = %s',
            (username,)
        )
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result and verify_password(password, result['password']):
            access_token, refresh_token = generate_tokens(
                result['user_id'],
                result['username'],
                result.get('user_type', 'user')
            )
            return jsonify({
                'success': True,
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user': {
                    'user_id': result['user_id'],
                    'username': result['username'],
                    'user_type': result.get('user_type', 'user')
                }
            })
        return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/register', methods=['POST'])
def register():
    """Register a new user with hashed password"""
    data = request.json
    username = data.get('username', '')
    password = data.get('password', '')
    user_type = data.get('user_type', 'user')
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Check if user already exists
        cursor.execute('SELECT 1 FROM users WHERE username = %s', (username,))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({'success': False, 'message': 'Username already exists'}), 409
        
        # Hash password and insert new user
        hashed_password = hash_password(password)
        cursor.execute(
            'INSERT INTO users (username, password, user_type, created_at) VALUES (%s, %s, %s, NOW())',
            (username, hashed_password, user_type)
        )
        conn.commit()
        user_id = cursor.lastrowid
        cursor.close()
        conn.close()
        
        # Generate tokens for new user
        access_token, refresh_token = generate_tokens(user_id, username, user_type)
        
        return jsonify({
            'success': True,
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': {
                'user_id': user_id,
                'username': username,
                'user_type': user_type
            },
            'message': 'User registered successfully'
        })
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/refresh', methods=['POST'])
def refresh_token():
    """Refresh access token using refresh token"""
    data = request.json
    refresh_token = data.get('refresh_token', '')
    
    if not refresh_token:
        return jsonify({'error': 'Refresh token is required'}), 400
    
    try:
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=['HS256'])
        
        if payload.get('type') != 'refresh':
            return jsonify({'error': 'Invalid token type'}), 401
        
        # Get user info from database
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            'SELECT user_id, username, user_type FROM users WHERE user_id = %s',
            (payload['user_id'],)
        )
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Generate new access token only
        access_token, _ = generate_tokens(
            user['user_id'],
            user['username'],
            user.get('user_type', 'user')
        )
        
        return jsonify({
            'success': True,
            'access_token': access_token
        })
    except jwt.ExpiredSignatureError:
        return jsonify({'error': 'Refresh token has expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'error': 'Invalid refresh token'}), 401

# RUN SERVER

if __name__ == '__main__':
    print("=" * 70)
    print("[*] Flask API Server for Smart Farm")
    print("=" * 70)
    print("Server running at: http://localhost:5000")
    print("\n📊 API ENDPOINTS:\n")
    
    print("🌍 ENVIRONMENT & PLOTS:")
    print("  GET  /api/environment")
    print("  GET  /api/plots")
    print("  POST /api/plots")
    print("  PUT  /api/plots/<id>")
    print("  DEL  /api/plots/<id>")
    
    print("\n🔌 DEVICES & SENSORS:")
    print("  GET  /api/devices/<name>")
    print("  PUT  /api/devices/<name>")
    print("  GET  /api/sensor/latest?type=<type>")
    print("  POST /api/sensor")
    print("  GET  /api/sensor-logs")
    
    print("\n🗑️  TRASH BIN MONITORING:")
    print("  POST /api/bin-data")
    print("  GET  /api/bin-data?bin_id=<id>&limit=<n>")
    print("  POST /api/bin-data/init")
    
    print("\n📝 DEVICE LOGS:")
    print("  POST /api/device-logs")
    print("  GET  /api/device-logs?device_id=<id>&limit=<n>")
    print("  POST /api/device-logs/init")
    
    print("\n🌤️  WEATHER:")
    print("  POST /api/weather")
    print("  GET  /api/weather?location=<name>&limit=<n>")
    print("  POST /api/weather/init")
    
    print("\n⚠️  ALERTS:")
    print("  POST /api/alerts")
    print("  GET  /api/alerts?plot_id=<id>&is_resolved=<bool>")
    print("  PUT  /api/alerts/<id>/resolve")
    print("  POST /api/alerts/init")
    
    print("\n🔧 MAINTENANCE SCHEDULE:")
    print("  POST /api/maintenance")
    print("  GET  /api/maintenance?device_id=<id>&status=<status>")
    print("  POST /api/maintenance/init")
    
    print("\n🌱 CROP HEALTH:")
    print("  POST /api/crop-health")
    print("  GET  /api/crop-health?plot_id=<id>&limit=<n>")
    print("  POST /api/crop-health/init")
    
    print("\n📊 STATISTICS:")
    print("  GET  /api/statistics/overview")
    print("  GET  /api/statistics/plot/<id>")
    
    print("\n📈 DEVICE HISTORY:")
    print("  POST /api/device-history")
    print("  GET  /api/device-history?device_id=<id>&limit=<n>")
    print("  POST /api/device-history/init")
    
    print("\n🔐 AUTHENTICATION:")
    print("  POST /api/auth/check")
    print("  POST /api/auth/login")
    print("  POST /api/auth/register")
    print("  POST /api/auth/refresh")
    print("  PUT  /api/user/profile")
    
    print("\n" + "=" * 70)
    
    logger.info(f"[PRODUCTION MODE] Starting Smart Farm API Server")
    logger.info(f"Environment: {'DEBUG' if DEBUG_MODE else 'PRODUCTION'}")
    logger.info(f"Database: {DB_CONFIG['host']}:{DB_CONFIG['database']}")
    logger.info(f"Server: http://0.0.0.0:5000")
    
    # Use production-safe settings
    app.run(
        debug=DEBUG_MODE,
        host='0.0.0.0',
        port=5000,
        use_reloader=DEBUG_MODE,
        threaded=True
    )


# ==================== GLOBAL ERROR HANDLER ====================
@app.errorhandler(Exception)
def handle_error(error):
    """Global error handler for production safety"""
    logger.error(f"Unhandled error: {str(error)}", exc_info=True)
    return jsonify({'error': 'Internal Server Error'}), 500

