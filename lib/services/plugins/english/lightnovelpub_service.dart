import 'dart:io';
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:dio/dio.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class LightNovelPub implements PluginService {
  @override
  String get name => 'LightNovelPub';

  String get version => '1.0.0';

  String get icon => 'src/pt-br/lightnovelpub/icon.png';

  String get id => 'LightNovelPub';

  String get nameService => 'LightNovelPub';

  final String baseURL = 'https://www.lightnovelpub.com';
  final Dio dio = Dio();
  final Random _random = Random();

  final List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Edg/120.0.2210.144',
  ];

  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Sem%20Capa';

  LightNovelPub() {
    HttpOverrides.global = MyHttpOverrides();
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': _userAgents[0],
    };
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+lightnovelpub\.com'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  Future<Response> _fetchApi(
    String url, {
    BuildContext? context,
    int retries = 3,
  }) async {
    try {
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));

      final response = await dio.get(
        url,
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'User-Agent': _userAgents[_random.nextInt(_userAgents.length)],
          },
        ),
      );

      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 403 && retries > 0) {
        print('Received 403, retrying... ($retries retries left)');
        await Future.delayed(
          Duration(seconds: (4 - retries) * 2 + _random.nextInt(3)),
        );
        return _fetchApi(url, context: context, retries: retries - 1);
      } else {
        print(
          'Request to $url failed with status code: ${response.statusCode}',
        );
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load data: Status code ${response.statusCode}',
              ),
            ),
          );
        }
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } catch (e) {
      print('Error in _fetchApi: $e');
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
      rethrow;
    }
  }

  Future<List<Novel>> _parseNovelList(String url) async {
    try {
      final response = await _fetchApi(url);
      final body = response.data;
      final document = parse(body);

      final novelElements = document.querySelectorAll('div.novel-list-item');

      List<Novel> novels = [];
      for (final element in novelElements) {
        try {
          final titleElement = element.querySelector('.novel-title a');
          final title = titleElement?.text.trim() ?? '';
          final link = _shrinkURL(titleElement?.attributes['href'] ?? '');
          final coverElement = element.querySelector('.novel-cover img');
          final cover = coverElement?.attributes['data-src'] ?? defaultCover;
          final author =
              element.querySelector('.novel-author')?.text.trim() ?? 'Unknown';

          if (title.isNotEmpty && link.isNotEmpty) {
            novels.add(
              Novel(
                id: link,
                title: title,
                coverImageUrl: cover,
                author: author,
                description: '',
                genres: [],
                chapters: [],
                artist: '',
                statusString: '',
                pluginId: name,
              ),
            );
          }
        } catch (e) {
          print('Erro ao processar item da lista: $e');
        }
      }
      return novels;
    } catch (e) {
      print('Erro ao obter lista de novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url = '$baseURL/browse/most-popular-novel/all/$pageNo?page=$pageNo';
    try {
      return await _parseNovelList(url);
    } catch (e) {
      print('Erro ao obter novels populares: $e');
      return [];
    }
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    final url =
        '$baseURL/browse/recently-updated-novel/all/$pageNo?page=$pageNo';
    try {
      return await _parseNovelList(url);
    } catch (e) {
      print('Erro ao obter novels recentes: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    try {
      final url = '$baseURL/lnsearchlive';

      final link = '$baseURL/search';
      final response = await _fetchApi(link);
      final document = parse(response.data);
      final verifytoken =
          document
              .querySelector(
                "#novelSearchForm input[name=__LNRequestVerifyToken]",
              )
              ?.attributes['value'];

      if (verifytoken == null) {
        throw Exception('LNRequestVerifyToken not found');
      }

      final formData = FormData.fromMap({'inputContent': searchTerm});

      final searchResponse = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'LNRequestVerifyToken': verifytoken,
            'User-Agent': _userAgents[_random.nextInt(_userAgents.length)],
          },
        ),
      );

      final resultView = searchResponse.data['resultview'];
      if (resultView != null) {
        final searchDocument = parse(resultView);
        final novelElements = searchDocument.querySelectorAll('.novel-item a');

        List<Novel> novels = [];
        for (final element in novelElements) {
          final titleElement = element.querySelector(
            'div.item-body .novel-title',
          );
          final title = titleElement?.text.trim() ?? '';
          final link = _shrinkURL(element.attributes['href'] ?? '');
          final coverElement = element.querySelector('div.novel-cover img');
          final cover = coverElement?.attributes['src'] ?? defaultCover;

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
      } else {
        throw Exception('Search results not found in response');
      }
    } catch (e) {
      print('Erro na busca de novels: $e');
      return [];
    }
  }

  @override
  Future<Novel> parseNovel(String novelPath, {BuildContext? context}) async {
    try {
      final response = await _fetchApi(_expandURL(novelPath));
      final document = parse(response.data);

      final title =
          document.querySelector('.novel-title')?.text.trim() ?? 'Sem título';
      final coverElement = document.querySelector('.novel-cover img');
      final cover = coverElement?.attributes['data-src'] ?? defaultCover;
      final author =
          document.querySelector('.novel-author')?.text.trim() ??
          'Desconhecido';
      final description =
          document.querySelector('.novel-summary')?.text.trim() ??
          'Sem descrição';
      final genres =
          document
              .querySelectorAll('.novel-genres a')
              .map((e) => e.text.trim())
              .toList();

      final statusSpan = document.querySelector('.novel-stats span.status');
      String statusString = statusSpan?.text.trim() ?? 'Unknown';

      NovelStatus status;
      if (statusString.contains('Ongoing')) {
        status = NovelStatus.Ongoing;
      } else if (statusString.contains('Completed')) {
        status = NovelStatus.Completed;
      } else {
        status = NovelStatus.Unknown;
      }

      final List<Chapter> chapters = [];
      final chapterElements = document.querySelectorAll('.chapter-list li a');
      int order = 0;
      for (final chapterElement in chapterElements) {
        order++;
        final chapterPath = _shrinkURL(chapterElement.attributes['href'] ?? '');
        final chapterTitle =
            chapterElement.querySelector('.chapter-title')?.text.trim() ?? '';

        if (chapterPath.isNotEmpty && chapterTitle.isNotEmpty) {
          chapters.add(
            Chapter(
              id: chapterPath,
              title: chapterTitle,
              order: order,
              content: '',
              releaseDate: '',
              chapterNumber: null,
            ),
          );
        }
      }
      chapters.sort((a, b) => a.order.compareTo(b.order));

      return Novel(
        id: novelPath,
        title: title,
        coverImageUrl: cover,
        author: author,
        description: description,
        genres: genres,
        status: status,
        chapters: chapters,
        artist: '',
        statusString: '',
        pluginId: nameService,
      );
    } catch (e) {
      print('Erro ao processar os detalhes da novel: $e');
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
      final response = await _fetchApi(_expandURL(chapterPath));
      final document = parse(response.data);

      final chapterContentElement = document.querySelector(
        'div.chapter-content',
      );

      if (chapterContentElement != null) {
        chapterContentElement
            .querySelectorAll('div[id^="div-gpt-ad"]')
            .forEach((el) => el.remove());
        chapterContentElement
            .querySelectorAll('div.hidden')
            .forEach((el) => el.remove());
        chapterContentElement
            .querySelectorAll('div.ads-holder')
            .forEach((el) => el.remove());

        return chapterContentElement.innerHtml;
      } else {
        throw Exception('Chapter content not found at $chapterPath');
      }
    } catch (e) {
      print('Erro ao processar o capítulo: $e');
      return 'Erro ao carregar o conteúdo do capítulo.';
    }
  }

  @override
  Map<String, dynamic> get filters => {
    'order': {
      'label': 'Ordenar por',
      'value': 'default',
      'options': [
        {'label': 'Padrão', 'value': 'default'},
        {'label': 'A-Z', 'value': 'a-z'},
        {'label': 'Z-A', 'value': 'z-a'},
        {'label': 'Últ. Att', 'value': 'latest-update'},
        {'label': 'Últ. Add', 'value': 'latest-added'},
        {'label': 'Populares', 'value': 'popular'},
      ],
    },
    'status': {
      'label': 'Status',
      'value': 'all',
      'options': [
        {'label': 'Todos', 'value': 'all'},
        {'label': 'Em andamento', 'value': 'ongoing'},
        {'label': 'Completo', 'value': 'completed'},
      ],
    },
    'genres': {
      'label': 'Gêneros',
      'value': [],
      'options': [
        {'label': 'All', 'value': 'all'},
        {'label': 'Action', 'value': 'action'},
        {'label': 'Adventure', 'value': 'adventure'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Fantasy', 'value': 'fantasy'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'Martial Arts', 'value': 'martial-arts'},
        {'label': 'Mature', 'value': 'mature'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'Tragedy', 'value': 'tragedy'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
        {'label': 'Ecchi', 'value': 'ecchi'},
        {'label': 'Comedy', 'value': 'comedy'},
        {'label': 'Slice of Life', 'value': 'slice-of-life'},
        {'label': 'Mystery', 'value': 'mystery'},
        {'label': 'Supernatural', 'value': 'supernatural'},
        {'label': 'Psychological', 'value': 'psychological'},
        {'label': 'Sci-fi', 'value': 'sci-fi'},
        {'label': 'Xianxia', 'value': 'xianxia'},
        {'label': 'School Life', 'value': 'school-life'},
        {'label': 'Josei', 'value': 'josei'},
        {'label': 'Wuxia', 'value': 'wuxia'},
        {'label': 'Shounen', 'value': 'shounen'},
        {'label': 'Horror', 'value': 'horror'},
        {'label': 'Mecha', 'value': 'mecha'},
        {'label': 'Historical', 'value': 'historical'},
        {'label': 'Shoujo', 'value': 'shoujo'},
        {'label': 'Adult', 'value': 'adult'},
        {'label': 'Seinen', 'value': 'seinen'},
        {'label': 'Sports', 'value': 'sports'},
        {'label': 'Lolicon', 'value': 'lolicon'},
        {'label': 'Gender Bender', 'value': 'gender-bender'},
        {'label': 'Shounen Ai', 'value': 'shounen-ai'},
        {'label': 'Yaoi', 'value': 'yaoi'},
        {'label': 'Video Games', 'value': 'video-games'},
        {'label': 'Smut', 'value': 'smut'},
        {'label': 'Magical Realism', 'value': 'magical-realism'},
        {'label': 'Eastern Fantasy', 'value': 'eastern-fantasy'},
        {'label': 'Contemporary Romance', 'value': 'contemporary-romance'},
        {'label': 'Fantasy Romance', 'value': 'fantasy-romance'},
        {'label': 'Shoujo Ai', 'value': 'shoujo-ai'},
        {'label': 'Yuri', 'value': 'yuri'},
      ],
    },
  };
}
