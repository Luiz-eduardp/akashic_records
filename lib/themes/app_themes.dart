import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData darkTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.dark);
  static ThemeData greenTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData redTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData purpleTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData orangeTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData tealTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData indigoTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData pinkTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData brownTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData amberTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);
  static ThemeData cyanTheme(Color accentColor) =>
      _buildTheme(accentColor, Brightness.light);

  static ThemeData akashicTheme = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFD4AF37),
      onPrimary: Colors.black,
      secondary: Color(0xFFCD7F32),
      onSecondary: Colors.black,
      background: Color(0xFF2B1B0E),
      onBackground: Color(0xFFF5DEB3),
      surface: Color(0xFF3B2A1C),
      onSurface: Colors.white,
      error: Colors.red,
      onError: Colors.white,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF2B1B0E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3B2A1C),
      foregroundColor: Color(0xFFD4AF37),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF5DEB3)),
      bodyMedium: TextStyle(color: Color(0xFFF5DEB3)),
      titleLarge: TextStyle(
        color: Color(0xFFD4AF37),
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
  );

  static ThemeData _buildTheme(Color accentColor, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
