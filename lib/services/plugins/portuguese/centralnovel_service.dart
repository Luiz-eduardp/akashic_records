import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class CentralNovel implements PluginService {
  @override
  String get name => 'CentralNovel';

  @override
  Map<String, dynamic> get filters => {};

  final String id = 'CentralNovel';
  final String nameService = 'Central Novel';
  final String baseURL = 'https://centralnovel.com';
  final String imageURL =
      'https://centralnovel.com/wp-content/uploads/2021/06/CENTRAL-NOVEL-LOGO-DARK-.png';
  final String version = '1.0.1';

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Sem%20Capa';

  CentralNovel() {
    HttpOverrides.global = MyHttpOverrides();
  }

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+centralnovel\.com'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  Future<List<Novel>> _parseList(String url) async {
    final body = await _fetchApi(url);
    final document = parse(body);
    final novelElements = document.querySelectorAll(
      'div.listupd div.mdthumb a.tip',
    );

    List<Novel> novels = [];
    for (var element in novelElements) {
      final imgElement = element.querySelector('img');
      final title = imgElement?.attributes['title'] ?? '';
      final cover =
          imgElement?.attributes['src']?.replaceAll(
            RegExp(r'e=\d+,\d+'),
            'e=370,500',
          ) ??
          defaultCover;
      final link = _shrinkURL(element.attributes['href'] ?? '');

      if (title.isNotEmpty && link.isNotEmpty) {
        novels.add(
          Novel(
            id: link,
            title: title,
            coverImageUrl: cover,
            author: '',
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
            pluginId: name,
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
  }) async {
    final url = 'https://centralnovel.com/series/?order=popular&page=$pageNo';
    return await _parseList(url);
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = 'https://centralnovel.com/series/?order=update&page=$pageNo';
    return await _parseList(url);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi(_expandURL(novelPath));
    final document = parse(body);

    final img = document.querySelector('div.thumb > img');
    final info = document.querySelector('div.ninfo > div.info-content');

    final novel = Novel(
      id: novelPath,
      title: img?.attributes['title'] ?? 'Sem título',
      coverImageUrl: img?.attributes['src'] ?? defaultCover,
      description:
          document.querySelector('div.entry-content')?.text.trim() ?? '',
      genres:
          info
              ?.querySelectorAll('div.genxed > a')
              .map((v) => v.text.trim())
              .toList() ??
          [],
      chapters: [],
      artist: '',
      statusString: '',
      author: '',
      pluginId: name,
    );
    final statusElement = document.querySelector('div.spe > span');
    final statusString = statusElement?.text.replaceAll('Status:', '').trim();

    switch (statusString) {
      case 'Em andamento':
        novel.status = NovelStatus.Andamento;
        break;
      case 'Completo':
        novel.status = NovelStatus.Completa;
        break;
      case 'Hiato':
        novel.status = NovelStatus.Pausada;
        break;
      default:
        novel.status = NovelStatus.Desconhecido;
    }

    final chapterElements = document.querySelectorAll('div.eplister li > a');
    int chapterNumber = 1;
    for (var el in chapterElements.reversed) {
      final num = el.querySelector('div.epl-num')?.text.trim() ?? '';
      final title = el.querySelector('div.epl-title')?.text.trim() ?? '';
      final chapterName = '$num $title';

      final chapterPath = _shrinkURL(el.attributes['href'] ?? '');
      if (chapterPath.isNotEmpty && chapterName.isNotEmpty) {
        novel.chapters.add(
          Chapter(
            id: chapterPath,
            title: chapterName,
            content: '',
            chapterNumber: chapterNumber,
          ),
        );
        chapterNumber++;
      }
    }
    novel.chapters = novel.chapters.reversed.toList();
    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi(_expandURL(chapterPath));
    final document = parse(body);
    final title =
        document.querySelector('div.epheader > div.cat-series')?.text.trim() ??
        '';
    final text = document.querySelector('div.epcontent');

    text?.querySelectorAll('p').forEach((element) {
      if (element.text.trim().isEmpty) {
        element.remove();
      }
    });
    text?.querySelectorAll('img').forEach((img) {
      img.attributes['style'] = 'max-width: 100%; height: auto;';
    });

    final chapterContent = '<h1>$title</h1>${text?.innerHtml ?? ''}';
    return chapterContent;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = 'https://centralnovel.com/series/?s=$searchTerm&page=$pageNo';
    return await _parseList(url);
  }
}
