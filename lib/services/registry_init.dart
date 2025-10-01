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
}
