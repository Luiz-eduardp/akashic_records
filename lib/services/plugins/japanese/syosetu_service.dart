import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

class Syosetu implements PluginService {
  @override
  String get name => 'Syosetu';

  @override
  String get lang => 'ja';
  @override
  String get siteUrl => site; 
  @override
  Map<String, dynamic> get filters => {
    'ranking': {
      'type': 'picker',
      'label': 'Ranked by',
      'options': [
        {'label': '日間', 'value': 'daily'},
        {'label': '週間', 'value': 'weekly'},
        {'label': '月間', 'value': 'monthly'},
        {'label': '四半期', 'value': 'quarter'},
        {'label': '年間', 'value': 'yearly'},
        {'label': '累計', 'value': 'total'},
      ],
      'value': 'total',
    },
    'genre': {
      'type': 'picker',
      'label': 'Ranking Genre',
      'options': [
        {'label': '総ジャンル', 'value': ''},
        {'label': '異世界転生/転移〔恋愛〕〕', 'value': '1'},
        {'label': '異世界転生/転移〔ファンタジー〕', 'value': '2'},
        {'label': '異世界転生/転移〔文芸・SF・その他〕', 'value': 'o'},
        {'label': '異世界〔恋愛〕', 'value': '101'},
        {'label': '現実世界〔恋愛〕', 'value': '102'},
        {'label': 'ハイファンタジー〔ファンタジー〕', 'value': '201'},
        {'label': 'ローファンタジー〔ファンタジー〕', 'value': '202'},
        {'label': '純文学〔文芸〕', 'value': '301'},
        {'label': 'ヒューマンドラマ〔文芸〕', 'value': '302'},
        {'label': '歴史〔文芸〕', 'value': '303'},
        {'label': '推理〔文芸〕', 'value': '304'},
        {'label': 'ホラー〔文芸〕', 'value': '305'},
        {'label': 'アクション〔文芸〕', 'value': '306'},
        {'label': 'コメディー〔文芸〕', 'value': '307'},
        {'label': 'VRゲーム〔SF〕', 'value': '401'},
        {'label': '宇宙〔SF〕', 'value': '402'},
        {'label': '空想科学〔SF〕', 'value': '403'},
        {'label': 'パニック〔SF〕', 'value': '404'},
        {'label': '童話〔その他〕', 'value': '9901'},
        {'label': '詩〔その他〕', 'value': '9902'},
        {'label': 'エッセイ〔その他〕', 'value': '9903'},
        {'label': 'その他〔その他〕', 'value': '9999'},
      ],
      'value': '',
    },
    'modifier': {
      'type': 'picker',
      'label': 'Modifier',
      'options': [
        {'label': 'すべて', 'value': 'total'},
        {'label': '連載中', 'value': 'r'},
        {'label': '完結済', 'value': 'er'},
        {'label': '短編', 'value': 't'},
      ],
      'value': 'total',
    },
  };

