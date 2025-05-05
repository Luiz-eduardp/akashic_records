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
  final String version = '1.0.0';

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    List<Novel> allNovels = await recentNovels(1);

    int startIndex = (pageNo - 1) * 10;
    int endIndex = startIndex + 10;

    if (startIndex >= allNovels.length) {
      return [];
    }

    endIndex = endIndex > allNovels.length ? allNovels.length : endIndex;

    return allNovels.sublist(startIndex, endIndex);
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$baseURL/book/?search=$searchTerm&page=$pageNo';
    return _fetchNovels(url);
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    return Future.value([]);
    // int page = 1;
    // bool hasNextPage = true;
    // String url = '$baseURL/book/';

    // while (hasNextPage) {
    //   try {
    //     final pageUrl = '$url?page=$page';
    //     final novels = await _fetchNovels(pageUrl);
    //     if (novels.isEmpty) {
    //       hasNextPage = false;
    //     } else {
    //       allNovels.addAll(novels);
    //       page++;
    //     }
    //   } catch (e) {
    //     print('Erro ao carregar novels da página $page: $e');
    //     hasNextPage = false;
    //   }
    // }
    // return allNovels;
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$baseURL/book/?page=$pageNo';
    return _fetchNovels(url);
  }

  Future<List<Novel>> _fetchNovels(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'];

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
              coverImageUrl: coverUrl ?? 'https://via.placeholder.com/150',
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
  }

  @override
  Future<Novel> parseNovel(String novelId) async {
    final url = '$baseURL/book/$novelId/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final item = jsonDecode(response.body);

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

      Novel novel = Novel(
        id: item['id'].toString(),
        title: item['title'],
        coverImageUrl: coverUrl ?? 'https://via.placeholder.com/150',
        author: author,
        description: item['description'] ?? 'No description available.',
        genres: (item['subjects'] as List<dynamic>).cast<String>(),
        chapters: [],
        artist: '',
        statusString: NovelStatus.Completa.toString(),
        pluginId: name,
      );

      if (item['resources'] != null) {
        try {
          final htmlResource = item['resources'].firstWhere(
            (resource) => resource['type'] == 'text/html',
          );
          final chapterContent = await parseChapter(htmlResource['uri']);
          print("Chapter content: $chapterContent");
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
      throw Exception('Failed to load novel details for ID: $novelId');
    }
  }

  @override
  Future<String> parseChapter(String chapterUri) async {
    final response = await http.get(Uri.parse(chapterUri));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load chapter content from: $chapterUri');
    }
  }
}
