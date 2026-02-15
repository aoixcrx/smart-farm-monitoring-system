import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DeviceProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Device names matching database
  static const String GROW_LIGHT = 'Grow Light';
  static const String WATER_PUMP = 'Water Pump';

  bool _light1 = false;
  bool _light2 = false;
  bool _humiditySystem = false;
  bool _masterSwitch = false;
  bool _isDeviceOnline = true;
  bool _isAutoMode = false;
  String _currentHumidity = '80';
  bool _isLoading = false;

  bool get light1 => _light1;
  bool get light2 => _light2;
  bool get humiditySystem => _humiditySystem;
  bool get masterSwitch => _masterSwitch;
  bool get isDeviceOnline => _isDeviceOnline;
  bool get isAutoMode => _isAutoMode;
  String get currentHumidity => _currentHumidity;
  bool get isLoading => _isLoading;

  // Check if manual control is allowed (not in auto mode and device is online)
  bool get canControlManually => !_isAutoMode && _isDeviceOnline;

  DeviceProvider() {
    _checkDeviceStatus();
    _fetchHumidity();
  }

  Future<void> _checkDeviceStatus() async {
    try {
      final lightStatus = await _dbService.getDeviceStatus(GROW_LIGHT);
      _isDeviceOnline = lightStatus['online'] ?? true;
      _isAutoMode = lightStatus['auto_mode'] ?? false;
      _light1 = lightStatus['status'] ?? false;

      final pumpStatus = await _dbService.getDeviceStatus(WATER_PUMP);
      _humiditySystem = pumpStatus['status'] ?? false;

      notifyListeners();
    } catch (e) {
      print('Error checking device status: $e');
      _isDeviceOnline = true; // Assume online for demo
      notifyListeners();
    }
  }

  Future<void> _fetchHumidity() async {
    try {
      final humidity = await _dbService.getLatestSensorValue('humidity');
      _currentHumidity = humidity.toStringAsFixed(1);
      notifyListeners();
    } catch (e) {
      _currentHumidity = '52.5'; // Mock value
    }
  }

  Future<bool> toggleLight1(bool value) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.updateDeviceStatus(GROW_LIGHT, value);
      _light1 = value;
      _isLoading = false;
      notifyListeners();
      print('[OK] Grow Light toggled to: ${value ? "ON" : "OFF"}');
      return true;
    } catch (e) {
      print('[ERROR] Error toggling Grow Light: $e');
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleLight2(bool value) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.updateDeviceStatus('light2', value);
      _light2 = value;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleHumiditySystem(bool value) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.updateDeviceStatus(WATER_PUMP, value);
      _humiditySystem = value;
      _isLoading = false;
      notifyListeners();
      print('[OK] Water Pump toggled to: ${value ? "ON" : "OFF"}');
      return true;
    } catch (e) {
      print('[ERROR] Error toggling Water Pump: $e');
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleMasterSwitch(bool value) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Update all devices at once
      await _dbService.updateDeviceStatus(GROW_LIGHT, value);
      await _dbService.updateDeviceStatus(WATER_PUMP, value);

      _masterSwitch = value;
      _light1 = value;
      _light2 = value;
      _humiditySystem = value;
      _isLoading = false;
      notifyListeners();
      print('[OK] Master Switch toggled to: ${value ? "ON" : "OFF"}');
      return true;
    } catch (e) {
      print('[ERROR] Error toggling Master Switch: $e');
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> refreshStatus() async {
    await _checkDeviceStatus();
    await _fetchHumidity();
  }
}
