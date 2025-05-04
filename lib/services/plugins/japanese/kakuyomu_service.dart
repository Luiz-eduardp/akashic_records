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
            {'label': '詩・童話・その他', 'value': 'others'}
          ],
          'value': 'all'
        },
        'period': {
          'type': 'picker',
          'label': 'Period',
          'options': [
            {'label': '累計', 'value': 'entire'},
            {'label': '日間', 'value': 'daily'},
            {'label': '週間', 'value': 'weekly'},
            {'label': '月間', 'value': 'monthly'},
            {'label': '年間', 'value': 'yearly'}
          ],
          'value': 'entire'
        }
      };

  final String id = 'Kakuyomu';
  final String icon = 'src/jp/kakuyomu/icon.png';
  final String site = 'https://kakuyomu.jp';
  @override
  final String version = '1.0.0';
  final String baseURL = 'https://kakuyomu.jp'; // Add baseURL
  final String defaultCover = 'https://placehold.co/400x500.png?text=Kakuyomu'; // Placeholder

  // You might need to configure imageRequestInit if you need special headers.

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
      // URLSearchParams are not directly available in dart so manual implementation
       print("Popular URL: $url");
    }

    final body = await _fetchApi(url);
    final document = parse(body);

    List<Novel> novels = [];
    final novelElements = document.querySelectorAll('.widget-media-genresWorkList-right > .widget-work');

    for (var element in novelElements) {
      final anchor = element.querySelector('a.widget-workCard-titleLabel');
      final path = anchor?.attributes['href'];

      if (path != null) {
        final name = anchor?.text.trim();

        final novel = Novel(
          id: _shrinkURL(path),
          title: name ?? 'Unknown Title',
          coverImageUrl: defaultCover, //Kakuyomu does not expose cover url directly, might have to extract this from the novel parse
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

    // Extract necessary data using the parsed HTML document.
    String title = document.querySelector('.widget-work-header-title')?.text.trim() ?? 'Sem título';
    String author = document.querySelector('.widget-creator-username')?.text.trim() ?? 'Sem Autor';
    String description = document.querySelector('.widget-work-introduction')?.text.trim() ?? 'Sem Descrição';
    String coverImageUrl = defaultCover; //Replace this when image extraction logic is determined
    List<String> genres = document.querySelectorAll('.widget-work-genreList > .widget-work-genreItem > a').map((e) => e.text.trim()).toList();
//Need to implement logic to get the novel status
    List<Chapter> chapters = [];

    //Extract Chapters
    final chapterElements = document.querySelectorAll('.widget-toc-chapter');
    for (var chapterElement in chapterElements) {
      final anchor = chapterElement.querySelector('a');
      final chapterPath = anchor?.attributes['href'];
      final chapterTitle = anchor?.text.trim() ?? '';

      if (chapterPath != null) {
        final chapter = Chapter(
          id: _shrinkURL(chapterPath),
          title: chapterTitle,
          content: '', //Chapter Content Parsing is done later
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
  Future<List<Novel>> searchNovels(String searchTerm, int pageNo, {Map<String, dynamic>? filters}) async {
      final url = '$site/search?q=$searchTerm'; // Use the search URL

    final body = await _fetchApi(url);
    final document = parse(body);

    List<Novel> novels = [];
    // Adjust this selector according to the actual HTML structure of the search results page.
    final novelElements = document.querySelectorAll('.widget-workCard');  // changed from what you had.  Use this to target your elements
    for (var element in novelElements) {
        final novelUrl = element.querySelector('a')?.attributes['href'];
        final novelName = element.querySelector('.widget-workCard-titleLabel')?.text.trim();


        if (novelName == null || novelUrl == null) continue;


        final novel = Novel(
          id: _shrinkURL(novelUrl),
          title: novelName,
          coverImageUrl: defaultCover, // Kakuyomu doesn't directly expose cover URL on listing
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

    return novels;

  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) {
    // getAllNovels is not typically implemented for a plugin like this.
    // It depends on how you want to present a combined view of all novels.
    return Future.value([]);
  }
}