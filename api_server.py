from flask import Flask, jsonify, request
from flask_cors import CORS
import mysql.connector
from datetime import datetime, timedelta
import jwt
import bcrypt
from functools import wraps

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter Web

# JWT Configuration
SECRET_KEY = 'smart_farm_secret_key_2026'  # In production, use environment variable
JWT_ACCESS_EXPIRES = timedelta(minutes=30)
JWT_REFRESH_EXPIRES = timedelta(days=7)

# MySQL Configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '200413',
    'database': 'smart_farm_db'
}

def get_db_connection():
    """Create and return a MySQL connection"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except mysql.connector.Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

# ==================== JWT HELPERS ====================

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


# ==================== ENVIRONMENT DATA ====================

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

# ==================== PLOTS ====================

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

# ==================== DEVICES ====================

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

# ==================== SENSOR DATA ====================

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

# ==================== SENSOR DATA CRUD ====================

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


# ==================== DEVICE CONTROL API ====================

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


# ==================== ENVIRONMENT API ====================

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

# ==================== AUTH ====================

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


# ==================== AUTH ====================

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
        
        # ==================== USERS TABLE ====================
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
        
        # ==================== PLOTS TABLE ====================
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
        
        # ==================== SENSOR_DATA TABLE ====================
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
        
        # ==================== SENSOR_LOGS TABLE ====================
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
        
        # ==================== DEVICES TABLE ====================
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
        
        # ==================== DEVICE_LOGS TABLE ====================
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
            'user_id': user_id,
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

# ==================== RUN SERVER ====================

if __name__ == '__main__':
    print("=" * 50)
    print("[*] Flask API Server for Smart Farm")
    print("=" * 50)
    print("Server running at: http://localhost:5000")
    print("API endpoints:")
    print("  GET  /api/environment")
    print("  GET  /api/plots")
    print("  POST /api/plots")
    print("  PUT  /api/plots/<id>")
    print("  DEL  /api/plots/<id>")
    print("  GET  /api/devices/<name>")
    print("  PUT  /api/devices/<name>")
    print("  GET  /api/sensor/latest?type=<type>")
    print("  POST /api/auth/check")
    print("  POST /api/auth/login")
    print("  POST /api/auth/register")
    print("=" * 50)
    app.run(debug=True, host='0.0.0.0', port=5000)

