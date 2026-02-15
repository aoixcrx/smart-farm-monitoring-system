import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/plot.dart';
import '../models/sensor_log.dart';

/// Mutex (Mutual Exclusion) Lock to prevent concurrent database queries
/// This prevents RangeError from concurrent access to the mysql1 connection
class _Mutex {
  Completer<void>? _completer;

  Future<T> synchronized<T>(FutureOr<T> Function() computation) async {
    // Wait for previous operation to complete
    while (_completer != null) {
      await _completer!.future;
    }

    // Mark that we're now in progress
    _completer = Completer<void>();
    try {
      // Run the operation
      return await computation();
    } finally {
      // Mark completion and notify waiters
      _completer!.complete();
      _completer = null;
    }
  }
}

class DatabaseService {
  // IMPORTANT: For Android Emulator, use '10.0.2.2'
  // For physical device, add your computer's IP (e.g., '192.168.1.100')
  // To find your IP on Windows: ipconfig | findstr IPv4

  // Try multiple hosts in order
  static const List<String> _hosts = [
    '10.0.2.2', // Android Emulator - access host machine
    'localhost', // Fallback for desktop
  ];

  static const int _port = 3306;
  static const String _database = 'smart_farm_db';
  static const String _username = 'root';
  static const String _password = '200413';

  // For Flutter Web - REST API endpoint
  static const String _apiBaseUrl =
      'http://localhost:5000/api'; // Change to your API server URL

  MySqlConnection? _connection;
  Completer<MySqlConnection>? _connectionCompleter;
  Map<String, dynamic>? _currentUser;

  /// 🔒 Lock to prevent concurrent queries that cause RangeError
  final _lock = _Mutex();

  Map<String, dynamic>? get currentUser => _currentUser;

  /* ================= CONNECTION ================= */

  Future<MySqlConnection> _getConnection() async {
    // Web browsers cannot use MySQL directly - must use HTTP API
    if (kIsWeb) {
      throw UnsupportedError('Direct MySQL connection is not supported on web. '
          'Please use HybridDatabaseService or the REST API instead.');
    }

    // Health check: if connection exists, verify it's still alive
    if (_connection != null) {
      try {
        await _connection!.query('SELECT 1'); // Simple ping
        print('[DatabaseService] [OK] Reusing existing MySQL connection');
        return _connection!;
      } catch (e) {
        print(
            '[DatabaseService] ⚠ Connection stale or broken, reconnecting...');
        // Clean up broken connection properly
        try {
          await _connection!.close();
        } catch (_) {
          print(
              '[DatabaseService] Could not close broken connection gracefully');
        }
        _connection = null;
      }
    }

    // If a connection attempt is already in progress, wait for it
    if (_connectionCompleter != null) {
      return _connectionCompleter!.future;
    }

    _connectionCompleter = Completer<MySqlConnection>();

    // Try each host in order until one succeeds
    MySqlConnection? conn;
    Exception? lastError;

    for (String host in _hosts) {
      try {
        print('Attempting to connect to MySQL at $host:$_port...');

        final settings = ConnectionSettings(
          host: host,
          port: _port,
          user: _username,
          password: _password,
          db: _database,
          timeout:
              const Duration(seconds: 5), // Shorter timeout for faster fallback
          useSSL: false, // Disable SSL to reduce packet corruption issues
        );

        conn = await MySqlConnection.connect(settings);
        print('Successfully connected to MySQL at $host');
        break; // Connection successful
      } catch (e) {
        print('Failed to connect to $host: $e');
        lastError = e as Exception;
        // Continue to next host
      }
    }

    if (conn == null) {
      // All hosts failed
      print('');
      print(
          '[DatabaseService] [ERROR] CRITICAL ERROR: Could not connect to MySQL on any host');
      print('[DatabaseService] Tried: ${_hosts.join(', ')}');
      print('');
      print('[DatabaseService] Make sure:');
      print('[DatabaseService] 1. MySQL is running on localhost:3306');
      print(
          '[DatabaseService] 2. MySQL credentials are correct (root / 200413)');
      print('[DatabaseService] 3. MySQL user has proper authentication plugin');
      print('');
      print(
          '[DatabaseService] ⚠️  MOST LIKELY ISSUE: MySQL Authentication Plugin');
      print(
          '[DatabaseService]    Your MySQL root user is using "caching_sha2_password"');
      print(
          '[DatabaseService]    but the mysql1 driver requires "mysql_native_password"');
      print('');
      print(
          '[DatabaseService] 🔧 TO FIX: Run these SQL commands on your MySQL server:');
      print('[DatabaseService]');
      print(
          '[DatabaseService]    ALTER USER "root"@"localhost" IDENTIFIED WITH mysql_native_password BY "200413";');
      print(
          '[DatabaseService]    ALTER USER "root"@"%" IDENTIFIED WITH mysql_native_password BY "200413";');
      print('[DatabaseService]    FLUSH PRIVILEGES;');
      print('');
      print('[DatabaseService] Then verify with:');
      print(
          '[DatabaseService]    SELECT user, plugin FROM mysql.user WHERE user="root";');
      print('');
      print('[DatabaseService] Then restart the app.');
      print('');

      _connection = null;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!
            .completeError(lastError ?? Exception('Connection failed'));
        _connectionCompleter = null;
      }
      throw lastError ?? Exception('Could not connect to MySQL');
    }

