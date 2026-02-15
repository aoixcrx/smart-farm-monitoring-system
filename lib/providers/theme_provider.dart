import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  AppColors get colors => _isDark ? darkColors : lightColors;
  
  bool get isDarkMode => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: lightColors.primary,
        scaffoldBackgroundColor: lightColors.background,
        colorScheme: ColorScheme.light(
          primary: lightColors.primary,
          secondary: lightColors.secondary,
          error: lightColors.error,
          surface: lightColors.cardBg,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: lightColors.primary,
          selectionColor: lightColors.primary.withOpacity(0.3),
          selectionHandleColor: lightColors.primary,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: darkColors.primary,
        scaffoldBackgroundColor: darkColors.background,
        colorScheme: ColorScheme.dark(
          primary: darkColors.primary,
          secondary: darkColors.secondary,
          error: darkColors.error,
          surface: darkColors.cardBg,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: darkColors.primary,
          selectionColor: darkColors.primary.withOpacity(0.3),
          selectionHandleColor: darkColors.primary,
        ),
      );
}

class AppColors {
  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color cardBg;
  final Color text;
  final Color textLight;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color tabBarBg;
  final Color tabBarActive;
  final Color tabBarInactive;
  final List<Color> headerGradient;
  final List<Color> cardGradientPrimary;
  final List<Color> cardGradientYellow;
  final List<Color> cardGradientBlue;
  final List<Color> cardGradientOrange;

  AppColors({
    required this.isDark,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.cardBg,
    required this.text,
    required this.textLight,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.tabBarBg,
    required this.tabBarActive,
    required this.tabBarInactive,
    required this.headerGradient,
    required this.cardGradientPrimary,
    required this.cardGradientYellow,
    required this.cardGradientBlue,
    required this.cardGradientOrange,
  });
}

final AppColors lightColors = AppColors(
  isDark: false,
  primary: const Color(0xFF2D5016),
  primaryDark: const Color(0xFF064E3B),
  secondary: const Color(0xFF059669),
  accent: const Color(0xFFF59E0B),
  background: const Color(0xFFF0FDF4),
  cardBg: Colors.white,
  text: const Color(0xFF1F2937),
  textLight: const Color(0xFF6B7280),
  border: const Color(0xFFE5E7EB),
  success: const Color(0xFF2D5016),
  warning: const Color(0xFFF59E0B),
  error: const Color(0xFFEF4444),
  info: const Color(0xFF3B82F6),
  tabBarBg: const Color(0xFF2D5016), // Solid Green from Login
  tabBarActive: Colors.white,
  tabBarInactive: const Color(0xB3FFFFFF), // ~70% opacity white
  headerGradient: const [
    Color(0xE6000000), // Dark Black (90%)
    Color(0x80000000), // Medium Black
    Colors.transparent, // Transparent for image visibility
  ],
  cardGradientPrimary: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
  cardGradientYellow: const [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
  cardGradientBlue: const [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
  cardGradientOrange: const [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
);

final AppColors darkColors = AppColors(
  isDark: true,
  primary: const Color(0xFF4ADE80),
  primaryDark: const Color(0xFF065F46),
  secondary: const Color(0xFF2D5016),
  accent: const Color(0xFFFBBF24),
  background: const Color(0xFF111827),
  cardBg: const Color(0xFF1F2937),
  text: const Color(0xFFF9FAFB),
  textLight: const Color(0xFF9CA3AF),
  border: const Color(0xFF374151),
  success: const Color(0xFF4ADE80),
  warning: const Color(0xFFFBBF24),
  error: const Color(0xFFF87171),
  info: const Color(0xFF60A5FA),
  tabBarBg: const Color(0xF2111827),
  tabBarActive: const Color(0xFF2D5016),
  tabBarInactive: const Color(0xFF9CA3AF),
  headerGradient: const [
    Color(0xF2111827),
    Color(0xCC111827),
    Colors.transparent,
  ],
  cardGradientPrimary: const [Color(0xFF065F46), Color(0xFF064E3B)],
  cardGradientYellow: const [Color(0xFF78350F), Color(0xFF451A03)],
  cardGradientBlue: const [Color(0xFF1E3A8A), Color(0xFF172554)],
  cardGradientOrange: const [Color(0xFF7C2D12), Color(0xFF431407)],
);
