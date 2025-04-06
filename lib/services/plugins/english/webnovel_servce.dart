// ignore_for_file: dead_code

import 'dart:async';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/material.dart';

class Webnovel implements PluginService {
  @override
  String get name => 'Webnovel';

  @override
  Map<String, dynamic> get filters => {
    'sort': {
      'label': 'Sort Results By',
      'value': '1',
      'options': [
        {'label': 'Popular', 'value': '1'},
        {'label': 'Recommended', 'value': '2'},
        {'label': 'Most Collections', 'value': '3'},
        {'label': 'Rating', 'value': '4'},
        {'label': 'Time Updated', 'value': '5'},
      ],
      'type': 'Picker',
    },
    'status': {
      'label': 'Content Status',
      'value': '0',
      'options': [
        {'label': 'All', 'value': '0'},
        {'label': 'Completed', 'value': '2'},
        {'label': 'Ongoing', 'value': '1'},
      ],
      'type': 'Picker',
    },
    'genres_gender': {
      'label': 'Genres (Male/Female)',
      'value': '1',
      'options': [
        {'label': 'Male', 'value': '1'},
        {'label': 'Female', 'value': '2'},
      ],
      'type': 'Picker',
    },
    'genres_male': {
      'label': 'Male Genres',
      'value': '1',
      'options': [
        {'label': 'All', 'value': '1'},
        {'label': 'Action', 'value': 'novel-action-male'},
        {'label': 'Animation, Comics, Games', 'value': 'novel-acg-male'},
        {'label': 'Eastern', 'value': 'novel-eastern-male'},
        {'label': 'Fantasy', 'value': 'novel-fantasy-male'},
        {'label': 'Games', 'value': 'novel-games-male'},
        {'label': 'History', 'value': 'novel-history-male'},
        {'label': 'Horror', 'value': 'novel-horror-male'},
        {'label': 'Realistic', 'value': 'novel-realistic-male'},
        {'label': 'Sci-fi', 'value': 'novel-scifi-male'},
        {'label': 'Sports', 'value': 'novel-sports-male'},
        {'label': 'Urban', 'value': 'novel-urban-male'},
        {'label': 'War', 'value': 'novel-war-male'},
      ],
      'type': 'Picker',
    },
    'genres_female': {
      'label': 'Female Genres',
      'value': '2',
      'options': [
        {'label': 'All', 'value': '2'},
        {'label': 'Fantasy', 'value': 'novel-fantasy-female'},
        {'label': 'General', 'value': 'novel-general-female'},
        {'label': 'History', 'value': 'novel-history-female'},
        {'label': 'LGBT+', 'value': 'novel-lgbt-female'},
        {'label': 'Sci-fi', 'value': 'novel-scifi-female'},
        {'label': 'Teen', 'value': 'novel-teen-female'},
        {'label': 'Urban', 'value': 'novel-urban-female'},
      ],
      'type': 'Picker',
    },
    'type': {
      'label': 'Content Type',
      'value': '0',
      'options': [
        {'label': 'All', 'value': '0'},
        {'label': 'Translate', 'value': '1'},
        {'label': 'Original', 'value': '2'},
        {'label': 'MTL (Machine Translation)', 'value': '3'},
      ],
      'type': 'Picker',
    },
    'fanfic_search': {
      'label': 'Search fanfics (Overrides other filters)',
      'value': '',
      'type': 'TextInput',
    },
  };

  final String id = 'Webnovel';
  final String nameService = 'Webnovel';
  final String site = 'https://www.webnovel.com';
  final String icon = 'src/en/webnovel/icon.png';
  final String version = '1.0.3';

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

