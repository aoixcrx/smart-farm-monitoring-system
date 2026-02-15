import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.currentUser != null;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get currentUser => _authService.currentUser;

  /// Initialize auth state on app start
  Future<bool> initialize() async {
    if (_isInitialized) return isAuthenticated;

    try {
      final hasValidSession = await _authService.initialize();
      _isInitialized = true;
      notifyListeners();
      return hasValidSession;
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate format if username looks like email
      if (username.contains('@')) {
        if (!_isValidEmail(username)) {
          _errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
          return false;
        }
      }

      // Login via AuthService
      final result = await _authService.login(username, password);

      if (result.success) {
        return true;
      } else {
        _errorMessage = result.message ?? 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}';
      return false;
    } finally {
      // สำคัญ! ปิดตัวหมุนไม่ว่าจะสำเร็จหรือพัง
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password,
      String confirmPassword, String userType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate all fields are filled
      if (username.trim().isEmpty ||
          password.trim().isEmpty ||
          confirmPassword.trim().isEmpty ||
          userType.isEmpty) {
        _errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
        return false;
      }

      // Validate password match
      if (password != confirmPassword) {
        _errorMessage = 'รหัสผ่านไม่ตรงกัน';
        return false;
      }

      // Validate password strength
      final strength = _validatePasswordStrength(password);
      if (strength.level < 2) {
        _errorMessage =
            'รหัสผ่านอ่อนเกินไป กรุณาใช้รหัสผ่านที่มีตัวเลขผสมตัวอักษร';
        return false;
      }

      // Check if user already exists
      if (await _authService.checkUsername(username)) {
        _errorMessage = 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';
        return false;
      }

      // Register via AuthService (userType passed but not sent to API)
      final result = await _authService.register(
        username,
        password,
        userType: userType,
      );

      if (result.success) {
        return true;
      } else {
        _errorMessage =
            result.message ?? 'ไม่สามารถลงทะเบียนได้ กรุณาลองใหม่อีกครั้ง';
        return false;
      }
    } catch (e) {
      print('Registration error: $e');
      _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}';
      return false;
    } finally {
      // สำคัญ! ปิดตัวหมุนไม่ว่าจะสำเร็จหรือพัง
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  /// Get AuthService for authenticated requests
  AuthService get authService => _authService;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  PasswordStrength _validatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;

    if (strength <= 1) {
      return PasswordStrength(
          level: 1, text: 'อ่อน', color: const Color(0xFFFF5252));
    } else if (strength <= 2) {
      return PasswordStrength(
          level: 2, text: 'ปานกลาง', color: const Color(0xFFFFB74D));
    } else if (strength <= 3) {
      return PasswordStrength(
          level: 3, text: 'ดี', color: const Color(0xFF81C784));
    } else {
      return PasswordStrength(
          level: 4, text: 'แข็งแรง', color: const Color(0xFF2D5016));
    }
  }
}

class PasswordStrength {
  final int level;
  final String text;
  final Color color;

  PasswordStrength({
    required this.level,
    required this.text,
    required this.color,
  });
}
