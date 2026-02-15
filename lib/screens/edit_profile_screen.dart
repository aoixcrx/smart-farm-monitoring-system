import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  // API base URL
  static const String _apiBaseUrl = 'http://localhost:5000/api';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text =
          user['display_name'] ?? user['username'] ?? 'Smart Farmer';
      _emailController.text = user['email'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user logged in');

      final username = user['username'] ?? '';
      final displayName = _nameController.text.trim();
      final email = _emailController.text.trim();

      bool savedToServer = false;

      // 1. Try to save to MySQL via API
      try {
        final response = await http
            .put(
              Uri.parse('$_apiBaseUrl/user/profile'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'username': username,
                'display_name': displayName,
                'email': email,
              }),
            )
            .timeout(const Duration(seconds: 5));

        savedToServer = response.statusCode == 200;
      } catch (e) {
        print('API save failed (offline mode): $e');
        // Continue to save locally
      }

      // 2. Always update local cache
      _authService.currentUser!['display_name'] = displayName;
      _authService.currentUser!['email'] = email;
      await _authService.saveUser(_authService.currentUser!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savedToServer
                ? '[OK] บันทึกโปรไฟล์สำเร็จ (บันทึกลง Server แล้ว)'
                : '[OK] บันทึกโปรไฟล์สำเร็จ (บันทึกในเครื่อง)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('[ERROR] Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('แก้ไขโปรไฟล์', style: TextStyle(color: colors.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colors.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 60, color: colors.primary),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: colors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ',
                labelStyle: TextStyle(color: colors.textLight),
                filled: true,
                fillColor: colors.cardBg,
                prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
              style: TextStyle(color: colors.text),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'อีเมล',
                labelStyle: TextStyle(color: colors.textLight),
                filled: true,
                fillColor: colors.cardBg,
                prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
              style: TextStyle(color: colors.text),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: colors.primary.withOpacity(0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('บันทึก',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
