import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';
import '../services/export_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'notification_screen.dart';
import 'data_log_screen.dart';
import 'about_screen.dart';
import 'admin_panel_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  String _username = 'Smart Farmer';
  String _userType = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _username = user['username'] ?? 'Smart Farmer';
        _userType = user['user_type'] ?? 'user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDark = themeProvider.isDarkMode;
    final exportService = ExportService();

    return Scaffold(
      body: Container(
        color: colors.background,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 400,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/tree1.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: colors.headerGradient,
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        children: [
                          const Align(
                              alignment: Alignment.centerRight,
                              child: ThemeToggle()),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen())),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5))
                                      ]),
                                  child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: _userType == 'admin'
                                          ? const Color(0xFF6366F1)
                                          : Colors.white24,
                                      child: Icon(
                                          _userType == 'admin'
                                              ? Icons.admin_panel_settings
                                              : Icons.person,
                                          size: 50,
                                          color: Colors.white)),
                                ),
                                Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            color: colors.primary,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.edit,
                                            size: 12, color: Colors.white))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(_username,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _userType == 'admin'
                                  ? const Color(0xFF6366F1)
                                  : colors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _userType == 'admin'
                                  ? '👑 Administrator'
                                  : '🌱 Farmer',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem('15', 'วัน'),
                                _buildDivider(),
                                _buildStatItem('2', 'แปลง'),
                                _buildDivider(),
                                _buildStatItem('98%', 'สุขภาพ'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('บัญชีของฉัน', colors),
                      _buildMenuTile(
                        icon: Icons.person_outline,
                        title: 'โปรไฟล์',
                        subtitle: 'จัดการข้อมูลส่วนตัว',
                        color: colors.primary,
                        colors: colors,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen())),
                      ),
                      _buildMenuTile(
                        icon: Icons.notifications_outlined,
                        title: 'การแจ้งเตือน',
                        subtitle: 'ดูประวัติการแจ้งเตือน',
                        color: const Color(0xFFF59E0B),
                        colors: colors,
                        isDark: isDark,
                        trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('3',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationScreen())),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('ข้อมูลและสถิติ', colors),
                      _buildMenuTile(
                        icon: Icons.description_outlined,
                        title: 'ดูข้อมูล',
                        subtitle: 'ตารางบันทึกข้อมูลย้อนหลัง',
                        color: const Color(0xFF059669),
                        colors: colors,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DataLogScreen())),
                      ),
                      _buildMenuTile(
                        icon: Icons.download_outlined,
                        title: 'ดาวน์โหลดข้อมูล',
                        subtitle: 'บันทึกข้อมูลลงเครื่อง (Excel)',
                        color: const Color(0xFFEAB308),
                        colors: colors,
                        isDark: isDark,
                        onTap: () async {
                          // Existing Export Logic
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white)));
                          try {
                            await exportService.exportSensorData();
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('ช่วยเหลือ', colors),
                      _buildMenuTile(
                        icon: Icons.info_outline,
                        title: 'เกี่ยวกับ',
                        subtitle: 'ข้อมูลแอปและผู้พัฒนา',
                        color: const Color(0xFF059669),
                        colors: colors,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen())),
                      ),
                      _buildSectionHeader('ผู้ดูแลระบบ', colors),
                      _buildMenuTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'จัดการฐานข้อมูล',
                        subtitle: 'จัดการผู้ใช้, อุปกรณ์, และ Logs',
                        color: const Color(0xFF6366F1),
                        colors: colors,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen())),
                      ),
                      const SizedBox(height: 32),
                      InkWell(
                        onTap: () => _showLogoutDialog(context, colors),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withOpacity(0.3))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.logout, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('ออกจากระบบ',
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))
                              ]),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))
    ]);
  }

  Widget _buildDivider() =>
      Container(height: 30, width: 1, color: Colors.white.withOpacity(0.2));

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(children: [
          Icon(Icons.auto_awesome, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.text))
        ]));
  }

  Widget _buildMenuTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required AppColors colors,
      required bool isDark,
      Widget? trailing,
      VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: colors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                ])),
            if (trailing != null)
              trailing
            else
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right,
                      size: 20, color: colors.textLight)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppColors colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colors.cardBg,
        title: Text('ออกจากระบบ', style: TextStyle(color: colors.text)),
        content: Text('คุณต้องการออกจากระบบใช่หรือไม่?',
            style: TextStyle(color: colors.textLight)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก', style: TextStyle(color: colors.textLight))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await _authService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
