import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? user;
  final String? accessToken;
  final String? refreshToken;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
  });
}

/// Service for handling JWT authentication
class AuthService {
  // ==================== CONFIGURATION ====================
  // 🔧 สำหรับมือถือจริง: เปลี่ยน IP เป็น IP ของคอมพิวเตอร์
  // หา IP ได้จาก: ipconfig (Windows) หรือ ifconfig (Mac/Linux)
  // ตัวอย่าง: '192.168.1.50'
  static const String _physicalDeviceIP = '192.168.1.50'; // ← แก้ตรงนี้!

  // Request timeout (ป้องกันหมุนไม่หยุด)
  static const Duration _requestTimeout = Duration(seconds: 10);

  // API base URL - different for web vs mobile vs physical device
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // สำหรับ Android Emulator ใช้ 10.0.2.2
    // สำหรับมือถือจริง ให้แก้ _physicalDeviceIP ด้านบน
    // หรือ uncomment บรรทัดด้านล่าง:
    // return 'http://$_physicalDeviceIP:5000/api';
    return 'http://10.0.2.2:5000/api';
  }

  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Cached user data
  Map<String, dynamic>? _currentUser;

  /// Get current user from token or cache
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  // ==================== TOKEN STORAGE ====================

  /// Save tokens to SharedPreferences
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Get access token from storage
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get refresh token from storage
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save user data to storage
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    _currentUser = user;
  }

  /// Clear all auth data
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  // ==================== TOKEN VALIDATION ====================

  /// Check if access token is expired
  Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  /// Get token expiration time
  Future<DateTime?> getTokenExpiration() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      return null;
    }
  }

  // ==================== AUTH API CALLS ====================

  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Extract data from response
        final responseData = data;

        // Save tokens
        final accessToken = responseData['access_token'] ?? '';
        final refreshToken = responseData['refresh_token'] ?? '';
        await saveTokens(accessToken, refreshToken);

        // Create user object from response data
        final userObj = responseData['user'] ?? {};
        final user = {
          'user_id': userObj['user_id'] ?? '',
          'username': userObj['username'] ?? '',
          'email': userObj.containsKey('email') ? userObj['email'] ?? '' : '',
        };
        await saveUser(user);

        return AuthResult(
          success: true,
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Register new user
  Future<AuthResult> register(
    String username,
    String password, {
    String? userType,
    String? email,
  }) async {
    try {
      final requestBody = {
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Extract data from response
        final responseData = data;

        // Save tokens
        final accessToken = responseData['access_token'] ?? '';
        final refreshToken = responseData['refresh_token'] ?? '';
        await saveTokens(accessToken, refreshToken);

        // Create user object
        final userObj = responseData['user'] ?? {};
        final user = {
          'user_id': userObj['user_id'] ?? '',
          'username': userObj['username'] ?? '',
          'email': userObj.containsKey('email') ? userObj['email'] ?? '' : '',
        };
        await saveUser(user);

        return AuthResult(
          success: true,
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
          message: data['message'],
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update access token only
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, data['access_token']);
        return true;
      } else {
        // Refresh token expired, clear everything
        await clearTokens();
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  /// Logout and clear all tokens
  Future<void> logout() async {
    await clearTokens();
  }

  /// Check if username exists
  Future<bool> checkUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/check?username=$username'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_requestTimeout);

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data']['exists'] == true;
      }
      return false;
    } catch (e) {
      print('Check username error: $e');
      return false; // Assume available on error
    }
  }

  // ==================== AUTHENTICATED REQUESTS ====================

  /// Make authenticated HTTP GET request
  Future<http.Response> authenticatedGet(String endpoint) async {
    // Check and refresh token if needed
    if (await isTokenExpired()) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw Exception('Session expired. Please login again.');
      }
    }

    final token = await getAccessToken();
    return await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Make authenticated HTTP POST request
  Future<http.Response> authenticatedPost(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // Check and refresh token if needed
    if (await isTokenExpired()) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw Exception('Session expired. Please login again.');
      }
    }

    final token = await getAccessToken();
    return await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Make authenticated HTTP PUT request
  Future<http.Response> authenticatedPut(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (await isTokenExpired()) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw Exception('Session expired. Please login again.');
      }
    }

    final token = await getAccessToken();
    return await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Make authenticated HTTP DELETE request
  Future<http.Response> authenticatedDelete(String endpoint) async {
    if (await isTokenExpired()) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw Exception('Session expired. Please login again.');
      }
    }

    final token = await getAccessToken();
    return await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // ==================== INITIALIZATION ====================

  /// Initialize auth service - call on app start
  Future<bool> initialize() async {
    try {
      // Load saved user data
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _currentUser = jsonDecode(userJson);
      }

      // Check if we have valid tokens
      final token = await getAccessToken();
      if (token == null) return false;

      // Check if token is expired
      if (await isTokenExpired()) {
        // Try to refresh
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          await clearTokens();
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Auth initialization error: $e');
      return false;
    }
  }
}
