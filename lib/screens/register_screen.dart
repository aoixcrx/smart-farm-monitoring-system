import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/shimmer_text.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _selectedUserType = '';

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(level: 0, text: '', color: Colors.grey);
    }

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกประเภทผู้ใช้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      _confirmPasswordController.text.trim(),
      _selectedUserType,
    );

    if (mounted) {
      if (success) {
        // Show success dialog
        _showSuccessDialog();

        // Navigate to main screen after delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.go('/main');
          }
        });
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'ลงทะเบียนไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D5016).withOpacity(0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'สำเร็จ!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ลงทะเบียนเรียบร้อยแล้ว',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final passwordStrength =
        _calculatePasswordStrength(_passwordController.text);
    final passwordMatch =
        _passwordController.text == _confirmPasswordController.text &&
            _confirmPasswordController.text.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/tree1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () => context.go('/welcome'),
                      ),
                      const SizedBox(height: 20),
                      // Header
                      const Text(
                        'Andrographis',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Smart farm',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 3.84,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Username Field
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'Username',
                                floatingLabelStyle:
                                    const TextStyle(color: Color(0xFF2D5016)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2D5016), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณากรอกชื่อผู้ใช้';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Password',
                                floatingLabelStyle:
                                    const TextStyle(color: Color(0xFF2D5016)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2D5016), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณากรอกรหัสผ่าน';
                                }
                                return null;
                              },
                            ),
                            // Password Strength Indicator
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: passwordStrength.level / 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: passwordStrength.color,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    passwordStrength.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: passwordStrength.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 15),
                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_showConfirmPassword,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Confirm Password',
                                floatingLabelStyle:
                                    const TextStyle(color: Color(0xFF2D5016)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: !passwordMatch &&
                                            _confirmPasswordController
                                                .text.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: !passwordMatch &&
                                            _confirmPasswordController
                                                .text.isNotEmpty
                                        ? Colors.red
                                        : const Color(0xFF2D5016),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showConfirmPassword =
                                          !_showConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณายืนยันรหัสผ่าน';
                                }
                                if (value != _passwordController.text) {
                                  return 'รหัสผ่านไม่ตรงกัน';
                                }
                                return null;
                              },
                            ),
                            // Password Match Error
                            if (!passwordMatch &&
                                _confirmPasswordController.text.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              const Text(
                                'รหัสผ่านไม่ตรงกัน',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 15),
                            // User Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedUserType.isEmpty
                                  ? null
                                  : _selectedUserType,
                              decoration: InputDecoration(
                                labelText: 'User Type',
                                floatingLabelStyle:
                                    const TextStyle(color: Color(0xFF2D5016)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2D5016), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'farmer',
                                  child: Text('เกษตรกร (Farmer)'),
                                ),
                                DropdownMenuItem(
                                  value: 'researcher',
                                  child: Text('นักวิจัย (Researcher)'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('อื่นๆ (Other)'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedUserType = value ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณาเลือกประเภทผู้ใช้';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D5016),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 5,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'REGISTER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Footer
                      Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.facebook,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 5),
                              Text(
                                ': Andrographis Smart farm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: const [
                              Icon(Icons.phone, color: Colors.white, size: 16),
                              SizedBox(width: 5),
                              Text(
                                ': 093-5899990',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
