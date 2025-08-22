import 'dart:async';
import 'dart:convert';

import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

class ReaperScans implements PluginService {
  @override
  String get name => 'ReaperScans';
  @override
  String get lang => 'en';
  @override
  String get siteUrl => site; // Implementando siteUrl
  @override
  Map<String, dynamic> get filters => {};

  final String id = 'ReaperScans';
  final String nameService = 'ReaperScans';
  @override
  final String version = '1.0.1';
  final String icon = 'src/en/reaperscans/icon.png';
  final String site = 'https://reaperscans.com';
  final String apiBase = 'https://api.reaperscans.com';
  final String mediaBase = 'https://media.reaperscans.com/file/4SRBHm/';

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  Future<http.Response> safeFetch(
    String url, {
    BuildContext? context,
    Map<String, String>? headers,
    int retries = 3,
  }) async {
    headers ??= _headers;
    try {
      print('Fetching: $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 404) {
        return response;
      } else if (response.statusCode == 403 && retries > 0) {
        print('Received 403, retrying... ($retries retries left)');
        await Future.delayed(Duration(seconds: (4 - retries) * 2));
        return safeFetch(
          url,
          context: context,
          headers: _headers,
          retries: retries - 1,
        );
      } else {
        print('safeFetch failed: Status Code ${response.statusCode}');
        throw Exception(
          'Could not reach site (${response.statusCode}) after multiple retries. Try to open in webview.',
        );
      }
    } catch (e) {
      print('Error in safeFetch: $e');
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
      return http.Response('Error', 500);
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    return query(page, '', context: context);
  }

  @override
  Future<Novel> parseNovel(String novelPath, {BuildContext? context}) async {
    try {
      final responses = await Future.wait([
        safeFetch(
          '$apiBase/series/$novelPath',
          context: context,
          headers: _headers,
        ),
        safeFetch(
          '$apiBase/chapters/$novelPath?perPage=500',
          context: context,
          headers: _headers,
        ),
      ]);

      final novelResp = responses[0];
      final chaptersResp = responses[1];

      if (novelResp.statusCode != 200) {
        print(
          'Failed to load novel details. Status code: ${novelResp.statusCode}',
        );
        return Novel(
          pluginId: id,
          id: novelPath,
          title: 'Failed to Load',
          coverImageUrl: '',
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
      }
      final novelData = jsonDecode(novelResp.body);

      if (chaptersResp.statusCode != 200) {
        print(
          'Failed to load chapters. Status code: ${chaptersResp.statusCode}',
        );
        return Novel(
          pluginId: id,
          id: novelPath,
          title: 'Failed to Load',
          coverImageUrl: '',
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
      }
      final chaptersJson = jsonDecode(chaptersResp.body);
      final List<dynamic> chaptersData = chaptersJson['data'];

      String coverUrl = novelData['thumbnail'] ?? '';
      coverUrl = coverUrl.isNotEmpty ? getCoverUrl(coverUrl) : '';

      final novel = Novel(
        pluginId: id,
        id: novelPath,
        title: novelData['title'] ?? 'No Title Found',
        coverImageUrl: coverUrl,
        author: novelData['author'] ?? '',
        artist: novelData['studio'] ?? '',
        statusString: novelData['status'] ?? '',
        description: novelData['description'] ?? '',
        genres: (novelData['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        chapters: [],
      );
      int chapterNumber = 1;
      List<Chapter> chapterList =
          chaptersData.reversed.map((chapter) {
            final chapterItem = Chapter(
              id: '$novelPath/${chapter['chapter_slug']}',
              title: chapter['chapter_name'] ?? 'No Chapter Name',
              content: '',
              order: int.tryParse(chapter['index'] ?? '') ?? 0,
              releaseDate: chapter['created_at']?.substring(0, 10) ?? '',
              chapterNumber: chapterNumber,
            );
            chapterNumber++;
            return chapterItem;
          }).toList();
      novel.chapters = chapterList;
      return novel;
    } catch (e) {
      print('Error parsing novel: $e');
      return Novel(
        pluginId: id,
        id: novelPath,
        title: 'Failed to Load',
        coverImageUrl: '',
        author: '',
        description: '',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
      );
    }
  }

  @override
  Future<String> parseChapter(
    String chapterPath, {
    BuildContext? context,
  }) async {
    try {
      final result = await safeFetch(
        '$site/series/$chapterPath',
        context: context,
        headers: {..._headers, 'RSC': '1'},
      );
      if (result.statusCode != 200) {
        print(
          'Failed to load chapter content. Status code: ${result.statusCode}',
        );
        return 'Failed to load chapter content.';
      }
      final body = result.body;
      return extractChapterContent(body);
    } catch (e) {
      print('Error parsing chapter: $e');
      return 'Failed to load chapter content.';
    }
  }

  String extractChapterContent(String chapterHtml) {
    try {
      final dom.Document $ = parser.parse(chapterHtml);
      final contentElement =
          $.querySelector('div.entry-content') ??
          $.querySelector('article.post') ??
          $.querySelector('div.chapter-content');

      if (contentElement != null) {
        return contentElement.innerHtml;
      } else {
        print('Could not find chapter content element.');
        return 'Could not load content: Content element not found.';
      }
    } catch (e) {
      print('Erro ao extract chapter content com parser: $e');
      return 'Erro ao carregar capítulo: $e';
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    return query(pageNo, searchTerm, context: context);
  }

  Future<List<Novel>> query(
    int page,
    String search, {
    BuildContext? context,
  }) async {
    try {
      final link =
          '$apiBase/query?page=$page&perPage=20&series_type=Novel&query_string=${Uri.encodeComponent(search)}&order=desc&orderBy=created_at&adult=true&status=All&tags_ids=[]';
      final result = await safeFetch(link, context: context, headers: _headers);
      if (result.statusCode != 200) {
        print(
          'Failed to load query results. Status code: ${result.statusCode}',
        );
        return [];
      }

      final json = jsonDecode(result.body);
      final List<dynamic> data = json['data'];

      return data.map((novel) {
        String coverUrl = novel['thumbnail'] ?? '';
        coverUrl = coverUrl.isNotEmpty ? getCoverUrl(coverUrl) : '';

        return Novel(
          pluginId: id,
          id: novel['series_slug'],
          title: novel['title'] ?? 'No Title Found',
          coverImageUrl: coverUrl,
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
      }).toList();
    } catch (e) {
      print('Error querying novels: $e');
      return [];
    }
  }

  String getCoverUrl(String thumbnail) {
    return thumbnail.startsWith('novels/') ? mediaBase + thumbnail : thumbnail;
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    return query(pageNo, '', context: context);
  }
}

enum FilterTypes { picker, toggle }
