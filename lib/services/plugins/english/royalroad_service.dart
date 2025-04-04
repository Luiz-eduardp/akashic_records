import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class RoyalRoad implements PluginService {
  @override
  String get name => 'RoyalRoad';

  String get version => '2.1.3';

  String get id => 'RoyalRoad';

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
        {'label': 'Completed', 'value': 'COMPLETED'},
        {'label': 'Dropped', 'value': 'DROPPED'},
        {'label': 'Ongoing', 'value': 'ONGOING'},
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
      'https://placehold.co/400x450.png?text=Sem%20Capa';

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
    String tempNovelName = '';
    String tempNovelPath = '';
    String tempNovelCover = '';
    bool isParsingNovel = false;
    bool isNovelName = false;

    final document = parse(html);
    final fictionListItems = document.querySelectorAll('div.fiction-list-item');

    for (final item in fictionListItems) {
      isParsingNovel = true;
      final novelLink = item.querySelector('a.bold');
      final coverImage = item.querySelector('img');

      if (novelLink != null) {
        tempNovelPath = novelLink.attributes['href'] ?? '';
        if (tempNovelPath.startsWith('/')) {
          tempNovelPath = tempNovelPath.substring(1);
        }
        tempNovelName = novelLink.text;
        isNovelName = true;
      }

      if (coverImage != null) {
        tempNovelCover = coverImage.attributes['src'] ?? '';
      }

      if (isParsingNovel &&
          isNovelName &&
          tempNovelPath.isNotEmpty &&
          tempNovelName.isNotEmpty) {
        novels.add(
          Novel(
            id: tempNovelPath,
            title: tempNovelName,
            coverImageUrl: tempNovelCover,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: 'RoyalRoad',
          ),
        );

        tempNovelName = '';
        tempNovelPath = '';
        tempNovelCover = '';
        isParsingNovel = false;
        isNovelName = false;
      }
    }

    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    bool showLatestNovels = false,
  }) async {
    String link = '${baseURL}fictions/search?page=$pageNo';

    filters ??= this.filters;

    if (showLatestNovels) {
      link += '&orderBy=last_update';
    }

    for (final key in filters.keys) {
      if (filters[key]?['value'] == null || filters[key]?['value'] == '') {
        continue;
      }

      if (key == 'genres' || key == 'tags' || key == 'content_warnings') {
        final includeList = filters[key]['value']['include'] as List?;
        final excludeList = filters[key]['value']['exclude'] as List?;

        if (includeList != null) {
          for (final include in includeList) {
            link += '&tagsAdd=$include';
          }
        }

        if (excludeList != null) {
          for (final exclude in excludeList) {
            link += '&tagsRemove=$exclude';
          }
        }
      } else if (filters[key]['value'] is String) {
        link += '&$key=${filters[key]['value']}';
      }
    }

    final body = await _fetchApi(link);
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
      pluginId: 'RoyalRoad',
    );

    novel.coverImageUrl =
        document.querySelector('img.thumbnail')?.attributes['src'] ??
        defaultCover;
    novel.title = document.querySelector('h1')?.text ?? '';
    novel.author = document.querySelector('h4 > a')?.text ?? '';
    novel.description =
        document.querySelector('div.description')?.text.trim() ?? '';

    String statusText = '';
    final spans = document.querySelectorAll('span.label-sm');
    if (spans.length >= 2) {
      statusText = spans[1].text.trim();
    }

    switch (statusText) {
      case 'ONGOING':
        novel.status = NovelStatus.Ongoing;
        break;
      case 'HIATUS':
        novel.status = NovelStatus.OnHiatus;
        break;
      case 'COMPLETED':
        novel.status = NovelStatus.Completed;
        break;
      default:
        novel.status = NovelStatus.Unknown;
    }

    final genreArray = <String>[];
    final genreElements = document.querySelectorAll('span.tags > a');
    for (final genre in genreElements) {
      genreArray.add(genre.text);
    }
    novel.genres = genreArray;

    List<ChapterEntry> chapterJson = [];
    List<VolumeEntry> volumeJson = [];

    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final data = script.innerHtml;
      if (data.contains('window.chapters =')) {
        final chapterMatch = RegExp(
          r'window\.chapters = (.*?)(\;|$)',
        ).firstMatch(data);
        final volumeMatch = RegExp(
          r'window\.volumes = (.*?)(\;|$)',
        ).firstMatch(data);
        if (chapterMatch != null) {
          try {
            final chapterJsonString = chapterMatch.group(1);
            chapterJson =
                (jsonDecode(chapterJsonString!) as List)
                    .cast<Map<String, dynamic>>()
                    .map<ChapterEntry>((e) => ChapterEntry.fromJson(e))
                    .toList();
          } catch (e) {
            print('Error parsing chapter JSON: $e');
          }
        }

        if (volumeMatch != null) {
          try {
            final volumeJsonString = volumeMatch.group(1);
            volumeJson =
                (jsonDecode(volumeJsonString!) as List)
                    .cast<Map<String, dynamic>>()
                    .map<VolumeEntry>((e) => VolumeEntry.fromJson(e))
                    .toList();
          } catch (e) {
            print('Error parsing volume JSON: $e');
          }
        }
      }
    }

    novel.chapters =
        chapterJson.map((chapter) {
          try {
            volumeJson.firstWhere((volume) => volume.id == chapter.volumeId);
          } catch (e) {
            print('Volume not found for chapter ${chapter.id}');
          }

          return Chapter(
            id: chapter.url.substring(1),
            title: chapter.title,
            order: chapter.order,
            content: '',
          );
        }).toList();

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    if (chapterPath.startsWith('/')) {
      chapterPath = chapterPath.substring(1);
    }
    final result = await _fetchApi(baseURL + chapterPath);
    final html = result;
    parse(html);

    final parts = <String>[];
    final regexPatterns = <RegExp>[
      RegExp(r'<style>\n\s+.(.+?){[^]+?display: none;'),
      RegExp(
        r'(<div class="portlet solid author-note-portlet"[^]+?)<div class="margin-bottom-20',
      ),
      RegExp(
        r'(<div class="chapter-inner chapter-content"[^]+?)<div class="portlet light t-center-3',
      ),
      RegExp(
        r'(<\/div>\s+<div class="portlet solid author-note-portlet"[^]+?)<div class="row margin-bottom-10',
      ),
    ];

    for (final regex in regexPatterns) {
      final match = regex.firstMatch(html);
      if (match != null && match.groupCount >= 1) {
        parts.add(match.group(1)!);
      }
    }

    String chapterText = parts.sublist(1).join('<hr>');

    if (parts.isNotEmpty) {
      final cleanup = RegExp('<p class="${parts[0]}.+?</p>', dotAll: true);
      chapterText = chapterText.replaceAll(cleanup, '');
    }

    chapterText = chapterText.replaceAll(RegExp(r'<p class="[^><]+>'), '<p>');

    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final searchUrl =
        '${baseURL}fictions/search?page=$pageNo&title=${Uri.encodeComponent(searchTerm)}';
    final body = await _fetchApi(searchUrl);
    return _parseNovels(body);
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
