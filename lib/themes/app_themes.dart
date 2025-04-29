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