    try {
      // Initialize database tables - use try/catch to prevent blocking
      try {
        await _initializeTables(conn);
      } catch (e) {
        print('[DatabaseService] ⚠ Table initialization warning: $e');
        // Don't fail the connection if initialization has issues
        // Tables may already exist
      }

      _connection = conn;
      _connectionCompleter!.complete(conn);
      _connectionCompleter = null;

      return conn;
    } catch (e) {
      print('Error initializing tables: $e');
      _connection = null;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(e);
        _connectionCompleter = null;
      }
      rethrow;
    }
  }

  /// 🔒 Safe query wrapper that prevents concurrent queries
  /// 🔒 Safe query wrapper that prevents concurrent queries
  /// Uses Mutex lock to ensure only one query runs at a time
  /// This prevents RangeError from concurrent access to mysql1 connection
  Future<Results> _safeQuery(String sql, [List<Object?>? values]) async {
    return await _query(sql, values);
  }

  Future<Results> _query(String sql, [List<Object?>? values]) async {
    // 🔒 ALWAYS protect with lock - regardless of caller
    return await _lock.synchronized(() async {
      try {
        final conn = await _getConnection();
        return await conn.query(sql, values);
      } catch (e) {
        print('[DatabaseService] ⚠ Query failed: $e');
        print('[DatabaseService] SQL was: $sql');
        print('[DatabaseService] Forcing connection cleanup and retrying...');

        // Force close existing connection if it's broken
        try {
          await _connection?.close();
        } catch (_) {}
        _connection = null;
        _connectionCompleter = null;

        try {
          final conn = await _getConnection();
          return await conn.query(sql, values);
        } catch (e2) {
          print('[DatabaseService] [ERROR] Retry failed: $e2');
          // Clean up again
          try {
            await _connection?.close();
          } catch (_) {}
          _connection = null;
          _connectionCompleter = null;

          // If this is a RangeError, provide specific guidance
          if (e2.toString().contains('RangeError')) {
            print('[DatabaseService]');
            print(
                '[DatabaseService] 🔴 RangeError detected - LIKELY AUTHENTICATION PLUGIN ISSUE');
            print(
                '[DatabaseService] The mysql1 driver cannot communicate with your MySQL server.');
            print('[DatabaseService]');
            print(
                '[DatabaseService] Run these SQL commands on your MySQL server:');
            print(
                '[DatabaseService]   ALTER USER "root"@"localhost" IDENTIFIED WITH mysql_native_password BY "200413";');
            print(
                '[DatabaseService]   ALTER USER "root"@"%" IDENTIFIED WITH mysql_native_password BY "200413";');
            print('[DatabaseService]   FLUSH PRIVILEGES;');
            print('[DatabaseService]');
          }
          rethrow;
        }
      }
    });
  }

  /* ================= INIT TABLES ================= */

  /* ================= INIT TABLES ================= */

  Future<void> _initializeTables(MySqlConnection conn) async {
    // Note: api.py is the primary source for table creation.
    // To avoid PrepareOkPacket RangeError issues, we only ensure critical tables exist using raw SQL.
    // ALTER TABLE operations are skipped to prevent concurrent query issues during init.

    // 1. Ensure 'thingspeak_logs' table exists (raw SQL, no parameterized queries)
    try {
      await conn.query('CREATE TABLE IF NOT EXISTS thingspeak_logs ('
          'id INT AUTO_INCREMENT PRIMARY KEY,'
          'entry_id INT UNIQUE NOT NULL,'
          'created_at DATETIME,'
          'air_temp DECIMAL(5,2),'
          'humidity DECIMAL(5,2),'
          'leaf_temp DECIMAL(5,2),'
          'lux DECIMAL(10,2),'
          'pump_status BOOLEAN,'
          'light_status BOOLEAN)');
      print('[DatabaseService] [OK] thingspeak_logs table ready');
    } catch (e) {
      // Table might already exist, continue
      print('[DatabaseService] thingspeak_logs note: $e');
    }

    // 2. Ensure 'device_logs' table exists (raw SQL, no parameterized queries)
    try {
      await conn.query('CREATE TABLE IF NOT EXISTS device_logs ('
          'id INT AUTO_INCREMENT PRIMARY KEY,'
          'device_name VARCHAR(100) NOT NULL,'
          'action VARCHAR(10) NOT NULL,'
          'timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,'
          'INDEX idx_device_name (device_name),'
          'INDEX idx_timestamp (timestamp))');
      print('[DatabaseService] [OK] device_logs table ready');
    } catch (e) {
      // Table might already exist, continue
      print('[DatabaseService] device_logs note: $e');
    }

    print(
        '[DatabaseService] [OK] Table initialization complete (columns assumed to exist from backend)');
  }

  /* ================= AUTH ================= */

  Future<bool> userExists(String username) async {
    // Use HTTP API for web platform
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/auth/check'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username}),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['exists'] == true;
        }
        return false;
      } catch (e) {
        print('Error checking user via API: $e');
        return false;
      }
    }

    // Use direct MySQL for mobile/desktop
    try {
      final res = await _safeQuery(
          'SELECT COUNT(*) as count FROM users WHERE username = ?', [username]);
      if (res.isEmpty) return false;
      final row = res.first;
      // Handle both numeric index and column name
      final count = row[0] as int? ?? (row['count'] as int? ?? 0);
      return count > 0;
    } catch (e) {
      print('[DatabaseService] ⚠ Error checking user: $e');
      return false;
    }
  }

  Future<bool> registerUser(
      String username, String password, String userType) async {
    // Use HTTP API for web platform
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'password': password,
            'user_type': userType,
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            // Auto-login after registration
            _currentUser = {
              'user_id': data['user_id'],
              'username': username,
              'user_type': userType,
            };
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', data['user_id']);
            return true;
          }
        }
        return false;
      } catch (e) {
        print('Register error via API: $e');
        return false;
      }
    }

    // Use direct MySQL for mobile/desktop
    try {
      await _safeQuery(
        'INSERT INTO users (username, password, user_type, created_at) VALUES (?, ?, ?, NOW())',
        [username, password, userType],
      );
      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyUser(
      String username, String password) async {
    // Use HTTP API for web platform
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'password': password,
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['user'] != null) {
            _currentUser = {
              'user_id': data['user']['user_id'],
              'username': data['user']['username'],
              'user_type': data['user']['user_type'] ?? 'user',
            };
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', data['user']['user_id']);
            return _currentUser;
          }
        }
        return null;
      } catch (e) {
        print('Error verifying user via API: $e');
        return null;
      }
    }

    // Use direct MySQL for mobile/desktop
    try {
      final res = await _safeQuery(
        'SELECT user_id, username, user_type FROM users WHERE username = ? AND password = ?',
        [username, password],
      );

      if (res.isEmpty) {
        print('[DatabaseService] ⚠ User not found or password incorrect');
        return null;
      }

      final row = res.first;
      // Handle both numeric index and column name access
      final userId = (row[0] as int?) ?? (row['user_id'] as int?) ?? 0;
      final userUsername =
          (row[1] as String?) ?? (row['username'] as String?) ?? username;
      final userType =
          (row[2] as String?) ?? (row['user_type'] as String?) ?? 'user';

      if (userId == 0) {
        print('[DatabaseService] ⚠ Invalid user_id from query');
        return null;
      }

      _currentUser = {
        'user_id': userId,
        'username': userUsername,
        'user_type': userType,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId);

      return _currentUser;
    } catch (e) {
      print('[DatabaseService] ⚠ Error verifying user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  /* ================= DEVICE ================= */
  // api.py uses 'devices' table: device_id, plot_id, device_name, device_type, status ('ON'/'OFF'), mode ('AUTO'/'MANUAL')

  Future<Map<String, dynamic>> getDeviceStatus(String deviceName) async {
    try {
      // Use parameterized query to prevent SQL injection
      final res = await _safeQuery(
          'SELECT status, mode FROM devices WHERE device_name = ? LIMIT 1',
          [deviceName]);

      if (res.isEmpty) {
        return {'status': false, 'online': true, 'auto_mode': false};
      }

      final row = res.first;
      // Handle both numeric index and column name access
      final statusStr =
          (row[0] as String?) ?? (row['status'] as String?) ?? 'OFF';
      final modeStr =
          (row[1] as String?) ?? (row['mode'] as String?) ?? 'MANUAL';

      return {
        'status': statusStr.toUpperCase() == 'ON',
        'online': true,
        'auto_mode': modeStr.toUpperCase() == 'AUTO',
      };
    } catch (e) {
      print('[DatabaseService] ⚠ Error getting device status: $e');
      return {'status': false, 'online': false, 'auto_mode': false};
    }
  }

  Future<void> updateDeviceStatus(String deviceName, bool status) async {
    try {
      final statusStr = status ? 'ON' : 'OFF';
      print('[DatabaseService] Updating device: $deviceName to $statusStr');

      // Update existing device using parameterized query
      final result = await _safeQuery(
          "UPDATE devices SET status = ? WHERE device_name = ?",
          [statusStr, deviceName]);

      // If no rows affected, auto-create device linked to Plot 1
      if (result.affectedRows == 0) {
        print('[DatabaseService] Device not found, creating new device record');
        try {
          final plotRes = await _safeQuery('SELECT plot_id FROM plots LIMIT 1');
          if (plotRes.isNotEmpty) {
            int plotId = plotRes.first[0];
            await _safeQuery(
                "INSERT INTO devices (plot_id, device_name, device_type, status, mode) VALUES (?, ?, 'GENERIC', ?, 'MANUAL')",
                [plotId, deviceName, statusStr]);
            print('[DatabaseService] New device created: $deviceName');
          }
        } catch (e) {
          print('[DatabaseService] Could not create device record: $e');
        }
      } else {
        print(
            '[DatabaseService] Device updated successfully: $deviceName = $statusStr');
      }

      // Log the device action
      await logDeviceAction(deviceName, statusStr);
    } catch (e) {
      print('[DatabaseService] Error updating device: $e');
      _connection = null;
      throw e;
    }
  }

  Future<void> updateAllDevices(bool status) async {
    try {
      final statusStr = status ? 'ON' : 'OFF';
      print('[DatabaseService] Update all devices requested');

      // Update all devices
      await _safeQuery("UPDATE devices SET status = ?", [statusStr]);

      print('[DatabaseService] All devices updated to $statusStr');

      // Log master switch action
      await logDeviceAction('master_switch', statusStr);
    } catch (e) {
      print('[DatabaseService] Error updating all devices: $e');
      _connection = null;
      throw e;
    }
  }

  /// Log device action (ON/OFF) to device_logs table
  /// Uses _safeQuery to protect against concurrent access
  Future<void> logDeviceAction(String deviceName, String action) async {
    try {
      // Log the device action using parameterized query with lock protection
      await _safeQuery(
          "INSERT INTO device_logs (device_name, action, timestamp) VALUES (?, ?, NOW())",
          [deviceName, action]);
      print('[DatabaseService] Logged action: $deviceName = $action');
    } catch (e) {
      // If device_logs logging fails, log the error but don't break the update
      print('[DatabaseService] ⚠ Could not log to device_logs: $e');
      // Don't rethrow - this is a non-critical logging operation
    }
  }

  /* ================= SENSOR ================= */

  Future<double> getLatestSensorValue(String sensorType) async {
    String column = '';
    switch (sensorType) {
      case 'air_temp':
        column = 'air_temp';
        break;
      case 'humidity':
        column = 'humidity';
        break;
      case 'lux':
        column = 'light_lux';
        break;
      case 'leaf_temp':
        column = 'leaf_temp';
        break;
      case 'water_level':
        column = 'water_level';
        break;
      default:
        return 0.0;
    }

    try {
      final res = await _safeQuery(
          'SELECT $column FROM sensor_logs ORDER BY timestamp DESC LIMIT 1');

      if (res.isEmpty) return 0.0;

      final row = res.first;
      // Handle both numeric index and column name access
      dynamic value = (row[0] ?? row[column]);
      return double.tryParse(value.toString()) ?? 0.0;
    } catch (e) {
      print('[DatabaseService] ⚠ Error getting sensor value $sensorType: $e');
      return 0.0;
    }
  }

  /// 🔒 Get the LATEST sensor log for EACH plot (not just global latest)
  /// Returns: Map<plot_id, SensorLog>
  /// This ensures each plot displays its own most recent sensor reading
  Future<Map<int, SensorLog>> getLatestLogsPerPlot() async {
    try {
      print('[DatabaseService] Fetching latest sensor logs per plot');

      // 🔒 Using _query() ensures Mutex lock protection
      /// Select the latest log for each plot using timestamp-based JOIN
      /// (more robust than log_id which may not be chronological)
      final results = await _query('''
        SELECT s1.*
        FROM sensor_logs s1
        INNER JOIN (
          SELECT plot_id, MAX(timestamp) AS latest_time
          FROM sensor_logs
          GROUP BY plot_id
        ) s2
        ON s1.plot_id = s2.plot_id
        AND s1.timestamp = s2.latest_time
        ''');

      Map<int, SensorLog> logsPerPlot = {};

      for (final row in results) {
        try {
          final plotId = row['plot_id'] ?? 0;

          // Build map with safe null handling
          final logMap = {
            'log_id': row['log_id'] ?? row['id'] ?? 0,
            'plot_id': plotId,
            'air_temp':
                double.tryParse((row['air_temp'] ?? 0).toString()) ?? 0.0,
            'air_humidity': double.tryParse(
                    (row['humidity'] ?? row['air_humidity'] ?? 0).toString()) ??
                0.0,
            'leaf_temp':
                double.tryParse((row['leaf_temp'] ?? 0).toString()) ?? 0.0,
            'light_lux': double.tryParse(
                    (row['lux'] ?? row['light_lux'] ?? 0).toString()) ??
                0.0,
            'cwsi_index': double.tryParse(
                    (row['cwsi'] ?? row['cwsi_index'] ?? 0).toString()) ??
                0.0,
            'recorded_at': (row['timestamp'] ?? DateTime.now()).toString(),
          };

          final log = SensorLog.fromMap(logMap);
          logsPerPlot[plotId] = log;
        } catch (e) {
          print('[DatabaseService] ⚠ Error parsing sensor log for plot: $e');
          continue;
        }
      }

      print(
          '[DatabaseService] Loaded latest logs for ${logsPerPlot.length} plots');
      return logsPerPlot;
    } catch (e) {
      print('[DatabaseService] Error fetching latest logs per plot: $e');
      return {};
    }
  }

  Future<Map<String, double>> getEnvironmentData() async {
    // Mock values based on actual sensor_logs data
    const mockData = {
      'air_temp': 24.0,
      'humidity': 52.5,
      'lux': 55.0,
      'leaf_temp': 25.6,
    };

    // Use HTTP API for web platform
    if (kIsWeb) {
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/environment'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          double airTemp =
              double.tryParse(data['air_temp']?.toString() ?? '0') ?? 0.0;
          double humidity =
              double.tryParse(data['humidity']?.toString() ?? '0') ?? 0.0;
          double lux = double.tryParse(data['lux']?.toString() ?? '0') ?? 0.0;
          double leafTemp =
              double.tryParse(data['leaf_temp']?.toString() ?? '0') ?? 0.0;

          print(
              '[HomeScreen] API Response: air_temp=$airTemp, humidity=$humidity, lux=$lux, leaf_temp=$leafTemp');

          // Use mock if all values are 0
          if (airTemp == 0 && humidity == 0 && lux == 0 && leafTemp == 0) {
            print('Using mock sensor data (no data from API)');
            return mockData;
          }

          return {
            'air_temp': airTemp > 0 ? airTemp : mockData['air_temp']!,
            'humidity': humidity > 0 ? humidity : mockData['humidity']!,
            'lux': lux > 0 ? lux : mockData['lux']!,
            'leaf_temp': leafTemp > 0 ? leafTemp : mockData['leaf_temp']!,
          };
        }
        return mockData;
      } catch (e) {
        print('Error getting env data from API: $e - using mock data');
        return mockData;
      }
    }

    // Use direct MySQL connection for mobile/desktop
    try {
      final res = await _safeQuery(
          'SELECT air_temp, humidity, light_lux, leaf_temp FROM sensor_logs ORDER BY timestamp DESC LIMIT 1');

      if (res.isEmpty) {
        print('No sensor_logs data found - using mock data');
        return mockData;
      }

      final row = res.first;
      double airTemp =
          double.tryParse(row['air_temp']?.toString() ?? '0') ?? 0.0;
      double humidity =
          double.tryParse(row['humidity']?.toString() ?? '0') ?? 0.0;
      double lux = double.tryParse(row['light_lux']?.toString() ?? '0') ?? 0.0;
      double leafTemp =
          double.tryParse(row['leaf_temp']?.toString() ?? '0') ?? 0.0;

      print(
          '[HomeScreen] MySQL Response: air_temp=$airTemp, humidity=$humidity, lux=$lux, leaf_temp=$leafTemp');

      // Use mock if all values are 0
      if (airTemp == 0 && humidity == 0 && lux == 0 && leafTemp == 0) {
        print('Using mock sensor data (DB values are 0)');
        return mockData;
      }

      return {
        'air_temp': airTemp > 0 ? airTemp : mockData['air_temp']!,
        'humidity': humidity > 0 ? humidity : mockData['humidity']!,
        'lux': lux > 0 ? lux : mockData['lux']!,
        'leaf_temp': leafTemp > 0 ? leafTemp : mockData['leaf_temp']!,
      };
    } catch (e) {
      print('Error getting env data: $e - using mock data');
      return mockData;
    }
  }

  // Used by Thingspeak sync to sync real-time buffer table
  Future<void> logSensorData(String type, double value) async {
    // Intentionally empty or implement if we have a separate 'sensor_data' table
    // The current schema uses 'sensor_logs' which is historical.
    // We could insert into sensor_logs but that requires all fields.
  }

  /* ================= THINGSPEAK & LOGS (RESTORED) ================= */

  Future<int> insertThingSpeakLog(Map<String, dynamic> log) async {
    try {
      // Check if exists
      final exists = await _safeQuery(
          'SELECT 1 FROM thingspeak_logs WHERE entry_id = ?',
          [log['entry_id']]);
      if (exists.isNotEmpty) return 0;

      await _safeQuery(
        '''
        INSERT INTO thingspeak_logs
        (entry_id, created_at, air_temp, humidity, leaf_temp, lux, pump_status, light_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          log['entry_id'],
          log['created_at'],
          log['air_temp'],
          log['humidity'],
          log['leaf_temp'],
          log['lux'],
          log['pump_status'],
          log['light_status'],
        ],
      );
      return 1;
    } catch (e) {
      print('Error inserting TS log: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getThingSpeakLogs({int limit = 50}) async {
    try {
      final res = await _safeQuery(
        'SELECT * FROM thingspeak_logs ORDER BY created_at DESC LIMIT ?',
        [limit],
      );
      return res.map((r) => r.fields).toList();
    } catch (e) {
      print('Error getting TS logs: $e');
      return [];
    }
  }

  /// Get sensor logs from sensor_logs table for display and CSV export
  Future<List<Map<String, dynamic>>> getSensorLogs({int limit = 100}) async {
    // For web, use API
    if (kIsWeb) {
      try {
        final response =
            await http.get(Uri.parse('$_apiBaseUrl/sensor-logs?limit=$limit'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return List<Map<String, dynamic>>.from(data['logs'] ?? []);
        }
      } catch (e) {
        print('Error getting sensor logs from API: $e');
      }
      return [];
    }

    // For mobile/desktop, use MySQL directly
    try {
      final res = await _safeQuery(
        'SELECT * FROM sensor_logs ORDER BY timestamp DESC LIMIT ?',
        [limit],
      );
      return res.map((r) => r.fields).toList();
    } catch (e) {
      print('Error getting sensor logs: $e');
      return [];
    }
  }

  /// Get sensor logs as SensorLog objects for graph/chart display
  Future<List<SensorLog>> getSensorLogsAsObjects({int limit = 50}) async {
    try {
      print('[DatabaseService] Fetching sensor logs (limit: $limit)');

      // 🔒 Use _query() to ensure Mutex lock protection
      // This prevents concurrent access from causing RangeError
      final results = await _query(
        'SELECT * FROM sensor_logs ORDER BY timestamp DESC LIMIT ?',
        [limit],
      );

      List<SensorLog> logs = [];
      for (var row in results) {
        try {
          // Convert Row to Map for SensorLog.fromMap
          // Use column names primarily, with numeric index fallback
          Map<String, dynamic> map = {};

          // Helper function to safely get value from row
          dynamic _get(dynamic indexOrKey, [dynamic defaultValue]) {
            try {
              if (row is Map) {
                return row[indexOrKey] ?? defaultValue;
              }
              // For numeric index, check bounds first
              if (indexOrKey is int && indexOrKey >= 0) {
                try {
                  return row[indexOrKey] ?? defaultValue;
                } catch (e) {
                  // Index out of range - return default
                  return defaultValue;
                }
              }
              return defaultValue;
            } catch (e) {
              return defaultValue;
            }
          }

          map = {
            'log_id': _get('id', _get('log_id', 0)) as int? ?? 0,
            'plot_id': _get('plot_id', 0) as int? ?? 0,
            'air_temp':
                double.tryParse((_get('air_temp', 0) ?? 0).toString()) ?? 0.0,
            'air_humidity': double.tryParse(
                    (_get('humidity', _get('air_humidity', 0)) ?? 0)
                        .toString()) ??
                0.0,
            'leaf_temp':
                double.tryParse((_get('leaf_temp', 0) ?? 0).toString()) ?? 0.0,
            'light_lux': double.tryParse(
                    (_get('lux', _get('light_lux', 0)) ?? 0).toString()) ??
                0.0,
            'cwsi_index': double.tryParse(
                    (_get('cwsi', _get('cwsi_index', 0)) ?? 0).toString()) ??
                0.0,
            'recorded_at': (_get('timestamp', DateTime.now()) ?? DateTime.now())
                .toString(),
          };

          logs.add(SensorLog.fromMap(map));
        } catch (e) {
          print('[DatabaseService] ⚠ Error parsing sensor log row: $e');
          // Continue to next row instead of crashing
          continue;
        }
      }

      // Reverse to show oldest -> newest (left to right for graphs)
      logs = logs.reversed.toList();
      print('[DatabaseService] Loaded ${logs.length} sensor logs');
      return logs;
    } catch (e) {
      print('[DatabaseService] Error fetching sensor logs: $e');
      // Mark connection as dirty so next call reconnects
      _connection = null;
      // Return empty list instead of throwing
      return [];
    }
  }

  /* ================= PLOTS ================= */

  Future<int> createPlot(Plot plot) async {
    try {
      int userId = 1;
      if (_currentUser != null) {
        userId = _currentUser!['user_id'];
      }

      // Use toMap() to get properly formatted data (especially the date)
      final plotData = plot.toMap();

      print(
          '[DatabaseService] Creating plot with formatted date: ${plotData['planting_date']}');

      final res = await _query('''INSERT INTO plots
           (user_id, plot_name, image_path, plant_type, planting_date, leaf_temp, water_level, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', [
        userId,
        plotData['plot_name'],
        plotData['image_path'],
        plotData['plant_type'],
        plotData['planting_date'], // Now using the cleaned date from toMap()
        0.0, // Force initial sensor value to 0.0 (not from plot object)
        0.0, //  Force initial water level to 0.0 (not from plot object)
        plotData['note'],
      ]);
      print(
          '[DatabaseService]  Plot created successfully with 0.0 sensor values');
      return res.insertId ?? 0;
    } catch (e) {
      print('Error creating plot: $e');
      throw e;
    }
  }

  /// Helper: Convert MySQL Blob/TEXT to String
  String _blobToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Blob) return String.fromCharCodes(value.toBytes());
    return value.toString();
  }

  Future<List<Plot>> getAllPlots() async {
    // Use HTTP API for web platform
    if (kIsWeb) {
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/plots'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data
              .map((item) => Plot(
                    id: item['plot_id'],
                    name: item['plot_name'] ?? '',
                    imagePath: item['image_path'] ?? 'assets/tree1.png',
                    plantType: item['plant_type'] ?? '',
                    datePlanted: item['planting_date']?.toString() ?? '',
                    leafTemp:
                        double.tryParse(item['leaf_temp']?.toString() ?? '0') ??
                            0.0,
                    waterLevel: double.tryParse(
                            item['water_level']?.toString() ?? '0') ??
                        0.0,
                    note: item['note'] ?? '',
                  ))
              .toList();
        }
        return [];
      } catch (e) {
        print('Error getting plots from API: $e');
        return [];
      }
    }

    // Use direct MySQL for mobile/desktop
    try {
      final results = await _query('SELECT * FROM plots ORDER BY plot_id ASC');
      return results.map((row) {
        return Plot(
            id: row['plot_id'],
            name: _blobToString(row['plot_name']),
            imagePath: _blobToString(row['image_path']).isEmpty
                ? 'assets/tree1.png'
                : _blobToString(row['image_path']),
            plantType: _blobToString(row['plant_type']),
            datePlanted: row['planting_date']?.toString() ?? '',
            leafTemp:
                double.tryParse(row['leaf_temp']?.toString() ?? '0') ?? 0.0,
            waterLevel:
                double.tryParse(row['water_level']?.toString() ?? '0') ?? 0.0,
            note: _blobToString(row['note']));
      }).toList();
    } catch (e) {
      print('Error getting plots: $e');
      return [];
    }
  }

  Future<void> updatePlot(Plot plot) async {
    try {
      print('[DatabaseService] ===== UPDATE PLOT START =====');
      print('[DatabaseService] Updating plot in MySQL:');
      print('[DatabaseService]   ID=${plot.id}');
      print('[DatabaseService]   Name=${plot.name}');
      print('[DatabaseService]   PlantType=${plot.plantType}');
      print('[DatabaseService]   LeafTemp=${plot.leafTemp}');
      print('[DatabaseService]   WaterLevel=${plot.waterLevel}');
      print('[DatabaseService]   Note=${plot.note}');

      // Critical check: ensure ID is not null
      if (plot.id == null) {
        throw Exception('CRITICAL: plot.id is NULL! Cannot update without ID');
      }

      // Use toMap() to get properly formatted data (especially the date)
      final plotData = plot.toMap();

      print('[DatabaseService] Using Plot.toMap() for properly formatted data');
      print(
          '[DatabaseService] Formatted planting_date: ${plotData['planting_date']}');

      final sql = '''UPDATE plots
           SET plot_name=?, image_path=?, plant_type=?, planting_date=?,
               leaf_temp=?, water_level=?, note=?
           WHERE plot_id=?''';

      print('[DatabaseService] Executing SQL: $sql');
      print(
          '[DatabaseService] Parameters: [${plotData['plot_name']}, ${plotData['image_path']}, ${plotData['plant_type']}, ${plotData['planting_date']}, ${plotData['leaf_temp']}, ${plotData['water_level']}, ${plotData['note']}, ${plotData['id']}]');

      await _query(sql, [
        plotData['plot_name'],
        plotData['image_path'],
        plotData['plant_type'],
        plotData['planting_date'], // Now using the cleaned date from toMap()
        plotData['leaf_temp'],
        plotData['water_level'],
        plotData['note'],
        plotData['id'],
      ]);

      print('[DatabaseService] Plot updated successfully in MySQL: ${plot.id}');
      print('[DatabaseService] ===== UPDATE PLOT END =====');
    } catch (e) {
      print('[DatabaseService] Error updating plot: $e');
      print('[DatabaseService] Stack trace: ${e.toString()}');
      throw e;
    }
  }

  /// Update only sensor data (leaf_temp, cwsi) for a plot to persist real-time readings
  Future<void> updatePlotSensorData(
      int plotId, double leafTemp, double cwsi) async {
    try {
      print(
          '[DatabaseService] Updating plot sensor data: plotId=$plotId, leafTemp=$leafTemp, cwsi=$cwsi');

      await _query('UPDATE plots SET leaf_temp = ?, note = ? WHERE plot_id = ?',
          [leafTemp, 'CWSI: ${cwsi.toStringAsFixed(2)}', plotId]);

      print('[DatabaseService] Sensor data persisted for plot $plotId');
    } catch (e) {
      print('[DatabaseService] Error updating sensor data: $e');
      // Don't throw - this is a background update, we don't want it to break the UI
    }
  }

  Future<void> deletePlot(int id) async {
    try {
      await _query('DELETE FROM plots WHERE plot_id = ?', [id]);
    } catch (e) {
      print('Error deleting plot: $e');
      throw e;
    }
  }

  /* ================= CLOSE ================= */

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}

