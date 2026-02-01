import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF016B61); // Updated Teal
  static const Color primarySubtle = Color(0xFFecfdf5);
  static const Color danger = Color(0xFFef4444);
  static const Color dangerSubtle = Color(0xFFfef2f2);
  static const Color surface = Color(0xFFffffff);
  static const Color background = Color(0xFFffffff);
  static const Color subtleBorder = Color(0xFFf1f5f9);
  static const Color textMain = Color(0xFF0f172A);
  static const Color textMuted = Color(0xFF64748b);

  static const Color orange400 = Color(0xFFfb923c);
  static const Color slate100 = Color(0xFFf1f5f9);

  // Slate Scale
  static const Color slate50 = Color(0xFFf8fafc);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate300 = Color(0xFFcbd5e1);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);

  // Emerald Scale
  static const Color emerald50 = Color(0xFFecfdf5);
  static const Color emerald500 = Color(0xFF10b981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald200 = Color(0xFFA7F3D0);

  // Additional colors
  static const Color teal600 = Color(0xFF0d9488);
  static const Color indigo500 = Color(0xFF6366f1);

  // Legacy mappings (Restored & Updated)
  // static const Color primary = Color(0xFF3BB44A); // Handled above
  static const Color primaryDark = Color(0xFF2E8F3A);
  static const Color primaryLight = Color(0xFFECFDF5);
  static const Color accent = Color(0xFFEF4444);

  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(
    0xFF1A1A2E,
  ); // Requested dark theme brand color
  static const Color textDark = Color(0xFF111813);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color greyText = Color(0xFF61896B);
  static const Color inputBorder = Color(0xFFDBE6DF);

  // Dark theme specific colors
  static const Color surfaceDark = Color(0xFF252542);
  static const Color cardDark = Color(0xFF252542);
  static const Color textDarkTheme = Color(0xFFE2E8F0);
  static const Color textMutedDark = Color(0xFF94A3B8);
}

/// Extension on BuildContext for easy theme-aware color access.
/// Use `context.colors.background` instead of `AppColors.backgroundLight`.
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Background color (scaffold)
  Color get background =>
      isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;

  /// Surface/card color
  Color get surface => isDarkMode ? AppColors.surfaceDark : Colors.white;

  /// Primary text color
  Color get textPrimary =>
      isDarkMode ? AppColors.textDarkTheme : AppColors.textDark;

  /// Muted/secondary text color
  Color get textMuted =>
      isDarkMode ? AppColors.textMutedDark : AppColors.textMuted;

  /// Card background color
  Color get cardColor => isDarkMode ? AppColors.cardDark : Colors.white;

  /// Border color
  Color get borderColor =>
      isDarkMode ? Colors.white.withOpacity(0.1) : AppColors.slate200;

  /// Subtle background (for containers, chips, etc.)
  Color get subtleBackground =>
      isDarkMode ? AppColors.surfaceDark : AppColors.slate50;

  /// AppBar background
  Color get appBarBackground =>
      isDarkMode ? AppColors.backgroundDark : Colors.white;

  /// Icon color
  Color get iconColor => isDarkMode ? Colors.white : AppColors.slate600;
}
