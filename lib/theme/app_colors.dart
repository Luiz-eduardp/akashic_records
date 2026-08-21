import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFF90E0EF);

  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryDark = Color(0xFF4F46E5);
  static const Color secondaryLight = Color(0xFF818CF8);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111726);
  static const Color darkSurfaceVariant = Color(0xFF1B2234);

  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color darkBorder = Color(0xFF1E293B);

  static const Color disabled = Color(0xFF64748B);

  static const Color readerPaperLight = Color(0xFFF8F6F0);
  static const Color readerTextPaperLight = Color(0xFF1E1E1E);

  static const Color readerWarmSepia = Color(0xFFF4ECD8);
  static const Color readerTextSepia = Color(0xFF3E2723);

  static const Color readerEinkMonochrome = Color(0xFFFFFFFF);
  static const Color readerTextEink = Color(0xFF000000);

  static const Color readerOledDark = Color(0xFF000000);
  static const Color readerTextOled = Color(0xFFE2E8F0);

  static const Color readerPaperDark = Color(0xFF1E293B);
  static const Color readerTextLight = Color(0xFF1E293B);
  static const Color readerTextDark = Color(0xFFF1F5F9);

  static const Color m3eSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color m3eSurfaceContainerLow = Color(0xFFF1F5F9);
  static const Color m3eSurfaceContainer = Color(0xFFE2E8F0);
  static const Color m3eSurfaceContainerHigh = Color(0xFFCBD5E1);
  static const Color m3eSurfaceContainerHighest = Color(0xFF94A3B8);

  static const List<Color> accentColors = [
    Color(0xFF00B4D8),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFFD1973A),
  ];

  static Color getTextColorForBackground(
    Color backgroundColor, {
    required bool isDark,
  }) {
    if (isDark) {
      return darkText;
    } else {
      return lightText;
    }
  }

  static Color getSurfaceColor(bool isDark) {
    return isDark ? darkSurface : lightSurface;
  }

  static Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackground : lightBackground;
  }
}
