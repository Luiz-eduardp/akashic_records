import 'package:akashic_records/services/plugin_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:akashic_records/services/plugins/japanese/syosetu_service.dart';
import 'package:akashic_records/services/plugins/japanese/kakuyomu_service.dart';
import 'package:akashic_records/services/plugins/portuguese/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/portuguese/novelmania_service.dart';
import 'package:akashic_records/services/multi/mtl_service.dart';
import 'package:akashic_records/services/plugins/english/projectgutenberg_service.dart';
import 'package:akashic_records/services/plugins/english/novelonline_service.dart';
import 'package:akashic_records/services/plugins/english/scribblehub_service.dart';
import 'package:akashic_records/services/plugins/english/webnovel_service.dart';
import 'package:akashic_records/services/plugins/english/novelbin_service.dart';
import 'package:akashic_records/services/plugins/english/royalroad_service.dart';
import 'package:akashic_records/services/plugins/arabic/sunovels_service.dart';
import 'package:akashic_records/services/plugins/indonesean/indowebnovel_service.dart';
import 'package:akashic_records/services/plugins/french/chireads_service.dart';
import 'package:akashic_records/services/plugins/spanish/novelsligera_service.dart';
import 'package:akashic_records/services/plugins/spanish/skynovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/blogdoamonnovels_service.dart';
import 'package:akashic_records/services/plugins/portuguese/centralnovel_service.dart';
import 'package:akashic_records/services/plugins/portuguese/lightnovelbrasil_service.dart';
import 'package:akashic_records/services/cross_plugin_loader.dart';
import 'dart:developer' as developer;

void registerDefaultPlugins() {
  try {
    PluginRegistry.register(Syosetu());
  } catch (_) {}
  try {
    PluginRegistry.register(Kakuyomu());
  } catch (_) {}

  try {
    PluginRegistry.register(Tsundoku());
  } catch (_) {}
  try {
    PluginRegistry.register(NovelMania());
  } catch (_) {}
  try {
    PluginRegistry.register(BlogDoAmonNovels());
  } catch (_) {}
  try {
    PluginRegistry.register(CentralNovel());
  } catch (_) {}
  try {
    PluginRegistry.register(LightNovelBrasil());
  } catch (_) {}

  try {
    PluginRegistry.register(MtlNovelMulti());
  } catch (_) {}
  try {
    PluginRegistry.register(ProjectGutenberg());
  } catch (_) {}
  try {
    PluginRegistry.register(NovelsOnline());
  } catch (_) {}
  try {
    PluginRegistry.register(NovelBin());
  } catch (_) {}
  try {
    PluginRegistry.register(RoyalRoad());
  } catch (_) {}
  try {
    PluginRegistry.register(ScribbleHub());
  } catch (_) {}
  try {
    PluginRegistry.register(Webnovel());
  } catch (_) {}

  try {
    PluginRegistry.register(Sunovels());
  } catch (e) {
    debugPrint('Failed to register Sunovels: $e');
  }

  try {
    PluginRegistry.register(IndoWebNovel());
  } catch (e) {
    debugPrint('Failed to register IndoWebNovel: $e');
  }

  try {
    PluginRegistry.register(Chireads());
  } catch (e) {
    debugPrint('Failed to register Chireads: $e');
  }

  try {
    PluginRegistry.register(NovelasLigera());
  } catch (e) {
    debugPrint('Failed to register NovelasLigera: $e');
  }

  try {
    PluginRegistry.register(SkyNovels());
  } catch (e) {
    debugPrint('Failed to register SkyNovels: $e');
  }

  _registerCrossPluginsSync();
}

void _registerCrossPluginsSync() {
  try {
    developer.log('Loading cross plugin list from JSON...');
    const listUrl =
        'https://raw.githubusercontent.com/lnreader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json';

    _loadPluginsAsync(listUrl);
  } catch (e) {
    developer.log('Error in sync plugin registration: $e');
  }
}

Future<void> _loadPluginsAsync(String listUrl) async {
  try {
    developer.log('Starting async plugin loading from: $listUrl');
    final loader = CrossPluginLoader();

    final plugins = await loader.loadPluginList(listUrl);
    developer.log('Loaded ${plugins.length} plugins from JSON');

    int successCount = 0;
    int failCount = 0;

    for (final plugin in plugins) {
      try {
        developer.log('Registering plugin: ${plugin.name} (${plugin.site})');
        final service = loader.createPluginMetadata(plugin, listUrl);
        PluginRegistry.register(service);
        successCount++;
        developer.log('✓ Registered: ${plugin.name}');
      } catch (e) {
        failCount++;
        developer.log('✗ Failed to register ${plugin.name}: $e');
      }
    }

    developer.log(
      'Plugin loading complete: $successCount success, $failCount failed',
    );
  } catch (e) {
    developer.log('Error loading plugins async: $e');
  }
}
