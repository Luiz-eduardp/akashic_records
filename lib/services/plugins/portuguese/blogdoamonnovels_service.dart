import 'dart:async';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class BlogDoAmonNovels implements PluginService {
  @override
  String get name => 'BlogDoAmonNovels';

  String get id => 'BlogDoAmonNovels';

  String get version => '1.0.0';

  @override
  Map<String, dynamic> get filters => {};

  final String baseURL = 'https://www.blogdoamonnovels.com';
  final String icon = 'src/pt-br/blogdoamonnovels/icon.png';

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Sem%20Capa';

  Future<String> _fetchApi(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': baseURL,
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 403) {
        print('Erro 403: Acesso proibido para a URL: $url');
        return '';
      } else {
        throw Exception(
          'Falha ao carregar dados de: $url - Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return '';
    }
  }

  List<Novel> _parseNovels(String body) {
    List<Novel> novels = [];
    try {
      final json = parseJson(body);
      if (json != null &&
          json['feed'] != null &&
          json['feed']['entry'] != null) {
        for (var entry in json['feed']['entry']) {
          String title = entry['title']['\$t'];
          String link =
              (entry['link'] as List).firstWhere(
                (link) => link['rel'] == 'alternate',
              )['href'];
          if (link != null) {
            String cover =
                entry['media\$thumbnail']['url'].replaceAll(
                  "/s72-c/",
                  "/w340/",
                ) ??
                defaultCover;
            String path = link.replaceAll(baseURL, "");
            novels.add(
              Novel(
                id: path,
                title: title,
                coverImageUrl: cover,
                description: '',
                genres: [],
                chapters: [],
                artist: '',
                statusString: '',
                pluginId: id,
                author: '',
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao parsear novels: $e');
    }
    return novels;
  }

  dynamic parseJson(String jsonString) {
    return null;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    if (pageNo > 1) {
      return [];
    }

    String body = await _fetchApi(baseURL);
    if (body.isEmpty) {
      return [];
    }

    final document = parse(body);
    final popularPosts = document.querySelectorAll('.PopularPosts article');

    List<Novel> novels = [];
    for (var post in popularPosts) {
      final titleElement = post.querySelector('h3 a');
      final title = titleElement?.text.trim() ?? '';
      final link = titleElement?.attributes['href'];
      final imgElement = post.querySelector('img');
      final cover = imgElement?.attributes['src'] ?? defaultCover;

      if (link != null) {
        String path = link.replaceAll(baseURL, "");
        novels.add(
          Novel(
            id: path,
            title: title,
            coverImageUrl: cover,
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: id,
            author: '',
          ),
        );
      }
    }
    return novels;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    String body = await _fetchApi(baseURL + novelPath);
    if (body.isEmpty) {
      return Novel(
        id: novelPath,
        title: 'Erro ao carregar',
        coverImageUrl: defaultCover,
        description: 'Não foi possível carregar os dados do novel.',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        pluginId: id,
        author: '',
      );
    }

    final document = parse(body);

    final title =
        document.querySelector('[itemprop="name"]')?.text ?? "Untitled";
    final cover =
        document.querySelector('img[itemprop="image"]')?.attributes['src'];
    final summaryElement = document.querySelector("#synopsis");
    final summary = summaryElement?.text.trim() ?? '';
    final artist =
        document
            .querySelector('#extra-info dl:contains("Artista") dd')
            ?.text
            .trim() ??
        '';
    final status = document.querySelector("[data-status]")?.text.trim() ?? '';
    final genreElements = document
        .querySelectorAll('dt:contains("Gênero:")')
        .first
        .parent
        ?.querySelectorAll("a");

    List<String> genres = genreElements!.map((e) => e.text.trim()).toList();

    List<Chapter> chapters = [];
    final chapterList = document.querySelector("#chapters chapter");
    if (chapterList != null) {
      final chapterElements = chapterList.querySelectorAll('a');
      for (var element in chapterElements) {
        final chapterTitle = element.text.trim();
        final chapterPath = element.attributes['href'];

        if (chapterPath != null) {
          String path = chapterPath.replaceAll(baseURL, "");
          chapters.add(
            Chapter(id: path, title: chapterTitle, content: '', order: 0),
          );
        }
      }

      chapters = chapters.reversed.toList();
      int chapterNumber = 1;
      for (var chapter in chapters) {
        chapter.title = "${chapter.title} - Ch. $chapterNumber";
        chapter.chapterNumber = chapterNumber;
        chapterNumber++;
      }
    }

    return Novel(
      id: novelPath,
      title: title,
      coverImageUrl: cover ?? defaultCover,
      description: summary,
      genres: genres,
      chapters: chapters,
      artist: artist,
      statusString: status,
      pluginId: id,
      author: '',
    );
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    String body = await _fetchApi(baseURL + chapterPath);
    if (body.isEmpty) {
      return 'Não foi possível carregar o conteúdo do capítulo.';
    }

    final document = parse(body);
    final contentElement = document.querySelector('.conteudo_teste');

    contentElement?.querySelectorAll('p').forEach((element) {
      final img = element.querySelector('img');
      final text = element.text.replaceAll(RegExp(r'\s| '), "");

      if (img == null && (text == null || text.isEmpty)) {
        element.remove();
      }
    });

    return contentElement?.innerHtml ?? '';
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final params = {
      'alt': 'json',
      'max-results': '10',
      'q': 'label:Series ${searchTerm.trim()}',
    };
    if (pageNo > 1) {
      params['start-index'] = (10 * (pageNo - 1) + 1).toString();
    }

    final url =
        Uri.parse(
          '$baseURL/feeds/posts/summary',
        ).replace(queryParameters: params).toString();
    String body = await _fetchApi(url);
    if (body.isEmpty) {
      return [];
    }
    return _parseNovels(body);
  }

  String createFilterUrl(
    Map<String, dynamic>? filters,
    String order,
    int page,
  ) {
    return baseURL;
  }
}
