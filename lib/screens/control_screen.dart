import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/theme_toggle.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      deviceProvider.refreshStatus();
    });
    
    // Auto-refresh device status every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        deviceProvider.refreshStatus();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      body: Container(
        color: colors.background,
        child: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Header Image
                      Image.asset(
                        'assets/tree1.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                      // Gradient Overlay
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
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F2937).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.settings,
                                          size: 16, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 8),
                                      Text(
                                        'SYSTEM CONTROL',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const ThemeToggle(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Control',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'DEVICE MANAGEMENT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Connection Status Warning
                        if (!deviceProvider.isDeviceOnline)
                          _buildConnectionWarning(colors, deviceProvider),

                        // Light Control Section
                        _buildSectionHeader(
                          icon: Icons.lightbulb,
                          title: 'ควบคุมระบบไฟ',
                          subtitle: 'จัดการเปิด-ปิดไฟแสงสว่างในแปลงทดลอง',
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                        // Only White Light (no purple light)
                        _buildLightCard(
                          'ไฟแสงสีขาว (Grow Light)',
                          deviceProvider.light1,
                          const Color(0xFFF59E0B), // สีส้ม/เหลือง
                          deviceProvider.canControlManually,
                              (value) => deviceProvider.toggleLight1(value),
                          colors,
                        ),
                        const SizedBox(height: 16),

                        // Humidity System Section
                        _buildSectionHeader(
                          icon: Icons.water_drop,
                          title: 'ระบบความชื้น',
                          subtitle: 'ตรวจสอบความชื้นและควบคุมการเปิดสปริงเกอร์น้ำ',
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildHumidityCard(deviceProvider, colors),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFanControlCard(
                                deviceProvider.humiditySystem,
                                deviceProvider.canControlManually,
                                    (value) => deviceProvider.toggleHumiditySystem(value),
                                colors,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Master Switch Section
                        _buildSectionHeader(
                          icon: Icons.power_settings_new,
                          title: 'สวิตช์หลัก',
                          subtitle: 'ควบคุมการเปิด-ปิดระบบทั้งหมดของฟาร์มในปุ่มเดียว',
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                        _buildMasterSwitchCard(deviceProvider, colors),
                        const SizedBox(height: 100),
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

  Widget _buildConnectionWarning(AppColors colors, DeviceProvider deviceProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: colors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'อุปกรณ์ออฟไลน์',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.error,
                  ),
                ),
                Text(
                  'ไม่สามารถควบคุมอุปกรณ์ได้ กรุณาตรวจสอบการเชื่อมต่อ',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colors.primary),
            onPressed: () => deviceProvider.refreshStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.text,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLightCard(
      String title,
      bool isActive,
      Color lightColor,
      bool enabled,
      Function(bool) onToggle,
      AppColors colors,
      ) {
    final bool isWhite = lightColor == const Color(0xFFF59E0B); // สีส้ม/เหลือง
    final bool isPurple = lightColor == const Color(0xFFA855F7); // สีม่วง

    // สี gradient เมื่อ ON ตามภาพ - สีอ่อนสวยงาม
    final List<Color> activeGradient = isWhite
        ? (colors.isDark
        ? [const Color(0xFF78350F), const Color(0xFF451A03)]
        : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]) // สีเหลืองอ่อน
        : (colors.isDark
        ? [const Color(0xFF581C87), const Color(0xFF3B0764)]
        : [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)]); // สีม่วงอ่อน

    final List<Color> inactiveGradient = colors.isDark
        ? [const Color(0xFF1F2937), const Color(0xFF111827)]
        : [Colors.white, const Color(0xFFF9FAFB)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive ? activeGradient : inactiveGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? (isWhite ? const Color(0xFFF59E0B).withOpacity(0.3) : const Color(0xFFA855F7).withOpacity(0.3))
              : (colors.isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? (isWhite ? Colors.orange.withOpacity(0.25) : Colors.purple.withOpacity(0.25))
                : Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: isActive ? 15 : 5,
            spreadRadius: isActive ? 1 : 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? (isWhite
                    ? (colors.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
                    : (colors.isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8)))
                    : colors.textLight,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Large Icon - Center aligned
          Center(
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: isActive
                    ? (colors.isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.85))
                    : (colors.isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFE5E7EB)),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: lightColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ]
                    : [],
              ),
              child: Icon(
                isActive
                    ? Icons.lightbulb
                    : Icons.lightbulb_outline,
                size: isActive ? 50 : 44,
                color: isActive
                    ? (isWhite
                    ? (colors.isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B))
                    : (colors.isDark ? const Color(0xFFD8B4FE) : const Color(0xFFA855F7)))
                    : colors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ON/OFF Buttons - Full width
          _buildToggleButtons(isActive, enabled, onToggle, lightColor, isWhite, colors),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(
      bool isActive,
      bool enabled,
      Function(bool) onToggle,
      Color lightColor,
      bool isWhite,
      AppColors colors,
      ) {
    final Color activeButtonColor = isWhite
        ? const Color(0xFFF59E0B)
        : const Color(0xFFA855F7);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onToggle(true) : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isActive && enabled
                      ? activeButtonColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive && enabled
                      ? [
                    BoxShadow(
                      color: activeButtonColor.withOpacity(0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'ON',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive && enabled
                          ? Colors.white
                          : (enabled
                          ? (colors.isDark ? Colors.white60 : const Color(0xFF9CA3AF))
                          : colors.textLight.withOpacity(0.4)),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onToggle(false) : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: !isActive && enabled
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isActive && enabled
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'OFF',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: !isActive && enabled
                          ? (colors.isDark ? Colors.black87 : const Color(0xFF374151))
                          : (enabled
                          ? (colors.isDark ? Colors.white60 : const Color(0xFF9CA3AF))
                          : colors.textLight.withOpacity(0.4)),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard(DeviceProvider deviceProvider, AppColors colors) {
    final humidityValue = double.tryParse(deviceProvider.currentHumidity) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)], // ฟ้าอ่อนไล่สี
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          const Text(
            'ความชื้นปัจจุบัน',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A), // สีน้ำเงินเข้ม
            ),
          ),
          const SizedBox(height: 12),

          // ส่วนแสดงไอคอนและตัวเลข (จุดที่แก้ Overflow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop,
                  size: 28,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),

              // --- 📌 จุดที่แก้ไข (ใช้ Expanded + FittedBox) ---
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown, // ย่อขนาดตัวอักษรลงถ้ายาวเกิน
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${humidityValue.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A), // สีตัวเลขน้ำเงินเข้มตามรูป
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              // ---------------------------------------------
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar ด้านล่าง
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (humidityValue / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanControlCard(
      bool isActive,
      bool enabled,
      Function(bool) onToggle,
      AppColors colors,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? (colors.isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)])
              : (colors.isDark
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFF9FAFB)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? (colors.isDark ? Colors.white10 : const Color(0xFFD1FAE5))
              : (colors.isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? Colors.green.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: isActive ? 10 : 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ระบบความชื้น',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? (colors.isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857))
                      : colors.textLight,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? (colors.isDark
                      ? Colors.white.withOpacity(0.15)
                      : const Color(0xFFD1FAE5))
                      : (colors.isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.air_rounded,
                  size: 20,
                  color: isActive
                      ? (colors.isDark ? const Color(0xFF6EE7B7) : colors.primary)
                      : colors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToggleButtons(isActive, enabled, onToggle, colors.primary, true, colors),
        ],
      ),
    );
  }

  Widget _buildMasterSwitchCard(DeviceProvider deviceProvider, AppColors colors) {
    final isOn = deviceProvider.masterSwitch;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOn
              ? (colors.isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)])
              : (colors.isDark
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOn
              ? (colors.isDark ? Colors.white10 : const Color(0xFFD1FAE5))
              : (colors.isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: isOn
                ? colors.primary.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: isOn ? 12 : 6,
            spreadRadius: isOn ? 1 : 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOn
                  ? (colors.isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white)
                  : (colors.isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isOn
                  ? [
                BoxShadow(
                  color: colors.primary.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ]
                  : [],
            ),
            child: Icon(
              Icons.flash_on,
              size: 26,
              color: isOn
                  ? colors.primary
                  : (colors.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ควบคุมทั้งหมด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isOn
                        ? (colors.isDark ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B))
                        : (colors.isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOn ? 'ระบบกำลังทำงาน' : 'ปิดการทำงานทั้งหมด',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOn
                        ? (colors.isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                        : (colors.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.25,
            child: Switch(
              value: isOn,
              onChanged: deviceProvider.canControlManually
                  ? (value) => deviceProvider.toggleMasterSwitch(value)
                  : null,
              activeColor: Colors.white,
              activeTrackColor: colors.primary,
              inactiveThumbColor: const Color(0xFFF4F3F4),
              inactiveTrackColor:
              colors.isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }
}
