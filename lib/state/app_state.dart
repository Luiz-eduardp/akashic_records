import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  bool _settingsLoaded = false;
  Set<String> _selectedPlugins = {
    'NovelMania',
    'Tsundoku',
    'CentralNovels',
    'LightNovelPub',
  };

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get settingsLoaded => _settingsLoaded;
  Set<String> get selectedPlugins => _selectedPlugins;

  void setThemeMode(ThemeMode newThemeMode) {
    _themeMode = newThemeMode;
    _saveThemeSettings();
    notifyListeners();
  }

  void setAccentColor(Color newAccentColor) {
    _accentColor = newAccentColor;
    _saveThemeSettings();
    notifyListeners();
  }

  void setSelectedPlugins(Set<String> newPlugins) {
    _selectedPlugins = newPlugins;
    _saveSelectedPlugins();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plugins = prefs.getStringList('selectedPlugins');

      Set<String> savedPlugins =
          (plugins?.isNotEmpty == true ? Set<String>.from(plugins!) : {});

      _selectedPlugins = {'CentralNovel'}.union(savedPlugins);

      _themeMode =
          ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
      _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.value);
      _settingsLoaded = true;
      notifyListeners();
    } catch (e) {
      print("Erro ao carregar configurações: $e");
    }
  }

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _saveSelectedPlugins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedPlugins', _selectedPlugins.toList());
    } catch (e) {
      print("Erro ao salvar plugins selecionados: $e");
    }
  }

  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('accentColor', _accentColor.value);
  }
}
