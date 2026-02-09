import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFE8EAFF);

  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFFCFFAFE);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0A0A0A);
  static const Color darkSurfaceVariant = Color(0xFF1A1A1A);

  static const Color lightText = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color darkBorder = Color(0xFF475569);

  static const Color disabled = Color(0xFFD1D5DB);

  static const Color readerPaperLight = Color(0xFFFEF5E7);
  static const Color readerPaperDark = Color(0xFF2D3E50);
  static const Color readerTextLight = Color(0xFF2C3E50);
  static const Color readerTextDark = Color(0xFFECF0F1);

  static const List<Color> accentColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFF3B82F6),
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
