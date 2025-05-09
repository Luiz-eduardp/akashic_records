import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/src/widgets/framework.dart';

class ProjectGutenberg implements PluginService {
  @override
  String get name => 'ProjectGutenberg';

  @override
  String get lang => 'en';

  @override
  Map<String, dynamic> get filters => {};

  final String id = 'ProjectGutenberg';
  final String nameService = 'Project Gutenberg';
  final String baseURL = 'https://gnikdroy.pythonanywhere.com/api';
  @override
  final String version = '1.0.4';

  String? _extractCoverUrl(List<dynamic>? resources) {
    if (resources == null || resources.isEmpty) {
      return null;
    }

    try {
      return resources.firstWhere(
            (resource) => resource['type'] == 'image/jpeg',
          )['uri']
          as String?;
    } catch (e) {
      print("No cover image found: $e");
      return null;
    }
  }

  Novel _createNovelFromItem(dynamic item) {
    final String author =
        (item['agents'] != null && item['agents'].isNotEmpty)
            ? item['agents'][0]['person'] ?? "Unknown"
            : "Unknown";

    final String? coverUrl = _extractCoverUrl(item['resources']);

    return Novel(
      id: item['id'].toString(),
      title: item['title'],
      coverImageUrl:
          coverUrl ??
          'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
      author: author,
      description: item['description'] ?? 'No description available.',
      genres: (item['subjects'] as List<dynamic>).cast<String>(),
      chapters: [],
      artist: '',
      statusString: NovelStatus.Completa.toString(),
      pluginId: name,
      downloads: item['downloads'] ?? 0,
    );
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    return recentNovels(pageNo, filters: filters);
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final Uri uri = Uri.parse('$baseURL/book/').replace(
      queryParameters: {'search': searchTerm, 'page': pageNo.toString()},
    );

    final String url = uri.toString();

    print('Search URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'];
        print('Response Data: ${response.body}');
        List<Novel> novels =
            results.map((item) {
              String author = "Unknown";
              if (item['agents'] != null && item['agents'].isNotEmpty) {
                author = item['agents'][0]['person'] ?? "Unknown";
              }
              String? coverUrl;

              if (item['resources'] != null) {
                try {
                  coverUrl =
                      item['resources'].firstWhere(
                        (resource) => resource['type'] == 'image/jpeg',
                      )['uri'];
                } catch (e) {
                  coverUrl = null;
                }
              }

              return Novel(
                id: item['id'].toString(),
                title: item['title'],
                coverImageUrl:
                    coverUrl ??
                    'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
                author: author,
                description: item['description'] ?? 'No description available.',
                genres: (item['subjects'] as List<dynamic>).cast<String>(),
                chapters: [],
                artist: '',
                statusString: NovelStatus.Completa.toString(),
                pluginId: name,
                downloads: item['downloads'] ?? 0,
              );
            }).toList();

        return novels;
      } else {
        throw Exception('Failed to load novels from $url');
      }
    } catch (e) {
      print('Error during search: $e');
      rethrow;
    }
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    String url = '$baseURL/book/?page=$pageNo';
    return _fetchNovels(url);
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = '$baseURL/book/?page=$pageNo';
    return _fetchNovels(url);
  }

  Future<List<Novel>> _fetchNovels(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'];

        List<Novel> novels =
            results.map((item) => _createNovelFromItem(item)).toList();

        return novels;
      } else {
        throw Exception(
          'Failed to load novels from $url. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching novels from $url: $e');
      rethrow;
    }
  }

  @override
  Future<Novel> parseNovel(String novelId) async {
    final url = '$baseURL/book/$novelId/';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final item = jsonDecode(response.body);
        Novel novel = _createNovelFromItem(item);

        if (item['resources'] != null) {
          try {
            final htmlResource = item['resources'].firstWhere(
              (resource) => resource['type'] == 'text/html',
            );
            final chapterContent = await parseChapter(htmlResource['uri']);
            novel.chapters.add(
              Chapter(
                id: htmlResource['uri'],
                title: item['title'],
                content: chapterContent,
                chapterNumber: 1,
              ),
            );
          } catch (e) {
            print("Error fetching chapter content: $e");
          }
        }
        return novel;
      } else {
        throw Exception(
          'Failed to load novel details for ID: $novelId, Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error parsing novel with ID $novelId: $e');
      rethrow;
    }
  }

  @override
  Future<String> parseChapter(String chapterUri) async {
    try {
      final response = await http.get(Uri.parse(chapterUri));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Failed to load chapter content from: $chapterUri, Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error parsing chapter from $chapterUri: $e');
      rethrow;
    }
  }
}
