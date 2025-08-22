import 'package:akashic_records/models/model.dart';
import 'package:flutter/material.dart';

abstract class PluginService {
  String get name;
  String get version;
  String get lang;
  String get siteUrl;
  Map<String, dynamic> get filters;
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic> filters,
    BuildContext? context,
  });
  Future<Novel> parseNovel(String novelPath);
  Future<String> parseChapter(String chapterPath);
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic> filters,
  });
  Future<List<Novel>> getAllNovels({BuildContext? context});
}
