import 'dart:io';
import 'package:flutter/src/widgets/framework.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/services/opds_service.dart';
import 'package:akashic_records/services/epub_import_service.dart';

abstract class OpdsPluginBase implements PluginService {
  final OpdsService _opdsService = OpdsService();
  final EpubImportService _importService = EpubImportService();

  String get feedUrl;

  @override
  String get version => '1.3.0';

  @override
  Map<String, dynamic> get filters => {};

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final targetUrl = (filters != null && filters['subUrl'] != null) ? filters['subUrl'] as String : feedUrl;
    return _fetchAsNovels(targetUrl);
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final all = await _fetchAsNovels(feedUrl);
    if (searchTerm.trim().isEmpty) return all;

    final query = searchTerm.toLowerCase();
    return all.where((n) {
      return n.title.toLowerCase().contains(query) ||
          n.author.toLowerCase().contains(query) ||
          n.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    return popularNovels(1, context: context);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    if (novelPath.startsWith('http://') || novelPath.startsWith('https://')) {
      final ext = novelPath.toLowerCase().contains('.pdf') ? '.pdf' : '.epub';
      final fileName = 'opds_${DateTime.now().millisecondsSinceEpoch}$ext';
      final file = await _opdsService.downloadBook(novelPath, fileName);
      return _importService.importFromFile(file.path);
    } else if (File(novelPath).existsSync()) {
      return _importService.importFromFile(novelPath);
    }

    return Novel(
      id: novelPath,
      title: name,
      coverImageUrl: '',
      author: name,
      description: 'OPDS catalog item',
      chapters: [],
      pluginId: name,
      genres: ['OPDS'],
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    return chapterPath;
  }

  Future<List<Novel>> _fetchAsNovels(String url) async {
    try {
      final entries = await _opdsService.fetchFeed(url);
      return entries.map((entry) {
        final isAcquisition = entry.downloadUrl != null;
        final targetId = entry.downloadUrl ?? entry.navUrl ?? url;
        final genres = <String>['OPDS', lang.toUpperCase()];
        if (isAcquisition) {
          genres.add('BOOK');
        } else {
          genres.add('NAV');
        }

        return Novel(
          id: targetId,
          title: entry.title,
          coverImageUrl: entry.coverUrl ?? '',
          author: entry.author,
          description: entry.summary.isNotEmpty ? entry.summary : 'Available via $name OPDS Feed',
          chapters: [],
          pluginId: name,
          genres: genres,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

class StandardEbooksOpds extends OpdsPluginBase {
  @override
  String get name => 'Standard Ebooks (OPDS)';
  @override
  String get lang => 'en';
  @override
  String get siteUrl => 'https://standardebooks.org';
  @override
  String get feedUrl => 'https://standardebooks.org/opds/all';
}

class ProjectGutenbergOpds extends OpdsPluginBase {
  @override
  String get name => 'Project Gutenberg (OPDS)';
  @override
  String get lang => 'en';
  @override
  String get siteUrl => 'https://gutenberg.org';
  @override
  String get feedUrl => 'https://www.gutenberg.org/ebooks/search.opds/?sort_order=downloads';
}

class FeedbooksOpds extends OpdsPluginBase {
  @override
  String get name => 'Feedbooks (OPDS)';
  @override
  String get lang => 'cross plugin';
  @override
  String get siteUrl => 'https://feedbooks.com';
  @override
  String get feedUrl => 'https://www.gutenberg.org/ebooks/search.opds/?sort_order=release_date';
}

class ManyBooksOpds extends OpdsPluginBase {
  @override
  String get name => 'ManyBooks (OPDS)';
  @override
  String get lang => 'en';
  @override
  String get siteUrl => 'https://manybooks.net';
  @override
  String get feedUrl => 'https://manybooks.net/opds/index.php';
}

class InternetArchiveOpds extends OpdsPluginBase {
  @override
  String get name => 'Internet Archive (OPDS)';
  @override
  String get lang => 'cross plugin';
  @override
  String get siteUrl => 'https://archive.org';
  @override
  String get feedUrl => 'https://bookserver.archive.org/catalog/';
}

class OapenOpds extends OpdsPluginBase {
  @override
  String get name => 'OAPEN Open Access (OPDS)';
  @override
  String get lang => 'cross plugin';
  @override
  String get siteUrl => 'https://oapen.org';
  @override
  String get feedUrl => 'https://library.oapen.org/opds';
}

class CalibreCustomOpds extends OpdsPluginBase {
  String customUrl = 'http://127.0.0.1:8080/opds';

  @override
  String get name => 'Calibre Server (OPDS)';
  @override
  String get lang => 'cross plugin';
  @override
  String get siteUrl => 'https://calibre-ebook.com';
  @override
  String get feedUrl => customUrl;
}
