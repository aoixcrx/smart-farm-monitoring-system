import 'package:shared_preferences/shared_preferences.dart';

class CredentialsService {
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';

  /// Save credentials locally when Remember Me is checked
  static Future<bool> saveCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
      await prefs.setBool(_rememberMeKey, true);
      print('[CredentialsService] [OK] Credentials saved successfully');
      return true;
    } catch (e) {
      print('[CredentialsService] ❌ Error saving credentials: $e');
      return false;
    }
  }

  /// Load saved credentials from local storage
  static Future<Map<String, String>?> loadCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (!rememberMe) {
        print('[CredentialsService] Remember Me is not enabled');
        return null;
      }

      final username = prefs.getString(_usernameKey);
      final password = prefs.getString(_passwordKey);

      if (username != null && password != null) {
        print('[CredentialsService] [OK] Credentials loaded successfully');
        return {
          'username': username,
          'password': password,
        };
      }

      print('[CredentialsService] No saved credentials found');
      return null;
    } catch (e) {
      print('[CredentialsService] [ERROR] Error loading credentials: $e');
      return null;
    }
  }

  /// Check if Remember Me was previously enabled
  static Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print(
          '[CredentialsService] [ERROR] Error checking Remember Me status: $e');
      return false;
    }
  }

  /// Clear saved credentials (logout)
  static Future<bool> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
      await prefs.remove(_rememberMeKey);
      print('[CredentialsService] [OK] Credentials cleared successfully');
      return true;
    } catch (e) {
      print('[CredentialsService] [ERROR] Error clearing credentials: $e');
      return false;
    }
  }
}
