import 'dart:io';

import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class NovelasLigera implements PluginService {
  @override
  String get name => 'NovelasLigera';

  @override
  Map<String, dynamic> get filters => {};

  final String id = 'novelasligera';
  final String nameService = 'novelasligera';
  final String baseURL = 'https://novelasligera.com/';
  final String version = '1.0.0';
  final String icon = 'src/es/novelasligera/icon.png';
  final String site = 'https://novelasligera.com/';

  static const String defaultCover =
      'https://placehold.co/400x500.png?text=Sem+Capa';

  NovelasLigera() {
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
    return url.replaceAll(RegExp(r'^.+novelasligera\.com'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = baseURL;
    final body = await _fetchApi(url);
    final document = parse(body);

    List<Novel> novels = [];

    final novelElements = document.querySelectorAll('.elementor-column');

    for (var element in novelElements) {
      final novelName =
          element
              .querySelector('.widget-image-caption.wp-caption-text')
              ?.text
              .trim();

      if (novelName != null) {
        final novelCover =
            element.querySelector('a > img')?.attributes['data-lazy-src'];
        final novelUrl = element.querySelector('a')?.attributes['href'];

        if (novelUrl == null) continue;

        final novel = Novel(
          id: _shrinkURL(novelUrl),
          title: novelName,
          coverImageUrl: novelCover ?? defaultCover,
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
  Future<Novel> parseNovel(String novelPath) async {
    final url = _expandURL(novelPath);
    final body = await _fetchApi(url);
    final document = parse(body);

    final novel = Novel(
      id: novelPath,
      title: document.querySelector('h1')?.text.trim() ?? 'Sem título',
      coverImageUrl:
          document
              .querySelector('.elementor-widget-container')
              ?.querySelector('img')
              ?.attributes['data-lazy-src'] ??
          defaultCover,
      description:
          document
              .querySelector('.elementor-text-editor.elementor-clearfix')
              ?.text
              .trim() ??
          '',
      genres: [],
      artist: '',
      statusString: '',
      author: '',
      pluginId: name,
      chapters: [],
    );

    final infoElements = document.querySelectorAll('.elementor-row > p');
    for (var element in infoElements) {
      final text = element.text;
      if (text.contains('Autor:')) {
        novel.author = text.replaceAll('Autor:', '').trim();
      }
      if (text.contains('Estado:')) {
        final statusString = text.replaceAll('Estado:', '').trim();
        switch (statusString.toLowerCase()) {
          case 'finalizado':
            novel.status = NovelStatus.Completa;
            break;
          case 'en curso':
            novel.status = NovelStatus.Andamento;
            break;
          default:
            novel.status = NovelStatus.Desconhecido;
            break;
        }
      }

      if (text.contains('Género:')) {
        element.querySelectorAll('span').forEach((e) => e.remove());
        novel.genres =
            text
                .replaceAll('Género:', '')
                .split(',')
                .map((e) => e.trim())
                .toList();
      }
    }

    final chapterElements = document.querySelectorAll(
      '.elementor-tab-content li a',
    );

    int chapterNumber = 1;

    for (var element in chapterElements) {
      final chapterName = element.text.trim();
      final chapterUrl = element.attributes['href'];

      if (chapterUrl != null) {
        final chapter = Chapter(
          id: _shrinkURL(chapterUrl),
          title: chapterName,
          content: '',
          chapterNumber: chapterNumber,
        );

        novel.chapters.add(chapter);
        chapterNumber++;
      }
    }
    novel.chapters = novel.chapters.reversed.toList();
    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final url = _expandURL(chapterPath);
    final body = await _fetchApi(url);
    final document = parse(body);

    document
        .querySelectorAll('.osny-nightmode.osny-nightmode--left')
        .forEach((e) => e.remove());
    document
        .querySelectorAll('.code-block.code-block-1')
        .forEach((e) => e.remove());
    document.querySelectorAll('.adsb30').forEach((e) => e.remove());
    document.querySelectorAll('.saboxplugin-wrap').forEach((e) => e.remove());
    document.querySelectorAll('.wp-post-navigation').forEach((e) => e.remove());

    final chapterText =
        document.querySelector('.entry-content')?.innerHtml ?? '';
    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$baseURL?s=$searchTerm&post_type=wp-manga';
    final body = await _fetchApi(url);
    final document = parse(body);

    List<Novel> novels = [];
    final novelElements = document.querySelectorAll('.inside-article');

    for (var element in novelElements) {
      final novelCover = element.querySelector('img')?.attributes['src'];
      var novelUrl = element.querySelector('a')?.attributes['href'];
      String? novelName;

      if (novelUrl != null) {
        novelName = novelUrl
            .replaceAll('-', ' ')
            .replaceFirstMapped(
              RegExp(r'^.'),
              (match) => match.group(0)!.toUpperCase(),
            );
      }

      novelUrl = '$novelUrl/';

      if (novelName == null || novelUrl == null) continue;

      final novel = Novel(
        id: _shrinkURL(novelUrl),
        title: novelName,
        coverImageUrl: novelCover ?? defaultCover,
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
    if (novels.length > 1) {
      novels = [novels[1]];
    }
    return novels;
  }

  @override
  Future<List<Novel>> getAllNovels({BuildContext? context}) {
    // TODO: implement getAllNovels
    throw UnimplementedError();
  }
}