  final String id = 'Syosetu';
  final String icon = 'src/jp/syosetu/icon.png';
  final String site = 'https://yomou.syosetu.com/';
  final String novelPrefix = 'https://syosetu.com/';
  @override
  final String version = '1.0.10';
  final Map<String, String> headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  };

  String searchUrl(String? page, String? order) {
    return '$site/search.php?order=${order ?? "hyoka"}${page != null ? "&p=${(int.tryParse(page) ?? 1) <= 1 || (int.tryParse(page) ?? 101) > 100 ? "1" : page}" : ""}';
  }

  static const String defaultCover =
      'https://placehold.co/400x500.png?text=no+cover';

  Future<String> _fetchApi(String url, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+ncode\.syosetu\.com'), '');
  }

  String _expandURL(String path) {
    return novelPrefix + path;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final String ranking = filters?['ranking']?['value'] ?? 'total';
    final String genre = filters?['genre']?['value'] ?? '';
    final String modifier = filters?['modifier']?['value'] ?? 'total';
    final String page = pageNo.toString();

    String url;
    if (genre.isNotEmpty) {
      url =
          '$site/rank/${genre.length == 1 ? "isekailist" : "genrelist"}/type/${ranking}_$genre${modifier == "total" ? "" : "_$modifier"}?p=$page';
    } else {
      url = '$site/rank/list/type/${ranking}_$modifier/?p=$page';
    }

    print("Popular URL: $url");

    final body = await _fetchApi(url, headers: headers);
    final document = parse(body);

    List<Novel> novels = [];

    final novelElements = document.querySelectorAll('.c-card');

    for (var element in novelElements) {
      final anchor = element.querySelector('.p-ranklist-item__title a');
      final path = anchor?.attributes['href'];

      if (path != null) {
        final name = anchor?.text.trim();

        final novel = Novel(
          id: _shrinkURL(path.replaceFirst(novelPrefix, '')),
          title: name ?? 'Unknown Title',
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

  Future<List<Chapter>> _parseChaptersFromDocument(
    dom.Document document,
  ) async {
    List<Chapter> chapters = [];
    for (var element in document.querySelectorAll('.p-eplist__sublist')) {
      final anchor = element.querySelector('a');
      final href = anchor?.attributes['href'];
      final name = anchor?.text.trim() ?? '';
      final releaseTimeText = element
          .querySelector('.p-eplist__update')
          ?.text
          .trim()
          .split(" ")[0]
          .replaceAll('/', '-');
      final releaseTime = releaseTimeText ?? '';

      if (href != null) {
        chapters.add(
          Chapter(
            id: _shrinkURL(href.replaceFirst(novelPrefix, '')),
            title: name,
            content: '',
            chapterNumber: chapters.length + 1,
            releaseDate: releaseTime,
          ),
        );
      }
    }
    return chapters;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final url = _expandURL(novelPath);
    final body = await _fetchApi(url, headers: headers);
    final document = parse(body);

    String title =
        document.querySelector('.p-novel__title')?.text.trim() ?? 'Sem título';
    String author =
        document.querySelector('.p-novel__author a')?.text.trim() ??
        'Sem Autor';
    String description =
        document.querySelector('#novel_ex')?.innerHtml ?? 'Sem Descrição';
    final descriptionTag =
        document
            .querySelector('meta[property="og:description"]')
            ?.attributes['content'];
    String genresString = descriptionTag ?? '';
    List<String> genres = genresString.split(" ").map((e) => e.trim()).toList();

    NovelStatus status = NovelStatus.Desconhecido;

    String statusString =
        document.querySelector('.c-announce')?.text.trim() ?? '';
    if (statusString.contains("連載中") || statusString.contains("未完結")) {
      status = NovelStatus.Andamento;
    } else if (statusString.contains("完結")) {
      status = NovelStatus.Completa;
    }

    List<Chapter> chapters = [];
    String? nextPageUrl = novelPath;
    while (nextPageUrl != null) {
      final pageUrl = _expandURL(nextPageUrl);
      final pageBody = await _fetchApi(pageUrl, headers: headers);
      final pageDocument = parse(pageBody);
      chapters.addAll(await _parseChaptersFromDocument(pageDocument));

      final nextPageAnchor = pageDocument.querySelector(
        '.c-pager__item--next a',
      );
      nextPageUrl = nextPageAnchor?.attributes['href'];
      if (nextPageUrl != null) {
        nextPageUrl = novelPath + nextPageUrl;
      }
    }

    final novel = Novel(
      id: novelPath,
      title: title,
      coverImageUrl: defaultCover,
      description: description,
      genres: genres,
      artist: '',
      status: status,
      statusString: statusString,
      author: author,
      pluginId: name,
      chapters: chapters,
    );

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = _expandURL(chapterPath);
    final body = await _fetchApi(url, headers: headers);
    final document = parse(body);

    final chapterTitle =
        document.querySelector('.p-novel__title')?.innerHtml ?? '';
    final chapterText =
        document
            .querySelector(
              '.p-novel__body .p-novel__text:not([class*="p-novel__text--"])',
            )
            ?.innerHtml ??
        '';

    return "<h1>$chapterTitle</h1>$chapterText";
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    String url = searchUrl(pageNo.toString(), null) + "&word=" + searchTerm;

    final body = await _fetchApi(url, headers: headers);
    final document = parse(body);

    List<Novel> novels = [];

    final novelElements = document.querySelectorAll(".searchkekka_box");

    for (var element in novelElements) {
      final titleAnchor = element.querySelector(".novel_h a");
      final novelPath = titleAnchor?.attributes['href'];
      final novelName = titleAnchor?.text.trim() ?? '';

      if (novelPath != null) {
        final novel = Novel(
          id: _shrinkURL(novelPath.replaceFirst(novelPrefix, '')),
          title: novelName,
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
