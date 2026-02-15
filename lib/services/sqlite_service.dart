import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plot.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  factory SQLiteService() => _instance;
  SQLiteService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_farm_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Plots table
    await db.execute('''
      CREATE TABLE plots (
        plot_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        plot_name TEXT NOT NULL,
        image_path TEXT,
        plant_type TEXT,
        planting_date TEXT NOT NULL,
        leaf_temp REAL DEFAULT 0.0,
        water_level REAL DEFAULT 0.0,
        note TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Sensor logs table
    await db.execute('''
      CREATE TABLE sensor_logs (
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        air_temp REAL NOT NULL,
        humidity REAL NOT NULL,
        light_lux REAL NOT NULL,
        leaf_temp REAL NOT NULL,
        water_level REAL NOT NULL,
        cwsi_value REAL NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (plot_id) REFERENCES plots (plot_id) ON DELETE CASCADE
      )
    ''');

    // Devices table
    await db.execute('''
      CREATE TABLE devices (
        device_id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        device_name TEXT NOT NULL,
        device_type TEXT NOT NULL,
        status TEXT NOT NULL,
        mode TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (plot_id) REFERENCES plots (plot_id) ON DELETE CASCADE
      )
    ''');

    // Device logs table
    await db.execute('''
      CREATE TABLE device_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_name TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    print('SQLite database initialized successfully');
  }

  // ==================== PLOTS CRUD ====================

  Future<int> createPlot(Plot plot) async {
    final db = await database;

    // Use toMap() to get properly formatted data
    final plotData = plot.toMap();

    final id = await db.insert('plots', {
      'user_id': 1, // Default user
      'plot_name': plotData['plot_name'],
      'image_path': plotData['image_path'],
      'plant_type': plotData['plant_type'],
      'planting_date': plotData['planting_date'], // Clean date from toMap()
      'leaf_temp': plotData['leaf_temp'],
      'water_level': plotData['water_level'],
      'note': plotData['note'],
      'synced': 0, // Not synced yet
    });

    print('Created plot in SQLite with ID: $id');
    return id;
  }

  Future<List<Plot>> getAllPlots() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plots',
      orderBy: 'plot_id ASC',
    );

    return List.generate(maps.length, (i) {
      return Plot(
        id: maps[i]['plot_id'],
        name: maps[i]['plot_name'] ?? '',
        imagePath: maps[i]['image_path'] ?? 'assets/tree1.png',
        plantType: maps[i]['plant_type'] ?? '',
        datePlanted: maps[i]['planting_date'] ?? '',
        leafTemp: (maps[i]['leaf_temp'] as num?)?.toDouble() ?? 0.0,
        waterLevel: (maps[i]['water_level'] as num?)?.toDouble() ?? 0.0,
        note: maps[i]['note'] ?? '',
      );
    });
  }

  Future<void> updatePlot(Plot plot) async {
    final db = await database;

    print(
        '[SQLiteService] Updating plot: ID=${plot.id}, name=${plot.name}, leaf_temp=${plot.leafTemp}, water=${plot.waterLevel}');

    // Use toMap() to get properly formatted data
    final plotData = plot.toMap();

    await db.update(
      'plots',
      {
        'plot_name': plotData['plot_name'],
        'image_path': plotData['image_path'],
        'plant_type': plotData['plant_type'],
        'planting_date': plotData['planting_date'], // Clean date from toMap()
        'leaf_temp': plotData['leaf_temp'],
        'water_level': plotData['water_level'],
        'note': plotData['note'],
        'synced': 0, // Mark as not synced
      },
      where: 'plot_id = ?',
      whereArgs: [plot.id],
    );

    print('[SQLiteService] Plot updated successfully: ${plot.id}');
  }

  Future<void> deletePlot(int id) async {
    final db = await database;

    await db.delete(
      'plots',
      where: 'plot_id = ?',
      whereArgs: [id],
    );

    print('Deleted plot from SQLite: $id');
  }

  // ==================== ENVIRONMENT DATA ====================

  Future<Map<String, double>> getLatestEnvironmentData() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'sensor_logs',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return {'air_temp': 0.0, 'humidity': 0.0, 'lux': 0.0};
    }

    final row = result.first;
    return {
      'air_temp': (row['air_temp'] as num?)?.toDouble() ?? 0.0,
      'humidity': (row['humidity'] as num?)?.toDouble() ?? 0.0,
      'lux': (row['light_lux'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<void> insertSensorLog({
    required int plotId,
    required double airTemp,
    required double humidity,
    required double lightLux,
    required double leafTemp,
    required double waterLevel,
    required double cwsiValue,
  }) async {
    final db = await database;

    await db.insert('sensor_logs', {
      'plot_id': plotId,
      'timestamp': DateTime.now().toIso8601String(),
      'air_temp': airTemp,
      'humidity': humidity,
      'light_lux': lightLux,
      'leaf_temp': leafTemp,
      'water_level': waterLevel,
      'cwsi_value': cwsiValue,
      'synced': 0,
    });
  }

  // ==================== DEVICES ====================

  Future<Map<String, dynamic>> getDeviceStatus(String deviceName) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'devices',
      where: 'device_name = ?',
      whereArgs: [deviceName],
      limit: 1,
    );

    if (result.isEmpty) {
      return {'status': false, 'online': true, 'auto_mode': false};
    }

    final row = result.first;
    return {
      'status': row['status'] == 'ON',
      'online': true,
      'auto_mode': row['mode'] == 'AUTO',
    };
  }

  Future<void> updateDeviceStatus(String deviceName, bool status) async {
    final db = await database;
    final statusStr = status ? 'ON' : 'OFF';

    // Update device status
    await db.update(
      'devices',
      {
        'status': statusStr,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'device_name = ?',
      whereArgs: [deviceName],
    );

    // Log the action
    await db.insert('device_logs', {
      'device_name': deviceName,
      'action': statusStr,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  // ==================== SYNC HELPERS ====================

  Future<List<Map<String, dynamic>>> getUnsyncedPlots() async {
    final db = await database;
    return await db.query(
      'plots',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markPlotAsSynced(int plotId) async {
    final db = await database;
    await db.update(
      'plots',
      {'synced': 1},
      where: 'plot_id = ?',
      whereArgs: [plotId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDeviceLogs() async {
    final db = await database;
    return await db.query(
      'device_logs',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markDeviceLogAsSynced(int logId) async {
    final db = await database;
    await db.update(
      'device_logs',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  // ==================== CLEAR DATA ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('device_logs');
    await db.delete('devices');
    await db.delete('sensor_logs');
    await db.delete('plots');
    await db.delete('users');
    print('All SQLite data cleared');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
