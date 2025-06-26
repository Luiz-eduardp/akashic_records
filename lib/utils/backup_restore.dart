import 'dart:convert';
import 'dart:io';
import 'package:akashic_records/models/favorite_list.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> exportBackup(AppState appState) async {
  try {
    final appStateJson = appState.toJson();
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = {};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      prefsJson[key] = value;
    }

    final backupJson = {
      'appState': appStateJson,
      'sharedPreferences': prefsJson,
    };

    final jsonString = jsonEncode(backupJson);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/akashic_records_backup.json');
    await file.writeAsString(jsonString);

    return file.path;
  } catch (e) {
    debugPrint('Erro ao exportar o backup: $e');
    return '';
  }
}

Future<bool> importBackup(AppState appState) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/akashic_records_backup.json');

    if (!await file.exists()) {
      debugPrint('Arquivo de backup não encontrado.');
      return false;
    }

    final jsonString = await file.readAsString();
    final backupJson = jsonDecode(jsonString);

    final appStateJson = backupJson['appState'] as Map<String, dynamic>;
    appState.setThemeMode(ThemeMode.values[appStateJson['themeMode'] as int]);
    appState.setAccentColor(Color(appStateJson['accentColor'] as int));
    appState.setSelectedPlugins(
      Set<String>.from(appStateJson['selectedPlugins'] as List),
    );
    appState.setReaderSettings(
      ReaderSettings.fromMap(
        appStateJson['readerSettings'] as Map<String, dynamic>,
      ),
    );
    appState.setCustomPlugins(
      (appStateJson['customPlugins'] as List)
          .map((e) => CustomPlugin.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    appState.setScriptUrls(
      List<String>.from(appStateJson['scriptUrls'] as List),
    );
    await appState.clearFavoriteLists();
    await appState.novelCacheBox.clear();

    for (var listJson in (appStateJson['favoriteLists'] as List)) {
      final favoriteList = FavoriteList.fromJson(listJson);
      await appState.addFavoriteListFromBackup(favoriteList);
    }

    if (backupJson.containsKey('cachedNovels')) {
      for (var novelJson in (backupJson['cachedNovels'] as List)) {
        final cachedNovel = CachedNovel.fromJson(novelJson);
        await appState.addCachedNovelFromBackup(cachedNovel);
      }
    }

    final prefsJson = backupJson['sharedPreferences'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefsJson.keys) {
      final value = prefsJson[key];
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }

    return true;
  } catch (e) {
    debugPrint('Erro ao importar o backup: $e');
    return false;
  }
}
