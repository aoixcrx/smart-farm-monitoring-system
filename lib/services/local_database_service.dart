import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plot.dart';
import '../models/user.dart';
import '../models/sensor_log.dart';
import '../models/device_status.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_farm_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Bumped version for new tables
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL'; // 0 or 1

    // PLOTS
    await db.execute('''
    CREATE TABLE plots (
      id $idType,
      name $textType,
      image_path $textType,
      plant_type $textType,
      date_planted $textType,
      leaf_temp $realType,
      water_level $realType,
      note $textNullable
    )
    ''');

    // USERS
    await db.execute('''
    CREATE TABLE users (
      user_id $idType,
      username $textType,
      password $textType,
      user_type $textType,
      full_name $textType,
      created_at $textType
    )
    ''');

    // SENSOR_LOGS
    await db.execute('''
    CREATE TABLE sensor_logs (
      log_id $idType,
      plot_id INTEGER NOT NULL,
      air_temp $realType,
      air_humidity $realType,
      leaf_temp $realType,
      light_lux $realType,
      cwsi_index $realType,
      recorded_at $textType,
      FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
    )
    ''');

    // DEVICE_STATUS
    await db.execute('''
    CREATE TABLE device_status (
      device_id $idType,
      device_name $textType,
      is_active $boolType,
      updated_at $textType
    )
    ''');

    // Insert initial data (Mockup)
    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL NOT NULL';
      const boolType = 'INTEGER NOT NULL';

      await db.execute('''
      CREATE TABLE users (
        user_id $idType,
        username $textType,
        password $textType,
        user_type $textType,
        full_name $textType,
        created_at $textType
      )
      ''');

      await db.execute('''
      CREATE TABLE sensor_logs (
        log_id $idType,
        plot_id INTEGER NOT NULL,
        air_temp $realType,
        air_humidity $realType,
        leaf_temp $realType,
        light_lux $realType,
        cwsi_index $realType,
        recorded_at $textType,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
      ''');

      await db.execute('''
      CREATE TABLE device_status (
        device_id $idType,
        device_name $textType,
        is_active $boolType,
        updated_at $textType
      )
      ''');

      // Seed initial data for new tables if upgrading
      await _seedData(db, onlyNew: true);
    }
  }

  Future<void> _seedData(Database db, {bool onlyNew = false}) async {
    if (!onlyNew) {
      // Plots
      await db.insert('plots', {
        'name': 'แปลงทดลอง 1',
        'image_path': 'assets/tree1.png',
        'plant_type': 'Green Oak',
        'date_planted': DateTime.now().toIso8601String(),
        'leaf_temp': 27.9,
        'water_level': 15.1,
        'note': 'แปลงทดลองที่ 1'
      });

      await db.insert('plots', {
        'name': 'แปลงทดลอง 2',
        'image_path': 'assets/tree1.png',
        'plant_type': 'Red Oak',
        'date_planted': DateTime.now().toIso8601String(),
        'leaf_temp': 26.6,
        'water_level': 14.1,
        'note': 'แปลงทดลองที่ 2'
      });
    }

    // Users
    await db.insert('users', {
      'username': 'admin',
      'password': 'password123', // In real app, hash this
      'user_type': 'Admin',
      'full_name': 'Admin User',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Devices
    await db.insert('device_status', {
      'device_name': 'Grow Light 1',
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('device_status', {
      'device_name': 'Humidifier Pump',
      'is_active': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== PLOTS ====================
  Future<int> createPlot(Plot plot) async {
    final db = await instance.database;
    return await db.insert('plots', plot.toMap());
  }

  Future<Plot> readPlot(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'plots',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Plot.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Plot>> readAllPlots() async {
    final db = await instance.database;
    final result = await db.query('plots');
    return result.map((json) => Plot.fromMap(json)).toList();
  }

  Future<int> updatePlot(Plot plot) async {
    final db = await instance.database;
    return db.update(
      'plots',
      plot.toMap(),
      where: 'id = ?',
      whereArgs: [plot.id],
    );
  }

  Future<int> deletePlot(int id) async {
    final db = await instance.database;
    return await db.delete(
      'plots',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== USERS ====================
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> readAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((json) => User.fromMap(json)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'user_id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DEVICES ====================
  Future<int> createDevice(DeviceStatus device) async {
    final db = await instance.database;
    return await db.insert('device_status', device.toMap());
  }

  Future<List<DeviceStatus>> readAllDevices() async {
    final db = await instance.database;
    final result = await db.query('device_status');
    return result.map((json) => DeviceStatus.fromMap(json)).toList();
  }

  Future<int> updateDevice(DeviceStatus device) async {
    final db = await instance.database;
    return await db.update(
      'device_status',
      device.toMap(),
      where: 'device_id = ?',
      whereArgs: [device.deviceId],
    );
  }

  Future<int> deleteDevice(int id) async {
    final db = await instance.database;
    return await db.delete(
      'device_status',
      where: 'device_id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SENSOR LOGS ====================
  Future<int> createSensorLog(SensorLog log) async {
    final db = await instance.database;
    return await db.insert('sensor_logs', log.toMap());
  }

  Future<List<SensorLog>> readAllSensorLogs() async {
    final db = await instance.database;
    final result = await db.query('sensor_logs', orderBy: 'recorded_at DESC');
    return result.map((json) => SensorLog.fromMap(json)).toList();
  }

  Future<int> deleteSensorLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'sensor_logs',
      where: 'log_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
