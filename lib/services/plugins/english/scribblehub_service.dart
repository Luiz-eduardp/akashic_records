import 'dart:async';

import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

class ScribbleHub implements PluginService {
  @override
  String get name => 'ScribbleHub';

  @override
  String get lang => 'en';

  @override
  Map<String, dynamic> get filters => _filters;
  @override
  String get siteUrl => site;

  final String id = 'ScribbleHub';
  final String nameService = 'ScribbleHub';

  @override
  final String version = '1.0.1';
  final String icon = 'src/en/scribblehub/icon.png';
  final String site = 'https://www.scribblehub.com/';

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.63 Safari/537.36',
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
          headers: headers,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_to_load_data'.translate}: $e')),
        );
      }
      return http.Response('Error', 500);
    }
  }

  List<Novel> parseNovels(dom.Document loadedCheerio) {
    final novels = <Novel>[];

    final elements = loadedCheerio.querySelectorAll('.search_main_box');

    for (final element in elements) {
      final novelName =
          element.querySelector('.search_title > a')?.text.trim() ?? '';
      final novelCover =
          element.querySelector('.search_img > img')?.attributes['src'] ?? '';
      final novelUrl =
          element.querySelector('.search_title > a')?.attributes['href'];

      if (novelUrl == null) continue;

      final novel = Novel(
        pluginId: id,
        id: novelUrl.replaceFirst(site, ''),
        title: novelName,
        coverImageUrl: novelCover,
        author: '',
        description: '',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
      );
      novels.add(novel);
    }
    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int page, {
    Map<String, dynamic>? filters,
    BuildContext? context,
    bool showLatestNovels = false,
  }) async {
    String url = site;
    if (showLatestNovels) {
      url += 'latest-series/?pg=$page';
    } else if (filters != null) {
      final params = <String, String>{};

      final genres = filters['genres']?['value'] as Map<String, dynamic>?;
      final genreOperator = filters['genre_operator']?['value'] as String?;
      final contentWarning =
          filters['content_warning']?['value'] as Map<String, dynamic>?;
      final contentWarningOperator =
          filters['content_warning_operator']?['value'] as String?;
      final storyStatus = filters['storyStatus']?['value'] as String?;
      final sort = filters['sort']?['value'] as String?;
      final order = filters['order']?['value'] as String?;

      if (genres?['include'] != null && genres?['include'] is List) {
        final includeGenres = (genres?['include'] as List).cast<String>();
        if (includeGenres.isNotEmpty) {
          params['gi'] = includeGenres.join(',');
        }
      }

      if ((genres?['include'] != null &&
              genres?['include'] is List &&
              (genres?['include'] as List).isNotEmpty) ||
          (genres?['exclude'] != null &&
              genres?['exclude'] is List &&
              (genres?['exclude'] as List).isNotEmpty)) {
        params['mgi'] = genreOperator ?? 'and';
      }

      if (genres?['exclude'] != null && genres?['exclude'] is List) {
        final excludeGenres = (genres?['exclude'] as List).cast<String>();
        if (excludeGenres.isNotEmpty) {
          params['ge'] = excludeGenres.join(',');
        }
      }

      if (contentWarning?['include'] != null &&
          contentWarning?['include'] is List) {
        final includeWarnings =
            (contentWarning?['include'] as List).cast<String>();
        if (includeWarnings.isNotEmpty) {
          params['cti'] = includeWarnings.join(',');
        }
      }

      if ((contentWarning?['include'] != null &&
              contentWarning?['include'] is List &&
              (contentWarning?['include'] as List).isNotEmpty) ||
          (contentWarning?['exclude'] != null &&
              contentWarning?['exclude'] is List &&
              (contentWarning?['exclude'] as List).isNotEmpty)) {
        params['mct'] = contentWarningOperator ?? 'and';
      }

      if (contentWarning?['exclude'] != null &&
          contentWarning?['exclude'] is List) {
        final excludeWarnings =
            (contentWarning?['exclude'] as List).cast<String>();
        if (excludeWarnings.isNotEmpty) {
          params['cte'] = excludeWarnings.join(',');
        }
      }

      params['cp'] = storyStatus ?? 'all';
      params['sort'] = sort ?? 'ratings';
      params['order'] = order ?? 'desc';
      params['pg'] = page.toString();

      final uri = Uri.parse(
        '${site}series-finder/?sf=1&${_mapToQueryParameters(params)}',
      );
      url = uri.toString();
    } else {
      url += 'series-finder/?sf=1&sort=ratings&order=desc&pg=$page';
    }

    final result = await safeFetch(url, context: context, headers: _headers);
    if (result.statusCode != 200) {
      print('Failed to load popular novels. Status code: ${result.statusCode}');
      return [];
    }

    final body = result.body;
    final loadedCheerio = parse(body);
    return parseNovels(loadedCheerio);
  }

  String _mapToQueryParameters(Map<String, String> params) {
    final queryParams = <String>[];
    params.forEach((key, value) {
      queryParams.add('$key=${Uri.encodeComponent(value)}');
    });
    return queryParams.join('&');
  }

  @override
  Future<Novel> parseNovel(String novelPath, {BuildContext? context}) async {
    final result = await safeFetch(
      site + novelPath,
      context: context,
      headers: _headers,
    );

    if (result.statusCode != 200) {
      print('Failed to load novel details. Status code: ${result.statusCode}');
      return Novel(
        pluginId: id,
        id: novelPath,
        title: 'failed_to_load_title'.translate,
        coverImageUrl: '',
        author: '',
        description: '',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
      );
    }

    final body = result.body;
    final loadedCheerio = parse(body);

    final novel = Novel(
      pluginId: id,
      id: novelPath,
      title:
          loadedCheerio.querySelector('.fic_title')?.text.trim() ?? 'Untitled',
      coverImageUrl:
          loadedCheerio.querySelector('.fic_image > img')?.attributes['src'] ??
          '',
      description:
          loadedCheerio.querySelector('.wi_fic_desc')?.text.trim() ?? '',
      author: loadedCheerio.querySelector('.auth_name_fic')?.text.trim() ?? '',
      genres: loadedCheerio
          .querySelectorAll('.fic_genre')
          .map((e) => e.text.trim())
          .toList()
          .join(','),
      chapters: [],
      artist: '',
      statusString:
          loadedCheerio
                      .querySelector('.rnd_stats')
                      ?.nextElementSibling
                      ?.text
                      .contains('Ongoing') ==
                  true
              ? 'Ongoing'
              : 'Completed',
    );

    final novelId = novelPath.split('/')[1];
    final formData = <String, String>{
      'action': 'wi_getreleases_pagination',
      'pagenum': '-1',
      'mypostid': novelId,
    };

    final chapterResult = await http.post(
      Uri.parse('${site}wp-admin/admin-ajax.php'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: _mapToQueryParameters(formData),
    );
    if (chapterResult.statusCode != 200) {
      print(
        'Failed to load chapters. Status code: ${chapterResult.statusCode}',
      );
      return novel;
    }

    final chapterBody = chapterResult.body;
    final chapterLoadedCheerio = parse(chapterBody);

    final chapterElements = chapterLoadedCheerio.querySelectorAll('.toc_w');
    final chapters = <Chapter>[];

    for (final element in chapterElements) {
      final chapterName = element.querySelector('.toc_a')?.text.trim() ?? '';
      final releaseDateText =
          element.querySelector('.fic_date_pub')?.text.trim() ?? '';
      final chapterUrl = element.querySelector('a')?.attributes['href'];

      if (chapterUrl == null) continue;

      final releaseDate = _parseISODate(releaseDateText);

      chapters.add(
        Chapter(
          id: chapterUrl.replaceFirst(site, ''),
          title: chapterName,
          content: '',
          order: chapters.length,
          releaseDate: releaseDate?.substring(0, 10) ?? '',
          chapterNumber: chapters.length,
        ),
      );
    }
    novel.chapters = chapters.reversed.toList();
    return novel;
  }

  String? _parseISODate(String date) {
    if (date.contains('ago')) {
      DateTime dayJSDate = DateTime.now();
      final RegExpMatch? timeAgoMatch = RegExp(r'(\d+)').firstMatch(date);
      final String timeAgo = timeAgoMatch?.group(1) ?? '';
      final int? timeAgoInt = int.tryParse(timeAgo);

      if (timeAgoInt == null) return null;

      if (date.contains('hours ago') || date.contains('hour ago')) {
        dayJSDate = dayJSDate.subtract(Duration(hours: timeAgoInt));
      } else if (date.contains('days ago') || date.contains('day ago')) {
        dayJSDate = dayJSDate.subtract(Duration(days: timeAgoInt));
      } else if (date.contains('months ago') || date.contains('month ago')) {
        dayJSDate = dayJSDate.subtract(Duration(days: timeAgoInt * 30));
      }

      return dayJSDate.toIso8601String();
    }
    return null;
  }

  @override
  Future<String> parseChapter(
    String chapterPath, {
    BuildContext? context,
  }) async {
    final result = await safeFetch(
      site + chapterPath,
      context: context,
      headers: _headers,
    );

    if (result.statusCode != 200) {
      print(
        'Failed to load chapter content. Status code: ${result.statusCode}',
      );
      return 'failed_to_load_chapter'.translate;
    }

    final body = result.body;
    final loadedCheerio = parse(body);

    final chapterText =
        loadedCheerio.querySelector('div.chp_raw')?.innerHtml ?? '';
    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url =
        '$site?s=${Uri.encodeComponent(searchTerm)}&post_type=fictionposts';
    final result = await safeFetch(url, context: context, headers: _headers);

    if (result.statusCode != 200) {
      print('Failed to load search results. Status code: ${result.statusCode}');
      return [];
    }

    final body = result.body;
    final loadedCheerio = parse(body);
    return parseNovels(loadedCheerio);
  }

  static final Map<String, dynamic> _filters = {
    'sort': {
      'label': 'Sort Results By',
      'value': 'ratings',
      'options': [
        {'label': 'Chapters', 'value': 'chapters'},
        {'label': 'Chapters per Week', 'value': 'frequency'},
        {'label': 'Date Added', 'value': 'dateadded'},
        {'label': 'Favorites', 'value': 'favorites'},
        {'label': 'Last Updated', 'value': 'lastchdate'},
        {'label': 'Number of Ratings', 'value': 'numofrate'},
        {'label': 'Pages', 'value': 'pages'},
        {'label': 'Pageviews', 'value': 'pageviews'},
        {'label': 'Ratings', 'value': 'ratings'},
        {'label': 'Readers', 'value': 'readers'},
        {'label': 'Reviews', 'value': 'reviews'},
        {'label': 'Total Words', 'value': 'totalwords'},
      ],
      'type': FilterTypes.picker,
    },
    'order': {
      'label': 'Order By',
      'value': 'desc',
      'options': [
        {'label': 'Descending', 'value': 'desc'},
        {'label': 'Ascending', 'value': 'asc'},
      ],
      'type': FilterTypes.picker,
    },
    'storyStatus': {
      'label': 'Story Status',
      'value': 'all',
      'options': [
        {'label': 'All', 'value': 'all'},
        {'label': 'Completed', 'value': 'completed'},
        {'label': 'Ongoing', 'value': 'ongoing'},
        {'label': 'Hiatus', 'value': 'hiatus'},
      ],
      'type': FilterTypes.picker,
    },
    'genre_operator': {
      'value': 'and',
      'label': 'Genres (And/Or)',
      'options': [
        {'label': 'And', 'value': 'and'},
        {'label': 'Or', 'value': 'or'},
      ],
      'type': FilterTypes.picker,
    },
    'genres': {
      'label': 'Genres',
      'value': {'include': [], 'exclude': []},
      'options': [
        {'label': 'Action', 'value': '9'},
        {'label': 'Adult', 'value': '902'},
        {'label': 'Adventure', 'value': '8'},
        {'label': 'Boys Love', 'value': '891'},
        {'label': 'Comedy', 'value': '7'},
        {'label': 'Drama', 'value': '903'},
        {'label': 'Ecchi', 'value': '904'},
        {'label': 'Fanfiction', 'value': '38'},
        {'label': 'Fantasy', 'value': '19'},
        {'label': 'Gender Bender', 'value': '905'},
        {'label': 'Girls Love', 'value': '892'},
        {'label': 'Harem', 'value': '1015'},
        {'label': 'Historical', 'value': '21'},
        {'label': 'Horror', 'value': '22'},
        {'label': 'Isekai', 'value': '37'},
        {'label': 'Josei', 'value': '906'},
        {'label': 'LitRPG', 'value': '1180'},
        {'label': 'Martial Arts', 'value': '907'},
        {'label': 'Mature', 'value': '20'},
        {'label': 'Mecha', 'value': '908'},
        {'label': 'Mystery', 'value': '909'},
        {'label': 'Psychological', 'value': '910'},
        {'label': 'Romance', 'value': '6'},
        {'label': 'School Life', 'value': '911'},
        {'label': 'Sci-fi', 'value': '912'},
        {'label': 'Seinen', 'value': '913'},
        {'label': 'Slice of Life', 'value': '914'},
        {'label': 'Smut', 'value': '915'},
        {'label': 'Sports', 'value': '916'},
        {'label': 'Supernatural', 'value': '5'},
        {'label': 'Tragedy', 'value': '901'},
      ],
      'type': FilterTypes.excludableCheckboxGroup,
    },
    'content_warning_operator': {
      'value': 'and',
      'label': 'Mature Content (And/Or)',
      'options': [
        {'label': 'And', 'value': 'and'},
        {'label': 'Or', 'value': 'or'},
      ],
      'type': FilterTypes.picker,
    },
    'content_warning': {
      'value': {'include': [], 'exclude': []},
      'label': 'Mature Content',
      'options': [
        {'label': 'Gore', 'value': '48'},
        {'label': 'Sexual Content', 'value': '50'},
        {'label': 'Strong Language', 'value': '49'},
      ],
      'type': FilterTypes.excludableCheckboxGroup,
    },
  };

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context, int pageNo = 1}) {
    return popularNovels(pageNo, context: context);
  }
}

enum FilterTypes { picker, excludableCheckboxGroup }