  Future<List<Novel>> parseNovels(
    String body,
    bool categoryBool,
    bool searchBool,
  ) async {
    try {
      final document = parse(body);
      String selector =
          categoryBool
              ? '.j_category_wrapper li'
              : searchBool
              ? '.j_list_container li'
              : '';

      List<Novel> novels = [];
      for (var element in document.querySelectorAll(selector)) {
        try {
          final novelName =
              element.querySelector('.g_thumb')?.attributes['title'] ??
              'No Title Found';
          final novelCover =
              element.querySelector('.g_thumb > img')?.attributes[categoryBool
                  ? 'data-original'
                  : 'src'];
          final novelPath =
              element.querySelector('.g_thumb')?.attributes['href'];

          if (novelPath != null) {
            novels.add(
              Novel(
                pluginId: id,
                id: novelPath,
                title: novelName,
                coverImageUrl: 'https:$novelCover',
                author: '',
                description: '',
                genres: [],
                chapters: [],
                artist: '',
                statusString: '',
              ),
            );
          }
        } catch (e) {
          print('Error parsing novel item: $e');
        }
      }
      return novels;
    } catch (e) {
      print('Error parsing novels list: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    bool showLatestNovels = false,
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    try {
      if (filters?['fanfic_search']?['value'] != null &&
          filters?['fanfic_search']?['value'].isNotEmpty) {
        return searchNovelsInternal(
          filters!['fanfic_search']['value'],
          page,
          'fanfic',
          context: context,
        );
      }

      String url = '$site/stories/';
      Map<String, String> params = {};

      if (showLatestNovels) {
        url += 'novel?orderBy=5&pageIndex=$page';
      } else if (filters != null) {
        if (filters['genres_gender']['value'] == '1') {
          if (filters['genres_male']['value'] != '1') {
            url += filters['genres_male']['value'];
          } else {
            url += 'novel';
            params['gender'] = '1';
          }
        } else if (filters['genres_gender']['value'] == '2') {
          if (filters['genres_female']['value'] != '2') {
            url += filters['genres_female']['value'];
          } else {
            url += 'novel';
            params['gender'] = '2';
          }
        }

        if (filters['type']['value'] != '3') {
          params['sourceType'] = filters['type']['value'];
        } else {
          params['translateMode'] = '3';
          params['sourceType'] = '1';
        }

        params['bookStatus'] = filters['status']['value'];
        params['orderBy'] = filters['sort']['value'];
        params['pageIndex'] = page.toString();

        if (params.isNotEmpty) {
          url +=
              '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
        }
      } else {
        url += 'novel?orderBy=1&pageIndex=$page';
      }

      final response = await safeFetch(
        url,
        context: context,
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return parseNovels(response.body, true, false);
      } else {
        print(
          'Failed to load popular novels. Status code: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('Error in popularNovels: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load popular novels: $e')),
        );
      }
      return [];
    }
  }

  Future<List<Chapter>> parseChapters(
    String novelPath, {
    BuildContext? context,
  }) async {
    try {
      final url = '$site$novelPath/catalog';

      final response = await safeFetch(
        url,
        context: context,
        headers: _headers,
      );
      if (response.statusCode != 200) {
        print('Failed to load chapters. Status code: ${response.statusCode}');
        return [];
      }
      final data = response.body;
      final document = parse(data);

      List<Chapter> chapters = [];

      for (var volumeElement in document.querySelectorAll('.volume-item')) {
        String originalVolumeName = volumeElement.text.trim();
        RegExp volumeNameRegex = RegExp(r'Volume\s(\d+)');
        RegExpMatch? volumeNameMatch = volumeNameRegex.firstMatch(
          originalVolumeName,
        );
        String volumeName =
            volumeNameMatch != null
                ? 'Volume ${volumeNameMatch[1]}'
                : 'Unknown Volume';

        print('Volume Name: $volumeName');

        for (var chapterElement in volumeElement.querySelectorAll('li a')) {
          String chapterName =
              '$volumeName: ${chapterElement.attributes['title']?.trim() ?? 'No Title Found'}';
          String? chapterPath = chapterElement.attributes['href'];

          var locked = false;

          print(
            'Chapter Name: $chapterName, Path: $chapterPath, Locked: $locked',
          );

          if (chapterPath != null && !(locked)) {
            chapters.add(
              Chapter(
                id: chapterPath,
                title: locked ? '$chapterName 🔒' : chapterName,
                content: '',
              ),
            );
          }
        }
      }

      print('Parsed Chapters: ${chapters.length}');
      return chapters;
    } catch (e) {
      print('Erro ao carregar chapters: $e');
      return [];
    }
  }

  @override
  Future<Novel> parseNovel(String novelPath, {BuildContext? context}) async {
    try {
      final url = '$site$novelPath';

      final response = await safeFetch(
        url,
        context: context,
        headers: _headers,
      );
      if (response.statusCode != 200) {
        print(
          'Failed to load novel details. Status code: ${response.statusCode}',
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
      final data = response.body;
      final document = parse(data);

      final String? cover =
          document.querySelector('.g_thumb > img')?.attributes['src'];

      final novel = Novel(
        pluginId: id,
        id: novelPath,
        title:
            document.querySelector('.g_thumb > img')?.attributes['alt'] ??
            'No Title Found',
        coverImageUrl: 'https:$cover',
        author:
            document
                .querySelector('.det-info .c_s')
                ?.nextElementSibling
                ?.text
                .trim() ??
            'No Author Found',
        description:
            document.querySelector('.j_synopsis > p')?.text.trim() ??
            'No Summary Found',
        genres:
            document
                .querySelector('.det-hd-detail > .det-hd-tag')
                ?.attributes['title']
                ?.split(',')
                .toList() ??
            [],
        statusString:
            document
                .querySelector('.det-hd-detail svg')
                ?.nextElementSibling
                ?.text
                .trim() ??
            'Unknown Status',
        chapters: await parseChapters(novelPath, context: context),
        artist: '',
      );
      return novel;
    } catch (e) {
      print('Erro ao carregar detalhes da novel: $e');
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
      final url = '$site$chapterPath';

      final response = await safeFetch(
        url,
        context: context,
        headers: _headers,
      );
      if (response.statusCode != 200) {
        print('Failed to load chapter. Status code: ${response.statusCode}');
        return 'Failed to load chapter content.';
      }
      final data = response.body;
      final document = parse(data);

      final bloatElements = ['.para-comment'];
      for (final tag in bloatElements) {
        document.querySelectorAll(tag).forEach((element) => element.remove());
      }

      final chapterContent =
          (document.querySelector('.cha-tit')?.outerHtml ?? '') +
          (document.querySelector('.cha-words')?.outerHtml ?? '');

      return chapterContent;
    } catch (e) {
      print('Erro ao carregar capítulo: $e');
      return 'Erro ao carregar capítulo';
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) {
    return searchNovelsInternal(searchTerm, pageNo, null, context: context);
  }

  Future<List<Novel>> searchNovelsInternal(
    String searchTerm,
    int pageNo,
    String? type, {
    BuildContext? context,
  }) async {
    try {
      searchTerm = searchTerm.replaceAll(RegExp(r'\s+'), '+');

      final url =
          '$site/search?keywords=${Uri.encodeComponent(searchTerm)}&pageIndex=$pageNo${type != null ? '&type=$type' : ''}';

      final response = await safeFetch(
        url,
        context: context,
        headers: _headers,
      );
      if (response.statusCode != 200) {
        print(
          'Failed to load search results. Status code: ${response.statusCode}',
        );
        return [];
      }
      final data = response.body;
      return parseNovels(data, false, true);
    } catch (e) {
      print('Erro ao pesquisar novels: $e');
      return [];
    }
  }
}
