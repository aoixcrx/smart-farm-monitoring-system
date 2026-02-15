import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Model class for sensor data
class SensorData {
  final int? dataId;
  final int deviceId;
  final double temperatureAir;
  final double temperatureLeaf;
  final double humidity;
  final double waterLevel;
  final double lightLux;
  final double soilMoisture;
  final DateTime? createdAt;

  SensorData({
    this.dataId,
    this.deviceId = 1,
    this.temperatureAir = 0,
    this.temperatureLeaf = 0,
    this.humidity = 0,
    this.waterLevel = 0,
    this.lightLux = 0,
    this.soilMoisture = 0,
    this.createdAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      dataId: json['data_id'],
      deviceId: json['device_id'] ?? 1,
      temperatureAir: _parseDouble(json['temperature_air']),
      temperatureLeaf: _parseDouble(json['temperature_leaf']),
      humidity: _parseDouble(json['humidity']),
      waterLevel: _parseDouble(json['water_level']),
      lightLux: _parseDouble(json['light_lux']),
      soilMoisture: _parseDouble(json['soil_moisture']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'temperature_air': temperatureAir,
    'temperature_leaf': temperatureLeaf,
    'humidity': humidity,
    'water_level': waterLevel,
    'light_lux': lightLux,
    'soil_moisture': soilMoisture,
  };
}

/// Service for sensor data with realtime polling
class SensorService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  Timer? _pollingTimer;
  SensorData? _latestData;
  List<SensorData> _history = [];
  bool _isLoading = false;
  String? _error;
  int _deviceId = 1;

  // Getters
  SensorData? get latestData => _latestData;
  List<SensorData> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get deviceId => _deviceId;

  /// Set current device ID
  void setDeviceId(int id) {
    _deviceId = id;
    fetchLatest();
  }

  /// Start realtime polling (every N seconds)
  void startPolling({int intervalSeconds = 5}) {
    stopPolling();
    fetchLatest(); // Fetch immediately
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => fetchLatest(),
    );
  }

  /// Stop realtime polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch latest sensor data
  Future<SensorData?> fetchLatest() async {
    try {
      _error = null;
      final response = await _authService.authenticatedGet(
        '/sensor/latest?device_id=$_deviceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _latestData = SensorData.fromJson(data);
        notifyListeners();
        return _latestData;
      } else {
        _error = 'Failed to fetch sensor data';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Fetch sensor history for graphs
  Future<List<SensorData>> fetchHistory({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.authenticatedGet(
        '/sensor/history?device_id=$_deviceId&limit=$limit',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _history = data.map((json) => SensorData.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
        return _history;
      } else {
        _error = 'Failed to fetch sensor history';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Update sensor data record
  Future<bool> updateSensorData(int dataId, SensorData data) async {
    try {
      final response = await _authService.authenticatedPut(
        '/sensor/$dataId',
        body: data.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Delete old sensor data
  Future<int> cleanupOldData({int days = 30}) async {
    try {
      final response = await _authService.authenticatedDelete(
        '/sensor/cleanup?days=$days',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['deleted_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      _error = e.toString();
      return 0;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
