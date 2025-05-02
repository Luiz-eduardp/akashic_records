import 'dart:convert';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class RoyalRoad implements PluginService {
  @override
  String get name => 'RoyalRoad';

  String get version => '2.2.3';

  String get id => 'royalroad';

  final String baseURL = 'https://www.royalroad.com/';

  @override
  Map<String, dynamic> get filters => {
    'keyword': {
      'type': FilterTypes.textInput,
      'label': 'Keyword (title or description)',
      'value': '',
    },
    'author': {'type': FilterTypes.textInput, 'label': 'Author', 'value': ''},
    'genres': {
      'type': FilterTypes.excludableCheckboxGroup,
      'label': 'Genres',
      'value': {'include': [], 'exclude': []},
      'options': [
        {'label': 'Action', 'value': 'action'},
        {'label': 'Adventure', 'value': 'adventure'},
        {'label': 'Comedy', 'value': 'comedy'},
        {'label': 'Contemporary', 'value': 'contemporary'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Fantasy', 'value': 'fantasy'},
        {'label': 'Historical', 'value': 'historical'},
        {'label': 'Horror', 'value': 'horror'},
        {'label': 'Mystery', 'value': 'mystery'},
        {'label': 'Psychological', 'value': 'psychological'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'Satire', 'value': 'satire'},
        {'label': 'Sci-fi', 'value': 'sci_fi'},
        {'label': 'Short Story', 'value': 'one_shot'},
        {'label': 'Tragedy', 'value': 'tragedy'},
      ],
    },
    'tags': {
      'type': FilterTypes.excludableCheckboxGroup,
      'label': 'Tags',
      'value': {'include': [], 'exclude': []},
      'options': [
        {'label': 'Anti-Hero Lead', 'value': 'anti-hero_lead'},
        {
          'label': 'Artificial Intelligence',
          'value': 'artificial_intelligence',
        },
        {'label': 'Attractive Lead', 'value': 'attractive_lead'},
        {'label': 'Cyberpunk', 'value': 'cyberpunk'},
        {'label': 'Dungeon', 'value': 'dungeon'},
        {'label': 'Dystopia', 'value': 'dystopia'},
        {'label': 'Female Lead', 'value': 'female_lead'},
        {'label': 'First Contact', 'value': 'first_contact'},
        {'label': 'GameLit', 'value': 'gamelit'},
        {'label': 'Gender Bender', 'value': 'gender_bender'},
        {'label': 'Genetically Engineered', 'value': 'genetically_engineered'},
        {'label': 'Grimdark', 'value': 'grimdark'},
        {'label': 'Hard Sci-fi', 'value': 'hard_sci-fi'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'High Fantasy', 'value': 'high_fantasy'},
        {'label': 'LitRPG', 'value': 'litrpg'},
        {'label': 'Low Fantasy', 'value': 'low_fantasy'},
        {'label': 'Magic', 'value': 'magic'},
        {'label': 'Male Lead', 'value': 'male_lead'},
        {'label': 'Martial Arts', 'value': 'martial_arts'},
        {'label': 'Multiple Lead Characters', 'value': 'multiple_lead'},
        {'label': 'Mythos', 'value': 'mythos'},
        {'label': 'Non-Human Lead', 'value': 'non-human_lead'},
        {'label': 'Portal Fantasy / Isekai', 'value': 'summoned_hero'},
        {'label': 'Post Apocalyptic', 'value': 'post_apocalyptic'},
        {'label': 'Progression', 'value': 'progression'},
        {'label': 'Reader Interactive', 'value': 'reader_interactive'},
        {'label': 'Reincarnation', 'value': 'reincarnation'},
        {'label': 'Ruling Class', 'value': 'ruling_class'},
        {'label': 'School Life', 'value': 'school_life'},
        {'label': 'Secret Identity', 'value': 'secret_identity'},
        {'label': 'Slice of Life', 'value': 'slice_of_life'},
        {'label': 'Soft Sci-fi', 'value': 'soft_sci-fi'},
        {'label': 'Space Opera', 'value': 'space_opera'},
        {'label': 'Sports', 'value': 'sports'},
        {'label': 'Steampunk', 'value': 'steampunk'},
        {'label': 'Strategy', 'value': 'strategy'},
        {'label': 'Strong Lead', 'value': 'strong_lead'},
        {'label': 'Super Heroes', 'value': 'super_heroes'},
        {'label': 'Supernatural', 'value': 'supernatural'},
        {
          'label': 'Technologically Engineered',
          'value': 'technologically_engineered',
        },
        {'label': 'Time Loop', 'value': 'loop'},
        {'label': 'Time Travel', 'value': 'time_travel'},
        {'label': 'Urban Fantasy', 'value': 'urban_fantasy'},
        {'label': 'Villainous Lead', 'value': 'villainous_lead'},
        {'label': 'Virtual Reality', 'value': 'virtual_reality'},
        {'label': 'War and Military', 'value': 'war_and_military'},
        {'label': 'Wuxia', 'value': 'wuxia'},
        {'label': 'Xianxia', 'value': 'xianxia'},
      ],
    },
    'content_warnings': {
      'type': FilterTypes.excludableCheckboxGroup,
      'label': 'Content Warnings',
      'value': {'include': [], 'exclude': []},
      'options': [
        {'label': 'Profanity', 'value': 'profanity'},
        {'label': 'Sexual Content', 'value': 'sexuality'},
        {'label': 'Graphic Violence', 'value': 'graphic_violence'},
        {'label': 'Sensitive Content', 'value': 'sensitive'},
        {'label': 'AI-Assisted Content', 'value': 'ai_assisted'},
        {'label': 'AI-Generated Content', 'value': 'ai_generated'},
      ],
    },
    'minPages': {
      'type': FilterTypes.textInput,
      'label': 'Min Pages',
      'value': '0',
    },
    'maxPages': {
      'type': FilterTypes.textInput,
      'label': 'Max Pages',
      'value': '20000',
    },
    'minRating': {
      'type': FilterTypes.textInput,
      'label': 'Min Rating (0.0 - 5.0)',
      'value': '0.0',
    },
    'maxRating': {
      'type': FilterTypes.textInput,
      'label': 'Max Rating (0.0 - 5.0)',
      'value': '5.0',
    },
    'status': {
      'type': FilterTypes.picker,
      'label': 'Status',
      'value': 'ALL',
      'options': [
        {'label': 'All', 'value': 'ALL'},
        {'label': 'Completa', 'value': 'COMPLETED'},
        {'label': 'Dropped', 'value': 'DROPPED'},
        {'label': 'Andamento', 'value': 'ONGOING'},
        {'label': 'Hiatus', 'value': 'HIATUS'},
        {'label': 'Stub', 'value': 'STUB'},
      ],
    },
    'orderBy': {
      'type': FilterTypes.picker,
      'label': 'Order by',
      'value': 'relevance',
      'options': [
        {'label': 'Relevance', 'value': 'relevance'},
        {'label': 'Popularity', 'value': 'popularity'},
        {'label': 'Average Rating', 'value': 'rating'},
        {'label': 'Last Update', 'value': 'last_update'},
        {'label': 'Release Date', 'value': 'release_date'},
        {'label': 'Followers', 'value': 'followers'},
        {'label': 'Number of Pages', 'value': 'length'},
        {'label': 'Views', 'value': 'views'},
        {'label': 'Title', 'value': 'title'},
        {'label': 'Author', 'value': 'author'},
      ],
    },
    'dir': {
      'type': FilterTypes.picker,
      'label': 'Direction',
      'value': 'desc',
      'options': [
        {'label': 'Ascending', 'value': 'asc'},
        {'label': 'Descending', 'value': 'desc'},
      ],
    },
    'type': {
      'type': FilterTypes.picker,
      'label': 'Type',
      'value': 'ALL',
      'options': [
        {'label': 'All', 'value': 'ALL'},
        {'label': 'Fan Fiction', 'value': 'fanfiction'},
        {'label': 'Original', 'value': 'original'},
      ],
    },
  };

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  Future<List<Novel>> _parseNovels(String html) async {
    final novels = <Novel>[];

    final document = parse(html);
    final fictionListItems = document.querySelectorAll('div.fiction-list-item');

    for (final item in fictionListItems) {
      final novelLink = item.querySelector('a.bold');
      final coverImage = item.querySelector('img');

      if (novelLink != null && coverImage != null) {
        String novelPath = novelLink.attributes['href'] ?? '';
        if (novelPath.startsWith('/')) {
          novelPath = novelPath.substring(1);
        }

        String coverImageUrl = coverImage.attributes['src'] ?? '';
        if (!coverImageUrl.startsWith('http')) {
          coverImageUrl = baseURL + coverImageUrl.substring(1);
        }

        novels.add(
          Novel(
            id: novelPath,
            title: novelLink.text,
            coverImageUrl: coverImageUrl,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: 'royalroad',
          ),
        );
      }
    }

    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    bool showLatestNovels = true,
  }) async {
    final params = <String, String>{'page': pageNo.toString()};

    if (showLatestNovels) {
      params['orderBy'] = 'last_update';
    }

    filters ??= this.filters;

    for (final key in filters.keys) {
      if (filters[key]?['value'] == null || filters[key]?['value'] == '') {
        continue;
      }

      if (key == 'genres' || key == 'tags' || key == 'content_warnings') {
        final includeList = filters[key]['value']['include'] as List?;
        final excludeList = filters[key]['value']['exclude'] as List?;

        if (includeList != null) {
          for (final include in includeList) {
            params['tagsAdd'] = include;
          }
        }

        if (excludeList != null) {
          for (final exclude in excludeList) {
            params['tagsRemove'] = exclude;
          }
        }
      } else if (filters[key]['value'] is String) {
        params[key] = filters[key]['value'];
      }
    }

    final uri = Uri.parse(
      '${baseURL}fictions/search',
    ).replace(queryParameters: params);
    final body = await _fetchApi(uri.toString());
    return _parseNovels(body);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    if (novelPath.startsWith('/')) {
      novelPath = novelPath.substring(1);
    }

    final result = await _fetchApi(baseURL + novelPath);
    final html = result;
    final document = parse(html);

    final novel = Novel(
      id: novelPath,
      title: '',
      coverImageUrl: '',
      description: '',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      author: '',
      pluginId: 'royalroad',
    );

    final coverElement = document.querySelector('img.thumbnail');
    novel.coverImageUrl = coverElement?.attributes['src'] ?? defaultCover;
    if (!novel.coverImageUrl.startsWith('http')) {
      novel.coverImageUrl = baseURL + novel.coverImageUrl.substring(1);
    }
    novel.title = document.querySelector('h1')?.text.trim() ?? '';
    novel.author = document.querySelector('h4 > a')?.text.trim() ?? '';
    novel.description =
        document.querySelector('div.description')?.text.trim() ?? '';

    String statusText = '';
    final spans = document.querySelectorAll('span.label-sm');
    if (spans.length >= 2) {
      statusText = spans[1].text.trim();
    }

    novel.status = _parseNovelStatus(statusText);

    final genreArray = <String>[];
    final genreElements = document.querySelectorAll('span.tags > a');
    for (final genre in genreElements) {
      genreArray.add(genre.text.trim());
    }
    novel.genres = genreArray;

    List<ChapterEntry> chapterJson = [];

    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final data = script.innerHtml;
      if (data.contains('window.chapters =')) {
        try {
          final chapterMatch = RegExp(
            r'window\.chapters = (\[.*?\]);',
          ).firstMatch(data);

          final volumeMatch = RegExp(
            r'window\.volumes = (\[.*?\]);',
          ).firstMatch(data);

          if (chapterMatch != null) {
            chapterJson =
                (jsonDecode(chapterMatch.group(1)!) as List)
                    .cast<Map<String, dynamic>>()
                    .map<ChapterEntry>((e) => ChapterEntry.fromJson(e))
                    .toList();
          }

          if (volumeMatch != null) {}
        } catch (e) {
          print('Error parsing chapter or volume JSON: $e');
        }
      }
    }
    int chapterNumber = 1;
    novel.chapters =
        chapterJson.map((chapter) {
          String chapterPath = chapter.url;
          if (chapterPath.startsWith('/')) {
            chapterPath = chapterPath.substring(1);
          }

          final chapterItem = Chapter(
            id: chapterPath,
            title: chapter.title,
            content: '',
            order: chapter.order?.toInt() ?? 0,
            chapterNumber: chapterNumber,
          );
          chapterNumber++;
          return chapterItem;
        }).toList();

    return novel;
  }

  NovelStatus _parseNovelStatus(String statusText) {
    switch (statusText) {
      case 'ONGOING':
        return NovelStatus.Andamento;
      case 'HIATUS':
        return NovelStatus.Pausada;
      case 'COMPLETED':
        return NovelStatus.Completa;
      default:
        return NovelStatus.Desconhecido;
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    if (chapterPath.startsWith('/')) {
      chapterPath = chapterPath.substring(1);
    }

    final result = await _fetchApi(baseURL + chapterPath);
    final html = result;
    final document = parse(html);

    String chapterContent = '';
    final chapterContentDiv = document.querySelector('div.chapter-content');

    if (chapterContentDiv != null) {
      chapterContentDiv
          .querySelectorAll('style, script')
          .forEach((element) => element.remove());
      chapterContentDiv.querySelectorAll('*').forEach((element) {
        element.attributes.removeWhere(
          (key, value) =>
              !['src', 'href', 'alt', 'title', 'class'].contains(key),
        );
      });

      chapterContent = chapterContentDiv.innerHtml;

      chapterContent = chapterContent.replaceAll(RegExp(r'<p>\s*</p>'), '');

      chapterContent = chapterContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');

      chapterContent = chapterContent.replaceAll(RegExp(r'class="[^"]*"'), '');
    }

    return chapterContent;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final params = {
      'page': pageNo.toString(),
      'title': searchTerm,
      'globalFilters': 'true',
    };

    final searchUrl =
        Uri.parse(
          '${baseURL}fictions/search',
        ).replace(queryParameters: params).toString();
    final body = await _fetchApi(searchUrl);
    return _parseNovels(body);
  }

  @override
  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) async {
    List<Novel> allNovels = [];
    int page = 1;
    bool hasNextPage = true;

    while (hasNextPage) {
      try {
        final url = '${baseURL}fictions/weekly-popular?page=$page';
        final body = await _fetchApi(url);
        final novels = await _parseNovels(body);
        if (novels.isEmpty) {
          hasNextPage = false;
        } else {
          allNovels.addAll(novels);
          page++;
        }
      } catch (e) {
        print('Erro ao carregar novels da página $page: $e');
        hasNextPage = false;
      }
    }

    return allNovels;
  }
}

enum FilterTypes { textInput, excludableCheckboxGroup, picker }

class ChapterEntry {
  final int id;
  final int volumeId;
  final String title;
  final String date;
  final int? order;
  final String url;

  ChapterEntry({
    required this.id,
    required this.volumeId,
    required this.title,
    required this.date,
    required this.order,
    required this.url,
  });

  factory ChapterEntry.fromJson(Map<String, dynamic> json) {
    return ChapterEntry(
      id: json['id'] as int? ?? 0,
      volumeId: json['volumeId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      order: json['order'] as int?,
      url: json['url'] as String? ?? '',
    );
  }
}

class VolumeEntry {
  final int id;
  final String title;
  final String cover;
  final int order;

  VolumeEntry({
    required this.id,
    required this.title,
    required this.cover,
    required this.order,
  });

  factory VolumeEntry.fromJson(Map<String, dynamic> json) {
    return VolumeEntry(
      id: json['id'] as int,
      title: json['title'] as String,
      cover: json['cover'] as String,
      order: json['order'] as int,
    );
  }
}
