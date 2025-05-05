import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class Kakuyomu implements PluginService {
  @override
  String get name => 'Kakuyomu';

  @override
  String get lang => 'ja';

  @override
  Map<String, dynamic> get filters => {
    'genre': {
      'type': 'picker',
      'label': 'Genre',
      'options': [
        {'label': '総合', 'value': 'all'},
        {'label': '異世界ファンタジー', 'value': 'fantasy'},
        {'label': '現代ファンタジー', 'value': 'action'},
        {'label': 'SF', 'value': 'sf'},
        {'label': '恋愛', 'value': 'love_story'},
        {'label': 'ラブコメ', 'value': 'romance'},
        {'label': '現代ドラマ', 'value': 'drama'},
        {'label': 'ホラー', 'value': 'horror'},
        {'label': 'ミステリー', 'value': 'mystery'},
        {'label': 'エッセイ・ノンフィクション', 'value': 'nonfiction'},
        {'label': '歴史・時代・伝奇', 'value': 'history'},
        {'label': '創作論・評論', 'value': 'criticism'},
        {'label': '詩・童話・その他', 'value': 'others'},
      ],
      'value': 'all',
    },
    'period': {
      'type': 'picker',
      'label': 'Period',
      'options': [
        {'label': '累計', 'value': 'entire'},
        {'label': '日間', 'value': 'daily'},
        {'label': '週間', 'value': 'weekly'},
        {'label': '月間', 'value': 'monthly'},
        {'label': '年間', 'value': 'yearly'},
      ],
      'value': 'entire',
    },
  };

  final String id = 'kakuyomu';
  final String icon = 'src/jp/kakuyomu/icon.png';
  final String site = 'https://kakuyomu.jp';
  @override
  final String version = '1.0.2';
  final String baseURL = 'https://kakuyomu.jp';
  final String defaultCover = 'https://placehold.co/400x500.png?text=Kakuyomu';

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+kakuyomu\.jp'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String genre = filters?['genre']?['value'] ?? 'all';
    String period = filters?['period']?['value'] ?? 'entire';

    final url = '$site/rankings/$genre/$period';
    if (pageNo > 1) {
      print("Popular URL: $url");
    }

    final body = await _fetchApi(url);
    final document = parse(body);

    List<Novel> novels = [];
    final novelElements = document.querySelectorAll(
      '.widget-media-genresWorkList-right > .widget-work',
    );

    for (var element in novelElements) {
      final anchor = element.querySelector('a.widget-workCard-titleLabel');
      final path = anchor?.attributes['href'];

      if (path != null) {
        final name = anchor!.text.trim();

        final novel = Novel(
          id: _shrinkURL(path),
          title: name,
          coverImageUrl: defaultCover,
          pluginId: this.name,
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
        novels.add(novel);
      }
    }

    return novels;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final url = _expandURL(novelPath);
    final body = await _fetchApi(url);
    final document = parse(body);

    String title =
        document.querySelector('.widget-work-header-title')?.text.trim() ??
        'Sem título';
    String author =
        document.querySelector('.widget-creator-username')?.text.trim() ??
        'Sem Autor';
    String description =
        document.querySelector('.widget-work-introduction')?.text.trim() ??
        'Sem Descrição';
    String coverImageUrl =
        document
            .querySelector('.widget-work-header > a > img')
            ?.attributes['src'] ??
        defaultCover;
    List<String> genres =
        document
            .querySelectorAll(
              '.widget-work-genreList > .widget-work-genreItem > a',
            )
            .map((e) => e.text.trim())
            .toList();
    List<Chapter> chapters = [];

    final chapterElements = document.querySelectorAll('.widget-toc-chapter');
    for (var element in chapterElements) {
      final anchor = element.querySelector('a');
      final chapterPath = anchor?.attributes['href'];
      final chapterTitle = anchor?.text.trim() ?? '';

      if (chapterPath != null) {
        final chapter = Chapter(
          id: _shrinkURL(chapterPath),
          title: chapterTitle,
          content: '',
          chapterNumber: chapters.length + 1,
        );
        chapters.add(chapter);
      }
    }

    final novel = Novel(
      id: novelPath,
      title: title,
      coverImageUrl: coverImageUrl,
      description: description,
      genres: genres,
      artist: '',
      statusString: '',
      author: author,
      pluginId: name,
      chapters: chapters,
    );

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = _expandURL(chapterPath);
    final body = await _fetchApi(url);
    final document = parse(body);

    final chapterContentElement = document.querySelector('.widget-episodeBody');
    String chapterText = chapterContentElement?.innerHtml ?? '';

    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$site/search?q=$searchTerm';
    final body = await _fetchApi(url);
    final document = parse(body);

    List<Novel> novels = [];

    final workElements = document.querySelectorAll(
      '.Layout_layout__5aFuw > div:nth-child(2) > div:nth-child(1) > div',
    );

    for (var element in workElements) {
      final titleAnchor = element.querySelector('a');
      final title = titleAnchor?.text.trim() ?? '';
      final novelUrl = titleAnchor?.attributes['href'] ?? '';

      if (novelUrl.isNotEmpty && title.isNotEmpty) {
        final novel = Novel(
          id: _shrinkURL(novelUrl),
          title: title,
          coverImageUrl: defaultCover,
          pluginId: name,
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
        );
        novels.add(novel);
      }
    }
    return novels;
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) {
    return Future.value([]);
  }
}
