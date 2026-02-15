import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = theme.colors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(
            icon: Icons.wb_sunny,
            active: !theme.isDark,
            onTap: theme.toggleTheme,
            activeColor: colors.accent,
          ),
          _buildIcon(
            icon: Icons.nightlight_round,
            active: theme.isDark,
            onTap: theme.toggleTheme,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
