import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sqlite_service.dart';
import 'database_service.dart';
import '../models/plot.dart';
import '../models/sensor_log.dart';

/// Hybrid Database Service
/// Automatically uses MySQL when online, SQLite when offline
/// Syncs data between SQLite and MySQL when connection is restored
class HybridDatabaseService {
  static final HybridDatabaseService _instance =
      HybridDatabaseService._internal();
  factory HybridDatabaseService() => _instance;
  HybridDatabaseService._internal();

  final SQLiteService _sqlite = SQLiteService();
  final DatabaseService _mysql = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  Timer? _syncTimer;

  // Initialize and start monitoring connectivity
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    _startPeriodicSync();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    // connectivity_plus now returns a List
    _isOnline = connectivityResults.isNotEmpty &&
        connectivityResults.first != ConnectivityResult.none;

    if (_isOnline) {
      print('🌐 ONLINE - Using MySQL');
      // Try to sync when we come online
      await syncToMySQL();
    } else {
      print('📴 OFFLINE - Using SQLite');
    }
  }

  void _startConnectivityMonitoring() {
    // connectivity_plus now provides List<ConnectivityResult>
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool wasOffline = !_isOnline;
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      if (_isOnline && wasOffline) {
        print('[OK] Connection restored - Syncing data...');
        await syncToMySQL();
      } else if (!_isOnline) {
        print('[ERROR] Connection lost - Switching to offline mode');
      }
    });
  }

  void _startPeriodicSync() {
    // Sync every 30 seconds when online
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isOnline) {
        await syncToMySQL();
      }
    });
  }

  // ==================== SYNC TO MYSQL ====================

  Future<void> syncToMySQL() async {
    if (!_isOnline) {
      print('Skipping sync - offline');
      return;
    }

    try {
      print('[SYNC] Starting sync to MySQL...');

      // Sync plots
      final unsyncedPlots = await _sqlite.getUnsyncedPlots();
      for (var plotData in unsyncedPlots) {
        try {
          final plot = Plot(
            id: plotData['plot_id'],
            name: plotData['plot_name'] ?? '',
            imagePath: plotData['image_path'] ?? '',
            plantType: plotData['plant_type'] ?? '',
            datePlanted: plotData['planting_date'] ?? '',
            leafTemp: (plotData['leaf_temp'] as num?)?.toDouble() ?? 0.0,
            waterLevel: (plotData['water_level'] as num?)?.toDouble() ?? 0.0,
            note: plotData['note'] ?? '',
          );

          // Check if plot exists in MySQL
          if (plotData['plot_id'] > 0) {
            await _mysql.updatePlot(plot);
            print('   [OK] Synced plot update: ${plot.name}');
          } else {
            final newId = await _mysql.createPlot(plot);
            print('   [OK] Synced new plot: ${plot.name} (MySQL ID: $newId)');
          }

          await _sqlite.markPlotAsSynced(plotData['plot_id']);
        } catch (e) {
          print('   ✗ Failed to sync plot ${plotData['plot_id']}: $e');
        }
      }

      // Sync device logs
      final unsyncedLogs = await _sqlite.getUnsyncedDeviceLogs();
      for (var log in unsyncedLogs) {
        try {
          await _mysql.logDeviceAction(
            log['device_name'],
            log['action'],
          );
          await _sqlite.markDeviceLogAsSynced(log['id']);
          print(
              '   [OK] Synced device log: ${log['device_name']} ${log['action']}');
        } catch (e) {
          print('   ✗ Failed to sync device log ${log['id']}: $e');
        }
      }

      if (unsyncedPlots.isEmpty && unsyncedLogs.isEmpty) {
        print('[OK] Sync complete - No pending changes');
      } else {
        print(
            '[OK] Sync complete - ${unsyncedPlots.length} plots, ${unsyncedLogs.length} logs');
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  // ==================== PLOTS CRUD ====================

  Future<int> createPlot(Plot plot) async {
    // Always save to SQLite first
    final localId = await _sqlite.createPlot(plot);

    // Try to save to MySQL if online
    if (_isOnline) {
      try {
        final mysqlId = await _mysql.createPlot(plot);
        await _sqlite.markPlotAsSynced(localId);
        print('Plot created in both SQLite and MySQL');
        return mysqlId;
      } catch (e) {
        print('MySQL save failed, will sync later: $e');
        return localId;
      }
    }

    return localId;
  }

  Future<List<Plot>> getAllPlots() async {
    if (_isOnline) {
      try {
        // Get from MySQL and update local cache
        final plots = await _mysql.getAllPlots();

        // Update SQLite cache (optional - for better offline experience)
        // await _updateLocalCache(plots);

        return plots;
      } catch (e) {
        print('MySQL fetch failed, using local data: $e');
        return await _sqlite.getAllPlots();
      }
    } else {
      return await _sqlite.getAllPlots();
    }
  }

  Future<void> updatePlot(Plot plot) async {
    // Always update SQLite first
    print('[HybridDB] Updating plot: ${plot.name} (ID: ${plot.id})');
    await _sqlite.updatePlot(plot);

    // Try to update MySQL if online
    if (_isOnline) {
      try {
        print('[HybridDB] Syncing to MySQL...');
        await _mysql.updatePlot(plot);
        print('[HybridDB] Plot updated in both SQLite and MySQL successfully');
      } catch (e) {
        print('[HybridDB] MySQL update failed, will sync later: $e');
      }
    } else {
      print('[HybridDB] Offline - will sync to MySQL when online');
    }
  }

  /// Update only sensor data (leaf_temp, cwsi) for a plot
  /// This is called frequently with real-time sensor readings
  Future<void> updatePlotSensorData(
      int plotId, double leafTemp, double cwsi) async {
    // Try to update MySQL if online (this is real-time data, prioritize MySQL)
    if (_isOnline) {
      try {
        print(
            '[HybridDB] Persisting sensor data to MySQL: plotId=$plotId, leafTemp=$leafTemp, cwsi=$cwsi');
        await _mysql.updatePlotSensorData(plotId, leafTemp, cwsi);
      } catch (e) {
        print('[HybridDB] MySQL sensor update failed: $e');
        // Don't throw - sensor updates are background operations
      }
    }
  }

  Future<void> deletePlot(int id) async {
    // Always delete from SQLite
    await _sqlite.deletePlot(id);

    // Try to delete from MySQL if online
    if (_isOnline) {
      try {
        await _mysql.deletePlot(id);
        print('Plot deleted from both SQLite and MySQL');
      } catch (e) {
        print('MySQL delete failed: $e');
      }
    }
  }

  // ==================== ENVIRONMENT DATA ====================

  Future<Map<String, double>> getEnvironmentData() async {
    if (_isOnline) {
      try {
        final data = await _mysql.getEnvironmentData();

        // Cache to SQLite for offline use
        if (data['air_temp']! > 0) {
          await _sqlite.insertSensorLog(
            plotId: 1,
            airTemp: data['air_temp']!,
            humidity: data['humidity']!,
            lightLux: data['lux']!,
            leafTemp: data['leaf_temp']!, // Use actual leaf_temp
            waterLevel: 2.0,
            cwsiValue: 0.0,
          );
        }

        return data;
      } catch (e) {
        print('MySQL fetch failed, using local data: $e');
        return await _sqlite.getLatestEnvironmentData();
      }
    } else {
      return await _sqlite.getLatestEnvironmentData();
    }
  }

  /// 🔒 Get the latest sensor logs for each plot
  /// Returns Map<plot_id, SensorLog> with per-plot sensor data
  Future<Map<int, SensorLog>> getLatestLogsPerPlot() async {
    if (_isOnline) {
      try {
        final logs = await _mysql.getLatestLogsPerPlot();
        print(
            '[HybridDB] Fetched ${logs.length} latest sensor logs from MySQL');
        return logs;
      } catch (e) {
        print('[HybridDB] MySQL fetch failed, using local data: $e');
        // Fallback to SQLite if MySQL fails
        return {}; // SQLite doesn't have this method yet, return empty
      }
    } else {
      print('[HybridDB] Offline - cannot fetch latest sensor logs per plot');
      return {}; // Return empty map when offline
    }
  }

  // ==================== DEVICES ====================

  Future<Map<String, dynamic>> getDeviceStatus(String deviceName) async {
    if (_isOnline) {
      try {
        return await _mysql.getDeviceStatus(deviceName);
      } catch (e) {
        print('MySQL fetch failed, using local data: $e');
        return await _sqlite.getDeviceStatus(deviceName);
      }
    } else {
      return await _sqlite.getDeviceStatus(deviceName);
    }
  }

  Future<void> updateDeviceStatus(String deviceName, bool status) async {
    // Always update SQLite first
    await _sqlite.updateDeviceStatus(deviceName, status);

    // Try to update MySQL if online
    if (_isOnline) {
      try {
        await _mysql.updateDeviceStatus(deviceName, status);
        print('Device status updated in both SQLite and MySQL');
      } catch (e) {
        print('MySQL update failed, will sync later: $e');
      }
    }
  }

  // ==================== STATUS ====================

  bool get isOnline => _isOnline;

  String get connectionStatus =>
      _isOnline ? 'Online (MySQL)' : 'Offline (SQLite)';

  // ==================== CLEANUP ====================

  void dispose() {
    _syncTimer?.cancel();
  }
}