/*
import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  //static const String _host = 'localhost';
  static const String _host = '10.0.2.2';
  static const int _port = 3306;
  static const String _database = 'smart_farm_db';
  static const String _username = 'root';
  static const String _password = '200413';

  MySqlConnection? _connection;
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> _connect() async {
    try {
      final settings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _username,
        password: _password,
        db: _database,
        timeout: const Duration(seconds: 10),// add Timeout
      );
      _connection = await MySqlConnection.connect(settings);
      print('Connected to MySQL database');

      // Initialize tables if they don't exist
      await _initializeTables();
    } catch (e) {
      print('Error connecting to MySQL database: $e');
      _connection = null;
      rethrow;
    }
  }

  Future<MySqlConnection> _getConnection() async {
    if (_connection == null) {
      await _connect();
    }
    return _connection!;
  }

  Future<Results> _query(String sql, [List<Object?>? values]) async {
    try {
      final conn = await _getConnection();
      return await conn.query(sql, values);
    } catch (e) {
      final err = e.toString();
      if (err.contains('SocketException') ||
          err.contains('Bad state') ||
          err.contains('Connection closed') ||
          err.contains('Cannot write to socket') ||
          err.contains('Broken pipe')) {
      print('Connection lost. Reconnecting');
      _connection = null;

      final conn = await _getConnection();
      return await conn.query(sql, values);
    }
    rethrow;
    }
  }

  Future<void> _initializeTables() async {
    final conn = _connection!;
    if (conn == null) return;
    
    // Users table with migration
    await conn.query('''
      CREATE TABLE IF NOT EXISTS users (
        user_id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        user_type VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Add 'id' column if it doesn't exist
    /*var idColumnExists = await conn.query("SHOW COLUMNS FROM `users` LIKE 'id'");
    if (idColumnExists.isEmpty) {
      try {
        await conn.query('ALTER TABLE `users` ADD COLUMN `id` INT NOT NULL AUTO_INCREMENT FIRST, ADD PRIMARY KEY (`id`)');
      } catch (e) {
        print('Migration failed: $e. Recreating users table.');
        await conn.query('RENAME TABLE `users` TO `users_backup_${DateTime.now().millisecondsSinceEpoch}`');
        await conn.query('''
          CREATE TABLE users (
            user_id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }
    }*/

    // Add 'user_type' column if it doesn't exist
    var userTypeColumnExists = await conn.query("SHOW COLUMNS FROM `users` LIKE 'user_type'");
    if (userTypeColumnExists.isEmpty) {
      await conn.query("ALTER TABLE `users` ADD COLUMN `user_type` VARCHAR(50) NOT NULL AFTER `password`");
    }

    // Device status table
    await conn.query('''
      CREATE TABLE IF NOT EXISTS device_status (
        device_id INT AUTO_INCREMENT PRIMARY KEY,
        device_name VARCHAR(100) UNIQUE NOT NULL,
        status BOOLEAN DEFAULT FALSE,
        online BOOLEAN DEFAULT TRUE,
        auto_mode BOOLEAN DEFAULT FALSE,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''');

    // Insert default device statuses if they don't exist
    await conn.query('''
      INSERT IGNORE INTO device_status (device_name, status, online, auto_mode) VALUES
      ('light1', FALSE, TRUE, FALSE),
      ('light2', FALSE, TRUE, FALSE),
      ('humidity_system', FALSE, TRUE, FALSE),
      ('master_switch', FALSE, TRUE, FALSE)
    ''');

    // Sensor data table (for humidity, temperature, etc.)
    await conn.query('''
      CREATE TABLE IF NOT EXISTS sensor_data (
        id INT AUTO_INCREMENT PRIMARY KEY,
        sensor_type VARCHAR(50) NOT NULL,
        value DECIMAL(10, 2) NOT NULL,
        recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_sensor_type (sensor_type),
        INDEX idx_recorded_at (recorded_at)
      )
    ''');

    // ThingSpeak logs table
    await conn.query('''
      CREATE TABLE IF NOT EXISTS thingspeak_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        entry_id INT UNIQUE NOT NULL,
        created_at DATETIME,
        air_temp DECIMAL(5,2),
        humidity DECIMAL(5,2),
        leaf_temp DECIMAL(5,2),
        lux DECIMAL(10,2),
        pump_status BOOLEAN,
        light_status BOOLEAN
      )
    ''');
  }

  Future<int> insertThingSpeakLog(Map<String, dynamic> log) async {
    try {
      final entryId = log['entry_id'];
      
      final check = await _query('SELECT id FROM thingspeak_logs WHERE entry_id = ?', [entryId]);
      if (check.isNotEmpty) return 0; // Already exists

      await _query(
        '''INSERT INTO thingspeak_logs 
           (entry_id, created_at, air_temp, humidity, leaf_temp, lux, pump_status, light_status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          log['entry_id'],
          log['created_at'],
          log['field1'],
          log['field2'],
          log['field3'],
          log['field5'],
          log['field6'],
          log['field7'],
        ]
      );
      return 1;
    } catch (e) {
      print('Error inserting ThingSpeak log: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getThingSpeakLogs({int limit = 50}) async {
    try {
      final results = await _query(
        'SELECT * FROM thingspeak_logs ORDER BY created_at DESC LIMIT ?',
        [limit]
      );
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('Error getting ThingSpeak logs: $e');
      return [];
    }
  }


  Future<bool> userExists(String username) async {
    try {
      final results = await _query(
        'SELECT user_id, username, user_type FROM users WHERE username = ? AND password = ?',
        [username],
      );
      return results.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyUser(String username, String password) async {
    try {
      final results = await _query(
        'SELECT user_id, username, user_type FROM users WHERE username = ? AND password = ?',
        //[username, password],
        [username, password],
      );
      
      if (results.isNotEmpty) {
        final row = results.first;
        _currentUser = {
          'user_id': row['user_id'],
          'username': row['username'],
          'user_type': row['user_type'],
        };
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_id', _currentUser!['user_id'].toString());
        
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Error verifying user: $e');
      return null;
    }
  }

  Future<bool> registerUser(String username, String password, String userType) async {
    try {
      await _query(
        'INSERT INTO users (username, password, user_type) VALUES (?, ?, ?)',
        [username, password, userType],
      );
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<Map<String, bool>> getDeviceStatus() async {
    try {
      final results = await _query(
        'SELECT device_name, online, auto_mode FROM device_status WHERE device_name = ?',
        ['light1'],
      );
      
      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'online': row['online'] == 1,
          'auto_mode': row['auto_mode'] == 1,
        };
      }
      return {'online': false, 'auto_mode': false};
    } catch (e) {
      print('Error getting device status: $e');
      return {'online': false, 'auto_mode': false};
    }
  }

  Future<bool> updateDeviceState(String deviceName, bool status) async {
    try {
      await _query(
        'UPDATE device_status SET status = ? WHERE device_name = ?',
        [status, deviceName],
      );
      return true;
    } catch (e) {
      print('Error updating device state: $e');
      return false;
    }
  }

  Future<bool> updateMasterSwitch(bool status) async {
    try {
      await _query(
        'UPDATE device_status SET status = ? WHERE device_name IN (?, ?, ?)',
        [status, 'light1', 'light2', 'humidity_system'],
      );
      await _query(
        'UPDATE device_status SET status = ? WHERE device_name = ?',
        [status, 'master_switch'],
      );
      return true;
    } catch (e) {
      print('Error updating master switch: $e');
      return false;
    }
  }

  Future<String> getCurrentHumidity() async {
    try {
      final results = await _query(
        'SELECT value FROM sensor_data WHERE sensor_type = ? ORDER BY recorded_at DESC LIMIT 1',
        ['humidity'],
      );
      
      if (results.isNotEmpty) {
        return results.first['value'].toString();
      }
      return '80'; // Default value
    } catch (e) {
      print('Error getting humidity: $e');
      return '80';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
*/
